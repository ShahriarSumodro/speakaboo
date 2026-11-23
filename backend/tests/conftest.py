"""
Pytest configuration and shared fixtures for Speakaboo backend tests.
"""

import os
# Ensure test mode is enabled for automated unit tests so mock providers are permitted
os.environ["TEST_MODE"] = "true"

import pytest
from fastapi.testclient import TestClient

from backend.main import app


@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    with TestClient(app) as c:
        yield c
