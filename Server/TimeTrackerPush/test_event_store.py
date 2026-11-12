import tempfile
import unittest
from pathlib import Path

from event_store import ConflictingRetry, EventStore, InvalidPairing, SequenceGap, Transition


class EventStoreTests(unittest.TestCase):
    def test_rapid_switches_survive_restart_and_retries(self):
        with tempfile.TemporaryDirectory() as directory:
            store = EventStore(Path(directory))
            for number in range(1, 101):
                event = Transition(str(number), "mac", number, str(number - 1) if number > 1 else None,
                                   str(number), "工作" if number % 2 else "生活", 1000, 1000 + number)
                accepted = store.accept("account", event)
                self.assertTrue(accepted.became_latest)
                self.assertFalse(accepted.duplicate)
                self.assertEqual(store.accept("account", event).global_sequence, accepted.global_sequence)
            store.close()
            store = EventStore(Path(directory))
            self.assertEqual(len(store.events_after("account", 0)), 100)
            self.assertEqual(store.latest("account")["event_id"], "100")
            self.assertEqual(store.events_after("other", 0), [])
            with self.assertRaises(SequenceGap) as gap:
                store.accept("account", Transition("102", "mac", 102, "100", "102", "刚需", 1000, 1200))
            self.assertEqual(gap.exception.expected, 101)
            with self.assertRaises(ConflictingRetry):
                store.accept("account", Transition("100", "mac", 100, "99", "100", "changed", 1000, 1100))
            old = store.accept("account", Transition("phone-1", "phone", 1, None, "phone-record", "刚需", 900, 900))
            self.assertFalse(old.became_latest)
            self.assertEqual(store.latest("account")["event_id"], "100")
            self.assertEqual(store.prune_before(9999999999), 100)
            self.assertEqual(store.latest("account")["event_id"], "100")
            store.close()

    def test_one_time_pairing_and_latest_delivery(self):
        with tempfile.TemporaryDirectory() as directory:
            store = EventStore(Path(directory))
            account, first_code = store.create_account()
            _, mac_token = store.redeem_pairing_code(first_code, "mac")
            with self.assertRaises(InvalidPairing):
                store.redeem_pairing_code(first_code, "other")
            second_code = store.create_pairing_code(account)
            _, phone_token = store.redeem_pairing_code(second_code, "phone")
            self.assertEqual(store.authenticate(mac_token), (account, "mac"))
            self.assertEqual(store.authenticate(phone_token), (account, "phone"))
            store.register_activity_token(account, "phone", "activity", "deadbeef", "development")
            for n in range(1, 101):
                store.accept(account, Transition(str(n), "mac", n, None, str(n), "工作", 1000, 1000+n))
            pending = store.pending_deliveries(9999999999)
            self.assertEqual(len(pending), 1)
            self.assertEqual(pending[0]["category"], "工作")
            self.assertEqual(pending[0]["global_sequence"], 100)
            store.delivery_attempted("phone", 100, True, 10000)
            self.assertFalse(store.pending_deliveries(9999999999))
            store.close()


if __name__ == "__main__":
    unittest.main()
