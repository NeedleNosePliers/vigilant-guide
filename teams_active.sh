#!/usr/bin/env bash
# Launcher — installe les dépendances si besoin, puis lance le script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation des dépendances manquantes
pip install --quiet pyautogui keyboard 2>/dev/null

# Lancement (sudo requis pour les hotkeys clavier sur Linux)
if [ "$EUID" -ne 0 ]; then
    exec sudo python3 "$SCRIPT_DIR/teams_active.py"
else
    exec python3 "$SCRIPT_DIR/teams_active.py"
fi
