"""End-to-End-Testszenario mit einer fiktiven auslaendischen Gesellschaft
("Nordlicht Trading Ltd.", England und Wales) - ausschliesslich Testdaten,
laeuft komplett ueber Mocks (kein Azure, kein echtes SharePoint), siehe
README "Rahmen"/"Lokal testbar machen".

Deckt den im Auftrag verlangten Ablauf ab: Zugangspruefung -> gefuehrter
Chat (Zweig, ask-once, Komposit-Fragen, 'weiss ich nicht') -> Zusammenfassung
-> Bestaetigung -> strukturiertes Schreiben in die Mock-SharePoint-Listen ->
Session-Loeschung.
"""

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from app.access_control import RateLimiter, verify_case_access
from app.conversation import ConversationEngine
from app.config import Settings
from app.llm_client import MockLLMClient
from app.session_store import SessionStore
from app.sharepoint_client import MockSharePointClient

from ._schema_fixture import build_fresh_schema_catalog

SEED_DIR = Path(__file__).parent.parent / "mocks" / "sharepoint_data"

# Beispiele fuer Felder, die der Chat laut Designprinzip NIE schreiben darf -
# auch nicht indirekt ueber einen generischen Katalog-Mechanismus.
NEVER_WRITTEN_FIELDS = {
    "tax_office",
    "small_business_rule",
    "vat_taxation_method",
    "site_type",
    "vat_relevant_site",
    "payroll_tax_site",
    "is_tax_group_parent",
    "asset_management_only",
    "deviating_management_place",
    "limited_tax_liability",
    "dependency_status",
}


