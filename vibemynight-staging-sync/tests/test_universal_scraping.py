import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
import httpx

from app.models.staging_event import StagingEvent, StagingEventStatus
from app.services.base_adapter import AdapterRegistry, DiscoveredEvent, DeepScrapedEvent
from app.services.adapters.showmates_adapter import ShowmatesAdapter
from app.services.adapters.bookmyshow_adapter import BookMyShowAdapter
from app.services.adapters.district_adapter import DistrictAdapter


MOCK_SHOWMATES_DISCOVERY_PAYLOAD = {
    "events": [
        {
            "id": "SM-AMD-TEST-01",
            "title": "Swarnim Nagari AC Dome Garba 2026",
            "description": "Grand air-conditioned Garba dome with live orchestra.",
            "startDate": "2026-10-10",
            "endDate": "2026-10-19",
            "time": "19:30",
            "venue": "Swarnim Ground, SG Highway",
            "city": "Ahmedabad",
            "state": "Gujarat",
            "bannerImage": "https://cdn.showmates.in/banners/swarnim.jpg",
            "posterImage": "https://cdn.showmates.in/posters/swarnim.jpg",
            "priceStarting": 499,
            "priceMax": 2499,
            "url": "https://showmates.in/event/swarnim-nagari-ac-dome-garba-2026",
            "artists": [{"name": "Aishwarya Majmudar", "role": "Lead Performer", "imageUrl": "https://cdn.showmates.in/artists/aishwarya.jpg"}],
            "passes": [{"name": "Season Pass", "price": 499, "totalQuantity": 2000, "benefits": ["9 Nights Ground Entry"]}],
            "facilities": ["AC Dome", "Parking"],
            "rules": ["Traditional dress mandatory"]
        }
    ]
}

MOCK_BMS_DISCOVERY_PAYLOAD = {
    "events": [
        {
            "id": "BMS-VDR-TEST-01",
            "title": "United Way of Baroda Garba 2026",
            "description": "Authentic Vadodara Garba with Atul Purohit.",
            "startDate": "2026-10-10",
            "endDate": "2026-10-19",
            "time": "20:00",
            "venue": "Navlakhi Ground",
            "city": "Vadodara",
            "state": "Gujarat",
            "bannerImage": "https://in.bmscdn.com/banners/unitedway.jpg",
            "posterImage": "https://in.bmscdn.com/posters/unitedway.jpg",
            "priceStarting": 799,
            "priceMax": 3999,
            "url": "https://in.bookmyshow.com/events/united-way-garba/ET00101",
            "artists": [{"name": "Atul Purohit", "role": "Maestro"}],
            "passes": [{"name": "Player Pass", "price": 799, "totalQuantity": 15000}],
            "facilities": ["Massive Arena"],
            "rules": ["Garba attire required"]
        }
    ]
}

MOCK_DISTRICT_DISCOVERY_PAYLOAD = {
    "events": [
        {
            "id": "DST-AMD-TEST-01",
            "title": "Ahmedabad Night Festival 2026",
            "description": "Premier nightlife music event.",
            "startDate": "2026-10-15",
            "time": "20:00",
            "venue": "Club O7 Arena",
            "city": "Ahmedabad",
            "state": "Gujarat",
            "bannerImage": "https://cdn.district.in/banners/party.jpg",
            "posterImage": "https://cdn.district.in/posters/party.jpg",
            "priceStarting": 500,
            "priceMax": 1500,
            "url": "https://www.district.in/events/ahmedabad-night-festival",
            "artists": [{"name": "DJ Zaeden", "role": "Headliner"}],
            "passes": [{"name": "General Admission", "price": 500, "totalQuantity": 1000}],
            "facilities": ["Valet Parking"],
            "rules": ["21+ only"]
        }
    ]
}


def test_adapter_registry():
    """Verify all 3 source adapters are registered properly."""
    sources = AdapterRegistry.list_sources()
    assert "showmates" in sources
    assert "bookmyshow" in sources
    assert "district" in sources

    assert AdapterRegistry.get("showmates") is not None
    assert AdapterRegistry.get("bookmyshow") is not None
    assert AdapterRegistry.get("district") is not None
    assert AdapterRegistry.get("nonexistent") is None


@pytest.mark.asyncio
async def test_showmates_adapter_discovery_and_deep_scrape():
    adapter = ShowmatesAdapter(api_url="https://api.showmates.test/events")
    
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = MOCK_SHOWMATES_DISCOVERY_PAYLOAD
    mock_resp.text = ""

    with patch("httpx.AsyncClient.get", return_value=mock_resp):
        # 1. Discover
        discovered = await adapter.discover(city="Ahmedabad")
        assert len(discovered) >= 1
        for ev in discovered:
            assert ev.source == "showmates"
            assert ev.source_event_id == "SM-AMD-TEST-01"
            assert ev.title == "Swarnim Nagari AC Dome Garba 2026"
            assert ev.event_url == "https://showmates.in/event/swarnim-nagari-ac-dome-garba-2026"

        # 2. Deep Scrape
        target = discovered[0]
        deep = await adapter.deep_scrape(
            event_url=target.event_url,
            hint_payload=target.raw_discovery_payload
        )
        assert deep.source == "showmates"
        assert deep.title == target.title
        assert len(deep.days) >= 1
        assert len(deep.passes) >= 1
        assert len(deep.artists) >= 1
        assert len(deep.facilities) >= 1
        assert len(deep.rules) >= 1
        assert deep.validation_status == "VALID"


