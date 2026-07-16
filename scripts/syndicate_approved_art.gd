extends RefCounted
## Exact approved dashboard art registry. The installer creates these files from
## the checksum-locked Wix Media source before Godot imports or exports.

const ROOT: String = "res://assets/approved/"
const SYSTEM_IDS: Array[String] = [
	"resource_alloy", "resource_helium", "resource_cores", "defense_jammer",
	"defense_sentry", "defense_blast_doors", "defense_escape_tunnels",
	"threat_survey", "threat_patrol", "threat_riot", "threat_cyber", "mission_hidden"
]
const UI_IDS: Array[String] = ["patrol", "heroes", "dermapack", "store", "alliance", "state", "rotate", "zoom"]

static var _cache: Dictionary = {}

static func approved_graphics_active() -> bool:
	return ResourceLoader.exists(ROOT + "lunar_base_board.webp") and FileAccess.file_exists(ROOT + "graphics-receipt.json")

static func board_texture() -> Texture2D:
	return _load_texture("board", ROOT + "lunar_base_board.webp")

static func npc_atlas() -> Texture2D:
	return _load_texture("npc", ROOT + "npc_atlas.png")

static func systems_atlas() -> Texture2D:
	return _load_texture("systems", ROOT + "systems_atlas.webp")

static func ui_atlas() -> Texture2D:
	return _load_texture("ui", ROOT + "ui_atlas.webp")

static func dermapack_texture() -> Texture2D:
	return _load_texture("dermapack", ROOT + "dermapack.webp")

static func cutscene_texture(key: String) -> Texture2D:
	var safe_key: String = key if key in ["prologue", "ghost_key", "war_room", "finale"] else "prologue"
	return _load_texture("cutscene_" + safe_key, ROOT + "cutscenes/%s.webp" % safe_key)

static func attack_texture(key: String) -> Texture2D:
	var safe_key: String = key if key in ["survey", "patrol", "riot", "cyber"] else "patrol"
	return _load_texture("attack_" + safe_key, ROOT + "attacks/%s.webp" % safe_key)

static func npc_region(role_index: int, frame: int) -> Rect2:
	var role: int = posmod(role_index, 8)
	var row: int = int(role / 4)
	var column: int = role % 4
	return Rect2(float(column * 256 + posmod(frame, 4) * 64), float(row * 128), 64.0, 128.0)

static func system_region(id: String) -> Rect2:
	var index: int = SYSTEM_IDS.find(id)
	if index < 0:
		index = 0
	return Rect2(float(index % 4) * 256.0, float(int(index / 4)) * 256.0, 256.0, 256.0)

static func ui_region(id: String) -> Rect2:
	var index: int = UI_IDS.find(id)
	if index < 0:
		index = 0
	return Rect2(float(index % 4) * 128.0, float(int(index / 4)) * 128.0, 128.0, 128.0)

static func graphics_receipt() -> Dictionary:
	var path: String = ROOT + "graphics-receipt.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

static func _load_texture(cache_key: String, path: String) -> Texture2D:
	if _cache.has(cache_key):
		return _cache[cache_key] as Texture2D
	if not ResourceLoader.exists(path):
		push_error("Approved MoonGoons graphic is missing: %s. Run tools/install_approved_graphics.py." % path)
		return GradientTexture2D.new()
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_error("Approved MoonGoons graphic failed to import: %s" % path)
		return GradientTexture2D.new()
	_cache[cache_key] = texture
	return texture
