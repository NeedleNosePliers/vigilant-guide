#!/usr/bin/env python3
"""
Teams Active Keeper
───────────────────
Bouge la souris discrètement pour que Teams ne passe pas en absent.
Fichier unique — installe ses dépendances tout seul au premier lancement.

Raccourcis :
  Ctrl+Shift+S  démarrer / reprendre
  Ctrl+Shift+X  pause
  Ctrl+Shift+Q  quitter

Urgence : glisser la souris dans le coin en haut-à-gauche de l'écran.
"""

import sys
import subprocess
import importlib
import os

# ── Auto-installation des dépendances ────────────────────────────────────────

DEPS = {"pyautogui": "pyautogui", "keyboard": "keyboard"}

def _install_deps():
    missing = [pkg for mod, pkg in DEPS.items()
               if importlib.util.find_spec(mod) is None]
    if not missing:
        return
    print(f"Installation des dépendances ({', '.join(missing)})…")
    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "--quiet", "--user"] + missing
    )
    print("Dépendances installées. Relancement…\n")
    os.execv(sys.executable, [sys.executable] + sys.argv)

_install_deps()

# ── Programme principal ───────────────────────────────────────────────────────

import time
import threading
import pyautogui
import keyboard

INTERVAL  = 60   # secondes entre chaque nudge
NUDGE_PX  = 5    # pixels de déplacement (retour immédiat)

_active = threading.Event()
_stop   = threading.Event()

pyautogui.FAILSAFE = True   # coin haut-gauche = arrêt d'urgence


def nudge():
    x, y = pyautogui.position()
    pyautogui.moveRel(NUDGE_PX, 0, duration=0.15)
    pyautogui.moveRel(-NUDGE_PX, 0, duration=0.15)
    print(f"[{time.strftime('%H:%M:%S')}]  nudge @ ({x}, {y})")


def _loop():
    while not _stop.is_set():
        if _active.is_set():
            try:
                nudge()
            except pyautogui.FailSafeException:
                print("⚠  FailSafe déclenché — arrêt.")
                _active.clear()
                _stop.set()
                break
            # attente fractionnée pour réagir vite aux commandes
            for _ in range(INTERVAL * 10):
                if not _active.is_set() or _stop.is_set():
                    break
                time.sleep(0.1)
        else:
            time.sleep(0.1)


def _start():
    if not _active.is_set():
        _active.set()
        print("▶  Actif — nudge toutes les", INTERVAL, "s")

def _pause():
    if _active.is_set():
        _active.clear()
        print("⏸  En pause")

def _quit():
    _active.clear()
    _stop.set()
    print("⏹  Arrêt.")


def main():
    keyboard.add_hotkey("ctrl+shift+s", _start)
    keyboard.add_hotkey("ctrl+shift+x", _pause)
    keyboard.add_hotkey("ctrl+shift+q", _quit)

    print(__doc__)
    print(f"  Intervalle : {INTERVAL} s   |   Déplacement : {NUDGE_PX} px")
    print("─" * 45)

    _start()

    worker = threading.Thread(target=_loop, daemon=True)
    worker.start()

    try:
        _stop.wait()
    except KeyboardInterrupt:
        _quit()

    worker.join(timeout=2)

    # Sur Windows, garde la fenêtre ouverte après une erreur
    if sys.platform == "win32" and getattr(sys, "frozen", False):
        input("\nAppuie sur Entrée pour fermer…")


if __name__ == "__main__":
    main()
