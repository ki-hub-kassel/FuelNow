#!/usr/bin/env python3
"""Reads axe describe-ui JSON from stdin; prints AXLabel of the first cluster pill (e.g. \"12 Tankstellen\")."""
from __future__ import annotations

import json
import re
import sys

_CLUSTER_RE = re.compile(r"^(\d+) Tankstellen$")


def _collect(node: object, out: list[str]) -> None:
    if isinstance(node, list):
        for item in node:
            _collect(item, out)
        return
    if not isinstance(node, dict):
        return
    if node.get("type") == "Button" and node.get("role") == "AXButton":
        lab = node.get("AXLabel")
        if isinstance(lab, str) and _CLUSTER_RE.match(lab):
            out.append(lab)
    for v in node.values():
        _collect(v, out)


def main() -> None:
    data = json.load(sys.stdin)
    matches: list[str] = []
    _collect(data, matches)
    if not matches:
        sys.stderr.write("extract_map_cluster_label: no cluster Button matched\n")
        sys.exit(1)
    sys.stdout.write(matches[0])


if __name__ == "__main__":
    main()
