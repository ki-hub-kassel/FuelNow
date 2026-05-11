#!/usr/bin/env python3
"""Reads axe describe-ui JSON from stdin; prints one AXLabel for a FuelNow **map** pin.

Heuristic: Buttons whose AXLabel matches StationVoiceOverCopy.mapPinSummary.
If several match (z. B. Karten-Annotation vs. andere UI), die oberste Annotation
wählen (kleinste Frame-Y-Mitte) — untere Treffer sind oft Tab-Leiste/Überlagerungen.
"""
from __future__ import annotations

import json
import re
import sys

_PIN_RE = re.compile(
    r"^(.+)\. (Geöffnet|Geschlossen)\. .+ für .+\.$",
)


def _center_y(node: dict) -> float:
    fr = node.get("frame")
    if isinstance(fr, dict):
        y = float(fr.get("y", 1e9))
        h = float(fr.get("height", 0))
        return y + h / 2.0
    return 1e9


def _collect(node: object, out: list[dict]) -> None:
    if isinstance(node, list):
        for item in node:
            _collect(item, out)
        return
    if not isinstance(node, dict):
        return
    if node.get("type") == "Button" and node.get("role") == "AXButton":
        lab = node.get("AXLabel")
        if isinstance(lab, str) and _PIN_RE.match(lab):
            out.append(node)
    for v in node.values():
        _collect(v, out)


def main() -> None:
    data = json.load(sys.stdin)
    matches: list[dict] = []
    _collect(data, matches)
    if not matches:
        sys.stderr.write("extract_map_pin_label: no map pin Button matched\n")
        sys.exit(1)
    best = min(matches, key=_center_y)
    lab = best.get("AXLabel")
    if isinstance(lab, str):
        sys.stdout.write(lab)
    else:
        sys.stderr.write("extract_map_pin_label: matched node has no AXLabel\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
