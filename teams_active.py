"""
Teams Active Keeper
───────────────────
Bouge la souris discrètement pour que Teams ne passe pas en absent.

Raccourcis :
  Ctrl+Shift+S  démarrer / reprendre
  Ctrl+Shift+X  pause
  Ctrl+Shift+Q  quitter

Urgence : Ctrl+C dans le terminal.
"""

import time
import threading
import sys

from pynput import mouse as _mouse
from pynput.keyboard import GlobalHotKeys, Key, Controller as KbController

INTERVAL = 60    # secondes entre chaque nudge
NUDGE_PX = 5     # pixels aller-retour

_active = threading.Event()
_stop   = threading.Event()
_mc     = _mouse.Controller()


def nudge():
    x, y = _mc.position
    _mc.move(NUDGE_PX, 0)
    time.sleep(0.15)
    _mc.move(-NUDGE_PX, 0)
    print(f"[{time.strftime('%H:%M:%S')}]  nudge @ ({int(x)}, {int(y)})")


def _loop():
    while not _stop.is_set():
        if _active.is_set():
            nudge()
            for _ in range(INTERVAL * 10):
                if not _active.is_set() or _stop.is_set():
                    break
                time.sleep(0.1)
        else:
            time.sleep(0.1)


def _start():
    if not _active.is_set():
        _active.set()
        print(f"▶  Actif — nudge toutes les {INTERVAL} s")

def _pause():
    if _active.is_set():
        _active.clear()
        print("⏸  En pause")

def _quit():
    _active.clear()
    _stop.set()
    print("⏹  Arrêt.")


def main():
    print(__doc__)
    print(f"  Intervalle : {INTERVAL} s   |   Déplacement : {NUDGE_PX} px")
    print("─" * 45)

    worker = threading.Thread(target=_loop, daemon=True)
    worker.start()

    _start()

    hotkeys = GlobalHotKeys({
        "<ctrl>+<shift>+s": _start,
        "<ctrl>+<shift>+x": _pause,
        "<ctrl>+<shift>+q": _quit,
    })
    hotkeys.start()

    try:
        _stop.wait()
    except KeyboardInterrupt:
        _quit()

    hotkeys.stop()
    worker.join(timeout=2)

    if sys.platform == "win32":
        input("\nAppuie sur Entrée pour fermer…")


if __name__ == "__main__":
    main()
