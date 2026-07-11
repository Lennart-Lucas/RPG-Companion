import uuid

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app

API = "/api/v1"


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_health(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_register_login_me_refresh_logout(client: AsyncClient):
    email = f"test-{uuid.uuid4().hex[:8]}@example.com"
    password = "password123"

    register = await client.post(
        f"{API}/auth/register",
        json={"email": email, "password": password},
    )
    assert register.status_code == 201
    tokens = register.json()
    assert "access_token" in tokens
    assert "refresh_token" in tokens

    login = await client.post(
        f"{API}/auth/login",
        json={"email": email, "password": password},
    )
    assert login.status_code == 200
    login_tokens = login.json()

    me = await client.get(
        f"{API}/auth/me",
        headers={"Authorization": f"Bearer {login_tokens['access_token']}"},
    )
    assert me.status_code == 200
    assert me.json()["email"] == email

    refresh = await client.post(
        f"{API}/auth/refresh",
        json={"refresh_token": login_tokens["refresh_token"]},
    )
    assert refresh.status_code == 200
    refreshed = refresh.json()
    assert refreshed["access_token"]
    assert refreshed["refresh_token"]

    logout = await client.post(
        f"{API}/auth/logout",
        json={"refresh_token": refreshed["refresh_token"]},
        headers={"Authorization": f"Bearer {refreshed['access_token']}"},
    )
    assert logout.status_code == 204
