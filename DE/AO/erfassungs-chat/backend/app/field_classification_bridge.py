"""Eigenstaendige Kopie von `generator.field_classification.Branch`.

Bewusst dupliziert statt importiert: das Backend wird separat deployt (siehe
../../infra/README.md) und soll nicht zur Laufzeit vom `generator/`-Paket
abhaengen, das ausserhalb des Deployment-Pakets liegt. Die drei Werte muessen
exakt mit den Dateinamens-Suffixen uebereinstimmen, die
`generator/cli.py` fuer die Zweig-Varianten erzeugt (`__gesellschaft`,
`__natuerliche_person`) - ein Test in `backend/tests/` prueft diese
Uebereinstimmung gegen das generierte `generator/output/`-Verzeichnis.
"""

from __future__ import annotations

from enum import Enum


class Branch(str, Enum):
    ALLE = "alle"
    NATUERLICHE_PERSON = "natuerliche_person"
    GESELLSCHAFT = "gesellschaft"
