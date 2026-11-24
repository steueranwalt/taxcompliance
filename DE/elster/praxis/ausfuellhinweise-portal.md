# ELSTER-Portal: Ausfüllhinweise aus der Praxis

**Stand:** 2026-11-24
**Zweck:** Portal- und Formularwissen für das Ausfüllen von ESt 1 C (Anlage S), ESt 1 D (Anlage FG bzw. FG-S), Anlage EÜR und USt 2 A (Anlage UN) im Mein-ELSTER-Portal.
**Abgrenzung:** Die festen Betriebsregeln (keine fiktiven Daten, Absenden nur mit ausdrücklicher Freigabe, Zertifikat HH/ZH nach Mandatsnummer, Passwörter nur über Secrets, Übermittlungsprotokoll) stehen in [`../elster-formularausfuellung-ablauf.md`](../elster-formularausfuellung-ablauf.md). Diese Seite ergänzt den Ablauf um Beobachtungen aus der Portal-UI; sie ersetzt ihn nicht.
**Quellen:** Amtliche Vordrucke und ELSTER-Hilfe der betreffenden Veranlagungszeiträume sowie wiederkehrende Prüfergebnisse im Portal. Keine Mandats-, Personen- oder Betragsdaten.

Diese Datei enthält bewusst **keine** Mandantennamen, Steuernummern, Anschriften, IdNr., Kontodaten oder mandatsbezogene Beträge. Beispiele sind klar als solche gekennzeichnet und verwenden erfundene Platzhalter.

---

## 1. Portal-Ablauf

- Anmeldung über die Zertifikatsdatei (Login-Weg `softpse`, Organisationszertifikat). Zertifikatsdateinamen und Passwörter gehören nicht ins Repo und nicht in den Chat; siehe Ablauf-Dokument, Abschnitt Zertifikat/Profil.
- Profilname: `Mandatsnummer-Projektnummer`. Mandatsnummern beginnend mit `1` verwenden das Kanzlei-Zertifikat HH, beginnend mit `2` das Zertifikat ZH.
- Speichern immer über **„Speichern und Formular verlassen“** und anschließend **„Speichern und Verlassen“**. Nicht den Browser-Tab einfach schließen.
- **Nur eine Person bzw. eine Browsersitzung** bearbeitet ein Formular gleichzeitig. Arbeitet der Nutzer parallel manuell im Portal, das betreffende Formular nicht zusätzlich öffnen oder speichern; vorher abstimmen.
- Entwürfe und übermittelte Formulare **anderer Mandanten** niemals öffnen, ändern oder überschreiben.
- Vor dem Anlegen eines neuen Entwurfs prüfen, ob für denselben Veranlagungszeitraum und dasselbe Formular bereits ein Entwurf existiert. Vorhandene Entwürfe nicht stillschweigend überschreiben.
- Übermittlung **nur mit ausdrücklicher Freigabe** in dem jeweiligen Fall. Häufig übermittelt der Nutzer selbst; der Bot legt dann nur den geprüften Entwurf an und speichert. Bereits eingereichte Steuererklärungen werden ohne ausdrückliche Freigabe weder erneut übermittelt noch inhaltlich verändert.
- Nach der Übermittlung verschwindet der Datensatz aus **„Meine Formulare“** und steht unter **„Übermittelte Formulare“**. Dort ist in der Liste typischerweise nur das **Datum** sichtbar, keine Uhrzeit. Inhaltliche Prüfung erfolgt über das Übermittlungsprotokoll.
- Vor dem Speichern stets **„Prüfen“** ausführen. Jeden Hinweis und jeden Fehler **wörtlich** notieren. Manche Meldungen wirken wie Hinweise, sind im Portal aber **Fehler**, die eine Übermittlung blockieren.
- Keine fiktiven Formulardaten und **keine erfundenen Nullwerte**. Ein Betrag `0,00` darf nur stehen, wenn er dem Sachverhalt entspricht (und, bei Pflichtfeldern, ausdrücklich bestätigt ist). Leere optionale Felder bleiben leer.

