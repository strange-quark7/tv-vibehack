#!/usr/bin/env bash
# Put a VisioWorld SW-22AE NF back the way it shipped: re-enable every package in debloat.txt,
# re-enable the Google TV launcher and setup wizard, make the launcher home again, restore the Google TV screensaver.
# The custom launcher stays installed but is no longer home; remove it with
#   tools/tv.py 'pm uninstall com.gathin.tvhome'
#
# Usage (Git Bash on Windows, or any bash):
#   TV_HOST=<tv ip> examples/visioworld-sw-22ae-nf/restore.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE/../.."
STOCK=com.google.android.apps.tv.launcherx/.home.HomeActivity
tools/restore.sh "$HERE/debloat.txt" "$STOCK"
PY=tools/venv/bin/python
[ -x "$PY" ] || PY=tools/venv/Scripts/python.exe
printf '%s\n' \
  "pm enable com.google.android.tungsten.setupwraith" \
  "cmd package set-home-activity --user 0 $STOCK" \
  "settings put secure screensaver_components com.google.android.apps.tv.dreamx/.service.Backdrop" \
  "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME" \
  | "$PY" -I tools/tv.py --batch
echo "Restored. Press Home on the remote."
