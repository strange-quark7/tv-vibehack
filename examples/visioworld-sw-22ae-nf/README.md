# VisioWorld SW-22AE NF

Skyworth-built Google TV (device `SW6H`, MediaTek, 1.8 GB RAM), Android 11, firmware
`RTT2.220103.001`. Debloated and switched to the `launcher/` home screen on 18 October 2026.

All commands below run from the repo root in **Git Bash** (Windows) or any bash, with the TV on and
on the same network. Set the TV's address once per terminal:

```bash
export TV_HOST=192.168.1.50   # your TV's IP
```

The first time on a new computer, create the Python ADB client:

```bash
python -m venv tools/venv && tools/venv/Scripts/pip install -r tools/requirements.txt
```

(On macOS/Linux the venv folder is `tools/venv/bin/` instead of `tools/venv/Scripts/`; the scripts
find either.) The TV asks "Allow USB debugging?" the first time a new computer connects.

## What was changed

| Change | How to undo |
|---|---|
| 25 packages disabled, listed with reasons in [`debloat.txt`](debloat.txt) | re-enable one app (below) or run the restore script |
| Google TV launcher (`com.google.android.apps.tv.launcherx`) disabled | restore script |
| Google TV setup wizard (`com.google.android.tungsten.setupwraith`) disabled: it claims Home with a higher priority than any installed app, so the new launcher could never become Home while it was enabled. Setup was already complete. | restore script |
| Screensaver switched from Google TV ambient mode to the built-in Colors screensaver | restore script |
| New home screen `com.gathin.tvhome` installed and set as Home | restore script, then `tools/tv.py 'pm uninstall com.gathin.tvhome'` |

Kept on purpose: Netflix, Prime Video, YouTube, YouTube Music, Apple TV, JioHotstar, SonyLIV, ZEE5,
Crunchyroll, Dropout, Google Assistant / voice search, Play Store, Live TV and the remote pairing
service.

## Re-enable one app

Find its package name in [`debloat.txt`](debloat.txt) (each line has a comment), then:

```bash
tools/venv/Scripts/python.exe -I tools/tv.py 'pm enable com.spotify.tv.android'
```

It appears on the home screen the next time you press Home. To disable it again:
`'pm disable-user --user 0 com.spotify.tv.android'`. Without a computer, the TV can do the same
from Settings, Apps, See all apps, Show system apps, then the app, Enable.

## Put everything back to stock

```bash
examples/visioworld-sw-22ae-nf/restore.sh
```

This re-enables every package in `debloat.txt`, the Google TV launcher and setup wizard, makes the
Google TV launcher Home again and restores the ambient screensaver. The full pre-change backup
(package lists, `getprop`, every global/secure/system setting, screenshots) is in
`backup/visioworld-sw-22ae-nf/` on the computer that did the work; it is kept out of git because it
holds the TV's serial and account details.

## Change the dock order

Edit [`launcher/app/src/main/res/values/config.xml`](../../launcher/app/src/main/res/values/config.xml),
array `dock_apps`. The first four packages are the dock, left to right; the rest set the order of
the first grid tiles, and every other app follows alphabetically. Current order: Netflix, Prime
Video, JioHotstar, Dropout | YouTube Music, Apple TV. `hidden_apps` lists apps that never get a
tile. Then rebuild and install:

```bash
STOCK_LAUNCHER=com.google.android.apps.tv.launcherx launcher/build-and-install.sh
```

Package names of the apps on this TV:

| App | Package |
|---|---|
| Netflix | `com.netflix.ninja` |
| Prime Video | `com.amazon.amazonvideo.livingroom` |
| JioHotstar | `in.startv.hotstar` |
| Dropout | `com.collegehumor.chdropout` |
| YouTube | `com.google.android.youtube.tv` |
| YouTube Music | `com.google.android.youtube.tvmusic` |
| Apple TV | `com.apple.atve.androidtv.appletv` |
| SonyLIV | `com.sonyliv` |
| ZEE5 | `com.graymatrix.did` |
| Crunchyroll | `com.crunchyroll.crunchyroid` |

## Change the wallpaper

The background is pitch black by default, set by
[`launcher/app/src/main/res/drawable/wallpaper.xml`](../../launcher/app/src/main/res/drawable/wallpaper.xml).

- **A different solid colour:** change `android:color` in that file (e.g. `#FF101418`).
- **A picture:** delete `wallpaper.xml` and save a 1920x1080 JPEG as
  `launcher/app/src/main/res/drawable-nodpi/wallpaper.jpg`. Keep it a JPEG of a few hundred KB;
  the TV has little memory to spare. Dark images keep the text readable.

Then run the build-and-install command above.

## Building on this computer (Windows)

`launcher/build-and-install.sh` uses JDK 17 and the Android SDK (platform 34, build-tools 34.0.0)
from `%LOCALAPPDATA%\tvhome-build\jdk17` and `%LOCALAPPDATA%\tvhome-build\sdk`, which are already
installed here. On another Windows computer, unzip a Temurin 17 JDK to `jdk17` there and the Android
command-line tools to `sdk\cmdline-tools\latest`, then run
`sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=<that sdk folder> "platforms;android-34" "build-tools;34.0.0"`.

## Things specific to this TV

- Leaving an HDMI input keeps a protected video layer alive, so `screencap` returns nothing until
  the Live TV app is stopped (`tools/tv.py 'am force-stop com.smartdevice.livetv'`).
  `tools/screenshot.py` retries and says so instead of returning an old image.
- A console on an HDMI port can show up as a separate HDMI-CEC input with no name; the launcher folds it into its port
  and shows the device name next to it.