---

## 2. Zeilennummern gelten nur für den jeweiligen VZ

Pflichtfeld- und Kennzahlen-Zeilen **verschieben sich zwischen den Veranlagungszeiträumen**. Ein Eintragsblatt aus dem Vorjahr darf nicht ungeprüft übernommen werden. Im Zweifel gilt die **Feldbezeichnung** bzw. die Kennzahl, nicht die Zeilennummer.

Beobachtete Verschiebungen (nur zur Illustration; vor dem Eintrag am Vordruck des Jahres prüfen):

| Formular | Beobachtung |
|---|---|
| Anlage S | Der Block „Gewinn laut gesonderter Feststellung“ (Kz 110) lag in einem VZ in anderen Zeilen als im Folgejahr. Ebenso der Block für den selbst ermittelten Gewinn (Kz 100). |
| USt 2 A | Das Freitextfeld „Weitere oder abweichende Angaben“ (Kz 123) und die Zeile „Vorauszahlungssoll“ wanderten von einem Jahr zum nächsten um eine Zeile. |
| ESt 1 C | Bereits zwischen nahe beieinanderliegenden Jahren verschob sich die Zählung in den hinteren Abschnitten um eine Zeile. |

Quellen für die Zählung des jeweiligen Jahres: amtlicher BMF-Vordruck, ELSTER-Hilfe zum Formular (z. B. `help_fein_95_YYYY` für die ESt 1 D des Jahres YYYY) und die Beschriftung im geöffneten Formular. Technische ERiC-Feldpfade werden nicht erfunden.

---

## 3. Freitextfelder

Typische Felder:

- ESt 1 D: **Zeile 44**, „Ergänzende Angaben zur Feststellungserklärung“ (Abschnitt zuvor **aktivieren**, erste Zeile 44). Die Kennzahl im Formular ablesen; in ESt 1 A / ESt 1 C entspricht das inhaltlich **Kz 175**, für die ESt 1 D ist die Kz jeweils am Formular zu prüfen.
- ESt 1 C: ergänzende Angaben **Kz 175**.
- USt 2 A: „Weitere oder abweichende Angaben“, **Kz 123** (nicht mit einer etwaigen Kurzbezeichnung „Kz 23“ verwechseln). Die Zeilennummer ist vz-abhängig.

Regeln für den Text:

- Höchstens **999 Zeichen**. Die Länge **vor dem Einfügen per Skript zählen**, nicht nach Augenmass.
- Keinen Gedankenstrich `–` (U+2013) und keinen Geviertstrich `—` (U+2014) verwenden; stattdessen den Bindestrich `-`.
- Beträge im Freitext sicherheitshalber mit `EUR` statt `€` schreiben.
- Beträge, die im Freitext genannt werden, müssen zu den Zahlen im Formular und in den übrigen Erklärungen desselben Jahres passen. Bei Rundungsabweichungen (etwa zwischen einzeln berechneter und vom Portal ermittelter Umsatzsteuer) die Zahl weglassen oder vorher abstimmen.
- Freitexte in ESt 1 D, ESt 1 C und USt müssen in der rechtlichen Aussage **widerspruchsfrei** bleiben (z. B. vorsorgliche Betriebsstätten-Annahme).
- Reicht das Feld nicht: nicht stillschweigend sinnentstellend kürzen und nicht ungefragt eine „Sonstige Nachricht“ senden. Laut ELSTER-Hilfe kann eine Sonstige Nachricht mit dem Betreff „Ergänzende Angaben zur Steuererklärung“ an das Finanzamt gehen; das ist eine Übermittlung und braucht Freigabe.

Beispiel für die Zählung (Platzhaltertext, nicht verwenden):

```python
text = "Beispieltext ohne Gedankenstrich."
assert "\u2013" not in text and "\u2014" not in text
assert len(text) <= 999
print(len(text))
```

---

## 4. Mitwirkung und Vertretung

