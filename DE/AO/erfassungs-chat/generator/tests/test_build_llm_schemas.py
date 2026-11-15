import json
import unittest
from pathlib import Path

from generator.build_llm_schemas import (
    MAX_NESTING_LEVELS,
    MAX_PROPERTIES,
    SchemaBuildError,
    build_section,
    wrap_for_structured_outputs,
)
from generator.field_classification import Branch, default_provider
from generator.pnp_schema_parser import parse_script_file

REAL_SCRIPT = (
    Path(__file__).parent.parent.parent.parent
    / "sharepoint-forms"
    / "New-SteuerlicheErfassungListen.ps1"
)

CHAT_LISTS = [
    "1_Allgemeiner_Stammblock",
    "2_Unternehmens_Gruendungsmodul",
    "3_Personen_und_Vertretung",
    "4_Beteiligte_und_Quoten",
    "5_Betriebsstaetten",
    "6_Steuer_und_Umsatzsteuerprofil",
    "8_Unterlagen",
]

EXPLICIT_ERGEBNIS_EXAMPLES = {"tax_office", "small_business_rule", "vat_taxation_method"}


class TestBuildSection(unittest.TestCase):
    def setUp(self):
        if not REAL_SCRIPT.exists():
            self.skipTest(f"Repo-Skript nicht gefunden: {REAL_SCRIPT}")
        self.catalog = parse_script_file(REAL_SCRIPT)
        self.classifier = default_provider()

    def test_within_property_and_nesting_limits(self):
        for list_name in CHAT_LISTS:
            section = build_section(
                catalog=self.catalog, list_name=list_name, classifier=self.classifier
            )
            with self.subTest(list_name=list_name):
                self.assertLessEqual(len(section.schema["properties"]), MAX_PROPERTIES)

    def test_every_property_is_required_and_nullable(self):
        section = build_section(
            catalog=self.catalog, list_name="1_Allgemeiner_Stammblock", classifier=self.classifier
        )
        schema = section.schema
        self.assertEqual(set(schema["required"]), set(schema["properties"].keys()))
        for name, prop in schema["properties"].items():
            with self.subTest(field=name):
                self.assertIn("null", prop["type"])

    def test_no_pattern_or_format_keywords(self):
        section = build_section(
            catalog=self.catalog, list_name="2_Unternehmens_Gruendungsmodul", classifier=self.classifier
        )
        serialized = json.dumps(section.schema)
        self.assertNotIn('"pattern"', serialized)
        self.assertNotIn('"format"', serialized)

    def test_additional_properties_false(self):
        section = build_section(
            catalog=self.catalog, list_name="5_Betriebsstaetten", classifier=self.classifier
        )
        self.assertFalse(section.schema["additionalProperties"])

    def test_ergebnis_fields_never_in_any_chat_schema(self):
        """Regressionstest: keine der von Nils Obenhaus genannten
        Wuerdigungsfragen darf jemals im Chat-Schema landen, in keiner der
        Listen."""
        for list_name in CHAT_LISTS:
            section = build_section(
                catalog=self.catalog, list_name=list_name, classifier=self.classifier
            )
            leaked = EXPLICIT_ERGEBNIS_EXAMPLES & set(section.schema["properties"].keys())
            with self.subTest(list_name=list_name):
                self.assertEqual(leaked, set())

    def test_branch_filtering_excludes_other_branch_fields(self):
        gesellschaft = build_section(
            catalog=self.catalog,
            list_name="3_Personen_und_Vertretung",
            classifier=self.classifier,
            branch=Branch.GESELLSCHAFT,
        )
        natuerlich = build_section(
            catalog=self.catalog,
            list_name="3_Personen_und_Vertretung",
            classifier=self.classifier,
            branch=Branch.NATUERLICHE_PERSON,
        )
        # date_of_birth gilt nur fuer natuerliche Personen.
        self.assertNotIn("date_of_birth", gesellschaft.schema["properties"])
        self.assertIn("date_of_birth", natuerlich.schema["properties"])
        # Felder ohne Zweigbindung (z. B. last_name_or_company) sind in beiden.
        self.assertIn("last_name_or_company", gesellschaft.schema["properties"])
        self.assertIn("last_name_or_company", natuerlich.schema["properties"])

    def test_choice_field_enum_includes_null(self):
        section = build_section(
            catalog=self.catalog, list_name="8_Unterlagen", classifier=self.classifier
        )
        prop = section.schema["properties"]["document_type"]
        self.assertIn(None, prop["enum"])

    def test_wrap_for_structured_outputs_envelope(self):
        section = build_section(
            catalog=self.catalog, list_name="8_Unterlagen", classifier=self.classifier
        )
        envelope = wrap_for_structured_outputs(section, schema_name="8_Unterlagen")
        self.assertEqual(envelope["type"], "json_schema")
        self.assertTrue(envelope["json_schema"]["strict"])
        self.assertEqual(envelope["json_schema"]["name"], "8_Unterlagen")

    def test_too_many_properties_raises(self):
        # Synthetischer Katalog mit > MAX_PROPERTIES Tatsachenfeldern, um den
        # Property-Limit-Guard tatsaechlich auszuloesen (im echten Katalog
        # bleibt jede Liste deutlich darunter).
        from generator.field_classification import (
            CompositeClassificationProvider,
            ConfigClassificationProvider,
        )
        from generator.pnp_schema_parser import Catalog, FieldDef, ListDef

        many_fields = [
            FieldDef(list_name="Big", internal_name=f"feld_{i}", display_name=f"Feld {i}", type="Text")
            for i in range(MAX_PROPERTIES + 1)
        ]
        catalog = Catalog(lists=[ListDef(name="Big", fields=many_fields)])
        config = {
            "Big": {f.internal_name: {"role": "tatsache", "applies_to": "alle"} for f in many_fields}
        }
        classifier = CompositeClassificationProvider([ConfigClassificationProvider(config)])
        with self.assertRaises(SchemaBuildError):
            build_section(catalog=catalog, list_name="Big", classifier=classifier)


if __name__ == "__main__":
    unittest.main()
