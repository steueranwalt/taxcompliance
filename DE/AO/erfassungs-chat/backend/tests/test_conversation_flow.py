import shutil
import tempfile
import unittest
from pathlib import Path

from app.conversation import ConversationEngine
from app.config import Settings
from app.llm_client import MockLLMClient
from app.session_store import SessionStore
from app.sharepoint_client import MockSharePointClient

from ._schema_fixture import build_fresh_schema_catalog

SEED_DIR = Path(__file__).parent.parent / "mocks" / "sharepoint_data"


class ConversationTestBase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        shutil.copytree(SEED_DIR, self.tmp.name, dirs_exist_ok=True)
        self.sharepoint = MockSharePointClient(self.tmp.name)
        self.llm = MockLLMClient()
        self.settings = Settings()
        self.sessions = SessionStore(ttl_minutes=45)
        self.schemas = build_fresh_schema_catalog()
        self.engine = ConversationEngine(
            sharepoint=self.sharepoint,
            llm=self.llm,
            settings=self.settings,
            sessions=self.sessions,
            schema_catalog=self.schemas,
        )

    def tearDown(self):
        self.tmp.cleanup()

    def start(self):
        return self.engine.start_session("2026-0042")


class TestAskOnce(ConversationTestBase):
    def test_company_name_asked_once_reused_across_lists(self):
        session = self.start()
        self.engine.submit_free_text_answer(
            session, "1_Allgemeiner_Stammblock", 0, '{"last_name_or_company": "Nordlicht Trading Ltd."}'
        )
        self.assertEqual(session.fact_cache["last_name_or_company"], "Nordlicht Trading Ltd.")

        # Im Stammblock-Schema taucht das Feld danach nicht mehr auf.
        schema = self.engine.generic_schema_for_section(
            "1_Allgemeiner_Stammblock", already_known={"last_name_or_company"}
        )
        self.assertNotIn("last_name_or_company", schema["json_schema"]["schema"]["properties"])

    def test_known_ask_once_fields_configured_for_both_lists(self):
        self.assertIn("company_name", self.engine._ask_once_fields("2_Unternehmens_Gruendungsmodul"))
        self.assertIn("last_name_or_company", self.engine._ask_once_fields("1_Allgemeiner_Stammblock"))


class TestBranchFiltering(ConversationTestBase):
    def test_natural_person_schema_includes_date_of_birth(self):
        session = self.start()
        self.engine.submit_free_text_answer(
            session, "3_Personen_und_Vertretung", 0, '{"person_type": "natürlich"}'
        )
        schema = self.engine.generic_schema_for_section(
            "3_Personen_und_Vertretung",
            branch=self.engine._resolve_branch(
                "3_Personen_und_Vertretung", session.section_data["3_Personen_und_Vertretung"][0]
            ),
        )
        self.assertIn("date_of_birth", schema["json_schema"]["schema"]["properties"])

    def test_company_person_schema_excludes_date_of_birth(self):
        session = self.start()
        self.engine.submit_free_text_answer(
            session, "3_Personen_und_Vertretung", 0, '{"person_type": "nicht natürlich"}'
        )
        schema = self.engine.generic_schema_for_section(
            "3_Personen_und_Vertretung",
            branch=self.engine._resolve_branch(
                "3_Personen_und_Vertretung", session.section_data["3_Personen_und_Vertretung"][0]
            ),
        )
        self.assertNotIn("date_of_birth", schema["json_schema"]["schema"]["properties"])


class TestUnsureHandling(ConversationTestBase):
    def test_weiss_ich_nicht_accepted_and_tracked(self):
        session = self.start()
        result = self.engine.submit_free_text_answer(
            session, "1_Allgemeiner_Stammblock", 0, "Das weiss ich leider nicht."
        )
        self.assertEqual(len(result.unsure_fields), 1)
        self.assertEqual(len(session.unsure_fields), 1)


class TestLegalFormComposite(ConversationTestBase):
    def test_domestic_kapitalgesellschaft_continues(self):
        session = self.start()
        decision = self.engine.submit_legal_form(
            session, grundtyp="kapitalgesellschaft", rechtsordnung="deutsch"
        )
        self.assertEqual(decision.action, "weiter")
        self.assertEqual(session.fact_cache["legal_form"], "Kapitalgesellschaft")

    def test_foreign_legal_form_wortlaut_and_staat_composed(self):
        session = self.start()
        decision = self.engine.submit_legal_form(
            session,
            grundtyp="kapitalgesellschaft",
            rechtsordnung="auslaendisch",
            wortlaut="Private Limited Company",
            staat="England und Wales",
            auslaendische_kategorie="kapitalgesellschaftsartig",
        )
        self.assertEqual(decision.action, "weiter")
        self.assertEqual(session.fact_cache["legal_form"], "Private Limited Company (England und Wales)")

    def test_verein_rejected_and_hint_logged(self):
        session = self.start()
        decision = self.engine.submit_legal_form(session, grundtyp="verein_stiftung_jpoer", rechtsordnung="deutsch")
        self.assertEqual(decision.action, "ablehnen")
        self.assertTrue(len(session.internal_hints) == 1)
        self.assertTrue(session.internal_hints[0].startswith("[Chat-Vorschlag, nicht verifiziert]"))

    def test_foreign_llc_marked_for_manual_review_not_rejected(self):
        session = self.start()
        decision = self.engine.submit_legal_form(
            session,
            grundtyp="personengesellschaft",
            rechtsordnung="auslaendisch",
            wortlaut="Limited Liability Company",
            staat="Delaware, USA",
            auslaendische_kategorie="personengesellschaftsartig_llp_llc",
        )
        self.assertEqual(decision.action, "manuelle_pruefung")
        self.assertEqual(len(session.internal_hints), 1)
        # Wird NICHT abgelehnt - Fall laeuft normal weiter.
        self.assertIn("legal_form", session.fact_cache)


