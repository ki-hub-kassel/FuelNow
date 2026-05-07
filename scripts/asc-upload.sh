#!/usr/bin/env bash
# TAN-95 — App Store Connect Upload via `asc` CLI (asccli.sh).
#
# Reproduzierbarer Pfad fuer Release-Builds:
#   1. `asc builds next-build-number`  → kollisionsfreie CFBundleVersion
#   2. `asc xcode version edit`        → Build-Number lokal setzen
#   3. `asc xcode archive`             → Release-Archive
#   4. `asc xcode export`              → IPA mit App-Store-Signing
#   5. `asc builds upload --wait`      → Upload + Processing-Polling
#
# Voraussetzungen (siehe docs/AppStoreConnectUpload.md):
#   - `asc` installiert (`brew install asc`)
#   - `asc auth login` ausgefuehrt (Keychain) ODER ASC_KEY_ID/ISSUER_ID/PRIVATE_KEY env
#   - Xcode-Account mit Apple-Team `FNXU97S3QK` eingeloggt (Settings → Accounts) fuer
#     Automatic Signing waehrend `xcodebuild archive`.
#
# Optionale ENV:
#   APP_ID         (Default: 6766354442)
#   APP_VERSION    (Default: aktueller Wert in Xcode-Projekt)
#   BUILD_NUMBER   (Default: `asc builds next-build-number` Resultat)
#   SCHEME         (Default: FuelNow)
#   CONFIGURATION  (Default: Release)
#   SKIP_UPLOAD=1  → Archive + Export, kein Upload (lokales IPA stehen lassen)
#   SKIP_PROCESS_WAIT=1 → Upload ohne `--wait` auf Processing
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_ID="${APP_ID:-6766354442}"
SCHEME="${SCHEME:-FuelNow}"
CONFIGURATION="${CONFIGURATION:-Release}"
PROJECT="${PROJECT:-FuelNow.xcodeproj}"
EXPORT_OPTIONS="${EXPORT_OPTIONS:-scripts/asc/ExportOptions.appstore.plist}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-.asc/artifacts}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ARTIFACTS_DIR/FuelNow.xcarchive}"
IPA_PATH="${IPA_PATH:-$ARTIFACTS_DIR/FuelNow.ipa}"

mkdir -p "$ARTIFACTS_DIR"
rm -rf "$ARCHIVE_PATH" "$IPA_PATH"

# Revert the auto-bumped CFBundleVersion in project.pbxproj on exit so the
# working tree stays clean. The build itself ist longst archiviert/uploaded;
# der Wert im pbxproj ist nur kurzzeitig relevant.
PBXPROJ_PATH="$PROJECT/project.pbxproj"
restore_project_version() {
	if [[ -f "$PBXPROJ_PATH" ]] && git ls-files --error-unmatch "$PBXPROJ_PATH" >/dev/null 2>&1; then
		git checkout -- "$PBXPROJ_PATH" 2>/dev/null || true
	fi
}
trap restore_project_version EXIT

echo "[asc-upload] Resolving next build number for app $APP_ID …"
if [[ -z "${BUILD_NUMBER:-}" ]]; then
	BUILD_NUMBER=$(asc builds next-build-number --app "$APP_ID" --platform IOS --output json \
		| python3 -c 'import sys, json; print(json.load(sys.stdin)["nextBuildNumber"])')
fi
echo "[asc-upload] Using BUILD_NUMBER=$BUILD_NUMBER"

VERSION_ARGS=()
if [[ -n "${APP_VERSION:-}" ]]; then
	VERSION_ARGS+=(--version "$APP_VERSION")
fi

asc xcode version edit \
	--project "$PROJECT" \
	--build-number "$BUILD_NUMBER" \
	${VERSION_ARGS[@]+"${VERSION_ARGS[@]}"} \
	--output json >/dev/null

echo "[asc-upload] Archive ($SCHEME / $CONFIGURATION) → $ARCHIVE_PATH"
asc xcode archive \
	--project "$PROJECT" \
	--scheme "$SCHEME" \
	--configuration "$CONFIGURATION" \
	--clean \
	--archive-path "$ARCHIVE_PATH" \
	--xcodebuild-flag=-destination \
	--xcodebuild-flag=generic/platform=iOS \
	--xcodebuild-flag=-allowProvisioningUpdates \
	--output json >/dev/null

echo "[asc-upload] Export IPA → $IPA_PATH"
asc xcode export \
	--archive-path "$ARCHIVE_PATH" \
	--export-options "$EXPORT_OPTIONS" \
	--ipa-path "$IPA_PATH" \
	--xcodebuild-flag=-allowProvisioningUpdates \
	--output json >/dev/null

if [[ "${SKIP_UPLOAD:-0}" == "1" ]]; then
	echo "[asc-upload] SKIP_UPLOAD=1 — IPA bleibt unter $IPA_PATH liegen, kein Upload."
	exit 0
fi

WAIT_FLAG=(--wait)
if [[ "${SKIP_PROCESS_WAIT:-0}" == "1" ]]; then
	WAIT_FLAG=()
fi

echo "[asc-upload] Upload IPA ($IPA_PATH) → App Store Connect ($APP_ID)"
asc builds upload \
	--app "$APP_ID" \
	--ipa "$IPA_PATH" \
	"${WAIT_FLAG[@]}" \
	--output json
