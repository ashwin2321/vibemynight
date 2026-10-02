import datetime
import logging
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc

from app.database import get_db
from app.models.staging_event import StagingEvent, StagingEventStatus
from app.schemas.staging_event import (
    StagingEventResponse,
    StagingEventListResponse,
    StagingEventUpdate,
    SyncFetchResponse,
    DiscoverEventsRequest,
    DiscoverEventsResponse,
    DiscoveredEventItem,
    DeepScrapeRequest,
    DeepScrapeResponse,
    DeepScrapeResultItem
)
from app.services.base_adapter import AdapterRegistry
# Import adapters so they register with AdapterRegistry
import app.services.adapters
from app.services.showmates_service import ShowmatesService
from app.services.bookmyshow_service import BookMyShowService
from app.services.district_service import DistrictService
from app.services.duplicate_detector import DuplicateDetector
from app.services.gemini_service import get_ai_service
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/sync", tags=["Staging & Sync"])


@router.get("/stats")
def get_staging_stats(db: Session = Depends(get_db)):
    """Returns aggregated count statistics for staged events."""
    try:
        total = db.query(StagingEvent).count()
        pending = db.query(StagingEvent).filter(
            or_(
                StagingEvent.status == StagingEventStatus.PENDING_REVIEW,
                StagingEvent.status == StagingEventStatus.READY_TO_IMPORT,
                StagingEvent.status == StagingEventStatus.APPROVED
            )
        ).count()
        imported = db.query(StagingEvent).filter(StagingEvent.status == StagingEventStatus.IMPORTED).count()
        rejected = db.query(StagingEvent).filter(StagingEvent.status == StagingEventStatus.REJECTED).count()
        conflicts = db.query(StagingEvent).filter(
            or_(
                StagingEvent.status == StagingEventStatus.DUPLICATE,
                StagingEvent.status == StagingEventStatus.AI_PROCESSING_FAILED,
                StagingEvent.status == StagingEventStatus.SYNC_FAILED,
                StagingEvent.status == StagingEventStatus.CONFLICT
            )
        ).count()
        return {
            "total": total,
            "pending": pending,
            "imported": imported,
            "rejected": rejected,
            "conflicts": conflicts
        }
    except Exception as e:
        logger.error(f"Error computing staging stats: {e}")
        return {
            "total": 0,
            "pending": 0,
            "imported": 0,
            "rejected": 0,
            "conflicts": 0
        }


@router.delete("/events/clear")
def clear_staging_events(
    force: bool = Query(False, description="Clear all staged events including duplicates"),
    db: Session = Depends(get_db)
):
    """Clears pending and duplicate staged events to reset the staging hub cleanly."""
    try:
        deleted = db.query(StagingEvent).filter(StagingEvent.status != StagingEventStatus.IMPORTED).delete()
        db.commit()
        return {"success": True, "deleted": deleted, "message": f"Cleared {deleted} staged events."}
    except Exception as e:
        db.rollback()
        logger.error(f"Error clearing staged events: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/reset-and-fetch", response_model=SyncFetchResponse)
async def reset_and_fetch_events(
    db: Session = Depends(get_db)
):
    """Resets un-imported staged events and re-ingests fresh multi-source events."""
    try:
        db.query(StagingEvent).filter(StagingEvent.status != StagingEventStatus.IMPORTED).delete()
        db.commit()
    except Exception as e:
        db.rollback()
        logger.warning(f"Error resetting before fetch: {e}")

    return await fetch_and_stage_events(source="all", payload=None, db=db)


@router.post("/fetch", response_model=SyncFetchResponse)
@router.post("/fetch-now", response_model=SyncFetchResponse)
async def fetch_and_stage_events(
    source: Optional[str] = Query("all", description="Source: 'all', 'showmates', 'bookmyshow', 'district'"),
    payload: Optional[dict] = None,
    db: Session = Depends(get_db)
):
    """
    Multi-Source Ingestion Pipeline:
    Ingests events from Showmates, BookMyShow, and District (Zomato District).
    Runs duplicate detection and AI enrichment before storing in staging DB.
    """
    selected_source = "all"
    if payload and isinstance(payload, dict) and payload.get("source"):
        selected_source = str(payload.get("source")).lower()
    elif source:
        selected_source = str(source).lower()

    logger.info(f"Starting staging sync pipeline for source: {selected_source}...")
    ai_service = get_ai_service()

    raw_events = []
    if selected_source in ("all", "showmates"):
        raw_events.extend(await ShowmatesService().fetch_events())
    if selected_source in ("all", "bookmyshow", "bms"):
        raw_events.extend(await BookMyShowService().fetch_events())
    if selected_source in ("all", "district", "zomato"):
        raw_events.extend(await DistrictService().fetch_events())

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
        message=f"Sync cycle completed: {processed_count} staged from {selected_source.upper()}, {duplicate_count} duplicates detected, {failed_count} errors."
    )


