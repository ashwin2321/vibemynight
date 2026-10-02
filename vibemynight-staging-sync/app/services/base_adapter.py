import logging
from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)


class DiscoveredEvent(BaseModel):
    """Represents a lightweight discovery item parsed from a live listing page."""
    source: str
    source_event_id: str
    title: str
    event_url: str
    poster_url: Optional[str] = None
    banner_url: Optional[str] = None
    venue_name: Optional[str] = None
    city: Optional[str] = None
    event_start_date: Optional[str] = None
    event_end_date: Optional[str] = None
    starting_price: Optional[float] = None
    currency: str = "INR"
    category: Optional[str] = None
    is_already_staged: bool = False
    is_already_in_production: bool = False
    discovered_at: Optional[str] = None
    raw_discovery_payload: Optional[Dict[str, Any]] = None


class ScrapedArtist(BaseModel):
    name: str
    role: Optional[str] = None
    image_url: Optional[str] = None
    bio: Optional[str] = None


class ScrapedPass(BaseModel):
    name: str
    type: Optional[str] = "REGULAR"
    price: Optional[float] = None
    available_quantity: Optional[int] = None
    max_per_customer: Optional[int] = None
    benefits: List[str] = Field(default_factory=list)
    description: Optional[str] = None


class ScrapedDay(BaseModel):
    day_number: int
    date: Optional[str] = None
    day_name: Optional[str] = None
    program_name: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    venue: Optional[str] = None
    description: Optional[str] = None


class ScrapedImageCandidate(BaseModel):
    url: str
    suggested_role: str = "GALLERY"  # POSTER_3_4, BANNER_16_9, GALLERY, THUMBNAIL
    alt_text: Optional[str] = None


class DeepScrapedEvent(BaseModel):
    """Complete deep-scraped event data preserving factual source integrity."""
    source: str
    source_event_id: str
    source_url: str
    title: str
    description: Optional[str] = None
    poster_url: Optional[str] = None
    banner_url: Optional[str] = None
    artwork_candidates: List[ScrapedImageCandidate] = Field(default_factory=list)
    event_start_date: Optional[str] = None
    event_end_date: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    venue_name: Optional[str] = None
    venue_address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    min_ticket_price: Optional[float] = None
    max_ticket_price: Optional[float] = None
    currency: str = "INR"
    days: List[ScrapedDay] = Field(default_factory=list)
    passes: List[ScrapedPass] = Field(default_factory=list)
    artists: List[ScrapedArtist] = Field(default_factory=list)
    facilities: List[str] = Field(default_factory=list)
    rules: List[str] = Field(default_factory=list)
    raw_source_payload: Optional[Dict[str, Any]] = None
    parser_version: str = "v1.0-universal"
    scraped_at: Optional[str] = None
    validation_status: str = "VALID"  # VALID, WARNING, NEEDS_REVIEW, INVALID
    validation_messages: List[str] = Field(default_factory=list)


class BaseSourceAdapter(ABC):
    """Abstract Base Class for universal event source adapters."""

    @property
    @abstractmethod
    def source_name(self) -> str:
        """Canonical platform name e.g. 'bookmyshow', 'district', 'showmates'."""
        pass

    @abstractmethod
    async def discover(
        self,
        city: Optional[str] = None,
        category: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> List[DiscoveredEvent]:
        """Discovers live events on the source platform's explore/listing catalog."""
        pass

    @abstractmethod
    async def deep_scrape(
        self,
        event_url: str,
        hint_payload: Optional[Dict[str, Any]] = None
    ) -> DeepScrapedEvent:
        """Deep scrapes an individual event URL to extract complete nested hierarchy."""
        pass

    @abstractmethod
    async def check_health(self) -> bool:
        """Verifies reachability of the source platform."""
        pass


class AdapterRegistry:
    """Registry maintaining active source adapters."""
    _adapters: Dict[str, BaseSourceAdapter] = {}

    @classmethod
    def register(cls, adapter: BaseSourceAdapter):
        key = adapter.source_name.lower().strip()
        cls._adapters[key] = adapter
        logger.info(f"Registered universal scraping adapter: '{key}'")

    @classmethod
    def get(cls, source_name: str) -> Optional[BaseSourceAdapter]:
        return cls._adapters.get(source_name.lower().strip())

    @classmethod
    def list_sources(cls) -> List[str]:
        return list(cls._adapters.keys())

    @classmethod
    def get_all(cls) -> List[BaseSourceAdapter]:
        return list(cls._adapters.values())
