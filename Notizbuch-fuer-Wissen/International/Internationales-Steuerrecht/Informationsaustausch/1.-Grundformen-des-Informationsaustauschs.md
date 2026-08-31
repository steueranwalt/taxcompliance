# 1. Grundformen des Informationsaustauschs

1\. Grundformen des Informationsaustauschs

Form | Typische Rechtsgrundlage | Kurzbeschreibung der gelieferten Datensatze  
---|---|---  
Automatisch (AEOI) | OECD‑CRS / EU‑DAC 2, FATCA (Model 1/2), DAC 1, 3‑8 | Periodische Massen­ubermittlung standardisierter XML‑Dateien  
Spontan | Art. 9 DAC / Art. 26 §3 OECD‑MAA | Ungefragte Übermittlung, wenn dem abgebenden Staat steuerrelevante Hinweise auffallen  
Auf Anfrage (EOIR) | Art. 26 OECD‑Musterabkommen, TIEA, MAAC | Fallbezogene Übermittlung aller „voraussichtlich relevanten“ Informationen  
  


2\. Dateninhalte im Einzelnen

2.1 Finanzkonten – CRS / DAC 2

  * Identifikationsdaten des Kontoinhabers bzw. der wirtschaftlich Berechtigten (Name, Anschrift, Steuer‑ID, Geburtsdatum)
  * Konto‑/Depotnummer
  * Meldendes Finanzinstitut (Name + Ident‑Nr.)
  * Kontosaldo per 31. 12.
  * Fur Custody‑Konten: Brutto‑Zinsen, ‑Dividenden, ‑sonstige Einkunfte sowie Brutto­erlose aus Veraußerungen￼Fur deutsche Zwecke entspricht das Custody‑Konto inhaltlich dem klassischen Wertpapierdepot nach § 1 Abs. 1a Nr. 5 KWG, inklusive etwaiger Unterdepots fur Investmentfonds oder andere Finanzinstrumente.
  * Fur Depository‑Konten: Brutto‑Zinsen
  * Fur sonstige Konten: Summe aller Auszahlungen an den Inhaber 



2.2 Finanzkonten mit US‑Bezug – FATCA (Model 1 IGA)

  * Name, Anschrift, US‑TIN des „Specified U.S. Person“ bzw. der beherrschten Nicht‑US‑Entitat
  * Konto‑/Depotnummer
  * Meldendes Institut
  * Kontostand bzw. Ruckkaufswert
  * Zinsen, Dividenden, sonstige Einkunfte, Brutto­erlose aus Verkaufen
  * Gesamtzahlungen bei anderen Kontotypen citeturn22view0



2.3 Einkunfts‑/Vermogenskategorien – DAC 1 (seit 2015, erweitert 2024/2025)

  * Arbeitslohn
  * Pensionen
  * Director’s fees
  * Lebens­versicherungs­produkte
  * Eigentum an/Ertrage aus Immobilien
  * Lizenzgebuhren (erstmals Meldung 2025 fur VZ 2024)
  * Nicht‑verwahrte Dividenden (erstmals Meldung 2026 fur VZ 2025) citeturn2view0



2.4 Steuervorbescheide – DAC 3

  * Identitat des Begunstigten (Name, Sitz, Konzern)
  * Kurzdarstellung des Rulings/APA (Geschaftsvorgange, betroffene Steuerarten)
  * Datum der Erteilung, Geltungsdauer, betroffene Steuerjahre, Finanzvolumen citeturn23search0



2.5 Country‑by‑Country Report – DAC 4 / BEPS Action 13

  * Fur jedes Steuer­hoheitsgebiet: Umsatze (verbunden/unverbunden), Gewinn/Verlust vor Steuern, gezahlte und angefallene Ertragsteuern, Stammkapital, einbehaltene Gewinne, Mitarbeiterzahl, materielle Vermogenswerte citeturn12view0



2.6 Meldepflichtige Gestaltungen – DAC 6

  * Kennnummer des Arrangements
  * Namen/Steuernummern aller Intermediare und betroffenen Steuerpflichtigen
  * Kurzbeschreibung (Hallmarks, wirtschaftlicher Zweck)
  * Datum der ersten Umsetzung, betroffene Rechtsvorschriften, geschatztes Steuervorteils­volumen citeturn11view0



2.7 Plattform­einkunfte – DAC 7

  * Betreiber­daten (Name, Adresse, Ident‑Nr.)
  * Verkaufer­daten inkl. TIN und USt‑ID
  * Jeder relevanten Tatigkeit zugeordnete Brutto‑Erlose, Gebuhren, Anzahl der Transaktionen
  * Standort vermieteter Immobilien (bei property‑rentals) citeturn3view0



2.8 Krypto‑Assets – DAC 8 / OECD‑CARF (ab Meldung 2027 fur VZ 2026)

  * Meldender Crypto‑Asset Service Provider (Name, Sitz, TIN)
  * Nutzer‑ bzw. Controlling‑Person‑Stammdaten
  * Fur jede Transaktion: Token‑Bezeichnung, Stuckzahl, Marktwert netto, Transaktionsart (Tausch, Fiat‑Konversion, Transfer, Retail‑Payment > 50 000 USD etc.) citeturn5view0



2.9 Austausch auf Anfrage (EOIR)

Je nach Ersuchen samtliche „voraussichtlich relevanten“ Unterlagen, z. B.:

  * Bankunterlagen (Kontoinformationen, Transaktions­historie)
  * Buch‑ und Belegwesen (Journale, Rechnungen, Vertrage)
  * Register‑ und Eigentumer­angaben zu Gesellschaften, Trusts u. Ä.
  * Immobilien‑ oder sonstige Vermogens­nachweise citeturn16view0



3\. Technische & organisatorische Eckpunkte

  * Austausch erfolgt i. d. R. uber verschlusselte XML‑Schemata (CRS, FATCA, CbCR, DAC6/7/8).
  * Empfangs­behorden laden die Dateien in nationale Risikomanagement‑Systeme und gleichen sie automatisiert mit inlandischen Steuer­daten ab.
  * Verwendung ist durch Vertraulichkeits‑ und Zwecke‑Bindungs­klauseln begrenzt (Art. 26 OECD‑MAA, Art. 22 DAC).
  

  


4\. Zeitliche Meldezyklen (Beispiele)

Instrument | Meldefrist Finanzinstitution / Unternehmen | Weiterleitung an auslandische Behorde  
---|---|---  
CRS/FATCA | 30 June / 31 May des Folgejahres (national abh.) | ≤ 30. September  
DAC 1 | i. d. R. 30 June | ≤ Ende September  
CbCR (DAC 4) | 12 Monate nach Bilanzstichtag | quartalsweise Upload durch verliehene MCAA‑Kanale  
DAC 6 | 30 Tage nach Bereitstellung/Implementierung | Quartalsweise Übermittlung durch meldenden Staat  
DAC 7 | 31 Januar | Ende Februar  
DAC 8 | 31 Januar (geplant) | Ende Februar  
  
Damit ist ersichtlich, welche Detailinformationen die empfangende Finanz­behorde je nach Austauschmechanismus erhalt und wie sie diese zeitnah nutzen kann, um steuerliche Risiken festzustellen oder Besteuerungsgrundlagen zu verifizieren.

  
Aus <<https://chatgpt.com/c/6800cd75-549c-800d-bce2-657238e1566f>>