# =========================================================================
# UNIVERSAL DYNAMIC LIVE DISCOVERY & DEEP SCRAPING ENDPOINTS
# =========================================================================

@router.post("/discover", response_model=DiscoverEventsResponse)
@router.get("/discover", response_model=DiscoverEventsResponse)
async def discover_events(
    request: Optional[DiscoverEventsRequest] = None,
    source: Optional[str] = Query("all", description="Source: 'all', 'showmates', 'bookmyshow', 'district'"),
    city: Optional[str] = Query(None, description="City name or 'ALL'"),
    category: Optional[str] = Query(None, description="Category filter"),
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """
    Live Catalog Discovery:
    Discovers live events across BookMyShow, District, and Showmates by City and Category.
    Returns lightweight summaries with live posters and dates without deep scraping.
    """
    req_source = request.source if request else source
    req_city = request.city if request else city
    req_cat = request.category if request else category
    req_page = request.page if request else page
    req_page_size = request.pageSize if request else pageSize

    req_source_clean = (req_source or "all").lower().strip()

    adapters_to_run = []
    if req_source_clean == "all":
        adapters_to_run = AdapterRegistry.get_all()
    else:
        adp = AdapterRegistry.get(req_source_clean)
        if adp:
            adapters_to_run.append(adp)
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Unknown source adapter '{req_source_clean}'. Available sources: {AdapterRegistry.list_sources()}"
            )

    all_discovered: List[DiscoveredEventItem] = []

    for adp in adapters_to_run:
        try:
            discovered_events = await adp.discover(
                city=req_city,
                category=req_cat,
                page=req_page,
                page_size=req_page_size
            )
            for d in discovered_events:
                # Check if already staged in database
                existing_staged = db.query(StagingEvent).filter(
                    StagingEvent.source == d.source,
                    StagingEvent.source_event_id == d.source_event_id
                ).first()

                is_staged = existing_staged is not None

                all_discovered.append(DiscoveredEventItem(
                    source=d.source,
                    source_event_id=d.source_event_id,
                    title=d.title,
                    event_url=d.event_url,
                    poster_url=d.poster_url,
                    banner_url=d.banner_url,
                    venue_name=d.venue_name,
                    city=d.city,
                    event_start_date=d.event_start_date,
                    event_end_date=d.event_end_date,
                    starting_price=d.starting_price,
                    currency=d.currency,
                    category=d.category,
                    is_already_staged=is_staged,
                    is_already_in_production=False,
                    discovered_at=d.discovered_at or datetime.datetime.utcnow().isoformat(),
                    raw_discovery_payload=d.raw_discovery_payload
                ))
        except Exception as e:
            logger.error(f"Error discovering events from adapter '{adp.source_name}': {e}")

    return DiscoverEventsResponse(
        success=True,
        source=req_source_clean,
        city=req_city,
        category=req_cat,
        total_discovered=len(all_discovered),
        items=all_discovered,
        timestamp=datetime.datetime.utcnow().isoformat()
    )