- In der Mitwirkung einer befugten Person steht der Name stets **„Obenhaus International Tax GmbH“**.
- Einzelne Namensfelder der ESt 1 C (insbesondere beim Empfangsbevollmächtigten) haben ein beobachtetes **Längenlimit von 25 Zeichen**. Die vollständige Firma hat mehr Zeichen. Wird gekürzt, die verwendete Schreibweise dokumentieren und nicht durch eine erfundene andere Bezeichnung ersetzen.
- Empfangsbevollmächtigter nach § 123 AO: Name bzw. Firmenname sowie Anschrift sind typische Pflichtangaben. Das Portal kann auch bei einer juristischen Person einen **Vornamen** verlangen. Einen Vornamen nicht erfinden; die Lösung mit dem Nutzer abstimmen.
- **Kanzleivorgabe:** In der ESt 1 D das Kästchen „Der Feststellungsbescheid soll an einen Zustellbevollmächtigten gemäß der dem Finanzamt vorliegenden Bekanntgabevollmacht gesandt werden“ **niemals ankreuzen**. Eine etwaige Bekanntgabevollmacht bleibt davon unberührt; der Bescheidadressat wird über die dafür vorgesehenen Anschriftfelder gesetzt.
- Anlage UN: das Kästchen zur Authentifizierung durch den Bevollmächtigten (§ 150 Abs. 3 AO) nur ankreuzen, wenn das dem zugelassenen Vertretungsverhältnis und der bisherigen Abgabepraxis entspricht.

---

## 5. ESt 1 C und Anlage S

Formular: „Einkommensteuererklärung für beschränkt Steuerpflichtige (ESt 1 C)“.

- In der ESt 1 C 2024 gibt es **kein Religionsfeld**; bei beschränkter Steuerpflicht fällt keine Kirchensteuer an.
- Typische Prüffehler des Portals, wörtlich sinngemäss und wiederholt beobachtet:
  - Es fehlt eine **Bankverbindung**, oder es ist nicht vermerkt **„keine SEPA-Bankverbindung“**. Weder IBAN noch das Kästchen „keine SEPA“ eintragen oder ankreuzen, solange der Sachverhalt unklar ist. Offene Pflichtfelder dem Nutzer vorlegen.
  - Es fehlen **Name und Anschrift des Bevollmächtigten bzw. Empfangsbevollmächtigten**; der **Vorname** kann Pflicht sein.
- Kz 824 (§ 50d Abs. 10 EStG) nur ausfüllen, wenn der Tatbestand tatsächlich vorliegt.
- **Muster bei gesonderter Feststellung:** In der Anlage S den Gewinn im Block **„Gewinn laut gesonderter Feststellung“ (Kz 110)** eintragen (Berufsbezeichnung, feststellendes Finanzamt, Betriebs-Steuernummer, Betrag). Den Block für den selbst ermittelten Gewinn (**Kz 100**) leer lassen, sonst droht eine doppelte Erfassung und das Portal verlangt eine Anlage EÜR zur ESt 1 C. Die EÜR gehört in diesem Muster zur Feststellung und wird als eigener Datensatz unter der Betriebs-Steuernummer übermittelt.
- Die Anlage S nimmt den Gewinn **nur in ganzen Euro**. Der aus der EÜR (Euro und Cent) übernommene Betrag wird kaufmännisch nicht aufgerundet, sondern typischerweise **abgerundet**. Feststellung, EÜR und Anlage S müssen konsistent sein. Ändert sich der festgestellte Gewinn, ist die ESt 1 C nachzuziehen, bevor übermittelt wird.
- Enthält die Feststellungserklärung bereits die Erläuterung zur Betriebsstätte bzw. festen Einrichtung, erhält die ESt 1 C **keinen zusätzlichen Betriebsstätten-Hinweis** (Kanzleivorgabe; Kz 175 bleibt in diesem Muster leer, sofern nicht ausdrücklich anders entschieden).
- Eine Anlage V nicht anlegen, solange inländische Vermietungseinkünfte nicht geklärt sind.

