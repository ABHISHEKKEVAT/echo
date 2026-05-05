from httpx import AsyncClient


async def register_and_verify(
    client: AsyncClient,
    email: str,
    username: str,
    password: str = "password123",
) -> dict:
    reg_resp = await client.post(
        "/v1/auth/register",
        json={"email": email, "username": username, "password": password},
    )
    assert reg_resp.status_code == 201
    verification_code = reg_resp.json()["verification_code"]
    verify_resp = await client.post(
        "/v1/auth/verify-email",
        json={"email": email, "code": verification_code},
    )
    assert verify_resp.status_code == 200
    return verify_resp.json()


async def issue_access_token(
    client: AsyncClient,
    email: str,
    username: str,
    password: str = "password123",
) -> str:
    body = await register_and_verify(client, email, username, password=password)
    return body["access_token"]


async def issue_token_pair(
    client: AsyncClient,
    email: str,
    username: str,
    password: str = "password123",
) -> tuple[str, str]:
    body = await register_and_verify(client, email, username, password=password)
    return body["access_token"], body["refresh_token"]
