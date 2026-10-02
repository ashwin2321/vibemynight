from sqlalchemy.orm import Session
from app.models.staging_event import StagingEvent, StagingEventStatus
from app.services.duplicate_detector import DuplicateDetector


def test_duplicate_detection_by_source_id(db_session: Session):
    existing = StagingEvent(
        source="showmates",
        source_event_id="EVT-100",
        title="Original Event Title",
        status=StagingEventStatus.PENDING_REVIEW
    )
    db_session.add(existing)
    db_session.commit()

    # Exact match on source + source_event_id
    is_dup, dup_id = DuplicateDetector.check_duplicate(
        db=db_session,
        source="showmates",
        source_event_id="EVT-100",
        title="Different Title"
    )
    assert is_dup is True
    assert dup_id == existing.id


def test_duplicate_detection_by_composite_attributes(db_session: Session):
    existing = StagingEvent(
        source="showmates",
        source_event_id="EVT-200",
        title="Parampara Navratri 2026",
        venue_name="SBR Ground",
        city="Ahmedabad",
        event_start_date="2026-10-10",
        status=StagingEventStatus.PENDING_REVIEW
    )
    db_session.add(existing)
    db_session.commit()

    # Different source ID, but same title, date, venue, city
    is_dup, dup_id = DuplicateDetector.check_duplicate(
        db=db_session,
        source="external_partner",
        source_event_id="EXT-999",
        title="Parampara Navratri 2026",
        venue_name="SBR Ground",
        city="Ahmedabad",
        event_start_date="2026-10-10"
    )
    assert is_dup is True
    assert dup_id == existing.id


def test_non_duplicate_event(db_session: Session):
    existing = StagingEvent(
        source="showmates",
        source_event_id="EVT-300",
        title="Unique DJ Night",
        venue_name="Club Vibe",
        city="Surat",
        event_start_date="2026-11-01",
        status=StagingEventStatus.PENDING_REVIEW
    )
    db_session.add(existing)
    db_session.commit()

    is_dup, dup_id = DuplicateDetector.check_duplicate(
        db=db_session,
        source="showmates",
        source_event_id="EVT-400",
        title="Completely Different Event",
        venue_name="Other Venue",
        city="Ahmedabad",
        event_start_date="2026-11-05"
    )
    assert is_dup is False
    assert dup_id is None
