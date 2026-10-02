from fastapi.testclient import TestClient


def test_root_endpoint(client: TestClient):
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "vibemynight-staging-sync"
    assert data["status"] == "ONLINE"


def test_health_endpoint(client: TestClient):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] in ["UP", "DEGRADED"]
    assert data["service"] == "vibemynight-staging-sync"
    assert data["database"] == "UP"
