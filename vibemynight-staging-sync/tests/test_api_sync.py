from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.models.staging_event import StagingEvent, StagingEventStatus


def test_sync_fetch_pipeline(client: TestClient, db_session: Session):
    # Trigger fetch pipeline
    response = client.post("/api/v1/sync/fetch")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["fetched"] >= 3
    assert data["processed"] >= 3

    # Verify records in database
    staged_events = db_session.query(StagingEvent).all()
    assert len(staged_events) >= 3
    for ev in staged_events:
        assert ev.status in [StagingEventStatus.PENDING_REVIEW, StagingEventStatus.AI_PROCESSING_FAILED]
        assert ev.title is not None
        assert ev.source in ["showmates", "bookmyshow", "district"]

    # Running fetch again should detect duplicates
    second_fetch = client.post("/api/v1/sync/fetch")
    assert second_fetch.status_code == 200
    second_data = second_fetch.json()
    assert second_data["duplicates"] >= 3


def test_list_staged_events_and_filters(client: TestClient, db_session: Session):
    # Insert test events
    ev1 = StagingEvent(
        source="showmates",
        source_event_id="TEST-01",
        title="Surat Garba Extravaganza",
        city="Surat",
        status=StagingEventStatus.PENDING_REVIEW
    )
    ev2 = StagingEvent(
        source="showmates",
        source_event_id="TEST-02",
        title="Ahmedabad DJ Fest",
        city="Ahmedabad",
        status=StagingEventStatus.READY_TO_IMPORT
    )
    db_session.add_all([ev1, ev2])
    db_session.commit()

    # List all
    res_all = client.get("/api/v1/sync/events")
    assert res_all.status_code == 200
    assert res_all.json()["total"] == 2

    # Filter by city
    res_surat = client.get("/api/v1/sync/events?city=Surat")
    assert res_surat.status_code == 200
    assert res_surat.json()["total"] == 1
    assert res_surat.json()["items"][0]["city"] == "Surat"

    # Filter by status
    res_ready = client.get("/api/v1/sync/events?status=READY_TO_IMPORT")
    assert res_ready.status_code == 200
    assert res_ready.json()["total"] == 1
    assert res_ready.json()["items"][0]["title"] == "Ahmedabad DJ Fest"


def test_get_single_staged_event(client: TestClient, db_session: Session):
    ev = StagingEvent(
        source="showmates",
        source_event_id="TEST-SINGLE",
        title="Exclusive Nightlife Concert",
        city="Ahmedabad",
        status=StagingEventStatus.PENDING_REVIEW
    )
    db_session.add(ev)
    db_session.commit()

    res = client.get(f"/api/v1/sync/events/{ev.id}")
    assert res.status_code == 200
    data = res.json()
    assert data["id"] == ev.id
    assert data["title"] == "Exclusive Nightlife Concert"

    # Not found case
    res_404 = client.get("/api/v1/sync/events/99999")
    assert res_404.status_code == 404


def test_update_staged_event_admin(client: TestClient, db_session: Session):
    ev = StagingEvent(
        source="showmates",
        source_event_id="TEST-EDIT",
        title="Raw Unpolished Title",
        city="Ahmedabad",
        status=StagingEventStatus.PENDING_REVIEW
    )
    db_session.add(ev)
    db_session.commit()

    update_payload = {
        "enhanced_title": "Polished VIP Experience | VibeMyNight",
        "min_ticket_price": 599.0,
        "max_ticket_price": 2999.0,
        "status": "READY_TO_IMPORT",
        "highlights": ["VIP Lounge", "Valet Parking"]
    }

    res = client.put(f"/api/v1/sync/events/{ev.id}", json=update_payload)
    assert res.status_code == 200
    data = res.json()
    assert data["enhanced_title"] == "Polished VIP Experience | VibeMyNight"
    assert data["min_ticket_price"] == 599.0
    assert data["status"] == "READY_TO_IMPORT"
    assert "VIP Lounge" in data["highlights"]
