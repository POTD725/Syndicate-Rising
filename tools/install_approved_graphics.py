#!/usr/bin/env python3
"""Download the approved MoonGoons dashboard art and derive every game texture.

The public Wix Media URL is the canonical raster source chosen in chat. The
checksum prevents silent replacement. Generated files are ignored by Git but
are included in Godot exports after this script runs.
"""
from __future__ import annotations

import hashlib
import json
import sys
import urllib.request
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps
except ImportError as exc:
    raise SystemExit("Pillow is required: python -m pip install pillow") from exc

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "approved"
CACHE = ROOT / ".ci" / "approved-dashboard-source.png"
SOURCE_URL = "https://static.wixstatic.com/media/c5b016_490d584acc22468db31c6c378c4b396d~mv2.png"
SOURCE_SHA256 = "53ecc228635c151d0511be9f81b7eb84099541d21984ccadcc5f796af19b7da2"

SYSTEM_IDS = [
    "resource_alloy", "resource_helium", "resource_cores", "defense_jammer",
    "defense_sentry", "defense_blast_doors", "defense_escape_tunnels",
    "threat_survey", "threat_patrol", "threat_riot", "threat_cyber", "mission_hidden",
]
UI_IDS = ["patrol", "heroes", "dermapack", "store", "alliance", "state", "rotate", "zoom"]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def download_source() -> None:
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    if CACHE.exists() and sha256(CACHE) == SOURCE_SHA256:
        return
    request = urllib.request.Request(SOURCE_URL, headers={"User-Agent": "MoonGoons-Syndicate-Rising/1.0"})
    with urllib.request.urlopen(request, timeout=60) as response:
        CACHE.write_bytes(response.read())
    actual = sha256(CACHE)
    if actual != SOURCE_SHA256:
        CACHE.unlink(missing_ok=True)
        raise SystemExit(f"Approved graphics checksum mismatch: {actual}")


def fit(source: Image.Image, box: tuple[int, int, int, int], size: tuple[int, int]) -> Image.Image:
    return ImageOps.fit(source.crop(box), size, method=Image.Resampling.LANCZOS)


def save_webp(image: Image.Image, name: str, quality: int = 93) -> None:
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(path, "WEBP", quality=quality, method=6)


def make_board(source: Image.Image) -> None:
    canvas = Image.new("RGB", (1024, 1536), "#050912")
    background = ImageOps.fit(source, canvas.size, method=Image.Resampling.LANCZOS)
    background = ImageEnhance.Brightness(background).enhance(0.42).filter(ImageFilter.GaussianBlur(4))
    canvas.paste(background, (0, 0))
    canvas.paste(fit(source, (620, 0, 1536, 250), (1024, 280)), (0, 0))
    canvas.paste(fit(source, (85, 125, 1450, 900), (1024, 1015)), (0, 250))
    lower = ImageEnhance.Brightness(fit(source, (150, 700, 1410, 920), (1024, 320))).enhance(0.72)
    canvas.paste(lower, (0, 1216))
    for y in (245, 1210):
        band = canvas.crop((0, y - 12, 1024, y + 12)).filter(ImageFilter.GaussianBlur(10))
        canvas.paste(band, (0, y - 12))
    save_webp(canvas, "lunar_base_board.webp", 94)


