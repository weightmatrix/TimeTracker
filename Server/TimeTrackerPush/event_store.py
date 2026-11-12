"""Small, isolated relay state. Complete time records stay in the user's iCloud."""

from __future__ import annotations

import sqlite3
import hashlib
import math
import secrets
import time
import uuid
from dataclasses import dataclass
from pathlib import Path


class SequenceGap(ValueError):
    def __init__(self, expected: int):
        super().__init__(f"expected source sequence {expected}")
        self.expected = expected


class ConflictingRetry(ValueError):
    pass


class InvalidPairing(ValueError):
    pass


@dataclass(frozen=True)
class Transition:
    event_id: str
    source_device_id: str
    source_sequence: int
    previous_record_id: str | None
    new_record_id: str
    category: str
    started_at: float
    committed_at: float
    yesterday_score: float | None = None


@dataclass(frozen=True)
class Accepted:
    global_sequence: int
    became_latest: bool
    duplicate: bool


class EventStore:
    def __init__(self, directory: Path):
        self.directory = directory
        self.directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        self.path = directory / "events.sqlite3"
        self.db = sqlite3.connect(self.path, timeout=15)
        self.db.row_factory = sqlite3.Row
        self.db.execute("PRAGMA journal_mode=WAL")
        self.db.execute("PRAGMA busy_timeout=15000")
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS events (
                global_sequence INTEGER PRIMARY KEY AUTOINCREMENT,
                account_id TEXT NOT NULL,
                event_id TEXT NOT NULL,
                source_device_id TEXT NOT NULL,
                source_sequence INTEGER NOT NULL,
                previous_record_id TEXT,
                new_record_id TEXT NOT NULL,
                category TEXT NOT NULL,
                started_at REAL NOT NULL,
                committed_at REAL NOT NULL,
                yesterday_score REAL,
                received_at REAL NOT NULL DEFAULT (unixepoch()),
                UNIQUE(account_id, event_id),
                UNIQUE(account_id, source_device_id, source_sequence)
            );
            CREATE INDEX IF NOT EXISTS events_account_sequence
                ON events(account_id, global_sequence);
            CREATE TABLE IF NOT EXISTS cursors (
                account_id TEXT NOT NULL,
                source_device_id TEXT NOT NULL,
                last_sequence INTEGER NOT NULL,
                PRIMARY KEY(account_id, source_device_id)
            );
            CREATE TABLE IF NOT EXISTS latest (
                account_id TEXT PRIMARY KEY,
                global_sequence INTEGER NOT NULL,
                event_id TEXT NOT NULL,
                committed_at REAL NOT NULL,
                source_device_id TEXT NOT NULL,
                source_sequence INTEGER NOT NULL
            );
            CREATE TABLE IF NOT EXISTS accounts (
                account_id TEXT PRIMARY KEY
            );
            CREATE TABLE IF NOT EXISTS pairing_codes (
                code_hash TEXT PRIMARY KEY,
                account_id TEXT NOT NULL,
                expires_at REAL NOT NULL
            );
            CREATE TABLE IF NOT EXISTS devices (
                device_id TEXT PRIMARY KEY,
                account_id TEXT NOT NULL,
                credential_hash TEXT NOT NULL UNIQUE,
                activity_id TEXT,
                activity_token TEXT,
                token_environment TEXT
            );
            CREATE INDEX IF NOT EXISTS devices_account ON devices(account_id);
            CREATE TABLE IF NOT EXISTS delivery (
                device_id TEXT PRIMARY KEY,
                global_sequence INTEGER NOT NULL,
                last_attempt_at REAL NOT NULL DEFAULT 0,
                attempts INTEGER NOT NULL DEFAULT 0
            );
        """)
        self.path.chmod(0o600)

    def close(self) -> None:
        self.db.close()

    @staticmethod
    def _hash(secret: str) -> str:
        return hashlib.sha256(secret.encode("utf-8")).hexdigest()

    def create_account(self) -> tuple[str, str]:
        account_id = str(uuid.uuid4())
        with self.db:
            self.db.execute("INSERT INTO accounts(account_id) VALUES (?)", (account_id,))
        return account_id, self.create_pairing_code(account_id)

    def create_pairing_code(self, account_id: str) -> str:
        if not self.db.execute("SELECT 1 FROM accounts WHERE account_id=?", (account_id,)).fetchone():
            raise InvalidPairing("unknown account")
        alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        code = "".join(secrets.choice(alphabet) for _ in range(16))
        with self.db:
            self.db.execute("INSERT INTO pairing_codes VALUES (?,?,?)",
                            (self._hash(code), account_id, time.time() + 600))
        return code

    def redeem_pairing_code(self, code: str, device_id: str) -> tuple[str, str]:
        if not device_id or not code:
            raise InvalidPairing("missing code or device")
        token = secrets.token_urlsafe(32)
        self.db.execute("BEGIN IMMEDIATE")
        with self.db:
            row = self.db.execute("SELECT account_id,expires_at FROM pairing_codes WHERE code_hash=?",
                                  (self._hash(code.upper().strip()),)).fetchone()
            if not row or row["expires_at"] < time.time():
                raise InvalidPairing("invalid or expired code")
            existing = self.db.execute("SELECT account_id FROM devices WHERE device_id=?", (device_id,)).fetchone()
            if existing and existing[0] != row["account_id"]:
                raise InvalidPairing("device already belongs to another account")
            self.db.execute("DELETE FROM pairing_codes WHERE code_hash=?", (self._hash(code.upper().strip()),))
            self.db.execute("""
                INSERT INTO devices(device_id,account_id,credential_hash) VALUES (?,?,?)
                ON CONFLICT(device_id) DO UPDATE SET credential_hash=excluded.credential_hash
            """, (device_id, row["account_id"], self._hash(token)))
            return row["account_id"], token

    def authenticate(self, token: str) -> tuple[str, str] | None:
        if not token:
            return None
        row = self.db.execute("SELECT account_id,device_id FROM devices WHERE credential_hash=?",
                              (self._hash(token),)).fetchone()
        return (row["account_id"], row["device_id"]) if row else None

    def register_activity_token(self, account_id: str, device_id: str, activity_id: str,
                                token: str, environment: str) -> None:
        if not activity_id or not token or len(token) > 512 or len(token) % 2 or environment not in ("development", "production"):
            raise ValueError("invalid activity token registration")
        try:
            bytes.fromhex(token)
        except ValueError as exc:
            raise ValueError("invalid activity token") from exc
        with self.db:
            updated = self.db.execute("""
                UPDATE devices SET activity_id=?,activity_token=?,token_environment=?
                WHERE account_id=? AND device_id=?
            """, (activity_id, token, environment, account_id, device_id))
            if updated.rowcount != 1:
                raise ValueError("device not registered")
            latest = self.latest(account_id)
            if latest:
                self.db.execute("""
                    INSERT INTO delivery(device_id,global_sequence) VALUES (?,?)
                    ON CONFLICT(device_id) DO UPDATE SET global_sequence=excluded.global_sequence,
                        attempts=0,last_attempt_at=0
                """, (device_id, latest["global_sequence"]))

    def pending_deliveries(self, now: float, limit: int = 100) -> list[sqlite3.Row]:
        return self.db.execute("""
            SELECT d.device_id,d.activity_token,d.activity_id,d.token_environment,
                   q.global_sequence,q.attempts,e.category,e.started_at,e.yesterday_score
            FROM delivery q JOIN devices d ON d.device_id=q.device_id
            JOIN events e ON e.global_sequence=q.global_sequence
            WHERE d.activity_token IS NOT NULL AND q.last_attempt_at <= ?
            ORDER BY q.global_sequence LIMIT ?
        """, (now, limit)).fetchall()

    def delivery_attempted(self, device_id: str, sequence: int, succeeded: bool, now: float) -> None:
        with self.db:
            if succeeded:
                self.db.execute("DELETE FROM delivery WHERE device_id=? AND global_sequence=?",
                                (device_id, sequence))
            else:
                attempts = self.db.execute("SELECT attempts FROM delivery WHERE device_id=? AND global_sequence=?",
                                           (device_id, sequence)).fetchone()
                delay = min(300, 2 ** min(attempts[0] if attempts else 0, 8))
                self.db.execute("""
                    UPDATE delivery SET attempts=attempts+1,last_attempt_at=?
                    WHERE device_id=? AND global_sequence=?
                """, (now + delay, device_id, sequence))

    def invalidate_activity_token(self, device_id: str, token: str) -> None:
        with self.db:
            self.db.execute("""
                UPDATE devices SET activity_token=NULL,activity_id=NULL,token_environment=NULL
                WHERE device_id=? AND activity_token=?
            """, (device_id, token))
            self.db.execute("DELETE FROM delivery WHERE device_id=?", (device_id,))

    def accept(self, account_id: str, event: Transition) -> Accepted:
        if (not account_id or not event.event_id or not event.source_device_id
                or not event.new_record_id or not event.category
                or max(map(len, (account_id, event.event_id, event.source_device_id,
                                 event.new_record_id, event.category))) > 100
                or event.source_sequence < 1 or event.source_sequence >= 2**63
                or not math.isfinite(event.started_at) or not math.isfinite(event.committed_at)
                or event.started_at > event.committed_at
                or event.committed_at > time.time() + 300):
            raise ValueError("invalid transition")
        self.db.execute("BEGIN IMMEDIATE")
        with self.db:
            old = self.db.execute(
                "SELECT * FROM events WHERE account_id=? AND event_id=?",
                (account_id, event.event_id),
            ).fetchone()
            if old:
                if not self._matches(old, event):
                    raise ConflictingRetry("event ID reused with different content")
                return Accepted(old["global_sequence"], self._is_latest(account_id, old["global_sequence"]), True)
            cursor = self.db.execute(
                "SELECT last_sequence FROM cursors WHERE account_id=? AND source_device_id=?",
                (account_id, event.source_device_id),
            ).fetchone()
            # A device may have acknowledged earlier local events before its first pairing.
            expected = (cursor[0] + 1) if cursor else event.source_sequence
            if event.source_sequence != expected:
                raise SequenceGap(expected)
            try:
                inserted = self.db.execute("""
                    INSERT INTO events(account_id,event_id,source_device_id,source_sequence,
                        previous_record_id,new_record_id,category,started_at,committed_at,yesterday_score)
                    VALUES (?,?,?,?,?,?,?,?,?,?)
                """, (account_id, event.event_id, event.source_device_id, event.source_sequence,
                      event.previous_record_id, event.new_record_id, event.category,
                      event.started_at, event.committed_at, event.yesterday_score))
            except sqlite3.IntegrityError as exc:
                raise ConflictingRetry("device sequence reused with another event") from exc
            self.db.execute("""
                INSERT INTO cursors(account_id,source_device_id,last_sequence) VALUES (?,?,?)
                ON CONFLICT(account_id,source_device_id) DO UPDATE SET last_sequence=excluded.last_sequence
            """, (account_id, event.source_device_id, event.source_sequence))
            sequence = inserted.lastrowid
            latest = self.db.execute("SELECT * FROM latest WHERE account_id=?", (account_id,)).fetchone()
            became_latest = not latest or (event.committed_at, event.source_device_id, event.source_sequence) > (
                latest["committed_at"], latest["source_device_id"], latest["source_sequence"])
            if became_latest:
                self.db.execute("""
                    INSERT INTO latest(account_id,global_sequence,event_id,committed_at,source_device_id,source_sequence)
                    VALUES (?,?,?,?,?,?) ON CONFLICT(account_id) DO UPDATE SET
                        global_sequence=excluded.global_sequence,event_id=excluded.event_id,
                        committed_at=excluded.committed_at,source_device_id=excluded.source_device_id,
                        source_sequence=excluded.source_sequence
                """, (account_id, sequence, event.event_id, event.committed_at,
                      event.source_device_id, event.source_sequence))
                self.db.execute("""
                    INSERT INTO delivery(device_id,global_sequence)
                    SELECT device_id,? FROM devices WHERE account_id=? AND activity_token IS NOT NULL
                    ON CONFLICT(device_id) DO UPDATE SET global_sequence=excluded.global_sequence,
                        attempts=0,last_attempt_at=0
                """, (sequence, account_id))
            return Accepted(sequence, became_latest, False)

    def events_after(self, account_id: str, sequence: int, limit: int = 500) -> list[sqlite3.Row]:
        return self.db.execute("""
            SELECT * FROM events WHERE account_id=? AND global_sequence>?
            ORDER BY global_sequence LIMIT ?
        """, (account_id, sequence, min(max(limit, 1), 500))).fetchall()

    def latest(self, account_id: str) -> sqlite3.Row | None:
        return self.db.execute("""
            SELECT e.* FROM latest l JOIN events e ON e.global_sequence=l.global_sequence
            WHERE l.account_id=?
        """, (account_id,)).fetchone()

    def prune_before(self, received_at: float) -> int:
        """Keep only short-lived events, but retain each account's latest state."""
        with self.db:
            deleted = self.db.execute("""
                DELETE FROM events WHERE received_at < ?
                AND global_sequence NOT IN (SELECT global_sequence FROM latest)
            """, (received_at,))
            return deleted.rowcount

    def _is_latest(self, account_id: str, sequence: int) -> bool:
        row = self.db.execute("SELECT global_sequence FROM latest WHERE account_id=?", (account_id,)).fetchone()
        return bool(row and row[0] == sequence)

    @staticmethod
    def _matches(row: sqlite3.Row, event: Transition) -> bool:
        return all(row[key] == value for key, value in {
            "source_device_id": event.source_device_id,
            "source_sequence": event.source_sequence,
            "previous_record_id": event.previous_record_id,
            "new_record_id": event.new_record_id,
            "category": event.category,
            "started_at": event.started_at,
            "committed_at": event.committed_at,
            "yesterday_score": event.yesterday_score,
        }.items())
