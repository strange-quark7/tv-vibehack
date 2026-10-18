#!/usr/bin/env bash
# Build the launcher APK and install it on the TV as the default home screen.
#
# Usage: TV_HOST=192.168.1.50 [STOCK_LAUNCHER=<pkg>] launcher/build-and-install.sh
# STOCK_LAUNCHER is disabled after the new home is set; Google TV sets use
# com.google.android.apps.tv.launcherx, older Android TV sets com.google.android.tvlauncher.
# Runs on macOS/Linux and in Git Bash on Windows.
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash: keep /data/local/tmp paths as TV paths
cd "$(dirname "$0")"
: "${TV_HOST:?set TV_HOST to the TV IP address, e.g. TV_HOST=192.168.1.50 $0}"
STOCK_LAUNCHER="${STOCK_LAUNCHER:-com.google.android.tvlauncher}"
if [ -n "${LOCALAPPDATA:-}" ]; then
  # Windows: JDK 17 and the SDK unpacked under %LOCALAPPDATA%\tvhome-build (see README)
  BUILD_ROOT="$(cygpath -m "$LOCALAPPDATA")/tvhome-build"
  export JAVA_HOME="${JAVA_HOME:-$BUILD_ROOT/jdk17}"
  export ANDROID_HOME="${ANDROID_HOME:-$BUILD_ROOT/sdk}"
else
  export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
  export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
fi
export PATH="$JAVA_HOME/bin:$PATH"
[ -f local.properties ] || echo "sdk.dir=$ANDROID_HOME" > local.properties
sh ./gradlew assembleDebug -q --console=plain
PY=../tools/venv/bin/python
[ -x "$PY" ] || PY=../tools/venv/Scripts/python.exe
APK=app/build/outputs/apk/debug/app-debug.apk
"$PY" -I ../tools/b64push.py "$APK" /data/local/tmp/tvhome.apk
# Google TV's setup wizard also claims Home, with a higher priority than any user app, so it would
# win over the preferred home. It is only needed for first-time setup; disable it when present.
BLOCKERS="$STOCK_LAUNCHER"
if "$PY" -I ../tools/tv.py 'pm list packages com.google.android.tungsten.setupwraith' | grep -q setupwraith; then
  BLOCKERS="$BLOCKERS com.google.android.tungsten.setupwraith"
fi
{
  echo "pm install -r /data/local/tmp/tvhome.apk"
  echo "rm -f /data/local/tmp/tvhome.apk"
  echo "pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION"
  echo "cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity"
  for p in $BLOCKERS; do echo "pm disable-user --user 0 $p"; done
  # disabling a Home candidate clears the preferred home, so set it again
  echo "cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity"
  echo "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME"
  echo "input keyevent KEYCODE_HOME"
} | "$PY" -I ../tools/tv.py --batch
echo "Installed. Press Home on the remote to see it."
