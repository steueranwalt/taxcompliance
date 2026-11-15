import unittest

from app.validation import (
    check_iban_bic_rule,
    check_required_facts_complete,
    check_tax_office_cross_rule,
    evaluate_legal_form_decision,
)


class TestIbanBicRule(unittest.TestCase):
    def test_non_sepa_iban_without_bic_flagged(self):
        finding = check_iban_bic_rule({"bank_iban": "CH9300762011623852957", "bank_bic": ""})
        self.assertIsNotNone(finding)
        self.assertEqual(finding.rule, "E.10.2_bic_bei_nicht_sepa_iban")

    def test_non_sepa_iban_with_bic_ok(self):
        finding = check_iban_bic_rule({"bank_iban": "CH9300762011623852957", "bank_bic": "UBSWCHZH80A"})
        self.assertIsNone(finding)

    def test_sepa_iban_without_bic_ok(self):
        finding = check_iban_bic_rule({"bank_iban": "DE89370400440532013000", "bank_bic": ""})
        self.assertIsNone(finding)

    def test_no_iban_ok(self):
        self.assertIsNone(check_iban_bic_rule({}))


class TestTaxOfficeCrossRule(unittest.TestCase):
    def test_flagged_when_par27_and_already_registered_but_fields_missing(self):
        finding = check_tax_office_cross_rule(
            list0_snapshot={"already_registered": True, "existing_tax_number": "", "tax_office_country": ""},
            list1_answers={"par27_ao_agreement": True},
        )
        self.assertIsNotNone(finding)
        self.assertEqual(finding.rule, "E.10.1_steuernummer_land_bei_par27")

    def test_not_flagged_when_fields_present(self):
        finding = check_tax_office_cross_rule(
            list0_snapshot={
                "already_registered": True,
                "existing_tax_number": "12345",
                "tax_office_country": "Oesterreich",
            },
            list1_answers={"par27_ao_agreement": True},
        )
        self.assertIsNone(finding)

    def test_not_flagged_when_par27_false(self):
        finding = check_tax_office_cross_rule(
            list0_snapshot={"already_registered": True, "existing_tax_number": "", "tax_office_country": ""},
            list1_answers={"par27_ao_agreement": False},
        )
        self.assertIsNone(finding)


class TestRequiredFactsComplete(unittest.TestCase):
    def test_missing_required_field_reported(self):
        field_meta = [
            {"internal_name": "a", "required_unbedingt": True},
            {"internal_name": "b", "required_unbedingt": False},
        ]
        missing = check_required_facts_complete(field_meta=field_meta, answers={}, unsure_fields=set())
        self.assertEqual(missing, ["a"])

    def test_unsure_field_not_reported_as_missing(self):
        field_meta = [{"internal_name": "a", "required_unbedingt": True}]
        missing = check_required_facts_complete(field_meta=field_meta, answers={}, unsure_fields={"a"})
        self.assertEqual(missing, [])

    def test_answered_field_not_reported(self):
        field_meta = [{"internal_name": "a", "required_unbedingt": True}]
        missing = check_required_facts_complete(
            field_meta=field_meta, answers={"a": "Wert"}, unsure_fields=set()
        )
        self.assertEqual(missing, [])


class TestLegalFormDecision(unittest.TestCase):
    def test_verein_stiftung_rejected(self):
        decision = evaluate_legal_form_decision(grundtyp="verein_stiftung_jpoer", rechtsordnung="deutsch")
        self.assertEqual(decision.action, "ablehnen")
        self.assertIsNotNone(decision.kanzlei_hinweis)

    def test_foreign_llc_goes_to_manual_review_not_rejected(self):
        decision = evaluate_legal_form_decision(
            grundtyp="personengesellschaft",
            rechtsordnung="auslaendisch",
            auslaendische_kategorie="personengesellschaftsartig_llp_llc",
        )
        self.assertEqual(decision.action, "manuelle_pruefung")

    def test_foreign_kapitalgesellschaft_continues_normally(self):
        decision = evaluate_legal_form_decision(
            grundtyp="kapitalgesellschaft",
            rechtsordnung="auslaendisch",
            auslaendische_kategorie="kapitalgesellschaftsartig",
        )
        self.assertEqual(decision.action, "weiter")

    def test_domestic_kapitalgesellschaft_continues_normally(self):
        decision = evaluate_legal_form_decision(grundtyp="kapitalgesellschaft", rechtsordnung="deutsch")
        self.assertEqual(decision.action, "weiter")


if __name__ == "__main__":
    unittest.main()
