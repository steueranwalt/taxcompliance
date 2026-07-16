# Prompt für separate Sitzung: Termstore read-first harmonisieren

Nutze diesen Prompt in einer neuen Agent-Session:

```
Ziel: Termstore-Gruppe "Wissen" auf transferpricingdocs read-first harmonisieren, ohne bestehende Systematik zu beschädigen.

Anforderungen:
1) Erst vollständigen Snapshot des aktuellen Termstores erstellen (Termsets + Terms inkl. Path).
2) Bestehende Struktur respektieren: keine Länderkürzel (CH/DE) im Termsatz "Rechtsgebiet", keine Einzelnormen (AO/FGO/AStG etc.) als Rechtsgebiet.
3) Länder-/Rechtsraumbezug nur über Termsatz "Rechtsordnung".
4) Nur fehlende Terme additiv ergänzen (Delta-Import), kein Full overwrite.
5) Labels in EN/FR mit echten Übersetzungen pflegen (nicht DE duplizieren).
6) Synonyme in DE/EN/FR nachziehen (separater Schritt, protokolliert).
7) Abschlussbericht mit:
   - Snapshot-Pfad
   - importierten Delta-Zeilen je Termsatz
   - konflikthaften Terms
   - offene fachliche Entscheidungen

Arbeitsverzeichnis:
_migration/termstore
Dateien:
- rechtsgebiet.csv
- rechtsordnung.csv
- schlagworte.csv
- dokumenttyp.csv
- labels-de-en-fr.csv
- synonyms-de-en-fr.csv
- Import-WissenTermstore.ps1
```
