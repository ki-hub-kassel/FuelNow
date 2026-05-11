#!/usr/bin/env python3
"""Exit 0 if axe describe-ui JSON (stdin) contains all argv[1:] substrings."""
from __future__ import annotations

import json
import sys


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: axe describe-ui … | python3 assert_ax_contains.py <needle> [needle…]", file=sys.stderr)
        sys.exit(2)
    data = json.load(sys.stdin)
    blob = json.dumps(data, ensure_ascii=False)
    for needle in sys.argv[1:]:
        if needle not in blob:
            sys.stderr.write(f"missing in AX tree: {needle!r}\n")
            sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
