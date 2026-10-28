import unittest
from datetime import datetime, timedelta, timezone

from app.access_control import AccessDenied, RateLimiter, verify_case_access
from app.config import Settings
from app.sharepoint_client import MockSharePointClient


def _sharepoint_with_case(**overrides) -> MockSharePointClient:
    sp = MockSharePointClient("/nonexistent-does-not-matter-for-this-test")
    sp._lists["0_Fallsteuerung"] = []
    fields = {
        "Id": "1",
        "case_id": "2026-0001",
        "access_code": "ABC123",
        "case_status": "offen",
        "Created": datetime.now(timezone.utc).isoformat(),
    }
    fields.update(overrides)
    sp.create_item("0_Fallsteuerung", fields)
    return sp


class FakeClock:
    def __init__(self, t: float = 0.0):
        self.t = t

    def __call__(self):
        return self.t


class TestVerifyCaseAccess(unittest.TestCase):
    def setUp(self):
        self.settings = Settings()
        self.sharepoint = _sharepoint_with_case()
        self.limiter = RateLimiter(self.settings)

    def test_correct_case_id_and_code_succeeds(self):
        result = verify_case_access(
            case_id="2026-0001",
            access_code="ABC123",
            client_key="1.2.3.4",
            sharepoint=self.sharepoint,
            settings=self.settings,
            rate_limiter=self.limiter,
        )
        self.assertEqual(result.case_id, "2026-0001")

    def test_unknown_case_id_denied_generic(self):
        with self.assertRaises(AccessDenied) as ctx:
            verify_case_access(
                case_id="2099-9999",
                access_code="ABC123",
                client_key="1.2.3.4",
                sharepoint=self.sharepoint,
                settings=self.settings,
                rate_limiter=self.limiter,
            )
        self.assertEqual(ctx.exception.reason, "invalid_credentials")

    def test_wrong_access_code_denied_with_same_generic_reason(self):
        with self.assertRaises(AccessDenied) as ctx:
            verify_case_access(
                case_id="2026-0001",
                access_code="FALSCH",
                client_key="1.2.3.4",
                sharepoint=self.sharepoint,
                settings=self.settings,
                rate_limiter=self.limiter,
            )
        # Bewusst DERSELBE Grund wie bei unbekannter case_id - verhindert
        # Enumeration, siehe access_control.py Moduldoc.
        self.assertEqual(ctx.exception.reason, "invalid_credentials")

    def test_expired_link_denied(self):
        old_created = (datetime.now(timezone.utc) - timedelta(days=365)).isoformat()
        sp = _sharepoint_with_case(Created=old_created)
        with self.assertRaises(AccessDenied) as ctx:
            verify_case_access(
                case_id="2026-0001",
                access_code="ABC123",
                client_key="1.2.3.4",
                sharepoint=sp,
                settings=self.settings,
                rate_limiter=RateLimiter(self.settings),
            )
        self.assertEqual(ctx.exception.reason, "link_expired")

    def test_closed_case_denied(self):
        sp = _sharepoint_with_case(case_status="übermittelt")
        with self.assertRaises(AccessDenied) as ctx:
            verify_case_access(
                case_id="2026-0001",
                access_code="ABC123",
                client_key="1.2.3.4",
                sharepoint=sp,
                settings=self.settings,
                rate_limiter=RateLimiter(self.settings),
            )
        self.assertEqual(ctx.exception.reason, "case_closed")


class TestLockoutAfterFailedAttempts(unittest.TestCase):
    def setUp(self):
        self.settings = Settings(max_attempts_per_window=3, lockout_duration_minutes=10)
        self.clock = FakeClock(0.0)
        self.limiter = RateLimiter(self.settings, clock=self.clock)
        self.sharepoint = _sharepoint_with_case()

    def _attempt_wrong_code(self):
        with self.assertRaises(AccessDenied):
            verify_case_access(
                case_id="2026-0001",
                access_code="FALSCH",
                client_key="9.9.9.9",
                sharepoint=self.sharepoint,
                settings=self.settings,
                rate_limiter=self.limiter,
            )

    def test_locked_out_after_max_attempts(self):
        for _ in range(3):
            self._attempt_wrong_code()
        # Vierter Versuch (auch mit korrektem Code!) ist jetzt gesperrt.
        with self.assertRaises(AccessDenied) as ctx:
            verify_case_access(
                case_id="2026-0001",
                access_code="ABC123",
                client_key="9.9.9.9",
                sharepoint=self.sharepoint,
                settings=self.settings,
                rate_limiter=self.limiter,
            )
        self.assertEqual(ctx.exception.reason, "locked_out")

    def test_lockout_expires_after_duration(self):
        for _ in range(3):
            self._attempt_wrong_code()
        self.clock.t += self.settings.lockout_duration_minutes * 60 + 1
        result = verify_case_access(
            case_id="2026-0001",
            access_code="ABC123",
            client_key="9.9.9.9",
            sharepoint=self.sharepoint,
            settings=self.settings,
            rate_limiter=self.limiter,
        )
        self.assertEqual(result.case_id, "2026-0001")


class TestRateLimit(unittest.TestCase):
    def test_rate_limit_triggers(self):
        settings = Settings(rate_limit_per_minute=2)
        clock = FakeClock(0.0)
        limiter = RateLimiter(settings, clock=clock)
        sharepoint = _sharepoint_with_case()

        for _ in range(2):
            verify_case_access(
                case_id="2026-0001",
                access_code="ABC123",
                client_key="5.5.5.5",
                sharepoint=sharepoint,
                settings=settings,
                rate_limiter=limiter,
            )
        with self.assertRaises(AccessDenied) as ctx:
            verify_case_access(
                case_id="2026-0001",
                access_code="ABC123",
                client_key="5.5.5.5",
                sharepoint=sharepoint,
                settings=settings,
                rate_limiter=limiter,
            )
        self.assertEqual(ctx.exception.reason, "rate_limited")


if __name__ == "__main__":
    unittest.main()
