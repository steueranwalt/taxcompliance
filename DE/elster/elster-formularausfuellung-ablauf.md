# ELSTER-Formularausfüllung: Betriebsablauf (Kanzlei-Bot)

**Stand:** 2026-09-28  
**Zweck:** Damit ein Agent aus dem Repo heraus Formulare vorschlagen, Daten abfragen, in ELSTER eintragen, absenden und das Übermittlungsprotokoll ablegen kann.  
**Quellen:** Ordner `01 Projekte/ELSTER-Entwickler` (Transport/Kataloge), `DE/AO/*` (Erfassungs-Feldkataloge), Zertifikatsregeln HH/ZH.

## Harte Regeln

1. **Keine fiktiven Formulardaten.** Nur vom Nutzer/Mandat gelieferte Werte.
2. **Absenden nur mit ausdrücklicher Freigabe** des Nutzers in dem jeweiligen Fall.
3. **Zertifikat:** Mandatsnummer beginnend mit `1` → Kanzlei HH (`obenhaus_hh_…`); beginnend mit `2` → Kanzlei ZH (`obhs_zh_…`). Login-Profil: `Mandatsnummer-Projektnummer`.
4. **Passwörter** nur über Secrets (`ELSTER_PFX_HH_PASSWORD` / `ELSTER_PFX_ZH_PASSWORD`), niemals im Chat oder Repo.
5. Nach Absendung: **Übermittlungsprotokoll-PDF** herunterladen und in den Postausgang der jeweiligen Kanzlei (HH/ZH) mit Metatags ablegen.
6. Bei Fehler: sofort stoppen und dem Nutzer melden (Screenshot/URL/Fehlermeldung), nichts erzwingen.

## Ablauf (immer diese Reihenfolge)

```
1. Auftrag klären (was soll gemacht werden?)
2. Verfügbare Formulare vorschlagen (siehe erfassungsformulare.json)
3. Formular wählen lassen
4. Mandatsnummer + Projektnummer erfragen (bestimmt HH/ZH + Profil)
5. Pflichtfelder aus Repo lesen und nacheinander abfragen
6. Optionale Felder anbieten (nicht erfinden)
7. Datensatz vollständig melden → Bestätigung
8. ELSTER-Anmeldung mit passendem Zertifikat/Profil
9. Formular öffnen und alle bestätigten Daten eintragen
10. Freigabe zum Absenden einholen
11. Absenden
12. Übermittlungsprotokoll herunterladen und ablegen
```

## Woher kommen die Formularlisten und Felder?

| Bedarf | Repo-Pfad |
|---|---|
| Vorschlagsliste Erfassung/BZSt2/LStB/Einspruch | [`DE/elster/erfassungsformulare.json`](erfassungsformulare.json) |
| Vollständige Kz-Feldkataloge Erfassung + BZSt2 | [`DE/AO/formulardaten-roherfassung.md`](../AO/formulardaten-roherfassung.md) |
| Pflichtlogik je Rechtsform | [`DE/AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md`](../AO/Einheitliches-Datenmodell-steuerliche-Erfassung-DE-Auslandsbezug.md) |
| Maschinenlesbare Verfahren/Datenarten (Header-XSD) | [`DE/elster/katalog-verfahren-datenarten.json`](katalog-verfahren-datenarten.json) |
| Transport/Auth/Datenabholung/OTTER/RABE/Lohn | [`DE/elster/README.md`](README.md) und Einzelseiten |
| DIVA / Fehlerliste / FA-Daten / Prüfziffern | [`DE/elster/kataloge/`](kataloge/) |

## Abgrenzung ELSTER-Entwickler vs. ERiC

Der Ordner **ELSTER-Entwickler** liefert die **Infrastruktur** (ElsterXML, Datenabholung, Kataloge, LStB-offen). Die **Fragebögen steuerliche Erfassung** und die übrigen Steuererklärungen liegen **nicht** als XSD in diesem Ordner (ERiC-Gap, dokumentiert in [`README.md`](README.md) Abschnitt 3). Für die Portal-UI-Ausfüllung reichen die Repo-Feldkataloge in `DE/AO/`; technische ERiC-Feldpfade fehlen weiterhin und dürfen nicht erfunden werden.

## Zertifikat / Profil

| Mandatsnummer | Zertifikat | Profilname |
|---|---|---|
| beginnt mit `1` | HH PFX | `{Mandatsnummer}-{Projektnummer}` |
| beginnt mit `2` | ZH PFX | `{Mandatsnummer}-{Projektnummer}` |

## Postausgang nach Absendung

1. Übermittlungsprotokoll-PDF aus ELSTER speichern.
2. Ablegen in den Postausgang der gewählten Kanzlei (HH bzw. ZH).
3. Metatags setzen (mindestens: Mandat, Projekt, Formular-ID, Datum, Transfer-Ticket falls sichtbar).

## Was absichtlich nicht automatisiert wird ohne Freigabe

- Jeder `send-Auth` / Portal-Absende-Klick
- Änderung von Zertifikatsdateien oder Secrets
- Inventarisierung von Testzertifikat-Inhalten
