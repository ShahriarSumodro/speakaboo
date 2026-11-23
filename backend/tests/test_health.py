"""
Tests for health endpoint and basic app setup.
"""


def test_health_endpoint(client):
    """Health endpoint returns ok status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "speakaboo"
    assert "version" in data


def test_health_has_version(client):
    """Health endpoint includes version string."""
    response = client.get("/health")
    data = response.json()
    assert data["version"] == "0.1.0"


def test_cors_headers(client):
    """CORS headers are set."""
    response = client.options(
        "/health",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
        },
    )
    # Should not be 405
    assert response.status_code in (200, 204)
