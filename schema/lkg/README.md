# Legal Knowledge Graph – maschinenlesbare Schicht

Ergänzt [`../legal-knowledge-graph.md`](../legal-knowledge-graph.md). Ersetzt keine Markdown-Register und nicht `DE/AO/ableitungsregeln.json`.

| Pfad | Inhalt |
|---|---|
| `graph.schema.json` | JSON Schema Draft 2020-12 für alle Objektklassen der Phase 1 |
| `../../data/lkg/examples/` | gültiger §-171-Kern und Negativbeispiele |
| `../../tools/lkg-validate/` | Ajv-Validator und Tests |

## Validieren

```bash
cd tools/lkg-validate
npm install
npm test
node src/cli.js ../../data/lkg/examples/valid-ao-171.json
```

## Status

`LEGAL_APPROVED` setzt nur eine fachliche Stelle. Der Beispieldatensatz bleibt `LEGAL_REVIEW_REQUIRED`. Technisch gültig ist keine Rechtsfreigabe.

`valid_from` der Beispiel-Normversion ist der Prüfstand des Fristenregisters (29.09.2026), nicht der gesetzliche Geltungsbeginn. Das steht in `open_verification`.
