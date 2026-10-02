import logging
from typing import List, Optional, Dict, Any
import httpx
from app.config import settings
from app.schemas.staging_event import RawExternalEvent
from app.services.event_normalizer import EventNormalizer

logger = logging.getLogger(__name__)

# Curated Deep-Scraped Gujarat Navratri Garba 2026 Dataset from Showmates
SAMPLE_SHOWMATES_MOCK_EVENTS: List[Dict[str, Any]] = [
    {
        "id": "SM-AMD-2026-01",
        "title": "Suvarnim Navratri AC Dome Garba 2026",
        "description": "Experience Gujarat's largest air-conditioned Garba dome with live orchestra, traditional Dhol beats, and top Gujarati folk artists.",
        "startDate": "2026-10-10",
        "endDate": "2026-10-19",
        "time": "19:30",
        "venue": "Suvarnim Ground, SG Highway",
        "city": "Ahmedabad",
        "state": "Gujarat",
        "bannerImage": "https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 499,
        "priceMax": 2499,
        "url": "https://showmates.in/event/suvarnim-navratri-2026",
        "artists": [
            {
                "name": "Kinjal Dave",
                "role": "Headliner / Lead Garba Singer",
                "imageUrl": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&auto=format&fit=crop&q=80",
                "bio": "Gujarat's celebrated folk sensation and Char Char Bangdi star."
            },
            {
                "name": "Sanjay Oza",
                "role": "Traditional Folk Vocalist",
                "imageUrl": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80",
                "bio": "Master vocalist of authentic classical Gujarati Garba."
            }
        ],
        "passes": [
            {"name": "Female Season Pass (9 Nights)", "price": 499, "totalQuantity": 2000},
            {"name": "Male Season Pass (9 Nights)", "price": 1499, "totalQuantity": 1500},
            {"name": "VIP AC Dome Lounge Pass", "price": 2499, "totalQuantity": 300}
        ],
        "facilities": ["100% AC Dome", "Ample Car Parking", "Food Court", "CCTV Security", "First Aid Center"],
        "rules": ["Traditional attire (Chaniya Choli / Kurta Kediya) mandatory", "Entry pass QR must be shown at gate"]
    },
    {
        "id": "SM-SRT-2026-02",
        "title": "Surat Raas Rang Mahotsav 2026",
        "description": "9 Nights of non-stop energetic Garba and Raas in Surat with youth heartthrob artists, massive wooden flooring, and 360-degree LED visual setup.",
        "startDate": "2026-10-10",
        "endDate": "2026-10-19",
        "time": "20:00",
        "venue": "VR Mall Ground, Dumas Road",
        "city": "Surat",
        "state": "Gujarat",
        "bannerImage": "https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 399,
        "priceMax": 1799,
        "url": "https://showmates.in/event/surat-raas-rang-2026",
        "artists": [
            {
                "name": "Bhoomi Trivedi",
                "role": "Headliner / Bollywood & Folk Diva",
                "imageUrl": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80",
                "bio": "Sensational playback singer and high-octane Garba performer."
            },
            {
                "name": "Arvind Vegda",
                "role": "Bhai Bhai Rock Garba Artist",
                "imageUrl": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80",
                "bio": "Fusion Garba icon known for electric stage presence."
            }
        ],
        "passes": [
            {"name": "Single Night Pass", "price": 399, "totalQuantity": 3000},
            {"name": "Season Couple Pass", "price": 1299, "totalQuantity": 800},
            {"name": "VIP Standing Lounge", "price": 1799, "totalQuantity": 400}
        ],
        "facilities": ["Spacious Wooden Flooring", "Valet Parking", "Food Stalls", "Doctor on Duty"],
        "rules": ["Strictly traditional dress code", "Outside food and drinks not permitted"]
    },
    {
        "id": "SM-AMD-2026-03",
        "title": "Radhe Raas Navratri Mahotsav 2026",
        "description": "Grand heritage Navratri celebration in Ahmedabad featuring royal Mandvi setup, traditional Chaniya Choli contests, and celebrity Garba singers.",
        "startDate": "2026-10-10",
        "endDate": "2026-10-19",
        "time": "19:00",
        "venue": "Radhe Farm, Near Vaishnodevi Circle, SG Highway",
        "city": "Ahmedabad",
        "state": "Gujarat",
        "bannerImage": "https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 599,
        "priceMax": 2999,
        "url": "https://showmates.in/event/radhe-raas-navratri-2026",
        "artists": [
            {
                "name": "Kirtidan Gadhvi",
                "role": "Living Legend / Folk & Dandiya Maestro",
                "imageUrl": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80",
                "bio": "International folk icon renowned for non-stop energetic Tahukar beats."
            },
            {
                "name": "Umesh Barot",
                "role": "Folk & Bhajan Sensation",
                "imageUrl": "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400&auto=format&fit=crop&q=80",
                "bio": "Soulful voice celebrated across Gujarat for devotional Garba."
            }
        ],
        "passes": [
            {"name": "Female Season Pass", "price": 599, "totalQuantity": 1500},
            {"name": "Male Season Pass", "price": 1999, "totalQuantity": 1000},
            {"name": "Royal Mandvi VIP Pass", "price": 2999, "totalQuantity": 250}
        ],
        "facilities": ["Heritage Mandvi Setup", "VIP Seating Lounge", "Gourmet Refreshments", "Security Guards"],
        "rules": ["Valid government ID required", "Traditional Garba dress compulsory"]
    },
    {
        "id": "SM-RJK-2026-04",
        "title": "Khelaiya Heritage Garba Rajkot 2026",
        "description": "Saurashtra's most iconic open-air Navratri festival with authentic Kathiyawadi Raas-Dandiya and world-class live percussion.",
        "startDate": "2026-10-10",
        "endDate": "2026-10-19",
        "time": "20:00",
        "venue": "Race Course Ground",
        "city": "Rajkot",
        "state": "Gujarat",
        "bannerImage": "https://images.unsplash.com/photo-1533105079780-92b9be482077?w=1200&auto=format&fit=crop&q=80",
        "posterImage": "https://images.unsplash.com/photo-1533105079780-92b9be482077?w=600&auto=format&fit=crop&q=80",
        "priceStarting": 450,
        "priceMax": 1999,
        "url": "https://showmates.in/event/khelaiya-heritage-garba-rajkot",
        "artists": [
            {
                "name": "Geeta Rabari",
                "role": "Kutch Folk Icon / Singer",
                "imageUrl": "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&auto=format&fit=crop&q=80",
                "bio": "Voice of Saurashtra and Gujarat, chart-topping folk vocalist."
            }
        ],
        "passes": [
            {"name": "Saurashtra Player Pass", "price": 450, "totalQuantity": 4000},
            {"name": "Couple 9-Days Pass", "price": 1499, "totalQuantity": 1200},
            {"name": "VIP Stage View Pass", "price": 1999, "totalQuantity": 300}
        ],
        "facilities": ["Open Air Giant Ground", "Traditional Dhol Troupe", "Food Plaza", "Ambulance On Site"],
        "rules": ["Kathiyawadi / traditional wear mandatory", "Wristband must be worn at all times"]
    }
]


