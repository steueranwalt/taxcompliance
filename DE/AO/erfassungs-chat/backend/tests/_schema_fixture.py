"""Test-Hilfsfunktion: baut die Chat-Schemas frisch aus dem aktuellen
PnP-Skript + der aktuellen `classification_config.json`, statt sich auf
committete `generator/output/`-Artefakte zu verlassen (die koennten
veralten). Importiert `generator` als Geschwisterpaket von `backend/` - nur
in Tests, NICHT im Laufzeitcode (siehe
`app/field_classification_bridge.py` fuer die Begruendung der Entkopplung).
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

_ERFASSUNGSCHAT_ROOT = Path(__file__).resolve().parents[2]
if str(_ERFASSUNGSCHAT_ROOT) not in sys.path:
    sys.path.insert(0, str(_ERFASSUNGSCHAT_ROOT))

from generator.cli import DEFAULT_SCRIPT_PATH, build_all  # noqa: E402

from app.schema_catalog import SchemaCatalog  # noqa: E402

_tmp_dir_handle = None


def build_fresh_schema_catalog() -> SchemaCatalog:
    global _tmp_dir_handle
    if _tmp_dir_handle is None:
        _tmp_dir_handle = tempfile.TemporaryDirectory(prefix="erfassungschat-schemas-")
        build_all(DEFAULT_SCRIPT_PATH, Path(_tmp_dir_handle.name))
    return SchemaCatalog(_tmp_dir_handle.name)
