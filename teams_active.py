#!/usr/bin/env python3
"""Keep Teams status active by nudging the mouse at regular intervals.

Controls:
  Ctrl+Shift+S  - Start/resume nudging
  Ctrl+Shift+X  - Stop nudging
  Ctrl+Shift+Q  - Quit the script entirely
"""

import time
import threading
import sys

try:
    import pyautogui
except ImportError:
    sys.exit("Missing dependency: pip install pyautogui")

try:
    import keyboard
except ImportError:
    sys.exit("Missing dependency: pip install keyboard")


INTERVAL_SECONDS = 60   # how often to nudge (seconds)
NUDGE_PIXELS = 5        # how far to move and return (pixels)

_running = threading.Event()
_quit = threading.Event()


def nudge():
    """Move mouse slightly and return to original position."""
    x, y = pyautogui.position()
    pyautogui.moveRel(NUDGE_PIXELS, 0, duration=0.1)
    pyautogui.moveRel(-NUDGE_PIXELS, 0, duration=0.1)
    print(f"[{time.strftime('%H:%M:%S')}] Nudged mouse at ({x}, {y})")


def loop():
    while not _quit.is_set():
        if _running.is_set():
            nudge()
            # Sleep in small chunks so we respond to quit quickly
            for _ in range(INTERVAL_SECONDS * 10):
                if not _running.is_set() or _quit.is_set():
                    break
                time.sleep(0.1)
        else:
            time.sleep(0.1)


def on_start():
    if not _running.is_set():
        _running.set()
        print(">> Started — mouse will nudge every", INTERVAL_SECONDS, "seconds")


def on_stop():
    if _running.is_set():
        _running.clear()
        print(">> Stopped")


def on_quit():
    _running.clear()
    _quit.set()
    print(">> Quitting…")


def main():
    pyautogui.FAILSAFE = True  # move mouse to top-left corner to abort

    keyboard.add_hotkey("ctrl+shift+s", on_start)
    keyboard.add_hotkey("ctrl+shift+x", on_stop)
    keyboard.add_hotkey("ctrl+shift+q", on_quit)

    print("Teams activity keeper ready.")
    print("  Ctrl+Shift+S  start")
    print("  Ctrl+Shift+X  stop")
    print("  Ctrl+Shift+Q  quit")
    print("  (move mouse to top-left corner for emergency stop)")
    print()

    on_start()  # start immediately

    worker = threading.Thread(target=loop, daemon=True)
    worker.start()

    _quit.wait()
    worker.join(timeout=2)


if __name__ == "__main__":
    main()