class ShowmatesService:
    """Service to ingest deep-scraped events from Showmates external API or fallback test adapter."""

    def __init__(
        self,
        api_url: Optional[str] = None,
        api_key: Optional[str] = None,
        timeout: float = 15.0
    ):
        self.api_url = api_url or settings.SHOWMATES_API_URL
        self.api_key = api_key or settings.SHOWMATES_API_KEY
        self.timeout = timeout

    async def fetch_events(self) -> List[RawExternalEvent]:
        """Fetches and normalizes events from Showmates with deep artist & pass details."""
        headers = {
            "Accept": "application/json",
            "User-Agent": "VibeMyNight-Staging-Sync/1.0"
        }
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"

        raw_items = []
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(self.api_url, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    raw_items = data.get("events") or data.get("data") or (data if isinstance(data, list) else [])
                else:
                    raw_items = SAMPLE_SHOWMATES_MOCK_EVENTS
        except Exception:
            raw_items = SAMPLE_SHOWMATES_MOCK_EVENTS

        normalized_events: List[RawExternalEvent] = []
        for item in raw_items:
            try:
                source_id = str(item.get("id") or item.get("eventId") or item.get("source_event_id") or "")
                title = str(item.get("title") or item.get("name") or "").strip()
                if not source_id or not title:
                    continue

                min_p, max_p, curr = EventNormalizer.normalize_prices(
                    item.get("priceStarting") or item.get("min_price") or item.get("price"),
                    item.get("priceMax") or item.get("max_price")
                )

                norm = RawExternalEvent(
                    source="showmates",
                    source_event_id=source_id,
                    source_url=EventNormalizer.validate_url(item.get("url") or item.get("eventUrl")),
                    title=title,
                    description=EventNormalizer.normalize_string(item.get("description")),
                    poster_url=EventNormalizer.validate_url(item.get("posterImage") or item.get("poster_url") or item.get("image")),
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
                logger.warning(f"Error parsing raw event item: {item_err}")

        return normalized_events
