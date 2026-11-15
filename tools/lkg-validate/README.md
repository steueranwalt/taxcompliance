# lkg-validate

Lokaler Validator für `schema/lkg/graph.schema.json`. Keine Netzfreigabe, keine SharePoint-Schreibzugriffe.

```bash
npm install
npm test
node src/cli.js ../../data/lkg/examples/valid-ao-171.json
```

Exit 0 = Schema und Semantik gültig. Exit 1 = Fehler. Technisch gültig ist keine juristische Freigabe.