Beispiel (erfunden, nur zur Abrundung): EÜR-Gewinn `8.765,44 EUR` wird in Anlage FG/FG-S und Anlage S als `8.765 EUR` angesetzt.

---

## 6. ESt 1 D und Anlage FG / FG-S

Formular: „Erklärung zur gesonderten Feststellung von Grundlagen für die Einkommensbesteuerung“ = Hauptvordruck **ESt 1 D** zuzüglich Anlage FG (bis 2024) bzw. **Anlage FG-S** (ab VZ 2025, Teilseite 1 „Laufende Einkünfte“) und, soweit einschlägig, Anlage EÜR.

- Nicht mit der **ESt 1 B** verwechseln (gesonderte **und einheitliche** Feststellung für Gesellschaften und Gemeinschaften, typischerweise mit Anlage FB).
- Portalpfad (vor Ort bestätigen): Formulare und Leistungen → Alle Formulare → Unternehmen → Feststellungserklärung → „Erklärung zur gesonderten Feststellung (ESt 1 D)“ des betreffenden Jahres.
- Anlage FG-AUS bzw. FG-S-AUS nicht anlegen, wenn nur inländische Einkünfte einer beschränkt steuerpflichtigen Person festgestellt werden. Ausländische Einkünfte gehören dann nicht in diese Feststellung.
- In der ESt 1 D **2024** gibt es **kein Kästchen „berichtigte Erklärung“**. Abweichungen gegenüber einer früher übermittelten Gewinnermittlung (etwa vertauschte Währungsspalten) werden im Freitext erläutert. Ob eine später übermittelte Erklärung einen bereits bestandskräftigen Feststellungsbescheid ändert, ist eine Frage der Korrekturvorschriften der AO und wird nicht durch ein Formular-Kästchen gelöst.
- Die **Anschrift im Block „Angaben zum Betrieb / zur Tätigkeit“** ist die Betriebs- bzw. Tätigkeitsanschrift, nicht die Wohnanschrift. Eine inländische Betriebsanschrift bleibt dort stehen, wenn sie die Anschrift der Tätigkeit ist (ELSTER-Hilfe zum Anschriftfeld der ESt 1 D). Die Wohnanschrift der steuerpflichtigen Person steht in den dafür vorgesehenen Feldern, auch wenn sie im Ausland liegt.
- Laufende Einkünfte aus selbständiger Arbeit stehen im dafür vorgesehenen Block der Anlage FG bzw. FG-S. Die Zeile ist am Formular des Jahres abzulesen (Hilfe nennt für mehrere Einkunftsarten mehrere Zeilenpaare). Betrag: steuerpflichtiger Gewinn der EÜR, in ganzen Euro, konsistent zur Anlage S.

**Reihenfolge:** Zuerst EÜR und Feststellung vollständig anlegen und abstimmen, danach den Gewinn in die ESt 1 C (Anlage S, Kz 110) übernehmen.

---

## 7. Anlage EÜR

Die Einnahmenüberschussrechnung ist in ELSTER ein **eigener Datensatz** („Einnahmenüberschussrechnung (EÜR)“) unter der Betriebs-Steuernummer, nicht bloss eine Unterseite der ESt 1 C.

### 7.1 Entnahmen und Einlagen (Pflicht)

Die Zeilen **Entnahmen** und **Einlagen** i. S. d. § 4 Abs. 4a EStG (in den Vordrucken 2024/2025: Zeile 106 / Kz 122 und Zeile 107 / Kz 123; jährlich prüfen) sind auszufüllen. Das Portal beanstandet leere Felder als Fehler und verweist dabei auf **§ 4 Abs. 4a Satz 6 EStG**.

Nach der amtlichen Anleitung zur Anlage EÜR sind Entnahmen und Einlagen **unabhängig vom Vorliegen von Schuldzinsen** einzutragen. Besteht **kein gesondertes betriebliches Konto**, stellen sämtliche Betriebseinnahmen auch Entnahmen und sämtliche Betriebsausgaben auch Einlagen dar. Andere Rechenwege (etwa Entnahmen in Höhe des Gewinns und Einlagen 0,00) nur verwenden, wenn sie dem Sachverhalt entsprechen und freigegeben sind. Werte nicht erfinden.

