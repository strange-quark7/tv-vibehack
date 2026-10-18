#!/usr/bin/env python3
"""Take a screenshot on the TV, optionally after pressing remote keys, and save it locally.

Usage: screenshot.py <out.png> [KEY ...]      e.g. screenshot.py shots/home.png HOME DPAD_DOWN
Keys are KEYCODE_ names without the prefix; WAIT pauses half a second.
"""
import base64
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tv  # noqa: E402


def main():
    out, keys = sys.argv[1], sys.argv[2:]
    dev = tv.connect()
    for k in keys:
        if k == "WAIT":
            time.sleep(0.5)
            continue
        dev.shell(f"input keyevent KEYCODE_{k}")
        time.sleep(0.35)
    time.sleep(0.8)
    # screencap can fail without touching an existing file (it does while a protected video layer,
    # e.g. an HDMI input, is alive), so delete first and retry rather than return a stale frame
    b64 = ""
    for _ in range(3):
        res = dev.shell("rm -f /data/local/tmp/shot.png; screencap -p /data/local/tmp/shot.png; echo rc=$?",
                        read_timeout_s=60.0)
        if "rc=0" in res:
            # base64 through the shell is slower than pull but never hangs
            b64 = dev.shell("base64 /data/local/tmp/shot.png", read_timeout_s=120.0)
            if b64.strip():
                break
        time.sleep(1.5)
    if not b64.strip():
        dev.close()
        sys.exit("screencap failed on the TV (a protected video layer may be on screen)")
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "wb") as f:
        f.write(base64.b64decode("".join(b64.split())))
    dev.close()
    print("saved", out)


if __name__ == "__main__":
    main()
