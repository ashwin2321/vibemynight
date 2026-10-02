import datetime
import logging
import re
import json
from typing import List, Optional, Dict, Any
import httpx

from app.config import settings
from app.services.base_adapter import (
    BaseSourceAdapter,
    DiscoveredEvent,
    DeepScrapedEvent,
    ScrapedPass,
    ScrapedArtist,
    ScrapedDay,
    ScrapedImageCandidate,
    AdapterRegistry
)
from app.services.event_normalizer import EventNormalizer

logger = logging.getLogger(__name__)


class DistrictAdapter(BaseSourceAdapter):
    """Universal Dynamic Live Source Adapter for District by Zomato (district.in)."""

    def __init__(self, api_url: Optional[str] = None, timeout: float = 12.0):
        self.api_url = api_url or getattr(settings, "DISTRICT_API_URL", None)
        self.timeout = timeout

    @property
    def source_name(self) -> str:
        return "district"

    async def check_health(self) -> bool:
        """Verifies connectivity to live District platform."""
        try:
            async with httpx.AsyncClient(timeout=5.0, follow_redirects=True) as client:
                res = await client.get(
                    "https://www.district.in",
                    headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) VibeMyNight/1.0"}
                )
                return res.status_code in (200, 301, 302)
        except Exception as e:
            logger.warning(f"District health check failed: {e}")
            return False

    async def discover(
        self,
        city: Optional[str] = None,
        category: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> List[DiscoveredEvent]:
        """
        Discovers live events directly from District platform.
        Strictly live extraction - no hardcoded mock event fallbacks.
        """
        headers = {
            "Accept": "text/html,application/json",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }

        discovered: List[DiscoveredEvent] = []
        city_query = (city or "").strip().lower() if city and city.strip().upper() != "ALL" else ""

        # Step 1: If an API endpoint is configured, query it
        if self.api_url and self.api_url.startswith("http"):
            try:
                params: Dict[str, Any] = {"page": page, "limit": page_size}
                if city_query:
                    params["city"] = city_query
                if category and category.strip().upper() != "ALL":
                    params["category"] = category.strip()

                async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True) as client:
                    resp = await client.get(self.api_url, headers=headers, params=params)
                    if resp.status_code == 200:
                        data = resp.json()
                        raw_items = data.get("events") or data.get("data") or (data if isinstance(data, list) else [])
                        for item in raw_items:
                            parsed = self._parse_discovery_dict(item, category=category)
                            if parsed:
                                discovered.append(parsed)
            except Exception as e:
                logger.warning(f"District API discovery failed: {e}")

        # Step 2: Live HTML scraping from District
        if not discovered:
            target_urls = ["https://www.district.in/events"]
            if city_query:
                target_urls.insert(0, f"https://www.district.in/{city_query}/events")

            for url in target_urls:
                try:
                    async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True) as client:
                        resp = await client.get(url, headers=headers)
                        if resp.status_code != 200:
                            continue

                        extracted = self._extract_events_from_html(
                            resp.text,
                            base_url="https://www.district.in",
                            default_city=city,
                            category=category
                        )
                        if extracted:
                            discovered.extend(extracted)
                            break
                except Exception as e:
                    logger.warning(f"District live HTML discovery error for {url}: {e}")

        return discovered[:page_size]

    async def deep_scrape(
        self,
        event_url: str,
        hint_payload: Optional[Dict[str, Any]] = None
    ) -> DeepScrapedEvent:
        """
        Deep scrapes an individual District live event to extract nested hierarchy.
        Factual extraction only — missing fields become None.
        """
        hint = hint_payload or {}
        validated_url = EventNormalizer.validate_url(event_url) or event_url

        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/json"
        }

        page_html = ""
        remote_json: Optional[Dict[str, Any]] = None

        try:
            async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True) as client:
                res = await client.get(validated_url, headers=headers)
                if res.status_code == 200:
                    page_html = res.text
                    try:
                        remote_json = res.json()
                    except Exception:
                        pass
        except Exception as e:
            logger.warning(f"District deep-scrape fetch failed for {validated_url}: {e}")

        # Extract structured data from HTML or JSON
        source_data = dict(hint)
        if isinstance(remote_json, dict):
            source_data.update(remote_json)

        # ID extraction
        sid = str(source_data.get("id") or source_data.get("eventId") or source_data.get("source_event_id") or "")
        if not sid:
            match_id = re.search(r'/events/([^/?#]+)', validated_url)
            sid = match_id.group(1) if match_id else f"DST-{abs(hash(validated_url)) % 1000000}"

        # Title
        title = str(source_data.get("title") or source_data.get("name") or "").strip()
        if not title and page_html:
            title_m = re.search(r'<title>([^<|]+)', page_html)
            if title_m:
                title = title_m.group(1).strip()
        if not title:
            title = hint.get("title") or "District Event"

        # Description
        desc = EventNormalizer.normalize_string(source_data.get("description") or hint.get("description"))

        # Dates & Times
        start_d = EventNormalizer.normalize_date(source_data.get("startDate") or source_data.get("event_start_date") or hint.get("event_start_date"))
        end_d = EventNormalizer.normalize_date(source_data.get("endDate") or source_data.get("event_end_date") or hint.get("event_end_date") or start_d)
        start_t = EventNormalizer.normalize_time(source_data.get("time") or source_data.get("startTime") or hint.get("start_time"))
        end_t = EventNormalizer.normalize_time(source_data.get("endTime") or hint.get("end_time"))

        # Venue & Location
        venue = EventNormalizer.normalize_string(source_data.get("venue") or source_data.get("venue_name") or hint.get("venue_name"))
        address = EventNormalizer.normalize_string(source_data.get("address") or source_data.get("venue_address") or hint.get("venue_address"))
        city_val = EventNormalizer.normalize_city(source_data.get("city") or hint.get("city"))
        state_val = EventNormalizer.normalize_string(source_data.get("state") or hint.get("state"))

        # Prices
        min_p, max_p, curr = EventNormalizer.normalize_prices(
            source_data.get("priceStarting") or source_data.get("min_price") or hint.get("starting_price"),
            source_data.get("priceMax") or source_data.get("max_price")
        )

        # Artwork
        poster = EventNormalizer.validate_url(source_data.get("posterImage") or source_data.get("poster_url") or hint.get("poster_url"))
        banner = EventNormalizer.validate_url(source_data.get("bannerImage") or source_data.get("banner_url") or hint.get("banner_url"))

        artwork_candidates: List[ScrapedImageCandidate] = []
        if poster:
            artwork_candidates.append(ScrapedImageCandidate(url=poster, suggested_role="POSTER_3_4", alt_text=title))
        if banner and banner != poster:
            artwork_candidates.append(ScrapedImageCandidate(url=banner, suggested_role="BANNER_16_9", alt_text=f"{title} Banner"))

        # Nested Artists
        artists: List[ScrapedArtist] = []
        raw_artists = source_data.get("artists") or hint.get("artists") or []
        if isinstance(raw_artists, list):
            for a in raw_artists:
                if isinstance(a, dict) and a.get("name"):
                    artists.append(ScrapedArtist(
                        name=str(a.get("name")).strip(),
                        role=a.get("role"),
                        image_url=EventNormalizer.validate_url(a.get("imageUrl") or a.get("image_url") or a.get("photo")),
                        bio=a.get("bio")
                    ))

        # Nested Passes (No artificial defaulting)
        passes: List[ScrapedPass] = []
        raw_passes = source_data.get("passes") or hint.get("passes") or []
        if isinstance(raw_passes, list):
            for p in raw_passes:
                if isinstance(p, dict) and p.get("name"):
                    p_price, _, _ = EventNormalizer.normalize_prices(p.get("price"))
                    passes.append(ScrapedPass(
                        name=str(p.get("name")).strip(),
                        type=str(p.get("type") or "REGULAR").upper(),
                        price=p_price,
                        available_quantity=int(p.get("totalQuantity") or p.get("available_quantity")) if (p.get("totalQuantity") or p.get("available_quantity")) is not None else None,
                        max_per_customer=int(p.get("maxPerCustomer") or p.get("max_per_customer")) if (p.get("maxPerCustomer") or p.get("max_per_customer")) is not None else None,
                        benefits=[str(b) for b in (p.get("benefits") or []) if b],
                        description=p.get("description")
                    ))

        # Facilities & Rules
        facilities = [str(f) for f in (source_data.get("facilities") or hint.get("facilities") or []) if f]
        rules = [str(r) for r in (source_data.get("rules") or hint.get("rules") or []) if r]

        # Days hierarchy
        days: List[ScrapedDay] = []
        if start_d:
            days.append(ScrapedDay(
                day_number=1,
                date=start_d,
                day_name="Opening Night" if end_d and end_d != start_d else "Event Day",
                start_time=start_t or "20:00",
                venue=venue
            ))

        validation_status = "VALID" if (title and start_d) else "NEEDS_REVIEW"

        return DeepScrapedEvent(
            source=self.source_name,
            source_event_id=sid,
            source_url=validated_url,
            title=title,
            description=desc,
            poster_url=poster,
            banner_url=banner,
            artwork_candidates=artwork_candidates,
            event_start_date=start_d,
            event_end_date=end_d,
            start_time=start_t,
            end_time=end_t,
            venue_name=venue,
            venue_address=address,
            city=city_val,
            state=state_val,
            min_ticket_price=min_p,
            max_ticket_price=max_p,
            currency=curr,
            days=days,
            passes=passes,
            artists=artists,
            facilities=facilities,
            rules=rules,
            raw_source_payload=source_data,
            parser_version="v2.0-district-live",
            scraped_at=datetime.datetime.utcnow().isoformat(),
            validation_status=validation_status
        )

    def _parse_discovery_dict(self, item: Dict[str, Any], category: Optional[str] = None) -> Optional[DiscoveredEvent]:
        """Parses an event dictionary from JSON into DiscoveredEvent."""
        sid = str(item.get("id") or item.get("eventId") or item.get("source_event_id") or "")
        title = str(item.get("title") or item.get("name") or "").strip()
        if not sid or not title:
            return None

        min_p, _, _ = EventNormalizer.normalize_prices(item.get("priceStarting") or item.get("min_price") or item.get("price"))

        return DiscoveredEvent(
            source=self.source_name,
            source_event_id=sid,
            title=title,
            event_url=EventNormalizer.validate_url(item.get("url") or item.get("eventUrl") or f"https://www.district.in/events/{sid}"),
            poster_url=EventNormalizer.validate_url(item.get("posterImage") or item.get("poster_url") or item.get("image")),
            banner_url=EventNormalizer.validate_url(item.get("bannerImage") or item.get("banner_url")),
            venue_name=EventNormalizer.normalize_string(item.get("venue") or item.get("venue_name")),
            city=EventNormalizer.normalize_city(item.get("city")),
            event_start_date=EventNormalizer.normalize_date(item.get("startDate") or item.get("event_start_date")),
            event_end_date=EventNormalizer.normalize_date(item.get("endDate") or item.get("event_end_date")),
            starting_price=min_p,
            currency="INR",
            category=category or "Nightlife / Parties",
            discovered_at=datetime.datetime.utcnow().isoformat(),
            raw_discovery_payload=item
        )

    def _extract_events_from_html(
        self,
        html: str,
        base_url: str,
        default_city: Optional[str] = None,
        category: Optional[str] = None
    ) -> List[DiscoveredEvent]:
        """Extracts live event items from District HTML page."""
        results: List[DiscoveredEvent] = []
        event_links = set(re.findall(r'href="(/events/[^"?#]+)"', html))

        for path in event_links:
            # Filter out non-event helper links
            if path in ("/events", "/events/comedy", "/events/music", "/events/nightlife"):
                continue

            full_url = f"{base_url}{path}"
            slug = path.replace("/events/", "").strip().split("/")[0]
            title_candidate = slug.replace("-", " ").title()

            results.append(DiscoveredEvent(
                source=self.source_name,
                source_event_id=slug,
                title=title_candidate,
                event_url=full_url,
                poster_url=None,
                banner_url=None,
                venue_name=None,
                city=EventNormalizer.normalize_city(default_city),
                event_start_date=None,
                event_end_date=None,
                starting_price=None,
                currency="INR",
                category=category or "Nightlife / Events",
                discovered_at=datetime.datetime.utcnow().isoformat(),
                raw_discovery_payload={"slug": slug, "path": path}
            ))

        return results


# Auto-register adapter
AdapterRegistry.register(DistrictAdapter())
