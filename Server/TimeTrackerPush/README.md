# TimeTracker APNs relay

The server stores short-lived switch events, device credentials, ActivityKit tokens and the latest state. Complete time records remain in iCloud. One event is retained for every accepted switch; APNs delivery can coalesce to the latest state per device.

## Isolated host directory

Deploy the contents of this folder under `/srv/apps/timetracker`. Keep `data/`, `secrets/`, `.env` and Compose inside that directory. The shared HTTPS ingress needs only the route in `nginx.location.conf` to `timetracker-push:8000` on the existing `paike_default` Docker network; it must not serve `/srv/apps/timetracker` as static files. The service also binds `127.0.0.1:8765` for host-only checks. Do not place this service inside the Paike or papers application directory. The deployed ingress template was backed up as `nginx.portal.conf.template.before-timetracker-20261112` before this route was added.

Create the directories with owner UID 10001 and mode 0700. Store the Apple `.p8` key at `secrets/AuthKey_....p8` with mode 0400. Copy `.env.example` to `.env`, fill the Team ID, Key ID and key filename, and keep both files out of Git. `compose.yml` exposes the app only on the host loopback interface. Use HTTPS at the public reverse proxy.

Run `docker compose -f compose.yml up -d --build` only after the key and HTTPS route are ready. `GET /healthz` checks the process. Run `docker compose -f compose.yml run --rm push python manage.py create-account` to issue the first account's ten-minute, single-use pairing code. After one device pairs, it can request another code for its other devices. Never log a credential or a pairing code.

## Endpoint contract

- `POST /v1/pair/redeem` accepts `{code,deviceID}`, returns a per-device bearer credential.
- `POST /v1/pair/create` requires that credential and returns a new ten-minute single-use code.
- `PUT /v1/activity-token` registers `{activityID,token,environment}` for the authenticated device.
- `POST /v1/transitions` accepts a `TimerTransitionEvent` from that device. The `id` is idempotent and `sourceSequence` must be contiguous after the first accepted sequence; a gap returns HTTP 409 with the expected sequence.
- `GET /v1/transitions?after=N` allows a device to inspect all retained events after global sequence N and the latest state.

Only the newest accepted state per account is queued for ActivityKit delivery. Older events remain queryable for seven days; the latest event remains until replaced. A late replay is accepted into the event log but cannot replace a newer `committedAt` state. APNs may delay or drop a push, so the iCloud record file and foreground reconciliation remain necessary.