### 7.2 Vereinnahmte Umsatzsteuer (Fehler, nicht nur Hinweis)

Wenn umsatzsteuerpflichtige Betriebseinnahmen (ohne solche zum ermäßigten Steuersatz von 0 %) angegeben sind, aber keine vereinnahmte Umsatzsteuer, behandelt das Portal das als **Fehler**, nicht bloss als Hinweis. Wortlaut (Portal, beobachtet):

> Ihre Angaben sind leider nicht korrekt: Es wurden umsatzsteuerpflichtige Betriebseinnahmen (ohne solche zum ermäßigten Steuersatz von 0 %) angegeben, aber keine vereinnahmte Umsatzsteuer. Vereinnahmte Umsatzsteuer sowie Umsatzsteuer auf unentgeltliche Wertabgaben. Dieser Fehler ist entstanden, da Sie im Bereich Umsatzsteuerpflichtige Betriebseinnahmen (ohne solche zum ermäßigten Steuersatz von 0 %) Angaben gemacht haben.

**Lösung:** Ist im Gewinnermittlungszeitraum tatsächlich keine Umsatzsteuer zugeflossen, die vereinnahmte Umsatzsteuer **ausdrücklich mit 0,00** eintragen. Die Einnahmen nicht als umsatzsteuerfrei oder nicht steuerbar umbuchen, nur um den Fehler zu beseitigen, wenn die Umsatzsteuererklärung dieselben Umsätze als steuerpflichtig behandelt.

Grundlage der EÜR ist das **Zufluss-/Abflussprinzip (§ 11 EStG)**. Vereinnahmte Umsatzsteuer, vom Finanzamt erstattete Umsatzsteuer, an das Finanzamt gezahlte Umsatzsteuer und abziehbare Vorsteuer folgen dem Zufluss- bzw. Abflussjahr, unabhängig vom Leistungsjahr. Die Umsatzsteuererklärung folgt der gewählten Ist- oder Soll-Versteuerung; EÜR und USt-Erklärung dürfen deshalb in der Periodenzuordnung auseinanderlaufen, müssen aber im Sachverhalt erklärbar bleiben.

### 7.3 Weitere EÜR-Punkte

- Das Feld zu **umsatzsteuerlichen Kleinunternehmern** nicht ankreuzen, wenn die Kleinunternehmerregelung nicht gilt. Für im Ausland ansässige Unternehmer ist § 19 UStG typischerweise nicht eröffnet; das jeweils geltende Recht prüfen.
- Orientierende Kennzahlen der Vordrucke 2024/2025 (vor dem Eintrag am Formular des Jahres prüfen):

  | Inhalt | Zeile (2024/2025) | Kz |
  |---|---|---|
  | Umsatzsteuerpflichtige Betriebseinnahmen | 15 | 112 |
  | Nicht steuerbare Umsätze / Umsätze, für die der Leistungsempfänger die Steuer schuldet | 16 | 103 |
  | Vereinnahmte Umsatzsteuer sowie Umsatzsteuer auf unentgeltliche Wertabgaben | 17 | 140 |
  | Vom Finanzamt erstattete Umsatzsteuer | 18 | 141 |
  | Summe der Betriebseinnahmen | 23 | 159 |
  | Miete/Pacht für Geschäftsräume | 39 | 150 |
  | Bewirtungsaufwendungen (nicht abziehbarer Teil / abziehbarer Teil) | 63 | 165 / 175 |
  | Gezahlte Vorsteuer | 57 | 185 |
  | An das Finanzamt gezahlte Umsatzsteuer | 58 | 186 |
  | Summe der Betriebsausgaben | 75 | 199 |
  | Summe der Betriebseinnahmen (Übertrag) / abzüglich Summe der Betriebsausgaben | 76 / 77 | — |
  | Steuerpflichtiger Gewinn | 92 / 95 / 97 | 290 / 293 / 219 |
  | Entnahmen / Einlagen | 106 / 107 | 122 / 123 |

