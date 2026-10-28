"""Laedt die vom Generator erzeugten Artefakte (siehe
`../../generator/cli.py`) zur Laufzeit fuer das Backend.

Trennt bewusst "Schema laden" von "Schema generieren" (generator/-Paket) -
das Backend soll den Generator nicht bei jedem Request erneut laufen lassen,
sondern die zuletzt committeten/gebauten JSON-Dateien lesen.
"""

from __future__ import annotations

import json
from pathlib import Path


class SchemaCatalogError(RuntimeError):
    pass


class SchemaCatalog:
    def __init__(self, output_dir: str | Path):
        self._dir = Path(output_dir)
        self._schema_cache: dict[str, dict] = {}
        self._meta_cache: dict[str, list[dict]] = {}

    def schema_envelope(self, schema_name: str) -> dict:
        if schema_name not in self._schema_cache:
            path = self._dir / "schemas" / f"{schema_name}.schema.json"
            if not path.exists():
                raise SchemaCatalogError(
                    f"Schema '{schema_name}' nicht gefunden unter {path}. "
                    "generator/cli.py build ausgefuehrt?"
                )
            self._schema_cache[schema_name] = json.loads(path.read_text(encoding="utf-8"))
        return self._schema_cache[schema_name]

    def field_meta(self, schema_name: str) -> list[dict]:
        if schema_name not in self._meta_cache:
            path = self._dir / "field_meta" / f"{schema_name}.meta.json"
            if not path.exists():
                raise SchemaCatalogError(
                    f"Feld-Metadaten '{schema_name}' nicht gefunden unter {path}."
                )
            data = json.loads(path.read_text(encoding="utf-8"))
            self._meta_cache[schema_name] = data["fields"]
        return self._meta_cache[schema_name]

    def filtered_schema_envelope(self, schema_name: str, *, exclude_fields: set) -> dict:
        """Kopie des Schemas ohne die in `exclude_fields` genannten
        Properties (z. B. bereits per ask-once bekannte Felder oder Felder,
        die ueber eine eigene Komposit-Frage laufen, siehe conversation.py)."""
        envelope = json.loads(json.dumps(self.schema_envelope(schema_name)))
        schema = envelope["json_schema"]["schema"]
        for name in exclude_fields:
            schema["properties"].pop(name, None)
        schema["required"] = [n for n in schema["required"] if n not in exclude_fields]
        return envelope