@router.post("/deep-scrape", response_model=DeepScrapeResponse)
async def deep_scrape_events(
    request: DeepScrapeRequest,
    db: Session = Depends(get_db)
):
    """
    Selective Deep Scraping & Staging:
    Deep-scrapes selected events, extracts full nested hierarchy (days, passes, artists, facilities, rules),
    runs duplicate checking and Gemini AI enrichment, and inserts into Staging DB.
    """
    if not request.events:
        raise HTTPException(status_code=400, detail="No events selected for deep scraping.")

    ai_service = get_ai_service()
    results: List[DeepScrapeResultItem] = []

    staged_count = 0
    duplicate_count = 0
    failed_count = 0

    for target in request.events:
        src_name = target.source.lower().strip()
        adp = AdapterRegistry.get(src_name)
        if not adp:
            failed_count += 1
            results.append(DeepScrapeResultItem(
                source=target.source,
                source_event_id=target.source_event_id,
                title=target.title or "Unknown",
                status="FAILED",
                validation_status="INVALID",
                message=f"No source adapter registered for '{target.source}'"
            ))
            continue

        try:
            # 1. Deep scrape from source adapter
            deep_scraped = await adp.deep_scrape(
                event_url=target.event_url,
                hint_payload=target.hint_payload
            )

            # 2. Check for duplicates in Staging DB
            is_dup, existing_id = DuplicateDetector.check_duplicate(
                db=db,
                source=deep_scraped.source,
                source_event_id=deep_scraped.source_event_id,
                title=deep_scraped.title,
                venue_name=deep_scraped.venue_name,
                event_start_date=deep_scraped.event_start_date,
                city=deep_scraped.city
            )

            # 3. AI Enrichment (only if not duplicate and requested)
            ai_enhanced = None
            ai_error = None
            ai_processed = False

            if not is_dup and request.run_ai_enrichment:
                ai_enhanced, ai_error = await ai_service.enhance_event(
                    title=deep_scraped.title,
                    description=deep_scraped.description,
                    venue=deep_scraped.venue_name,
                    city=deep_scraped.city,
                    start_date=deep_scraped.event_start_date,
                    raw_info=deep_scraped.raw_source_payload or deep_scraped.model_dump()
                )
                ai_processed = ai_enhanced is not None

            # 4. Status determination
            if is_dup:
                status_val = StagingEventStatus.DUPLICATE
                duplicate_count += 1
            elif deep_scraped.validation_status == "INVALID":
                status_val = StagingEventStatus.CONFLICT
            else:
                status_val = StagingEventStatus.PENDING_REVIEW

            # Prepare full hierarchy payload
            full_raw_payload = deep_scraped.model_dump()
            if deep_scraped.raw_source_payload:
                full_raw_payload["source_original_payload"] = deep_scraped.raw_source_payload

            staging_obj = StagingEvent(
                source=deep_scraped.source,
                source_event_id=deep_scraped.source_event_id,
                source_url=deep_scraped.source_url,
                title=deep_scraped.title,
                description=deep_scraped.description,
                enhanced_title=ai_enhanced.enhancedTitle if ai_enhanced else deep_scraped.title,
                catchy_description=ai_enhanced.catchyDescription if ai_enhanced else deep_scraped.description,
                highlights=ai_enhanced.highlights if ai_enhanced else [],
                genre_tags=ai_enhanced.genreTags if ai_enhanced else [],
                seo_keywords=ai_enhanced.seoKeywords if ai_enhanced else [],
                whatsapp_teaser=ai_enhanced.whatsAppTeaser if ai_enhanced else None,
                poster_url=deep_scraped.poster_url,
                banner_url=deep_scraped.banner_url,
                event_start_date=deep_scraped.event_start_date,
                event_end_date=deep_scraped.event_end_date,
                start_time=deep_scraped.start_time,
                end_time=deep_scraped.end_time,
                venue_name=deep_scraped.venue_name,
                venue_address=deep_scraped.venue_address,
                city=deep_scraped.city,
                state=deep_scraped.state,
                min_ticket_price=deep_scraped.min_ticket_price,
                max_ticket_price=deep_scraped.max_ticket_price,
                currency=deep_scraped.currency,
                raw_payload=full_raw_payload,
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
            staged_count += 1

            results.append(DeepScrapeResultItem(
                source=deep_scraped.source,
                source_event_id=deep_scraped.source_event_id,
                staging_id=staging_obj.id,
                title=deep_scraped.title,
                status=status_val.value,
                validation_status=deep_scraped.validation_status,
                is_duplicate=is_dup,
                duplicate_of=existing_id,
                message="Successfully deep-scraped and staged" if not is_dup else f"Duplicate of #{existing_id}"
            ))

        except Exception as e:
            db.rollback()
            logger.error(f"Error deep scraping target '{target.title}': {e}")
            failed_count += 1
            results.append(DeepScrapeResultItem(
                source=target.source,
                source_event_id=target.source_event_id,
                title=target.title or "Unknown",
                status="FAILED",
                validation_status="INVALID",
                message=str(e)
            ))

    return DeepScrapeResponse(
        success=True,
        total_requested=len(request.events),
        total_staged=staged_count,
        total_duplicates=duplicate_count,
        total_failed=failed_count,
        results=results,
        message=f"Deep scraping completed: {staged_count} staged, {duplicate_count} duplicates, {failed_count} failures."
    )


@router.get("/events", response_model=StagingEventListResponse)
def list_staged_events(
    status: Optional[str] = Query(None, description="Filter by status (PENDING_REVIEW, APPROVED, CONFLICT, etc.)"),
    source: Optional[str] = Query(None, description="Filter by source (showmates, bookmyshow, district)"),
    city: Optional[str] = Query(None, description="Filter by city"),
    search: Optional[str] = Query(None, description="Search in title or venue"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    db: Session = Depends(get_db)
):
    """Lists staged events with pagination, status filtering, source filtering, and search capabilities."""
    query = db.query(StagingEvent)

    if status:
        status_clean = status.strip().upper()
        if status_clean in ("CONFLICT", "CONFLICTS"):
            query = query.filter(
                or_(
                    StagingEvent.status == StagingEventStatus.DUPLICATE,
                    StagingEvent.status == StagingEventStatus.AI_PROCESSING_FAILED,
                    StagingEvent.status == StagingEventStatus.SYNC_FAILED,
                    StagingEvent.status == StagingEventStatus.CONFLICT
                )
            )
        elif status_clean in StagingEventStatus.__members__:
            query = query.filter(StagingEvent.status == StagingEventStatus[status_clean])
        else:
            query = query.filter(StagingEvent.status == status_clean)

    if source and source.strip().lower() != "all":
        query = query.filter(StagingEvent.source.ilike(f"%{source.strip()}%"))

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