- Bewirtungsaufwendungen aus betrieblichem Anlass sind nach **§ 4 Abs. 5 Satz 1 Nr. 2 EStG** nur zu **70 %** abziehbar (abziehbarer Teil Kz 175, nicht abziehbarer Teil Kz 165). Die gesetzlichen Aufzeichnungspflichten (Anlass, Teilnehmer, Beleg) bleiben unberührt. Geschenke sind gesondert nach § 4 Abs. 5 Satz 1 Nr. 1 EStG zu prüfen. Spenden sind keine Betriebsausgaben (§ 12 Nr. 1 EStG).
- Wird die Miete brutto in den Raumkosten (Kz 150) erfasst, darf dieselbe Vorsteuer nicht zusätzlich in Kz 185 abgezogen werden.
- Eine Vorsteuer oder eine an das Finanzamt gezahlte Steuer nicht eintragen, wenn der Zahlungsfluss nicht belegt ist.
- Den Betrieb nicht als beendet kennzeichnen, nur weil das Bestehen einer inländischen Betriebsstätte rechtlich offen ist, sofern die Tätigkeit fortläuft.
- Bei regelmäßig wiederkehrenden Ausgaben die 10-Tage-Regel des § 11 Abs. 2 Satz 2 EStG beachten.

---

## 8. USt 2 A und Anlage UN

- „Im Ausland ansässiger Unternehmer“ (**Kz 125**) = Ja aktiviert die **Anlage UN**.
- Freitext: Kz 123, Zeile jährlich prüfen (siehe Abschnitt 3).
- **Vorauszahlungssoll** nicht mit `0` füllen, wenn Voranmeldungen und Zahlungen nicht belegt sind. Das Feld ist typischerweise kein Pflichtfeld; das Portal rechnet die Abschlusszahlung auch ohne Eintrag. Verlangt die Prüfung gleichwohl einen Wert: nichts erfinden, die Meldung wörtlich notieren und dem Nutzer vorlegen.
- Vorsteuer (Kz 320) nur mit ordnungsgemäßer Rechnung (§ 15 Abs. 1 Satz 1 Nr. 1 Satz 2 UStG).
- Ist- oder Soll-Versteuerung (Kz 133) an der bisherigen Praxis und einer etwaigen Gestattung nach § 20 UStG ausrichten. Bei Besteuerung nach vereinbarten Entgelten entscheidet der **Leistungszeitpunkt**, nicht der Zahlungseingang.
- Die vom Portal aus 19 % der Bemessungsgrundlage errechnete Steuer kann um einzelne Cent von der Summe der in den Rechnungen ausgewiesenen Steuer abweichen (Rundung je Rechnung). Eine Plausibilitätswarnung nicht stillschweigend wegdrücken; den ausgewiesenen Betrag nur ändern, wenn das Portal ihn nicht zulässt, und den Vorgang dokumentieren.
- Die **umsatzsteuerliche Zuständigkeit** für im Ausland ansässige Unternehmer folgt § 21 Abs. 1 Satz 2 AO i. V. m. der Umsatzsteuerzuständigkeitsverordnung und kann vom Finanzamt der Einkommensteuer abweichen. Ländertabelle: [`../../AO/ustzustv-laendertabelle.json`](../../AO/ustzustv-laendertabelle.json). Vor der Übermittlung klären, nicht stillschweigend die ESt-Steuernummer verwenden.
- In der Hauptvariante einer höchst vorsorglichen Erklärung werden inländische Umsätze als eigene steuerpflichtige Umsätze zum Regelsteuersatz (Kz 177) erklärt. Fehlt eine inländische Betriebsstätte, kann der Leistungsempfänger die Steuer nach § 13b Abs. 2 Nr. 1, Abs. 5 und 7 UStG schulden; ein gleichwohl erfolgter Steuerausweis wäre nach § 14c Abs. 1 UStG geschuldet. Die alternative Erfassung über Kz 209 (§ 13b) und gegebenenfalls Kz 318 (§ 14c) ist eine andere rechtliche Linie und darf nicht mit der Hauptvariante vermischt werden. Der Freitext muss die gewählte Linie tragen.
- Nicht steuerbare Auslandsumsätze nicht ohne Belege und ohne Entscheidung in die betreffenden Kennzahlen eintragen.
- Verlangt das Portal ein inländisches Anschriftformat, nicht stillschweigend eine andere Anschrift einsetzen, sondern den Konflikt melden.

