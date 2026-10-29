#!/usr/bin/env bash
# Checks or renews the iOS development signing profile, then installs the app IN PLACE.
#
# A free-account development profile lasts 7 days. Reinstalling or rebuilding does NOT extend it: Xcode
# reuses a still-valid profile. Renewing means removing the cached copy (kept as a backup) so that Xcode,
# with automatic signing, issues a new one during the next build.
#
#   tool/renew_ios_signing.sh --check                 # profile, certificate and phone data; changes nothing
#   tool/renew_ios_signing.sh --renew [DEVICE_ID]     # renew, rebuild, install in place, compare phone data
#
# Never uninstalls the app, never clears its storage, never changes the bundle identifier, never uses
# `flutter install`. Run it from a clean checkout of the commit you want installed.
set -euo pipefail
cd "$(dirname "$0")/.."

PROFILES="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
APP=build/ios/iphoneos/Runner.app
BUNDLE=app.mooncycle.mobile.dev
DEVICE="${2:-${MOONCYCLE_DEVICE:-4738C18C-0B38-513A-987F-738F68B66C77}}"
MODE="${1:---check}"

profile_info() { # prints "expires <iso> created <iso> team <id>" for the newest cached profile
  local f; f=$(ls -t "$PROFILES"/*.mobileprovision 2>/dev/null | head -1 || true)
  [ -n "$f" ] || { echo "no cached profile"; return 1; }
  security cms -D -i "$f" | python3 -W ignore -c "
import plistlib,sys,datetime
p=plistlib.loads(sys.stdin.buffer.read())
e=p['ExpirationDate']; left=(e-datetime.datetime.utcnow()).total_seconds()/86400
print(f\"{p['Name']}: created {p['CreationDate']} UTC, expires {e} UTC ({left:.1f} days left), team {p['TeamIdentifier'][0]}\")"
}
cert_info() {
  security find-identity -v -p codesigning | sed -n 1,2p
}
data_listing() { # names and sizes only (never contents) of the app's data folder on the phone; the system's
  # caches and launch snapshots are left out because iOS rebuilds them on every install
  xcrun devicectl device info files --device "$DEVICE" --domain-type appDataContainer \
    --domain-identifier "$BUNDLE" 2>/dev/null | grep -v '^SystemData/\|^tmp\|^Library/Caches\|^Library/SplashBoard\|^[0-9][0-9]:\|^[[:space:]]*$' || true
}

echo "== signing status"; profile_info || true; cert_info
echo "== app data on the phone (names and sizes only)"; data_listing | awk 'NF>=4 {print $1, $(NF-3), $(NF-2)}' | head -12

[ "$MODE" = "--check" ] && { echo "(check only: nothing changed)"; exit 0; }
[ "$MODE" = "--renew" ] || { echo "usage: $0 --check | --renew [DEVICE_ID]"; exit 2; }

[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "Uncommitted changes: build from a clean checkout so the installed commit is exact."; exit 1; }
before=$(mktemp); data_listing > "$before"
grep -q 'moon_cycle.db' "$before" || { echo "Cannot see moon_cycle.db on the phone; refusing to continue."; exit 1; }

backup="$HOME/.moon-cycle-signing-backup/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$backup"; cp "$PROFILES"/*.mobileprovision "$backup"/
echo "== cached profile backed up to $backup; removing it so Xcode issues a new one"
rm -f "$PROFILES"/*.mobileprovision

tool/build_ios.sh
echo "== new profile embedded in the build:"
security cms -D -i "$APP/embedded.mobileprovision" | grep -A1 -E 'CreationDate|ExpirationDate' | grep date

xcrun devicectl device install app --device "$DEVICE" "$APP" | grep -E 'App installed|bundleID|rror'
after=$(mktemp); data_listing > "$after"
if diff <(awk 'NF>=4 {print $1,$(NF-3),$(NF-2)}' "$before") <(awk 'NF>=4 {print $1,$(NF-3),$(NF-2)}' "$after") >/dev/null; then
  echo "== phone data folder unchanged (same files and sizes), moon_cycle.db present"
else
  echo "!! phone data folder differs; compare $before and $after before doing anything else"; exit 1
fi
echo "== done: $(git rev-parse --short HEAD) installed in place. Renew again before the expiry shown above."
