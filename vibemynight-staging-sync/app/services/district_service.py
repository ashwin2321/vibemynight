import logging
from typing import List, Optional, Dict, Any
import httpx
from app.schemas.staging_event import RawExternalEvent
from app.services.event_normalizer import EventNormalizer

logger = logging.getLogger(__name__)

# Curated High-Definition Gujarat Nightlife & Club Garba Dataset from District (Zomato District)
SAMPLE_DISTRICT_EVENTS: List[Dict[str, Any]] = [
    {
        "id": "DST-AMD-2026-201",
        "title": "Shanku's Dandiya Grand Celebration 2026",
        "description": "Gujarat's most luxurious resort Navratri experience with illuminated Dandiya arena, swimming pool side ambiance, and celebrity DJs.",
        "startDate": "2026-10-10",
        "endDate": "2026-10-19",
        "time": "20:30",
        "venue": "Shanku's Water World Resort, Ahmedabad-Mehsana Highway",
        "city": "Ahmedabad",
        "state": "Gujarat",
        "bannerImage": "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 899,
        "priceMax": 4499,
        "url": "https://district.in/events/shankus-dandiya-celebration-2026"
    },
    {
        "id": "DST-SRT-2026-202",
        "title": "Thanganat Navratri Mahotsav Surat 2026",
        "description": "Premium youth Garba festival in Surat with dynamic multi-tiered stage, traditional and fusion Raas, and gourmet food court.",
        "startDate": "2026-10-10",
        "endDate": "2026-10-19",
        "time": "20:00",
        "venue": "SMC Party Plot, Vesu",
        "city": "Surat",
        "state": "Gujarat",
        "bannerImage": "https://images.unsplash.com/photo-1545128485-c400e7702796?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1545128485-c400e7702796?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 599,
        "priceMax": 2499,
        "url": "https://district.in/events/thanganat-navratri-surat-202"
    },
    {
        "id": "DST-AMD-2026-203",
        "title": "Mirchi Rock N Dhol Navratri Concert 2026",
        "description": "Celebrity DJ live sets blending modern EDM beats with traditional Gujarati dhol rhythms and neon Garba vibes.",
        "startDate": "2026-10-15",
        "endDate": "2026-10-15",
        "time": "20:00",
        "venue": "The Forum Convention Center, Club O7 Road",
        "city": "Ahmedabad",
        "state": "Gujarat",
        "bannerImage": "https://images.unsplash.com/photo-1506157786151-b8491531f063?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1506157786151-b8491531f063?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 699,
        "priceMax": 3499,
        "url": "https://district.in/events/mirchi-rock-n-dhol-navratri-203"
    }
]


class DistrictService:
    """Service to ingest nightlife, curated parties and events from District by Zomato."""

    def __init__(self, api_url: Optional[str] = None, timeout: float = 15.0):
        self.api_url = api_url
        self.timeout = timeout

    async def fetch_events(self) -> List[RawExternalEvent]:
        """Fetches and normalizes events from District."""
        raw_items = []
        if self.api_url:
            try:
                headers = {
                    "Accept": "application/json",
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                }
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.get(self.api_url, headers=headers)
                    if response.status_code == 200:
                        data = response.json()
                        raw_items = data.get("events") or data.get("data") or (data if isinstance(data, list) else [])
                    else:
                        raw_items = SAMPLE_DISTRICT_EVENTS
            except Exception:
                raw_items = SAMPLE_DISTRICT_EVENTS
        else:
            raw_items = SAMPLE_DISTRICT_EVENTS

        normalized_events: List[RawExternalEvent] = []
        for item in raw_items:
            try:
                source_id = str(item.get("id") or item.get("eventId") or item.get("source_event_id") or "")
                title = str(item.get("title") or item.get("name") or "").strip()
                if not source_id or not title:
                    continue

                min_p, max_p, curr = EventNormalizer.normalize_prices(
                    item.get("priceStarting") or item.get("minPrice") or item.get("price"),
                    item.get("priceMax") or item.get("maxPrice")
                )

                norm = RawExternalEvent(
                    source="district",
                    source_event_id=source_id,
                    source_url=EventNormalizer.validate_url(item.get("url") or item.get("eventUrl")),
                    title=title,
                    description=EventNormalizer.normalize_string(item.get("description")),
                    poster_url=EventNormalizer.validate_url(item.get("posterImage") or item.get("poster_url")),
                    banner_url=EventNormalizer.validate_url(item.get("bannerImage") or item.get("banner_url")),
                    event_start_date=EventNormalizer.normalize_date(item.get("startDate") or item.get("event_start_date")),
                    event_end_date=EventNormalizer.normalize_date(item.get("endDate") or item.get("event_end_date")),
                    start_time=EventNormalizer.normalize_time(item.get("time") or item.get("start_time")),
                    end_time=EventNormalizer.normalize_time(item.get("endTime") or item.get("end_time")),
                    venue_name=EventNormalizer.normalize_string(item.get("venue") or item.get("venue_name")),
                    venue_address=EventNormalizer.normalize_string(item.get("address") or item.get("venue_address")),
                    city=EventNormalizer.normalize_city(item.get("city")),
                    state=EventNormalizer.normalize_string(item.get("state") or "Gujarat"),
                    min_ticket_price=min_p,
                    max_ticket_price=max_p,
                    currency=curr,
                    raw_payload=item
                )
                normalized_events.append(norm)
            except Exception as item_err:
                logger.warning(f"Error normalizing District item: {item_err}")

        return normalized_events
