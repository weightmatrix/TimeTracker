"""ActivityKit APNs sender. The .p8 key is loaded only inside the server sandbox."""

from __future__ import annotations

import base64
import json
import time
from pathlib import Path

import httpx
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

APPLE_REFERENCE_OFFSET = 978307200


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


class APNsSender:
    def __init__(self, *, team_id: str, key_id: str, key_path: Path, bundle_id: str):
        self.team_id = team_id
        self.key_id = key_id
        self.bundle_id = bundle_id
        self.key = serialization.load_pem_private_key(key_path.read_bytes(), password=None)
        if not isinstance(self.key, ec.EllipticCurvePrivateKey):
            raise ValueError("APNs key must be an elliptic-curve private key")
        self._jwt = ""
        self._jwt_issued_at = 0
        self.client = httpx.AsyncClient(http2=True, timeout=10)

    def _authorization(self) -> str:
        now = int(time.time())
        if self._jwt and now - self._jwt_issued_at < 45 * 60:
            return f"bearer {self._jwt}"
        header = _b64url(json.dumps({"alg": "ES256", "kid": self.key_id}, separators=(",", ":")).encode())
        claims = _b64url(json.dumps({"iss": self.team_id, "iat": now}, separators=(",", ":")).encode())
        signing_input = f"{header}.{claims}".encode("ascii")
        der = self.key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
        r, s = decode_dss_signature(der)
        self._jwt = f"{header}.{claims}.{_b64url(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))}"
        self._jwt_issued_at = now
        return f"bearer {self._jwt}"

    async def update(self, *, token: str, environment: str, category: str,
                     started_at: float, yesterday_score: float | None,
                     timestamp: int) -> tuple[int, str]:
        if environment not in ("development", "production"):
            raise ValueError("invalid APNs environment")
        host = "api.sandbox.push.apple.com" if environment == "development" else "api.push.apple.com"
        payload = {"aps": {
            "timestamp": timestamp,
            "event": "update",
            "content-state": {
                "category": category,
                "startTime": started_at - APPLE_REFERENCE_OFFSET,
                "yesterdayScore": yesterday_score or 0.0,
            },
        }}
        response = await self.client.post(
            f"https://{host}/3/device/{token}", json=payload,
            headers={
                "authorization": self._authorization(),
                "apns-topic": f"{self.bundle_id}.push-type.liveactivity",
                "apns-push-type": "liveactivity",
                "apns-priority": "10",
                "apns-expiration": str(timestamp + 60),
            },
        )
        return response.status_code, response.text[:200]

    async def close(self) -> None:
        await self.client.aclose()
