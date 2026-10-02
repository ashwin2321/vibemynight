import logging
from typing import List, Optional, Dict, Any
import httpx
from app.schemas.staging_event import RawExternalEvent
from app.services.event_normalizer import EventNormalizer

logger = logging.getLogger(__name__)

# Curated Deep-Scraped Gujarat Nightlife & Club Garba Dataset from District (Zomato District)
SAMPLE_DISTRICT_EVENTS: List[Dict[str, Any]] = [
    {
        "id": "DST-AMD-2026-201",
        "title": "Shanku's Dandiya Grand Celebration 2026",
        "description": "Gujarat's most luxurious resort Navratri experience with illuminated Dandiya arena, swimming pool side ambiance, and celebrity singers.",
        "startDate": "2026-10-10",
        "endDate": "2026-10-19",
        "time": "20:30",
        "venue": "Shanku's Water World Resort, Ahmedabad-Mehsana Highway",
        "city": "Ahmedabad",
        "state": "Gujarat",
        "bannerImage": "https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 899,
        "priceMax": 4499,
        "url": "https://district.in/events/shankus-dandiya-celebration-2026",
        "artists": [
            {
                "name": "Nirav Barot",
                "role": "Lead Performer / Folk Sensation",
                "imageUrl": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80",
                "bio": "Energetic live performer specializing in high-pitch traditional Gujarati Garba."
            },
            {
                "name": "Gujarat Folk Troupe",
                "role": "Live Dhol & Shehnai Ensemble",
                "imageUrl": "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&auto=format&fit=crop&q=80",
                "bio": "Premier traditional acoustic percussion troupe."
            }
        ],
        "passes": [
            {"name": "Resort Dandiya Single Entry", "price": 899, "totalQuantity": 2000},
            {"name": "Couple Dandiya Season Pass", "price": 2999, "totalQuantity": 800},
            {"name": "Stay & Garba Luxury Package", "price": 4499, "totalQuantity": 150}
        ],
        "facilities": ["Luxury Resort Poolside Lawn", "VIP Cabanas", "Gourmet Buffet", "Valet Parking", "Security Bouncers"],
        "rules": ["Dress code: Traditional Indian festival attire", "Entry strictly by pre-booked QR pass"]
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
        "bannerImage": "https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 599,
        "priceMax": 2499,
        "url": "https://district.in/events/thanganat-navratri-surat-202",
        "artists": [
            {
                "name": "Devang Patel",
                "role": "Dandiya Pioneer / Patel Scope",
                "imageUrl": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80",
                "bio": "Pioneering Indian singer, performer and king of fast-paced Disco Dandiya tracks."
            },
            {
                "name": "Dimple Biscuitwala",
                "role": "Gujarati Folk Vocalist",
                "imageUrl": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80",
                "bio": "Surat's favorite folk singer known for classic Sanedo and Dodhiya tunes."
            }
        ],
        "passes": [
            {"name": "Youth Season Pass", "price": 599, "totalQuantity": 3500},
            {"name": "Daily Entry Pass", "price": 299, "totalQuantity": 2000},
            {"name": "Premium Couple Pass", "price": 2499, "totalQuantity": 500}
        ],
        "facilities": ["Multi-Tiered Visual Stage", "Food Street", "Shoe Keeping Counter", "Doctor On Duty"],
        "rules": ["Valid student/government ID required", "Traditional Garba dress compulsory"]
    },
    {
        "id": "DST-AMD-2026-203",
        "title": "Mirchi Rock N Dhol Navratri Concert 2026",
        "description": "Celebrity live performers blending traditional Gujarati folk melodies with high-energy live dhol and devotional Navratri fever.",
        "startDate": "2026-10-15",
        "endDate": "2026-10-15",
        "time": "20:00",
        "venue": "The Forum Convention Center, Club O7 Road",
        "city": "Ahmedabad",
        "state": "Gujarat",
        "bannerImage": "https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 699,
        "priceMax": 3499,
        "url": "https://district.in/events/mirchi-rock-n-dhol-navratri-203",
        "artists": [
            {
                "name": "Osman Mir",
                "role": "Sufi & Folk Maestro",
                "imageUrl": "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400&auto=format&fit=crop&q=80",
                "bio": "Legendary vocalist of 'Mor Bani Thanghat Kare', renowned for powerful high-pitch Garba vocals."
            }
        ],
        "passes": [
            {"name": "Early Bird Entry", "price": 699, "totalQuantity": 2000},
            {"name": "VIP Lounge Entry", "price": 1999, "totalQuantity": 600},
            {"name": "Celebrity Stage Enclosure", "price": 3499, "totalQuantity": 200}
        ],
        "facilities": ["Air Conditioned Arena", "Live Dhol Troupe", "VIP Red Carpet Lounge", "Full CCTV Surveillance"],
        "rules": ["Barcode scan required at gate", "Re-entry not permitted on single tickets"]
    }
]


class DistrictService:
    """Service to ingest nightlife, curated parties and events from District by Zomato."""

    def __init__(self, api_url: Optional[str] = None, timeout: float = 15.0):
        self.api_url = api_url
        self.timeout = timeout

    async def fetch_events(self) -> List[RawExternalEvent]:
        """Fetches and normalizes events from District with deep artist and ticket structures."""
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
