#!/usr/bin/env bash
set -Eeuo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
mkdir -p logs
: > logs/approved_graphics.log
: > logs/godot_import.log
: > logs/smoke_test.log
: > logs/isometric_test.log
: > logs/animation_cutscene_test.log
: > logs/full_isometric_art_test.log
: > logs/approved_graphics_test.log

if ! command -v "${GODOT_BIN}" >/dev/null 2>&1 && [[ ! -x "${GODOT_BIN}" ]]; then
  echo "Godot 4.3+ was not found. Set GODOT_BIN to the executable path." | tee logs/smoke_test.log
  exit 1
fi

if ! python3 -c "import PIL" >/dev/null 2>&1; then
  python3 -m pip install --quiet --disable-pip-version-check pillow
fi
python3 tools/install_approved_graphics.py 2>&1 | tee logs/approved_graphics.log

test -s assets/approved/lunar_base_board.webp
test -s assets/approved/npc_atlas.png
test -s assets/approved/systems_atlas.webp
test -s assets/approved/ui_atlas.webp
test -s assets/approved/dermapack.webp
test -s assets/approved/graphics-receipt.json

"${GODOT_BIN}" --headless --path . --editor --quit 2>&1 | tee logs/godot_import.log
"${GODOT_BIN}" --headless --path . --script res://tests/syndicate_smoke_test.gd 2>&1 | tee logs/smoke_test.log
"${GODOT_BIN}" --headless --path . --script res://tests/isometric_board_test.gd 2>&1 | tee logs/isometric_test.log
"${GODOT_BIN}" --headless --path . --script res://tests/animation_cutscene_test.gd 2>&1 | tee logs/animation_cutscene_test.log
"${GODOT_BIN}" --headless --path . --script res://tests/full_isometric_art_test.gd 2>&1 | tee logs/full_isometric_art_test.log
"${GODOT_BIN}" --headless --path . --script res://tests/approved_graphics_test.gd 2>&1 | tee logs/approved_graphics_test.log

echo "SUCCESS: MoonGoons Syndicate Rising approved-graphics verification passed."