@pytest.mark.asyncio
async def test_bookmyshow_adapter_discovery_and_deep_scrape():
    adapter = BookMyShowAdapter(api_url="https://api.bookmyshow.test/events")
    
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = MOCK_BMS_DISCOVERY_PAYLOAD
    mock_resp.text = ""

    with patch("httpx.AsyncClient.get", return_value=mock_resp):
        # 1. Discover
        discovered = await adapter.discover(city="Vadodara")
        assert len(discovered) >= 1
        for ev in discovered:
            assert ev.source == "bookmyshow"
            assert ev.city == "Vadodara"

        # 2. Deep Scrape
        target = discovered[0]
        deep = await adapter.deep_scrape(
            event_url=target.event_url,
            hint_payload=target.raw_discovery_payload
        )
        assert deep.source == "bookmyshow"
        assert len(deep.passes) >= 1
        assert len(deep.artists) >= 1
        assert deep.validation_status == "VALID"


@pytest.mark.asyncio
async def test_district_adapter_discovery_and_deep_scrape():
    adapter = DistrictAdapter(api_url="https://api.district.test/events")
    
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = MOCK_DISTRICT_DISCOVERY_PAYLOAD
    mock_resp.text = ""

    with patch("httpx.AsyncClient.get", return_value=mock_resp):
        # 1. Discover
        discovered = await adapter.discover(city="Ahmedabad")
        assert len(discovered) >= 1
        for ev in discovered:
            assert ev.source == "district"

        # 2. Deep Scrape
        target = discovered[0]
        deep = await adapter.deep_scrape(
            event_url=target.event_url,
            hint_payload=target.raw_discovery_payload
        )
        assert deep.source == "district"
        assert len(deep.passes) >= 1
        assert len(deep.artists) >= 1
        assert deep.validation_status == "VALID"


def test_api_discover_endpoint(client: TestClient):
    """Test POST /api/v1/sync/discover."""
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = MOCK_SHOWMATES_DISCOVERY_PAYLOAD
    mock_resp.text = ""

    with patch("httpx.AsyncClient.get", return_value=mock_resp):
        # Discover all sources
        resp = client.post("/api/v1/sync/discover", json={"source": "showmates", "city": "Ahmedabad"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["total_discovered"] >= 1
        assert len(data["items"]) >= 1


def test_api_deep_scrape_and_staging(client: TestClient, db_session: Session):
    """Test POST /api/v1/sync/deep-scrape workflow."""
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = MOCK_SHOWMATES_DISCOVERY_PAYLOAD
    mock_resp.text = ""

    with patch("httpx.AsyncClient.get", return_value=mock_resp):
        # 1. First discover events
        discover_resp = client.post("/api/v1/sync/discover", json={"source": "showmates", "city": "Ahmedabad"})
        items = discover_resp.json()["items"]
        assert len(items) >= 1
        first_item = items[0]

        # 2. Deep scrape selected item
        scrape_payload = {
            "events": [
                {
                    "source": first_item["source"],
                    "source_event_id": first_item["source_event_id"],
                    "event_url": first_item["event_url"],
                    "title": first_item["title"],
                    "hint_payload": first_item.get("raw_discovery_payload")
                }
            ],
            "run_ai_enrichment": True
        }

        scrape_resp = client.post("/api/v1/sync/deep-scrape", json=scrape_payload)
        assert scrape_resp.status_code == 200
        scrape_data = scrape_resp.json()
        assert scrape_data["success"] is True
        assert scrape_data["total_staged"] == 1
        assert scrape_data["total_duplicates"] == 0

        # 3. Verify in staging DB
        db_session.expire_all()
        staged = db_session.query(StagingEvent).filter(
            StagingEvent.source == first_item["source"],
            StagingEvent.source_event_id == first_item["source_event_id"]
        ).first()
        assert staged is not None
        assert staged.title == first_item["title"]
        assert staged.raw_payload is not None
        assert "passes" in staged.raw_payload
        assert "artists" in staged.raw_payload

        # 4. Deep scraping again should flag as duplicate
        duplicate_scrape_resp = client.post("/api/v1/sync/deep-scrape", json=scrape_payload)
        assert duplicate_scrape_resp.status_code == 200
        dup_data = duplicate_scrape_resp.json()
        assert dup_data["total_duplicates"] == 1
        assert dup_data["results"][0]["is_duplicate"] is True
