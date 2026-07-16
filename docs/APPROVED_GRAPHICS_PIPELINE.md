# Approved Graphics and Dashboard Pipeline

## Canonical source

The game uses the polished MoonGoons isometric lunar-base dashboard approved in chat. The canonical source is stored in Wix Media and locked by SHA-256:

- Source: `https://static.wixstatic.com/media/c5b016_490d584acc22468db31c6c378c4b396d~mv2.png`
- SHA-256: `53ecc228635c151d0511be9f81b7eb84099541d21984ccadcc5f796af19b7da2`
- Dimensions: `1536 × 1024`

The build fails if the downloaded bytes do not match that checksum.

## Generated game graphics

`tools/install_approved_graphics.py` derives the complete runtime pack before Godot imports the project:

- 1024 × 1536 portrait lunar district board
- 1024 × 256 four-frame NPC animation atlas
- 1024 × 768 resources, defenses, Peacekeeper threats, and side-mission atlas
- 512 × 256 mobile navigation/dashboard atlas
- 256 × 256 wearable DermaPack image
- four 720 × 1280 story and prologue scenes
- four 720 × 720 Peacekeeper attack scenes

Generated files live in `assets/approved/`. They are ignored by Git because they are deterministic derivatives of the checksum-locked source, but they are imported and packaged into browser and Android exports.

## Scenes using the approved art

- Lunar city and hideout
- Harvesting, defenses, threats, and side missions
- Mission selection and crew assembly
- Tactical raids
- Galaxy, Alliance, and Private communications
- Interactive origin scene and story interstitials
- Survey, Patrol, Riot, and Cyber attack scenes

## Verification

`compile_and_test.sh` installs the art pack first and then runs all established gameplay tests plus `tests/approved_graphics_test.gd`.

The approved-graphics test independently checks:

- source checksum and dimensions
- every generated texture and exact resolution
- seven approved scene controllers
- all twelve interactive building hotspots
- 32 NPC jobs and movement routes
- DermaPack navigation
- pan, zoom, recenter, and quarter-turn rotation
- Operations, Mission, Chat, Prologue, and Attack integration

Browser and Android exports run the same installer and verification before packaging.
