#!/usr/bin/env bash
# Automatischer Post-Push-Release (main):
# - ermittelt naechste Marketing-Version
# - fuehrt asc Upload inklusive naechster Build-Nummer aus
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "${FUELNOW_SKIP_POST_PUSH_RELEASE:-0}" == "1" ]]; then
  echo "[post-main-release] Skipped via FUELNOW_SKIP_POST_PUSH_RELEASE=1"
  exit 0
fi

if ! command -v asc >/dev/null 2>&1; then
  echo "[post-main-release] asc CLI fehlt. Installiere mit: brew install asc" >&2
  exit 1
fi

current_version="$(
  asc xcode version view --project "FuelNow.xcodeproj" --output json \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])'
)"

next_version="$(
  python3 - "$current_version" <<'PY'
import re
import sys

raw = sys.argv[1].strip()
parts = [p for p in raw.split(".") if p != ""]

if not parts:
    print("1.0.0")
    raise SystemExit(0)

nums = []
for p in parts:
    if not re.fullmatch(r"\d+", p):
        print(raw)
        raise SystemExit(0)
    nums.append(int(p))

if len(nums) == 1:
    nums = [nums[0], 0, 0]
elif len(nums) == 2:
    nums = [nums[0], nums[1], 0]

nums[-1] += 1
print(".".join(str(n) for n in nums))
PY
)"

echo "[post-main-release] Marketing-Version: $current_version -> $next_version"
APP_VERSION="$next_version" ./scripts/asc-upload.sh