---

## 9. Muster: Im Ausland (CH) ansässige, selbständig tätige Person mit Inlandstätigkeit

Dieses Muster ist eine Kanzleipraxis für die Formularwahl, keine abschliessende Rechtsprüfung des Einzelfalls.

- Nach **§ 49 Abs. 1 Nr. 3 EStG** können Einkünfte aus selbständiger Arbeit bereits durch Ausübung oder Verwertung im Inland beschränkt steuerpflichtig sein; eine Betriebsstätte ist nach nationalem Recht nicht in jedem Fall Voraussetzung. Das deutsche Besteuerungsrecht kann gleichwohl nach **Art. 14 Abs. 1 DBA Deutschland-Schweiz** entfallen, wenn im Inland keine feste Einrichtung gewöhnlich zur Verfügung steht.
- Höchst vorsorglich werden die inländischen Einkünfte gleichwohl als solche einer inländischen Betriebsstätte bzw. festen Einrichtung erklärt, mit Vorbehalt der Berichtigung. Die Erläuterung gehört in den Freitext der **Feststellungserklärung** (ESt 1 D, Zeile 44).
- Gesonderte Feststellung nach **§ 180 Abs. 1 Satz 1 Nr. 2 Buchst. b AO**, wenn das für die Feststellung zuständige Finanzamt nicht zugleich für die Steuern vom Einkommen zuständig ist. Tätigkeitsfinanzamt ist nach **§ 18 Abs. 1 Nr. 3 AO** das Finanzamt, von dessen Bezirk aus die Berufstätigkeit vorwiegend ausgeübt wird; massgeblich sind typischerweise die Verhältnisse am Schluss des Gewinnermittlungszeitraums. Entfällt ein inländisches Tätigkeitsfinanzamt, kann die Feststellung entbehrlich sein (dann Gewinnermittlung in der ESt-Veranlagung, Anlage S Kz 100 und EÜR beim Veranlagungsfinanzamt). Die Fortsetzung der bisherigen Feststellungspraxis höchst vorsorglich ist eine Entscheidung im Einzelfall.
- **Formularmuster (Kanzleivorgabe, wie bisher):** ESt 1 D + Anlage FG bzw. FG-S + EÜR beim Tätigkeitsfinanzamt, danach Übernahme des Gewinns in die ESt 1 C, Anlage S Kz 110, **ohne** Betriebsstätten-Hinweis in der ESt 1 C.
- Nicht ESt 1 B verwenden.

### 9.1 Kostenaufteilung Inland / Ausland bei fehlenden Einzelbelegen

