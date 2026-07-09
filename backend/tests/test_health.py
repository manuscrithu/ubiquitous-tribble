"""
Smoke test for CI.

Runs the real FastAPI lifespan (which connects to Postgres + Redis), so this
test doubles as a startup check: if config.py, database.py, or the Redis
wiring is broken, this fails fast in CI instead of on the VM.
"""
from fastapi.testclient import TestClient

from app.main import app


def test_health_check_returns_ok():
    with TestClient(app) as client:  # triggers startup/shutdown lifespan
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_docs_are_served():
    with TestClient(app) as client:
        response = client.get("/docs")

    assert response.status_code == 200