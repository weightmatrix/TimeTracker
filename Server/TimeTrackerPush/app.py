"""TimeTracker's isolated APNs relay. No complete time records are accepted here."""

from __future__ import annotations

import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import Depends, FastAPI, Header, HTTPException, Query
from pydantic import BaseModel, Field

from apns import APNsSender
from event_store import ConflictingRetry, EventStore, InvalidPairing, SequenceGap, Transition

logger = logging.getLogger("timetracker.push")
home = Path(os.environ["TT_PUSH_HOME"]).resolve()
store = EventStore(home / "data")


class PairRequest(BaseModel):
    code: str = Field(min_length=8, max_length=32)
    deviceID: str = Field(min_length=1, max_length=80)


class TokenRequest(BaseModel):
    activityID: str = Field(min_length=1, max_length=100)
    token: str = Field(min_length=16, max_length=512)
    environment: str


class TransitionRequest(BaseModel):
    id: str
    sourceDeviceID: str
    sourceSequence: int
    previousRecordID: str | None = None
    newRecordID: str
    category: str
    startedAt: float
    committedAt: float
    yesterdayScore: float | None = None


async def identity(authorization: str = Header(default="")) -> tuple[str, str]:
    scheme, _, token = authorization.partition(" ")
    found = store.authenticate(token) if scheme.lower() == "bearer" else None
    if not found:
        raise HTTPException(401, "invalid credentials")
    return found


async def deliver(sender: APNsSender) -> None:
    last_prune = 0.0
    last_timestamps: dict[str, int] = {}
    while True:
        await asyncio.sleep(1)
        now = time.time()
        if now - last_prune >= 3600:
            store.prune_before(now - 7 * 86400)
            last_prune = now
        for row in store.pending_deliveries(now):
            try:
                device_id = row["device_id"]
                timestamp = max(int(time.time()), last_timestamps.get(device_id, 0) + 1)
                last_timestamps[device_id] = timestamp
                status, reason = await sender.update(
                    token=row["activity_token"], environment=row["token_environment"],
                    category=row["category"], started_at=row["started_at"],
                    yesterday_score=row["yesterday_score"], timestamp=timestamp)
                if status == 200:
                    store.delivery_attempted(row["device_id"], row["global_sequence"], True, now)
                elif status == 410 or (status == 400 and "BadDeviceToken" in reason):
                    store.invalidate_activity_token(row["device_id"], row["activity_token"])
                else:
                    logger.warning("APNs rejected update: status=%s reason=%s", status, reason)
                    store.delivery_attempted(row["device_id"], row["global_sequence"], False, now)
            except Exception as exc:
                logger.warning("APNs update failed: %s", type(exc).__name__)
                store.delivery_attempted(row["device_id"], row["global_sequence"], False, now)


@asynccontextmanager
async def lifespan(_: FastAPI):
    key_path = (home / "secrets" / os.environ["TT_APNS_KEY_FILE"]).resolve()
    if not key_path.is_relative_to(home) or not key_path.is_file():
        raise RuntimeError("APNs key must be inside the TimeTracker sandbox")
    sender = APNsSender(team_id=os.environ["TT_APNS_TEAM_ID"],
        key_id=os.environ["TT_APNS_KEY_ID"], key_path=key_path,
        bundle_id=os.getenv("TT_APNS_BUNDLE_ID", "Han.TimeTracker"))
    worker = asyncio.create_task(deliver(sender))
    try:
        yield
    finally:
        worker.cancel()
        try:
            await worker
        except asyncio.CancelledError:
            pass
        await sender.close()
        store.close()


app = FastAPI(lifespan=lifespan, docs_url=None, redoc_url=None, openapi_url=None)


@app.get("/healthz")
async def health():
    return {"status": "ok"}


@app.post("/v1/pair/redeem")
async def redeem(request: PairRequest):
    try:
        account_id, token = store.redeem_pairing_code(request.code, request.deviceID)
    except InvalidPairing:
        raise HTTPException(400, "invalid or expired pairing code") from None
    return {"accountID": account_id, "credential": token}


@app.post("/v1/pair/create")
async def create_pair(identity_value: tuple[str, str] = Depends(identity)):
    return {"code": store.create_pairing_code(identity_value[0]), "expiresInSeconds": 600}


@app.put("/v1/activity-token")
async def register_token(request: TokenRequest, identity_value: tuple[str, str] = Depends(identity)):
    try:
        store.register_activity_token(identity_value[0], identity_value[1],
            request.activityID, request.token, request.environment)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from None
    return {"accepted": True}


@app.post("/v1/transitions")
async def transition(request: TransitionRequest, identity_value: tuple[str, str] = Depends(identity)):
    account_id, device_id = identity_value
    if request.sourceDeviceID != device_id:
        raise HTTPException(403, "source device mismatch")
    try:
        accepted = store.accept(account_id, Transition(request.id, request.sourceDeviceID,
            request.sourceSequence, request.previousRecordID, request.newRecordID,
            request.category, request.startedAt, request.committedAt, request.yesterdayScore))
    except SequenceGap as exc:
        raise HTTPException(409, {"expectedSourceSequence": exc.expected}) from None
    except (ConflictingRetry, ValueError) as exc:
        raise HTTPException(400, str(exc)) from None
    return {"globalSequence": accepted.global_sequence,
            "becameLatest": accepted.became_latest, "duplicate": accepted.duplicate}


@app.get("/v1/transitions")
async def transitions(after: int = Query(default=0, ge=0),
                      identity_value: tuple[str, str] = Depends(identity)):
    rows = store.events_after(identity_value[0], after)
    return {"events": [dict(row) for row in rows],
            "latest": dict(store.latest(identity_value[0])) if store.latest(identity_value[0]) else None}
