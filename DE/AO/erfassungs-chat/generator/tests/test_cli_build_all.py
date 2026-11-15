import json
import tempfile
import unittest
from pathlib import Path

from generator.cli import CHAT_LISTS, DEFAULT_SCRIPT_PATH, build_all


class TestBuildAll(unittest.TestCase):
    def setUp(self):
        if not DEFAULT_SCRIPT_PATH.exists():
            self.skipTest(f"Repo-Skript nicht gefunden: {DEFAULT_SCRIPT_PATH}")
        self.tmp = tempfile.TemporaryDirectory()
        build_all(DEFAULT_SCRIPT_PATH, Path(self.tmp.name))

    def tearDown(self):
        self.tmp.cleanup()

    def test_all_expected_files_written(self):
        out = Path(self.tmp.name)
        self.assertTrue((out / "catalog.json").exists())
        self.assertTrue((out / "classification_report.json").exists())
        self.assertTrue((out / "required_ergebnis_konflikte.json").exists())
        for list_name in CHAT_LISTS:
            self.assertTrue((out / "schemas" / f"{list_name}.schema.json").exists())
            self.assertTrue((out / "field_meta" / f"{list_name}.meta.json").exists())

    def test_required_ergebnis_konflikte_contains_known_gaps(self):
        """Dokumentiert einen bewussten, in der README festgehaltenen
        Architektur-Punkt: einige Ergebnisfelder sind im PnP-Skript noch
        `-Required`, obwohl der Chat sie nie erhebt. Dieser Report macht das
        sichtbar statt es zu verstecken - siehe README 'Offene Punkte'."""
        data = json.loads((Path(self.tmp.name) / "required_ergebnis_konflikte.json").read_text(encoding="utf-8"))
        self.assertIn("tax_office", data.get("1_Allgemeiner_Stammblock", []))
        self.assertIn("site_type", data.get("5_Betriebsstaetten", []))

    def test_classification_report_lists_excluded_fields_with_reason(self):
        data = json.loads((Path(self.tmp.name) / "classification_report.json").read_text(encoding="utf-8"))
        excluded_names = {
            item["internal_name"]
            for item in data["6_Steuer_und_Umsatzsteuerprofil"]["ausgeschlossen"]
        }
        self.assertIn("small_business_rule", excluded_names)


if __name__ == "__main__":
    unittest.main()