class TestBusinessActivityFollowUp(ConversationTestBase):
    def test_no_followup_for_plain_activity(self):
        session = self.start()
        needs_followup = self.engine.submit_business_activity(session, "Handel mit Elektronikartikeln")
        self.assertFalse(needs_followup)

    def test_followup_triggered_for_vermoegensverwaltung_mention(self):
        session = self.start()
        needs_followup = self.engine.submit_business_activity(
            session, "Vermietung von Gewerbeimmobilien (Vermoegensverwaltung)"
        )
        self.assertTrue(needs_followup)

    def test_followup_answers_appended_to_business_activity(self):
        session = self.start()
        self.engine.submit_business_activity(session, "Verwaltung von Kapitalanlagen")
        self.engine.submit_vermoegensverwaltung_anteile(
            session, anteil_umsatz="ca. 80%", anteil_gewinn="ca. 90%"
        )
        text = session.section_data["1_Allgemeiner_Stammblock"]["business_activity"]
        self.assertIn("80%", text)
        self.assertIn("90%", text)

    def test_asset_management_only_field_never_asked(self):
        # Ergebnisfeld - darf in keinem generierten Schema vorkommen.
        schema = self.engine.generic_schema_for_section("1_Allgemeiner_Stammblock")
        self.assertNotIn("asset_management_only", schema["json_schema"]["schema"]["properties"])


class TestWirtschaftsjahr(ConversationTestBase):
    def test_kalenderjahr_true_sets_no_start_date(self):
        session = self.start()
        self.engine.submit_wirtschaftsjahr(session, entspricht_kalenderjahr=True)
        record = session.section_data["2_Unternehmens_Gruendungsmodul"]
        self.assertFalse(record["deviating_fiscal_year"])
        self.assertIsNone(record["fiscal_year_start"])

    def test_kalenderjahr_false_requires_start_date(self):
        session = self.start()
        self.engine.submit_wirtschaftsjahr(session, entspricht_kalenderjahr=False, beginn="01.07.")
        record = session.section_data["2_Unternehmens_Gruendungsmodul"]
        self.assertTrue(record["deviating_fiscal_year"])
        self.assertEqual(record["fiscal_year_start"], "01.07.")


class TestGeschaeftsfuehrerArbeitsort(ConversationTestBase):
    def test_management_address_never_asked_directly(self):
        schema = self.engine.generic_schema_for_section("1_Allgemeiner_Stammblock")
        self.assertNotIn("management_address", schema["json_schema"]["schema"]["properties"])

    def test_deviating_management_place_excluded_as_ergebnisfeld(self):
        schema = self.engine.generic_schema_for_section("1_Allgemeiner_Stammblock")
        self.assertNotIn("deviating_management_place", schema["json_schema"]["schema"]["properties"])

    def test_composed_from_multiple_geschaeftsfuehrer(self):
        session = self.start()
        self.engine.submit_geschaeftsfuehrer_arbeitsort(
            session, person_name="Jane Doe", arbeitsort="London", andere_orte=None
        )
        self.engine.submit_geschaeftsfuehrer_arbeitsort(
            session, person_name="John Smith", arbeitsort="Hamburg", andere_orte="ca. 1x/Monat London"
        )
        text = session.section_data["1_Allgemeiner_Stammblock"]["management_address"]
        self.assertIn("Jane Doe", text)
        self.assertIn("John Smith", text)
        self.assertIn("Hamburg", text)


class TestExplainAndNoLegalConclusionsInPrompts(ConversationTestBase):
    def test_explain_returns_text_for_known_field(self):
        text = self.engine.explain("wirtschaftsjahr_kalenderjahr")
        self.assertIn("Wirtschaftsjahr", text)

    def test_explain_fallback_for_unknown_field(self):
        text = self.engine.explain("komplett_unbekanntes_feld")
        self.assertIn("keine zusaetzliche Erklaerung", text)


if __name__ == "__main__":
    unittest.main()
