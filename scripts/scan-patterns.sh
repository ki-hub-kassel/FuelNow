#!/usr/bin/env bash
# SDD Research / Agent-Helfer: grobe Stack-Erkennung im Repo-Wurzelverzeichnis.
# Nutzung: scripts/scan-patterns.sh [projekt-root]
set -euo pipefail

ROOT="$(cd "${1:-.}" && pwd)"
echo "scan-patterns: root=${ROOT}"

if [[ -f "${ROOT}/FuelNow.xcodeproj/project.pbxproj" ]]; then
  echo "stack: xcode_swift"
  echo "project: FuelNow.xcodeproj"
fi

if [[ -d "${ROOT}/FuelNow" ]]; then
  echo "sources: FuelNow/"
fi

if [[ -f "${ROOT}/FuelNow.xcodeproj/project.pbxproj" ]] && grep -q "FuelNowTests" "${ROOT}/FuelNow.xcodeproj/project.pbxproj" 2>/dev/null; then
  echo "tests: FuelNowTests (Xcode)"
fi

if [[ -f "${ROOT}/scripts/build-and-run-simulator.sh" ]]; then
  echo "scripts: ios_simulator_build (build-and-run-simulator.sh)"
fi

if [[ -f "${ROOT}/scripts/run-axe-batch.sh" ]] && command -v axe >/dev/null 2>&1; then
  echo "tooling: axe_cli_available"
elif [[ -f "${ROOT}/scripts/run-axe-batch.sh" ]]; then
  echo "tooling: axe_scripts_present (CLI nicht im PATH)"
fi

echo "scan-patterns: done."
