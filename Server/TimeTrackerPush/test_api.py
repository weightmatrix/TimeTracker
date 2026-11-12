import asyncio
import importlib
import os
import sys
import tempfile
import types
import unittest

import httpx


class APITests(unittest.IsolatedAsyncioTestCase):
    async def test_pairing_auth_sequence_and_latest_state(self):
        with tempfile.TemporaryDirectory() as directory:
            os.environ["TT_PUSH_HOME"] = directory
            fake = types.ModuleType("apns")
            fake.APNsSender = object
            sys.modules["apns"] = fake
            server = importlib.import_module("app")
            account, code = server.store.create_account()
            transport = httpx.ASGITransport(app=server.app)
            async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post("/v1/pair/redeem", json={"code": code, "deviceID": "mac"})
                self.assertEqual(response.status_code, 200)
                credential = response.json()["credential"]
                headers = {"Authorization": f"Bearer {credential}"}
                self.assertEqual((await client.post("/v1/pair/redeem", json={"code": code, "deviceID": "phone"})).status_code, 400)
                self.assertEqual((await client.get("/v1/transitions")).status_code, 401)
                event = {"id": "e1", "sourceDeviceID": "mac", "sourceSequence": 1,
                    "previousRecordID": "old", "newRecordID": "new", "category": "生活",
                    "startedAt": 1000, "committedAt": 1001, "yesterdayScore": 80}
                accepted = await client.post("/v1/transitions", json=event, headers=headers)
                self.assertEqual(accepted.status_code, 200)
                self.assertTrue(accepted.json()["becameLatest"])
                self.assertTrue((await client.post("/v1/transitions", json=event, headers=headers)).json()["duplicate"])
                self.assertEqual((await client.post("/v1/transitions", json={**event, "id": "e3", "sourceSequence": 3}, headers=headers)).status_code, 409)
                self.assertEqual((await client.post("/v1/transitions", json={**event, "id": "bad", "sourceDeviceID": "phone"}, headers=headers)).status_code, 403)
                events = (await client.get("/v1/transitions", headers=headers)).json()
                self.assertEqual(len(events["events"]), 1)
                self.assertEqual(events["latest"]["new_record_id"], "new")
                self.assertEqual((await client.post("/v1/pair/create", headers=headers)).status_code, 200)
            server.store.close()
            del sys.modules["app"]
            del sys.modules["apns"]


if __name__ == "__main__":
    unittest.main()