- Direkt zuordenbare Kosten (etwa Miete eines inländischen Arbeitsraums) werden **direkt** der inländischen Tätigkeit zugeordnet.
- Kosten, die dem ausländischen Stammhaus zuzuordnen sind (etwa ausländische Miete, dortige Abschreibungen) oder die keine Betriebsausgaben der inländischen Tätigkeit sind, werden **nicht** in die deutsche EÜR übernommen.
- Übrige gemischte Kosten können, wenn Einzelbelege fehlen und so entschieden wird, nach einem **Umsatzschlüssel** (inländische Honorare geteilt durch Gesamthonorare) aufgeteilt werden. Der Schlüssel und seine Grenzen gehören in den Freitext.
- Unverändert richtig bleibt: Fahrten ins Inland wären bei Einzelzuordnung **vollständig** der inländischen Tätigkeit zuzuordnen, Fahrten im Ansässigkeitsstaat **gar nicht**. Dafür wären Einzelbelege nötig. Fehlen sie und wird gleichwohl geschlüsselt, muss die Erläuterung das offenlegen.
- Bewirtung und Repräsentation sind für die deutsche Gewinnermittlung nur zu **70 %** abziehbar (§ 4 Abs. 5 Satz 1 Nr. 2 EStG), soweit es sich um Bewirtung handelt; die Art der Aufwendungen ist vor dem Eintrag zu klären.
- Fremdwährungsbeträge: streng genommen ist nach § 11 EStG der Kurs des Zahlungs- bzw. Zuflusstags massgeblich. Die Umrechnung mit dem **ESTV-Jahresmittelkurs** des betreffenden Jahres ist eine Vereinfachung und sollte nachvollziehbar dokumentiert sein. Originär in Euro entstandene Beträge nicht zusätzlich umrechnen.
- Weist die Schweizer Erklärung denselben Gewinn als solchen einer „deutschen Betriebsstätte“ aus und stellt ihn frei, während die deutsche Erklärung höchst vorsorglich das Fehlen einer festen Einrichtung erläutert, besteht ein Abstimmungsbedarf: eine unkoordinierte Behandlung kann zu Doppelbesteuerung oder zu doppelter Nichtbesteuerung führen.

---

## 10. Datenprüfung vor der Gewinnermittlung

- Mandantenlisten, Arbeitstabellen und Jahresrechnungen **vor** der Übernahme in die EÜR auf **vertauschte Spalten** prüfen, insbesondere wenn nebeneinander EUR- und CHF-Beträge stehen. Überschriften und Werte an den **Originaldateien oder -bildern** prüfen, nicht nur an einem Textextrakt.
- Eine Spalte „EUR“ ist nicht automatisch „Inland“. Ohne zugrunde liegende Rechnungen bleibt offen, ob Euro-Eingänge wirklich inländische Tätigkeit sind.
- In die deutsche EÜR der inländischen Tätigkeit gehören nur die dieser Tätigkeit zuzuordnenden Einnahmen, nicht die Honorare ausländischer Auftraggeber der ausländischen Tätigkeit.
- Annahmen und Schätzungen als solche kennzeichnen. Offene Beträge nicht durch Nullen ersetzen.
- Prüfkette vor der Übermittlung: Quelle (Rechnung/Jahresrechnung) → EÜR (Euro und Cent) → Feststellung (ganze Euro) → Anlage S der ESt 1 C (derselbe ganze-Euro-Betrag). Wird ein Glied geändert, sind die anderen nachzuziehen.

---

## 11. Kurz-Checkliste vor „Prüfen“ und Speichern

1. Richtiges Formular des Jahres, Felder nach Bezeichnung, nicht nach Vorjahres-Zeile.
2. Kein paralleler Bearbeiter im selben Formular; keine fremden Mandantenentwürfe geöffnet.
3. Freitexte: höchstens 999 Zeichen, kein Gedankenstrich, Beträge stimmig, Linien ESt/USt konsistent, Abschnitt aktiviert.
4. Mitwirkung „Obenhaus International Tax GmbH“; Zustellbevollmächtigten-Kästchen in der ESt 1 D nicht gesetzt.
5. EÜR: Entnahmen und Einlagen gesetzt; vereinnahmte Umsatzsteuer gesetzt (gegebenenfalls 0,00); Kleinunternehmer nur wenn einschlägig; Bewirtung 70 %.
6. Feststellung und ESt 1 C: Gewinn identisch (ganze Euro); in der Anlage S Kz 110 oder Kz 100, nicht beide; kein Betriebsstätten-Text in der ESt 1 C, wenn er in der ESt 1 D steht.
7. USt: Kz 125/Anlage UN, Vorauszahlungssoll nicht erfunden, Zuständigkeit nach UStZustV geprüft.
8. „Prüfen“ ausgeführt, Fehler wörtlich notiert, nur gespeichert, nicht gesendet, sofern keine Freigabe vorliegt.