class TestForeignLtdScenario(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        shutil.copytree(SEED_DIR, self.tmp.name, dirs_exist_ok=True)
        self.sharepoint = MockSharePointClient(self.tmp.name)
        self.settings = Settings()
        self.rate_limiter = RateLimiter(self.settings)
        self.sessions = SessionStore(ttl_minutes=45)
        self.schemas = build_fresh_schema_catalog()
        self.engine = ConversationEngine(
            sharepoint=self.sharepoint,
            llm=MockLLMClient(),
            settings=self.settings,
            sessions=self.sessions,
            schema_catalog=self.schemas,
        )

    def tearDown(self):
        self.tmp.cleanup()

    def test_full_scenario(self):
        # 1. Zugangspruefung (Mandantenlink mit case_id + access_code)
        access = verify_case_access(
            case_id="2026-0042",
            access_code="TESTCODE42",
            client_key="203.0.113.5",
            sharepoint=self.sharepoint,
            settings=self.settings,
            rate_limiter=self.rate_limiter,
        )
        session = self.engine.start_session(access.case_id)
        session_id = session.session_id

        # 2. Stammblock - Art des Meldepflichtigen (Zweig-Schluessel) + Stammdaten
        self.engine.submit_free_text_answer(
            session,
            "1_Allgemeiner_Stammblock",
            0,
            json.dumps(
                {
                    "party_type": "Firma",
                    "last_name_or_company": "Nordlicht Trading Ltd.",
                    "id_number": "DE999999999",
                    "address_type": "Ausland",
                    "street": "12 Baker Street",
                    "postal_code_city": "London NW1 6XE",
                    "country": "Vereinigtes Königreich",
                    "tax_id_type": "neu beantragen",
                }
            ),
        )

        # 2a. Rechtsform zweistufig (Vorgabe Nils Obenhaus) - Grundtyp dann
        # auslaendisches Recht mit Wortlaut + Staat.
        decision = self.engine.submit_legal_form(
            session,
            grundtyp="kapitalgesellschaft",
            rechtsordnung="auslaendisch",
            wortlaut="Private Limited Company",
            staat="England und Wales",
            auslaendische_kategorie="kapitalgesellschaftsartig",
        )
        self.assertEqual(decision.action, "weiter")

        # 2b. Taetigkeit offen erfragt, erwaehnt Vermietung -> Folgefrage.
        needs_followup = self.engine.submit_business_activity(
            session, "Handel mit Unterhaltungselektronik, zusaetzlich Vermietung einer Lagerhalle."
        )
        self.assertTrue(needs_followup)
        self.engine.submit_vermoegensverwaltung_anteile(
            session, anteil_umsatz="ca. 15%", anteil_gewinn="ca. 10%"
        )

        # 2c. "weiss ich nicht" fuer eine freiwillige Angabe - wird akzeptiert,
        # blockiert den weiteren Ablauf nicht.
        self.engine.submit_free_text_answer(
            session, "1_Allgemeiner_Stammblock", 0, "Die Postfach-Angabe weiss ich nicht."
        )

        # 3. Gruendungsmodul: Firma/Rechtsform werden NICHT erneut gefragt
        # (ask-once), Wirtschaftsjahr ueber die Kalenderjahr-Frage.
        self.assertEqual(session.fact_cache.get("last_name_or_company"), "Nordlicht Trading Ltd.")
        self.engine.submit_free_text_answer(
            session,
            "2_Unternehmens_Gruendungsmodul",
            0,
            json.dumps(
                {
                    "formation_date": "2019-03-01",
                    "activity_start_date": "2024-01-15",
                    "register_status": "erfolgt",
                    "registry_court": "Companies House Cardiff",
                    "register_number": "12345678",
                }
            ),
        )
        self.engine.submit_wirtschaftsjahr(session, entspricht_kalenderjahr=True)

        # 4. Personen (Liste 3, wiederholbar): ein Geschaeftsfuehrer.
        self.engine.submit_free_text_answer(
            session,
            "3_Personen_und_Vertretung",
            0,
            json.dumps(
                {
                    "role": "Gesetzlicher Vertreter",
                    "person_type": "natürlich",
                    "last_name_or_company": "Doe",
                    "first_name": "Jane",
                    "address": "12 Baker Street, London",
                }
            ),
        )
        self.engine.submit_geschaeftsfuehrer_arbeitsort(
            session, person_name="Jane Doe", arbeitsort="London", andere_orte="ca. 1x/Monat Hamburg"
        )

        # 5. Beteiligte (Liste 4): ein Anteilseigner mit Wohnsitz.
        self.engine.submit_free_text_answer(
            session,
            "4_Beteiligte_und_Quoten",
            0,
            json.dumps(
                {
                    "sequence_number": 1,
                    "participant_type": "natürlich",
                    "last_name_or_company": "Jane Doe",
                    "address": "12 Baker Street, London",
                    "participation_type": "direkt",
                    "role": "Anteilseigner",
                    "nominal_share": 100,
                    "share_percentage": 100,
                    "trust_relationship": False,
                }
            ),
        )

        # 6. Betriebsstaetten (Liste 5): eine deutsche Niederlassung.
        self.engine.submit_free_text_answer(
            session,
            "5_Betriebsstaetten",
            0,
            json.dumps(
                {
                    "site_name": "Lager Hamburg",
                    "country": "Deutschland",
                    "address": "Industriestrasse 5, 20095 Hamburg",
                    "ownership_status": "Miete",
                    "usage_type": "Lagerung",
                }
            ),
        )

        # 7. Steuer-/Umsatzsteuerprofil (Liste 6): nur Tatsachen.
        self.engine.submit_free_text_answer(
            session,
            "6_Steuer_und_Umsatzsteuerprofil",
            0,
            json.dumps(
                {
                    "estimated_revenue_opening_year": 250000,
                    "estimated_revenue_following_year": 400000,
                    "employees_total": 3,
                }
            ),
        )

        # 8. Unterlagen: Upload der Gruendungsurkunde (Mock).
        upload_result = self.engine.handle_upload(
            session,
            filename="certificate_of_incorporation.pdf",
            content_type="application/pdf",
            data=b"%PDF-1.4 Testdokument",
            document_type="Handelsregisterauszug",
            note="Certificate of Incorporation, Companies House.",
        )
        self.assertTrue(upload_result.file_link.startswith("mock://"))

        # 9. Zusammenfassung ansehen, bestaetigen, abschliessen.
        summary = self.engine.build_summary(session)
        self.assertEqual(summary["case_id"], "2026-0042")
        self.assertIn("1_Allgemeiner_Stammblock", summary["sections"])

        self.engine.confirm(session)
        outcome = self.engine.submit(session)

        # -- Assertions ------------------------------------------------

        self.assertIn("1_Allgemeiner_Stammblock", outcome.written_lists)
        self.assertIn("3_Personen_und_Vertretung", outcome.written_lists)
        self.assertIn("4_Beteiligte_und_Quoten", outcome.written_lists)
        self.assertIn("5_Betriebsstaetten", outcome.written_lists)
        self.assertIn("8_Unterlagen", outcome.written_lists)

        written = self.sharepoint.snapshot()

        stamm = written["1_Allgemeiner_Stammblock"][0]
        self.assertEqual(stamm["last_name_or_company"], "Nordlicht Trading Ltd.")
        self.assertEqual(stamm["legal_form"], "Private Limited Company (England und Wales)")
        self.assertIn("Jane Doe", stamm["management_address"])
        self.assertIn("ca. 15%", stamm["business_activity"])

        # Keine Rechtsfolgen-/Ergebnisfelder jemals in Chat-geschriebenen
        # Daten. 0_Fallsteuerung ist ausgenommen: dort steht `tax_office` seit
        # der Fallanlage durch die Kanzlei selbst (Seed-Daten), nicht vom Chat.
        for list_name, items in written.items():
            if list_name == "0_Fallsteuerung":
                continue
            for item in items:
                leaked = NEVER_WRITTEN_FIELDS & set(item.keys())
                self.assertEqual(leaked, set(), f"Ergebnisfeld(er) {leaked} in {list_name} geschrieben!")

        # Interner Chat-Hinweis landet in 0_Fallsteuerung.processing_note,
        # klar als Vorschlag markiert - NIE als Mandantenangabe in einer
        # Fachliste.
        case_record = self.sharepoint.get_item("0_Fallsteuerung", "case_id", "2026-0042")
        # In diesem Szenario wurde kein Kanzleientscheid-Hinweis ausgeloest
        # (normale Kapitalgesellschaft) - processing_note bleibt wie beim Seed.
        self.assertEqual(case_record.get("processing_note", ""), "")

        # Session wird nach erfolgreichem Abschluss geloescht (Datenschutz).
        self.assertIsNone(self.sessions.get(session_id))

    def test_verein_scenario_is_rejected_before_any_data_is_written(self):
        access = verify_case_access(
            case_id="2026-0042",
            access_code="TESTCODE42",
            client_key="203.0.113.6",
            sharepoint=self.sharepoint,
            settings=self.settings,
            rate_limiter=self.rate_limiter,
        )
        session = self.engine.start_session(access.case_id)
        decision = self.engine.submit_legal_form(session, grundtyp="verein_stiftung_jpoer", rechtsordnung="deutsch")
        self.assertEqual(decision.action, "ablehnen")
        self.assertEqual(self.sharepoint.snapshot().get("1_Allgemeiner_Stammblock", []), [])

    def test_missing_required_fact_defers_section_to_eingang_fehler(self):
        """Eine amtlich unbedingte Tatsache (hier: business_activity) bleibt
        offen (nie gefragt, nicht als 'weiss ich nicht' markiert) -> der
        Abschnitt wird NICHT in die Fachliste geschrieben, sondern vollstaendig
        in Eingang_Fehler protokolliert, statt unvollstaendig durchzurutschen."""
        access = verify_case_access(
            case_id="2026-0042",
            access_code="TESTCODE42",
            client_key="203.0.113.7",
            sharepoint=self.sharepoint,
            settings=self.settings,
            rate_limiter=self.rate_limiter,
        )
        session = self.engine.start_session(access.case_id)
        self.engine.submit_free_text_answer(
            session,
            "1_Allgemeiner_Stammblock",
            0,
            json.dumps({"party_type": "Firma", "last_name_or_company": "Luecke GmbH (Test)"}),
        )
        self.engine.confirm(session)
        outcome = self.engine.submit(session)

        self.assertIn("1_Allgemeiner_Stammblock", outcome.deferred_sections)
        self.assertGreaterEqual(outcome.eingang_fehler_count, 1)
        written = self.sharepoint.snapshot()
        self.assertEqual(written.get("1_Allgemeiner_Stammblock", []), [])
        fehler = written["Eingang_Fehler"]
        self.assertTrue(any("business_activity" in f["reason"] for f in fehler))


if __name__ == "__main__":
    unittest.main()
