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


async def _register_and_login(client: AsyncClient) -> str:
    email = f"test-{uuid.uuid4().hex[:8]}@example.com"
    password = "password123"
    register = await client.post(
        f"{API}/auth/register",
        json={"email": email, "password": password},
    )
    assert register.status_code == 201
    return register.json()["access_token"]


@pytest.mark.asyncio
async def test_author_crud(client: AsyncClient):
    token = await _register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}

    create = await client.post(
        f"{API}/authors",
        headers=headers,
        json={
            "name": "Test Author",
            "links": [
                {"source": "website", "url": "https://example.com"},
                {"source": "patreon", "url": "https://patreon.com/test"},
            ],
        },
    )
    assert create.status_code == 201
    author = create.json()
    assert author["name"] == "Test Author"
    assert len(author["links"]) == 2
    author_id = author["id"]

    listing = await client.get(f"{API}/authors", headers=headers)
    assert listing.status_code == 200
    assert listing.json()["total"] == 1

    detail = await client.get(f"{API}/authors/{author_id}", headers=headers)
    assert detail.status_code == 200
    assert detail.json()["name"] == "Test Author"

    updated = await client.patch(
        f"{API}/authors/{author_id}",
        headers=headers,
        json={"name": "Renamed Author"},
    )
    assert updated.status_code == 200
    assert updated.json()["name"] == "Renamed Author"

    deleted = await client.delete(f"{API}/authors/{author_id}", headers=headers)
    assert deleted.status_code == 204


@pytest.mark.asyncio
async def test_file_crud_with_author_filter(client: AsyncClient):
    token = await _register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}

    author = await client.post(
        f"{API}/authors",
        headers=headers,
        json={"name": "File Author", "links": []},
    )
    assert author.status_code == 201
    author_id = author.json()["id"]

    create = await client.post(
        f"{API}/files",
        headers=headers,
        json={
            "name": "Adventure PDF",
            "address": "https://example.com/adventure.pdf",
            "author_id": author_id,
        },
    )
    assert create.status_code == 201
    resource_file = create.json()
    assert resource_file["author_id"] == author_id
    file_id = resource_file["id"]

    filtered = await client.get(
        f"{API}/files?author_id={author_id}",
        headers=headers,
    )
    assert filtered.status_code == 200
    body = filtered.json()
    assert body["total"] == 1
    assert body["items"][0]["id"] == file_id

    detail = await client.get(f"{API}/files/{file_id}", headers=headers)
    assert detail.status_code == 200

    deleted = await client.delete(f"{API}/files/{file_id}", headers=headers)
    assert deleted.status_code == 204


@pytest.mark.asyncio
async def test_class_crud_with_file_source(client: AsyncClient):
    token = await _register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}

    resource_file = await client.post(
        f"{API}/files",
        headers=headers,
        json={
            "name": "Class Source PDF",
            "address": "https://example.com/class.pdf",
        },
    )
    assert resource_file.status_code == 201
    file_id = resource_file.json()["id"]

    create = await client.post(
        f"{API}/classes",
        headers=headers,
        json={
            "name": "Wizard",
            "file_id": file_id,
            "caster": True,
        },
    )
    assert create.status_code == 201
    character_class = create.json()
    assert character_class["name"] == "Wizard"
    assert character_class["file_id"] == file_id
    assert character_class["caster"] is True
    class_id = character_class["id"]

    listing = await client.get(f"{API}/classes", headers=headers)
    assert listing.status_code == 200
    assert listing.json()["total"] == 1

    detail = await client.get(f"{API}/classes/{class_id}", headers=headers)
    assert detail.status_code == 200

    updated = await client.patch(
        f"{API}/classes/{class_id}",
        headers=headers,
        json={"caster": False, "name": "Mage"},
    )
    assert updated.status_code == 200
    assert updated.json()["name"] == "Mage"
    assert updated.json()["caster"] is False

    deleted = await client.delete(f"{API}/classes/{class_id}", headers=headers)
    assert deleted.status_code == 204