def make_npc_atlas() -> None:
    atlas = Image.new("RGBA", (1024, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(atlas)
    role_colors = [
        ("#5b3f8f", "#b564ff"), ("#1c5c78", "#54e6ff"), ("#563a2c", "#ff9b47"),
        ("#693a42", "#ff5b6d"), ("#334b60", "#73b4ff"), ("#285548", "#56e4b0"),
        ("#5a4b30", "#ffd268"), ("#3f4760", "#aab7ff"),
    ]
    for role in range(8):
        row, column = divmod(role, 4)
        body, accent = role_colors[role]
        for frame in range(4):
            cx = column * 256 + frame * 64 + 32
            cy = row * 128 + 62
            bob = (0, -3, 0, 3)[frame]
            step = 5 if frame % 2 == 0 else -5
            draw.ellipse((cx - 17, cy + 27, cx + 17, cy + 36), fill=(0, 0, 0, 100))
            draw.line((cx - 5, cy + 13, cx - 7 + step, cy + 31), fill="#18222f", width=6)
            draw.line((cx + 5, cy + 13, cx + 7 - step, cy + 31), fill="#18222f", width=6)
            draw.rounded_rectangle((cx - 13, cy - 10 + bob, cx + 13, cy + 17 + bob), 6, fill=body, outline="#101722", width=3)
            draw.rectangle((cx - 10, cy - 2 + bob, cx + 10, cy + 4 + bob), fill=accent)
            draw.ellipse((cx - 10, cy - 30 + bob, cx + 10, cy - 10 + bob), fill="#d5a17c", outline="#101722", width=3)
            draw.polygon([(cx - 11, cy - 25 + bob), (cx, cy - 36 + bob), (cx + 11, cy - 25 + bob), (cx + 9, cy - 16 + bob), (cx - 9, cy - 16 + bob)], fill="#26384c")
            draw.rectangle((cx - 7, cy - 20 + bob, cx + 7, cy - 16 + bob), fill=accent)
            arm = (-3, 1, 3, -1)[frame]
            draw.line((cx - 12, cy - 3 + bob, cx - 22, cy + 8 + arm + bob), fill=body, width=6)
            draw.line((cx + 12, cy - 3 + bob, cx + 22, cy + 6 - arm + bob), fill=body, width=6)
    (OUT / "npc_atlas.png").parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT / "npc_atlas.png")


def make_systems(source: Image.Image) -> None:
    boxes = {
        "resource_alloy": (100, 365, 480, 660),
        "resource_helium": (820, 385, 1135, 680),
        "resource_cores": (730, 150, 1115, 485),
        "defense_jammer": (0, 75, 355, 310),
        "defense_sentry": (1200, 190, 1536, 455),
        "defense_blast_doors": (670, 540, 1015, 840),
        "defense_escape_tunnels": (1020, 255, 1400, 555),
        "threat_survey": (610, 0, 1425, 610),
        "threat_patrol": (1160, 175, 1536, 655),
        "threat_riot": (1080, 395, 1450, 770),
        "threat_cyber": (720, 125, 1115, 530),
        "mission_hidden": (390, 250, 900, 720),
    }
    atlas = Image.new("RGB", (1024, 768), "#07101a")
    for index, key in enumerate(SYSTEM_IDS):
        tile = fit(source, boxes[key], (256, 256))
        atlas.paste(tile, ((index % 4) * 256, (index // 4) * 256))
    save_webp(atlas, "systems_atlas.webp", 94)


def make_ui(source: Image.Image) -> None:
    boxes = {
        "patrol": (0, 855, 155, 1024),
        "heroes": (145, 855, 295, 1024),
        "dermapack": (285, 850, 535, 1024),
        "store": (525, 855, 650, 1024),
        "alliance": (640, 850, 780, 1024),
        "state": (1290, 830, 1536, 1024),
        "rotate": (1415, 680, 1536, 835),
        "zoom": (1415, 550, 1536, 700),
    }
    atlas = Image.new("RGB", (512, 256), "#07101a")
    for index, key in enumerate(UI_IDS):
        tile = fit(source, boxes[key], (128, 128))
        atlas.paste(tile, ((index % 4) * 128, (index // 4) * 128))
    save_webp(atlas, "ui_atlas.webp", 95)
    save_webp(fit(source, (285, 850, 535, 1024), (256, 256)), "dermapack.webp", 95)


def make_cinematics(source: Image.Image) -> None:
    cutscene_boxes = {
        "prologue": (500, 0, 1470, 760),
        "ghost_key": (690, 95, 1130, 550),
        "war_room": (410, 250, 920, 730),
        "finale": (0, 0, 1536, 900),
    }
    attack_boxes = {
        "survey": (600, 0, 1430, 620),
        "patrol": (1150, 165, 1536, 670),
        "riot": (1070, 385, 1460, 790),
        "cyber": (705, 110, 1130, 550),
    }
    for key, box in cutscene_boxes.items():
        save_webp(fit(source, box, (720, 1280)), f"cutscenes/{key}.webp", 94)
    for key, box in attack_boxes.items():
        save_webp(fit(source, box, (720, 720)), f"attacks/{key}.webp", 94)


def main() -> int:
    download_source()
    OUT.mkdir(parents=True, exist_ok=True)
    source = Image.open(CACHE).convert("RGB")
    if source.size != (1536, 1024):
        raise SystemExit(f"Unexpected approved source size: {source.size}")
    make_board(source)
    make_npc_atlas()
    make_systems(source)
    make_ui(source)
    make_cinematics(source)
    receipt = {
        "status": "approved",
        "source_url": SOURCE_URL,
        "source_sha256": SOURCE_SHA256,
        "source_size": list(source.size),
        "generated": sorted(str(path.relative_to(ROOT)) for path in OUT.rglob("*") if path.is_file()),
    }
    (OUT / "graphics-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(f"Approved MoonGoons graphics installed: {len(receipt['generated'])} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
