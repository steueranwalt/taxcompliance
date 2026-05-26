# Mapping: SharePoint Wissen → GitHub Repo

Zuordnung der SP-Ordner zu Repo-Pfaden. Grundregel:
- **Binärdokumente** (PDF, DOCX, PPTX): bleiben in SP, kommen **nicht** ins Repo
- **Reintext** (Markdown, JSONL, YAML, TXT): kommen ins Repo
- **Strukturdefinition**: das Repo-Verzeichnis gibt die Soll-Struktur für SP-neu vor

## Zuordnungstabelle

| SP-Ordner (alt) | Repo-Pfad | Anmerkung |
|---|---|---|
| `01 Internationales Steuerrecht/Verrechnungspreise/` | `DE-CH/Verrechnungspreise/` | Übergreifendes Thema → DE-CH |
| `01 Internationales Steuerrecht/Amtshilfe und Rechtshilfe/DAC6/` | `DE-CH/DBA/` | DAC6 betrifft beide Rechtsordnungen |
| `01 Internationales Steuerrecht/Amtshilfe und Rechtshilfe/Amtshilfe CH/` | `CH/Sonstiges/` | CH-Verwaltungsgericht |
| `02 Steuern DE/Betriebsprüfung/` | `DE/AO/` | Betriebsprüfung = AO §§ 193 ff. |
| `02 Steuern DE/Betriebsprüfung/*.jsonl` | `DE/AO/grounds/` | **Reintext → ins Repo** |
| `02 Steuern DE/Betriebsprüfung/*.yaml` | `DE/AO/grounds/` | **Reintext → ins Repo** |
| `02 Steuern DE/Einkommensteuer/` | `DE/EStG/` | |
| `03 Steuern CH/Steuerverfahrensrecht_CH/` | `CH/Sonstiges/` | ZStP-Aufsätze |
| `04 Recht allgemein/Strafrecht_DE/` | `DE/Sonstiges/` | |
| `04 Recht allgemein/Recht_CH_Diverse/` | `CH/Sonstiges/` | |
| `05 eigene Literatur/01 Wassermeyer DBA/01 Schweiz/` | `DE-CH/DBA/` | Kernstück: Wassermeyer DBA DE-CH |
| `05 eigene Literatur/01 Wassermeyer DBA/02 Malta/` | _(kein Pendant im Repo)_ | Malta-DBA → ggf. neuen Ordner anlegen |

## Reintext-Dateien, die ins Repo kommen

| Datei (SP) | Repo-Pfad | Priorität |
|---|---|---|
| `02 Steuern DE/Betriebsprüfung/grounds_bp_master.jsonl` | `DE/AO/grounds/grounds_bp_master.jsonl` | hoch |
| `02 Steuern DE/Betriebsprüfung/grounds_bp_reviewbot.jsonl` | `DE/AO/grounds/grounds_bp_reviewbot.jsonl` | hoch |
| `02 Steuern DE/Betriebsprüfung/grounds_bp_verfahrensbot.jsonl` | `DE/AO/grounds/grounds_bp_verfahrensbot.jsonl` | hoch |
| `02 Steuern DE/Betriebsprüfung/grounds_kassenbot.jsonl` | `DE/AO/grounds/grounds_kassenbot.jsonl` | hoch |
| `02 Steuern DE/Betriebsprüfung/grounds_schaetzungsbot.jsonl` | `DE/AO/grounds/grounds_schaetzungsbot.jsonl` | hoch |
| `02 Steuern DE/Betriebsprüfung/grounds_steuerdatenschutzbot.jsonl` | `DE/AO/grounds/grounds_steuerdatenschutzbot.jsonl` | hoch |
| `02 Steuern DE/Betriebsprüfung/prozessmatrix_bp_master.yaml` | `DE/AO/grounds/prozessmatrix_bp_master.yaml` | hoch |
| `02 Steuern DE/Betriebsprüfung/TP_Copy_Paste_Uebergabebloecke.md` | `DE-CH/Verrechnungspreise/` | mittel |
| `02 Steuern DE/Betriebsprüfung/README.md` | `DE/AO/` | mittel |
