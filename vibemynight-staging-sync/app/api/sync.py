import logging
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc

from app.database import get_db
from app.models.staging_event import StagingEvent, StagingEventStatus
from app.schemas.staging_event import (
    StagingEventResponse,
    StagingEventListResponse,
    StagingEventUpdate,
    SyncFetchResponse
)
from app.services.showmates_service import ShowmatesService
from app.services.duplicate_detector import DuplicateDetector
from app.services.gemini_service import get_ai_service
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/sync", tags=["Staging & Sync"])


@router.get("/stats")
def get_staging_stats(db: Session = Depends(get_db)):
    """Returns aggregated count statistics for staged events."""
    total = db.query(StagingEvent).count()
    pending = db.query(StagingEvent).filter(StagingEvent.status == StagingEventStatus.PENDING_REVIEW).count()
    imported = db.query(StagingEvent).filter(StagingEvent.status == StagingEventStatus.IMPORTED).count()
    rejected = db.query(StagingEvent).filter(StagingEvent.status == StagingEventStatus.REJECTED).count()
    conflicts = db.query(StagingEvent).filter(
        or_(
            StagingEvent.status == StagingEventStatus.DUPLICATE,
            StagingEvent.status == StagingEventStatus.AI_PROCESSING_FAILED
        )
    ).count()
    return {
        "total": total,
        "pending": pending,
        "imported": imported,
        "rejected": rejected,
        "conflicts": conflicts
    }


@router.post("/fetch", response_model=SyncFetchResponse)
@router.post("/fetch-now", response_model=SyncFetchResponse)
async def fetch_and_stage_events(
    db: Session = Depends(get_db)
):
    """
    Ingestion Pipeline:
    1. Fetch latest raw events from Showmates.
    2. Check duplicate detection against staging DB.
    3. Run Gemini AI enhancement on new records.
    4. Persist enriched event in staging database with PENDING_REVIEW status.
    """
    logger.info("Starting staging sync pipeline...")
    showmates = ShowmatesService()
    ai_service = get_ai_service()

    raw_events = await showmates.fetch_events()
    fetched_count = len(raw_events)
    processed_count = 0
    duplicate_count = 0
    failed_count = 0

    for raw in raw_events:
        try:
            # Step 1: Duplicate check
            is_dup, existing_id = DuplicateDetector.check_duplicate(
                db=db,
                source=raw.source,
                source_event_id=raw.source_event_id,
                title=raw.title,
                venue_name=raw.venue_name,
                event_start_date=raw.event_start_date,
                city=raw.city
            )

            # Step 2: AI Enrichment
            ai_enhanced = None
            ai_error = None
            ai_processed = False
            
            if not is_dup:
                ai_enhanced, ai_error = await ai_service.enhance_event(
                    title=raw.title,
                    description=raw.description,
                    venue=raw.venue_name,
                    city=raw.city,
                    start_date=raw.event_start_date,
                    raw_info=raw.raw_payload
                )
                ai_processed = ai_enhanced is not None

            # Determine initial staging status
            if is_dup:
                status_val = StagingEventStatus.DUPLICATE
                duplicate_count += 1
            elif ai_enhanced is not None:
                status_val = StagingEventStatus.PENDING_REVIEW
            else:
                status_val = StagingEventStatus.AI_PROCESSING_FAILED
                if ai_error:
                    logger.warning(f"Event '{raw.title}' AI failed: {ai_error}")

            # Step 3: Create Staging Event Record
            staging_obj = StagingEvent(
                source=raw.source,
                source_event_id=raw.source_event_id,
                source_url=raw.source_url,
                title=raw.title,
                description=raw.description,
                enhanced_title=ai_enhanced.enhancedTitle if ai_enhanced else raw.title,
                catchy_description=ai_enhanced.catchyDescription if ai_enhanced else raw.description,
                highlights=ai_enhanced.highlights if ai_enhanced else [],
                genre_tags=ai_enhanced.genreTags if ai_enhanced else [],
                seo_keywords=ai_enhanced.seoKeywords if ai_enhanced else [],
                whatsapp_teaser=ai_enhanced.whatsAppTeaser if ai_enhanced else None,
                poster_url=raw.poster_url,
                banner_url=raw.banner_url,
                event_start_date=raw.event_start_date,
                event_end_date=raw.event_end_date,
                start_time=raw.start_time,
                end_time=raw.end_time,
                venue_name=raw.venue_name,
                venue_address=raw.venue_address,
                city=raw.city,
                state=raw.state,
                min_ticket_price=raw.min_ticket_price,
                max_ticket_price=raw.max_ticket_price,
                currency=raw.currency,
                raw_payload=raw.raw_payload,
                status=status_val,
                duplicate_of=existing_id,
                ai_processed=ai_processed,
                ai_provider="gemini" if settings.GEMINI_API_KEY else "fallback",
                ai_model=settings.GEMINI_MODEL if settings.GEMINI_API_KEY else "rule-based",
                ai_error=ai_error
            )

            db.add(staging_obj)
            db.commit()
            db.refresh(staging_obj)
            processed_count += 1

        except Exception as e:
            db.rollback()
            logger.error(f"Failed to stage event '{raw.title}': {e}")
            failed_count += 1

    return SyncFetchResponse(
        success=True,
        fetched=fetched_count,
        processed=processed_count,
        duplicates=duplicate_count,
        failed=failed_count,
        message=f"Sync cycle completed: {processed_count} staged, {duplicate_count} duplicates detected, {failed_count} errors."
    )


@router.get("/events", response_model=StagingEventListResponse)
def list_staged_events(
    status: Optional[StagingEventStatus] = Query(None, description="Filter by status"),
    city: Optional[str] = Query(None, description="Filter by city"),
    search: Optional[str] = Query(None, description="Search in title or venue"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    db: Session = Depends(get_db)
):
    """Lists staged events with pagination, status filtering, and search capabilities."""
    query = db.query(StagingEvent)

    if status:
        query = query.filter(StagingEvent.status == status)
    if city:
        query = query.filter(StagingEvent.city.ilike(f"%{city}%"))
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            or_(
                StagingEvent.title.ilike(search_pattern),
                StagingEvent.enhanced_title.ilike(search_pattern),
                StagingEvent.venue_name.ilike(search_pattern)
            )
        )

    total = query.count()
    total_pages = (total + page_size - 1) // page_size if total > 0 else 1

    items = (
        query.order_by(desc(StagingEvent.id))
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    return StagingEventListResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages
    )


@router.get("/events/{event_id}", response_model=StagingEventResponse)
def get_staged_event(
    event_id: int,
    db: Session = Depends(get_db)
):
    """Retrieves full details of a specific staged event."""
    event = db.query(StagingEvent).filter(StagingEvent.id == event_id).first()
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Staging event #{event_id} not found"
        )
    return event


@router.put("/events/{event_id}", response_model=StagingEventResponse)
def update_staged_event(
    event_id: int,
    update_data: StagingEventUpdate,
    db: Session = Depends(get_db)
):
    """Allows admin editing of staged event fields before approving import."""
    event = db.query(StagingEvent).filter(StagingEvent.id == event_id).first()
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Staging event #{event_id} not found"
        )

    update_dict = update_data.model_dump(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(event, key, value)

    db.commit()
    db.refresh(event)
    return event
