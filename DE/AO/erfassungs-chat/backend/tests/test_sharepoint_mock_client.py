import json
import tempfile
import unittest
from pathlib import Path

from app.sharepoint_client import MockSharePointClient, SharePointError


class TestMockSharePointClient(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.data_dir = Path(self.tmp.name)
        (self.data_dir / "0_Fallsteuerung.json").write_text(
            json.dumps([{"Id": "1", "case_id": "2026-0001", "access_code": "X"}]), encoding="utf-8"
        )

    def tearDown(self):
        self.tmp.cleanup()

    def test_loads_seed_data(self):
        client = MockSharePointClient(self.data_dir)
        item = client.get_item("0_Fallsteuerung", "case_id", "2026-0001")
        self.assertEqual(item["access_code"], "X")

    def test_get_item_missing_returns_none(self):
        client = MockSharePointClient(self.data_dir)
        self.assertIsNone(client.get_item("0_Fallsteuerung", "case_id", "nope"))

    def test_create_item_assigns_id_and_is_retrievable(self):
        client = MockSharePointClient(self.data_dir)
        created = client.create_item("1_Allgemeiner_Stammblock", {"case_id": "2026-0001", "last_name_or_company": "Acme"})
        self.assertIn("Id", created)
        fetched = client.get_item("1_Allgemeiner_Stammblock", "case_id", "2026-0001")
        self.assertEqual(fetched["last_name_or_company"], "Acme")

    def test_update_item(self):
        client = MockSharePointClient(self.data_dir)
        client.update_item("0_Fallsteuerung", "1", {"processing_note": "Hinweis"})
        item = client.get_item("0_Fallsteuerung", "case_id", "2026-0001")
        self.assertEqual(item["processing_note"], "Hinweis")

    def test_update_missing_item_raises(self):
        client = MockSharePointClient(self.data_dir)
        with self.assertRaises(SharePointError):
            client.update_item("0_Fallsteuerung", "nicht-vorhanden", {"x": 1})

    def test_persist_writes_only_dirty_lists(self):
        client = MockSharePointClient(self.data_dir)
        client.create_item("8_Unterlagen", {"case_id": "2026-0001", "document_type": "Sonstiges"})
        client.persist()
        self.assertTrue((self.data_dir / "8_Unterlagen.json").exists())


if __name__ == "__main__":
    unittest.main()
