from enum import Enum
import datetime
from sqlalchemy import (
    Column, Integer, String, Text, Float, Boolean, DateTime, Enum as SQLEnum, JSON, Index
)
from app.database import Base


class StagingEventStatus(str, Enum):
    PENDING_REVIEW = "PENDING_REVIEW"
    READY_TO_IMPORT = "READY_TO_IMPORT"
    IMPORTED = "IMPORTED"
    DUPLICATE = "DUPLICATE"
    AI_PROCESSING_FAILED = "AI_PROCESSING_FAILED"
    SYNC_FAILED = "SYNC_FAILED"


class StagingEvent(Base):
    """Represents an external event staged for AI enrichment and review before VibeMyNight import."""
    
    __tablename__ = "staging_events"

    # Primary Identification
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    source = Column(String(50), nullable=False, default="showmates", index=True)
    source_event_id = Column(String(100), nullable=False, index=True)
    source_url = Column(String(500), nullable=True)

    # Core Event Content
    title = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True)

    # AI Enhanced Content
    enhanced_title = Column(String(255), nullable=True)
    catchy_description = Column(Text, nullable=True)
    highlights = Column(JSON, nullable=True, default=list)
    genre_tags = Column(JSON, nullable=True, default=list)
    seo_keywords = Column(JSON, nullable=True, default=list)
    whatsapp_teaser = Column(String(500), nullable=True)

    # Visual Assets
    poster_url = Column(String(500), nullable=True)
    banner_url = Column(String(500), nullable=True)

    # Schedule & Timing
    event_start_date = Column(String(50), nullable=True, index=True)  # ISO YYYY-MM-DD
    event_end_date = Column(String(50), nullable=True)                # ISO YYYY-MM-DD
    start_time = Column(String(20), nullable=True)                    # HH:MM
    end_time = Column(String(20), nullable=True)                      # HH:MM

    # Location Information
    venue_name = Column(String(255), nullable=True, index=True)
    venue_address = Column(Text, nullable=True)
    city = Column(String(100), nullable=True, index=True)
    state = Column(String(100), nullable=True)

    # Ticket Pricing
    min_ticket_price = Column(Float, nullable=True)
    max_ticket_price = Column(Float, nullable=True)
    currency = Column(String(10), nullable=False, default="INR")

    # Raw Payload (Full fidelity preservation)
    raw_payload = Column(JSON, nullable=True)

    # Status & Workflow Control
    status = Column(
        SQLEnum(StagingEventStatus),
        nullable=False,
        default=StagingEventStatus.PENDING_REVIEW,
        index=True
    )
    duplicate_of = Column(Integer, nullable=True, index=True)

    # AI Telemetry
    ai_processed = Column(Boolean, nullable=False, default=False)
    ai_provider = Column(String(50), nullable=True)
    ai_model = Column(String(50), nullable=True)
    ai_error = Column(Text, nullable=True)

    # Audit Timestamps
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow,
        nullable=False
    )

    __table_args__ = (
        Index('idx_source_source_id', 'source', 'source_event_id'),
        Index('idx_title_city_date', 'title', 'city', 'event_start_date'),
    )

    def to_dict(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}
