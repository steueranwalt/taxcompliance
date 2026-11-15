import unittest
from pathlib import Path

from generator.pnp_schema_parser import PnpScriptParseError, parse_script, parse_script_file

FIXTURE = Path(__file__).parent / "fixtures" / "sample_script.ps1"
REAL_SCRIPT = (
    Path(__file__).parent.parent.parent.parent
    / "sharepoint-forms"
    / "New-SteuerlicheErfassungListen.ps1"
)


class TestParseFixture(unittest.TestCase):
    def setUp(self):
        self.catalog = parse_script_file(FIXTURE)

    def test_list_order_preserved(self):
        self.assertEqual(self.catalog.list_names(), ["0_Testliste", "1_Folgeliste"])

    def test_simple_text_field_with_required_and_index(self):
        f = self.catalog.fields_of("0_Testliste")[0]
        self.assertEqual(f.internal_name, "test_id")
        self.assertEqual(f.type, "Text")
        self.assertTrue(f.required)
        self.assertTrue(f.indexed)
        self.assertTrue(f.enforce_unique_values)

    def test_multiline_choices_with_embedded_comment(self):
        f = self.catalog.fields_of("0_Testliste")[1]
        self.assertEqual(f.type, "Choice")
        self.assertEqual(f.choices, ["offen", "erledigt"])
        self.assertTrue(f.required)

    def test_boolean_default_value(self):
        f = self.catalog.fields_of("0_Testliste")[2]
        self.assertEqual(f.type, "Boolean")
        self.assertEqual(f.default_value, "0")
        self.assertFalse(f.required)

    def test_lookup_with_delete_behavior(self):
        f = self.catalog.fields_of("1_Folgeliste")[0]
        self.assertEqual(f.type, "Lookup")
        self.assertEqual(f.lookup_list, "0_Testliste")
        self.assertEqual(f.lookup_field, "test_id")
        self.assertEqual(f.delete_behavior, "Restrict")

    def test_number_with_min_max_decimals(self):
        f = self.catalog.fields_of("1_Folgeliste")[1]
        self.assertEqual(f.type, "Number")
        self.assertEqual(f.min, 0.0)
        self.assertEqual(f.max, 100.0)
        self.assertEqual(f.decimals, 2)

    def test_note_field_without_extra_params(self):
        f = self.catalog.fields_of("1_Folgeliste")[2]
        self.assertEqual(f.type, "Note")
        self.assertFalse(f.required)


class TestParseErrors(unittest.TestCase):
    def test_empty_script_raises(self):
        with self.assertRaises(PnpScriptParseError):
            parse_script("# nur ein Kommentar, keine Anweisungen")

    def test_missing_required_param_raises(self):
        broken = 'Add-Field -List "X" -InternalName "y" -Type Text'
        with self.assertRaises(PnpScriptParseError):
            parse_script(broken)


class TestParseRealRepoScript(unittest.TestCase):
    """Integrationstest gegen das echte Skript im Repository. Prueft bewusst
    nur STRUKTURELLE Eigenschaften (keine harten Feld-/Mengen-Erwartungen,
    die bei einem Merge eines parallelen PRs sofort veralten wuerden)."""

    def setUp(self):
        if not REAL_SCRIPT.exists():
            self.skipTest(f"Repo-Skript nicht gefunden: {REAL_SCRIPT}")
        self.catalog = parse_script_file(REAL_SCRIPT)

    def test_known_lists_present(self):
        names = set(self.catalog.list_names())
        expected = {
            "0_Fallsteuerung",
            "1_Allgemeiner_Stammblock",
            "2_Unternehmens_Gruendungsmodul",
            "3_Personen_und_Vertretung",
            "4_Beteiligte_und_Quoten",
            "5_Betriebsstaetten",
            "6_Steuer_und_Umsatzsteuerprofil",
            "7_Auslandsmitteilung_BZSt2",
            "8_Unterlagen",
            "Technische_Mindestfelder",
            "Eingang_Fehler",
        }
        self.assertTrue(expected.issubset(names), f"Fehlende Listen: {expected - names}")

    def test_every_field_has_internal_name_and_type(self):
        for l in self.catalog.lists:
            for f in l.fields:
                self.assertTrue(f.internal_name, f"Leerer InternalName in {l.name}")
                self.assertTrue(f.type, f"Leerer Type in {l.name}/{f.internal_name}")

    def test_internal_names_respect_32_char_sharepoint_limit(self):
        # Dieselbe Regel, die das PnP-Skript selbst vor jeder Verbindung
        # prueft (Test-InternalFieldNamingRules) - siehe README dort.
        violations = [
            f"{l.name}/{f.internal_name} ({len(f.internal_name)})"
            for l in self.catalog.lists
            for f in l.fields
            if len(f.internal_name) > 32
        ]
        self.assertEqual(violations, [], f"Zu lange interne Feldnamen: {violations}")

    def test_case_id_lookup_present_in_every_fachliste(self):
        internal_lists = {"Eingang_Fehler"}
        for l in self.catalog.lists:
            if l.name == "0_Fallsteuerung" or l.name in internal_lists:
                continue
            names = {f.internal_name for f in l.fields}
            self.assertIn("case_id", names, f"case_id-Lookup fehlt in {l.name}")


if __name__ == "__main__":
    unittest.main()
