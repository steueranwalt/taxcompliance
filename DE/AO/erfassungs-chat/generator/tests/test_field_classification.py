import unittest
from pathlib import Path

from generator.field_classification import (
    Branch,
    CompositeClassificationProvider,
    ConfigClassificationProvider,
    FieldRole,
    MetadataClassificationProvider,
    UnclassifiedFieldError,
    default_provider,
)
from generator.pnp_schema_parser import FieldDef, parse_script_file

CONFIG_PATH = Path(__file__).parent.parent / "classification_config.json"
REAL_SCRIPT = (
    Path(__file__).parent.parent.parent.parent
    / "sharepoint-forms"
    / "New-SteuerlicheErfassungListen.ps1"
)

# Felder, die Nils Obenhaus explizit als Beispiele fuer "rechtliche Wuerdigung
# statt Tatsache" genannt hat. Diese muessen IMMER role=ERGEBNIS sein -
# Regressionsschutz, falls jemand die Konfiguration versehentlich lockert.
EXPLICIT_ERGEBNIS_EXAMPLES = [
    ("1_Allgemeiner_Stammblock", "tax_office"),
    ("6_Steuer_und_Umsatzsteuerprofil", "vat_taxation_method"),
    ("6_Steuer_und_Umsatzsteuerprofil", "small_business_rule"),
    ("5_Betriebsstaetten", "site_type"),
    ("5_Betriebsstaetten", "vat_relevant_site"),
    ("5_Betriebsstaetten", "payroll_tax_site"),
    ("2_Unternehmens_Gruendungsmodul", "is_tax_group_parent"),
    ("2_Unternehmens_Gruendungsmodul", "is_tax_group_subsidiary"),
    ("2_Unternehmens_Gruendungsmodul", "is_vat_group_member"),
]

# Felder, die laut Nils Obenhaus Kontaktdaten sind und im CRM der Kanzlei
# liegen, nicht im Chat.
EXPLICIT_CRM_EXAMPLES = [
    ("1_Allgemeiner_Stammblock", "phone"),
    ("1_Allgemeiner_Stammblock", "callback_email"),
    ("3_Personen_und_Vertretung", "phone"),
]


def _mk_field(**kwargs) -> FieldDef:
    defaults = dict(
        list_name="L", internal_name="f", display_name="F", type="Text"
    )
    defaults.update(kwargs)
    return FieldDef(**defaults)


class TestConfigProvider(unittest.TestCase):
    def setUp(self):
        self.provider = ConfigClassificationProvider.from_file(CONFIG_PATH)

    def test_unknown_field_returns_none(self):
        f = _mk_field(list_name="0_Fallsteuerung", internal_name="irgendwas_unbekanntes")
        self.assertIsNone(self.provider.classify(f))

    def test_known_ergebnis_field(self):
        f = _mk_field(list_name="1_Allgemeiner_Stammblock", internal_name="tax_office")
        result = self.provider.classify(f)
        self.assertEqual(result.role, FieldRole.ERGEBNIS)

    def test_known_tatsache_field_with_branch(self):
        f = _mk_field(list_name="3_Personen_und_Vertretung", internal_name="first_name")
        result = self.provider.classify(f)
        self.assertEqual(result.role, FieldRole.TATSACHE)
        self.assertEqual(result.applies_to, Branch.NATUERLICHE_PERSON)


class TestMetadataProvider(unittest.TestCase):
    def test_no_metadata_attribute_returns_none(self):
        provider = MetadataClassificationProvider()
        f = _mk_field()
        self.assertIsNone(provider.classify(f))

    def test_metadata_attribute_present_is_used(self):
        provider = MetadataClassificationProvider()
        f = _mk_field()
        # FieldDef ist keine frozen dataclass, daher ist die direkte
        # Attributzuweisung hier zulaessig (simuliert das zukuenftige
        # Metadatum aus dem parallelen PR, siehe Moduldoc in
        # field_classification.py).
        f.field_role = "ergebnis"
        f.applies_to = ["gesellschaft"]
        result = provider.classify(f)
        self.assertIsNotNone(result)
        self.assertEqual(result.role, FieldRole.ERGEBNIS)
        self.assertEqual(result.applies_to, Branch.GESELLSCHAFT)
        self.assertEqual(result.source, "metadata")


class TestCompositeFailClosed(unittest.TestCase):
    def test_unclassified_field_raises(self):
        empty_config_provider = ConfigClassificationProvider({})
        composite = CompositeClassificationProvider(
            [MetadataClassificationProvider(), empty_config_provider]
        )
        f = _mk_field()
        with self.assertRaises(UnclassifiedFieldError):
            composite.classify(f)

    def test_metadata_takes_precedence_over_config(self):
        config_provider = ConfigClassificationProvider(
            {"L": {"f": {"role": "tatsache", "applies_to": "alle"}}}
        )
        composite = CompositeClassificationProvider(
            [MetadataClassificationProvider(), config_provider]
        )
        f = _mk_field()
        f.field_role = "ergebnis"
        result = composite.classify(f)
        self.assertEqual(result.role, FieldRole.ERGEBNIS)
        self.assertEqual(result.source, "metadata")


class TestExplicitExamplesFromNils(unittest.TestCase):
    """Regressionsschutz fuer die woertlich genannten Beispiele aus der
    Aufgabenstellung (Finanzamt, Soll-/Ist-Besteuerung, Kleinunternehmer,
    Organschaft, Betriebsstaette ja/nein, Kontaktdaten)."""

    def setUp(self):
        self.provider = default_provider()

    def test_ergebnis_examples(self):
        for list_name, internal_name in EXPLICIT_ERGEBNIS_EXAMPLES:
            with self.subTest(field=f"{list_name}/{internal_name}"):
                f = _mk_field(list_name=list_name, internal_name=internal_name)
                result = self.provider.classify(f)
                self.assertEqual(result.role, FieldRole.ERGEBNIS)

    def test_crm_examples_are_system(self):
        for list_name, internal_name in EXPLICIT_CRM_EXAMPLES:
            with self.subTest(field=f"{list_name}/{internal_name}"):
                f = _mk_field(list_name=list_name, internal_name=internal_name)
                result = self.provider.classify(f)
                self.assertEqual(result.role, FieldRole.SYSTEM)


class TestAllCatalogFieldsOfChatListsAreClassified(unittest.TestCase):
    """Stellt sicher, dass JEDES Feld der vom Chat genutzten Listen
    klassifiziert ist (Fail-Closed-Garantie end-to-end gegen das echte
    Skript, nicht nur gegen die Fixture)."""

    CHAT_LISTS = [
        "1_Allgemeiner_Stammblock",
        "2_Unternehmens_Gruendungsmodul",
        "3_Personen_und_Vertretung",
        "4_Beteiligte_und_Quoten",
        "5_Betriebsstaetten",
        "6_Steuer_und_Umsatzsteuerprofil",
        "8_Unterlagen",
    ]

    def setUp(self):
        if not REAL_SCRIPT.exists():
            self.skipTest(f"Repo-Skript nicht gefunden: {REAL_SCRIPT}")
        self.catalog = parse_script_file(REAL_SCRIPT)
        self.provider = default_provider()

    def test_no_unclassified_field(self):
        for list_name in self.CHAT_LISTS:
            for f in self.catalog.fields_of(list_name):
                with self.subTest(field=f"{list_name}/{f.internal_name}"):
                    try:
                        self.provider.classify(f)
                    except UnclassifiedFieldError as exc:
                        self.fail(str(exc))


if __name__ == "__main__":
    unittest.main()
