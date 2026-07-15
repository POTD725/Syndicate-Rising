extends Node
## Loads the exact MoonGoons concept-art board shown to the user and exposes its real artwork as game atlas regions.

signal skin_changed(index: int)

const SAVE_PATH: String = "user://syndicate_skin.json"
const BOARD_PARTS: Array[String] = [
	"res://assets/concept_atlases/board.part0.b64",
	"res://assets/concept_atlases/board.part1.b64"
]
const SOURCE_SIZE: Vector2 = Vector2(1536.0, 1024.0)
const BOARD_SIZE: Vector2 = Vector2(640.0, 427.0)

const SKIN_NAMES: Array[String] = [
	"Industrial Steel", "Neon Violet", "Toxic Circuit", "Ember Cartel", "Cryo Authority"
]
const PALETTES: Array[Dictionary] = [
	{"accent":"65e8ff", "secondary":"f1c56d", "panel":"142333", "dark":"070b12", "text":"dcecff"},
	{"accent":"ff5dd8", "secondary":"9d74ff", "panel":"25152f", "dark":"08050d", "text":"ffe2fa"},
	{"accent":"a8ff4f", "secondary":"42e69b", "panel":"152a1b", "dark":"050b07", "text":"ecffd9"},
	{"accent":"ff8a3d", "secondary":"ff4f5e", "panel":"2b1912", "dark":"0e0604", "text":"fff0df"},
	{"accent":"4ec5ff", "secondary":"a8f2ff", "panel":"10263a", "dark":"040a10", "text":"e5fbff"}
]

const BASE_BOXES: Array[Rect2] = [
	Rect2(6, 37, 153, 176), Rect2(161, 37, 138, 176), Rect2(301, 37, 133, 176),
	Rect2(436, 37, 144, 176), Rect2(582, 37, 147, 176)
]
const ROOM_BOXES: Array[Rect2] = [
	Rect2(739, 37, 158, 176), Rect2(899, 37, 154, 176), Rect2(1055, 37, 156, 176),
	Rect2(1213, 37, 150, 176), Rect2(1365, 37, 165, 176)
]
const THREAT_BOXES: Array[Rect2] = [
	Rect2(6, 257, 131, 190), Rect2(139, 257, 138, 190), Rect2(279, 257, 148, 190),
	Rect2(429, 257, 147, 190), Rect2(578, 257, 146, 190)
]
const DEFENSE_BOXES: Array[Rect2] = [
	Rect2(739, 257, 153, 191), Rect2(894, 257, 153, 191), Rect2(1049, 257, 157, 191),
	Rect2(1208, 257, 156, 191), Rect2(1366, 257, 164, 191)
]
const MISSION_BOXES: Array[Rect2] = [
	Rect2(739, 489, 154, 126), Rect2(895, 489, 153, 126), Rect2(1050, 489, 157, 126),
	Rect2(1209, 489, 156, 126), Rect2(1367, 489, 163, 126)
]
const CUTSCENE_BOXES: Array[Rect2] = [
	Rect2(739, 655, 145, 118), Rect2(886, 655, 154, 118), Rect2(1042, 655, 156, 118),
	Rect2(1200, 655, 164, 118), Rect2(1366, 655, 164, 118)
]
const CREW_BOXES: Array[Rect2] = [
	Rect2(6, 791, 131, 224), Rect2(139, 791, 132, 224), Rect2(273, 791, 137, 224),
	Rect2(412, 791, 143, 224), Rect2(557, 791, 151, 224)
]
const UI_BOXES: Array[Rect2] = [
	Rect2(743, 819, 505, 37), Rect2(743, 860, 505, 37), Rect2(743, 901, 505, 37),
	Rect2(743, 942, 505, 37), Rect2(743, 983, 505, 36)
]
const BUTTON_BOXES: Array[Rect2] = [
	Rect2(1304, 819, 188, 37), Rect2(1304, 860, 188, 37), Rect2(1304, 901, 188, 37),
	Rect2(1304, 942, 188, 37), Rect2(1304, 983, 188, 36)
]
const RESOURCE_ROWS: Dictionary = {
	"alloy": [Rect2(95,489,89,79), Rect2(205,489,89,79), Rect2(315,489,90,79), Rect2(425,489,91,79), Rect2(535,489,91,79)],
	"helium": [Rect2(95,573,89,81), Rect2(205,573,89,81), Rect2(315,573,90,81), Rect2(425,573,91,81), Rect2(535,573,91,81)],
	"cores": [Rect2(95,659,89,83), Rect2(205,659,89,83), Rect2(315,659,90,83), Rect2(425,659,91,83), Rect2(535,659,91,83)]
}

var selected_skin: int = 0
var _board_texture: Texture2D

func _ready() -> void:
	_load_preference()

func cycle_skin() -> int:
	selected_skin = (selected_skin + 1) % SKIN_NAMES.size()
	_save_preference()
	skin_changed.emit(selected_skin)
	return selected_skin

func set_skin(index: int) -> void:
	selected_skin = clampi(index, 0, SKIN_NAMES.size() - 1)
	_save_preference()
	skin_changed.emit(selected_skin)

func skin_name() -> String:
	return SKIN_NAMES[selected_skin]

func accent() -> Color:
	return Color(String(PALETTES[selected_skin].get("accent", "65e8ff")))

func secondary() -> Color:
	return Color(String(PALETTES[selected_skin].get("secondary", "f1c56d")))

func panel() -> Color:
	return Color(String(PALETTES[selected_skin].get("panel", "142333")))

func dark() -> Color:
	return Color(String(PALETTES[selected_skin].get("dark", "070b12")))

func text() -> Color:
	return Color(String(PALETTES[selected_skin].get("text", "dcecff")))

func danger() -> Color:
	return secondary().lerp(Color("ff4f68"), 0.55)

func atlas() -> Texture2D:
	if _board_texture != null:
		return _board_texture
	var encoded: String = ""
	for path: String in BOARD_PARTS:
		encoded += FileAccess.get_file_as_string(path).strip_edges()
	var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
	var image: Image = Image.new()
	var load_error: Error = image.load_webp_from_buffer(bytes)
	if load_error != OK:
		push_error("The displayed MoonGoons concept board could not be decoded: %s" % error_string(load_error))
		var fallback: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		fallback.fill(Color("ff00ff"))
		_board_texture = ImageTexture.create_from_image(fallback)
		return _board_texture
	_board_texture = ImageTexture.create_from_image(image)
	return _board_texture

func region(item_id: String) -> Rect2:
	if item_id.begins_with("room_"):
		return _scaled(_room_box(item_id.trim_prefix("room_")))
	if item_id.begins_with("threat_"):
		return _scaled(_threat_box(item_id.trim_prefix("threat_")))
	if item_id.begins_with("resource_"):
		return _scaled(_resource_box(item_id.trim_prefix("resource_")))
	if item_id.begins_with("defense_"):
		return _scaled(_defense_box(item_id.trim_prefix("defense_")))
	if item_id.begins_with("mission_"):
		return _scaled(_mission_box(item_id.trim_prefix("mission_")))
	if item_id.begins_with("crew_"):
		return _scaled(_crew_box(item_id.trim_prefix("crew_")))
	match item_id:
		"moon_base", "hideout", "operations", "outpost", "construction", "moon_emblem": return base_region()
		"station", "alert": return cutscene_region(0)
		"rover", "shop", "inventory": return _scaled(ROOM_BOXES[3])
		"drone": return _scaled(THREAT_BOXES[2])
		"cargo", "power_core": return _scaled(_resource_box("alloy" if item_id == "cargo" else "cores"))
		"chat_galaxy", "chat_alliance": return _scaled(MISSION_BOXES[1])
		"chat_private", "lock", "unlock", "prison": return _scaled(MISSION_BOXES[4])
		"score": return _scaled(MISSION_BOXES[2])
		"save": return _scaled(_resource_box("cores"))
		"rotate", "cipher": return _scaled(MISSION_BOXES[3])
		"zoom", "hidden_target": return _scaled(MISSION_BOXES[0])
		"heal", "research": return _scaled(ROOM_BOXES[0])
		"weapons": return _scaled(ROOM_BOXES[1])
		"victory": return cutscene_region(4)
		"defeat": return cutscene_region(1)
		"alliance", "hero": return _scaled(CREW_BOXES[1])
		_: return _scaled(ROOM_BOXES[2])

func base_region() -> Rect2:
	return _scaled(BASE_BOXES[selected_skin])

func ui_frame_region() -> Rect2:
	return _scaled(UI_BOXES[selected_skin])

func button_region() -> Rect2:
	return _scaled(BUTTON_BOXES[selected_skin])

func cutscene_region(index: int) -> Rect2:
	return _scaled(CUTSCENE_BOXES[clampi(index, 0, CUTSCENE_BOXES.size() - 1)])

func room_item(room_id: String) -> String:
	return "room_" + room_id

func crew_item(role_name: String) -> String:
	match role_name.to_lower():
		"runner", "smuggler": return "crew_smuggler"
		"sharpshot", "sharpshooter", "gunner": return "crew_gunner"
		"hacker": return "crew_hacker"
		"techie": return "crew_techie"
		_: return "crew_brawler"

func style_box(active: bool = false, radius: int = 10, alpha: float = 0.96) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var fill: Color = panel().lightened(0.10 if active else 0.0)
	fill.a = alpha
	style.bg_color = fill
	style.border_color = accent() if active else accent().darkened(0.42)
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(radius)
	return style

func _room_box(room_id: String) -> Rect2:
	match room_id:
		"black_research", "clinic": return ROOM_BOXES[0]
		"weapons_workshop", "enforcer_gym", "sharpshooter_range": return ROOM_BOXES[1]
		"backroom", "signal_den", "boss_office": return ROOM_BOXES[2]
		"chop_shop", "tunnel": return ROOM_BOXES[3]
		_: return ROOM_BOXES[4]

func _threat_box(threat_id: String) -> Rect2:
	match threat_id:
		"patrol": return THREAT_BOXES[0]
		"riot": return THREAT_BOXES[1]
		"survey", "drone": return THREAT_BOXES[2]
		"k9": return THREAT_BOXES[3]
		_: return THREAT_BOXES[4]

func _defense_box(defense_id: String) -> Rect2:
	match defense_id:
		"sentry": return DEFENSE_BOXES[0]
		"laser": return DEFENSE_BOXES[1]
		"blast_doors": return DEFENSE_BOXES[2]
		"escape_tunnels": return DEFENSE_BOXES[3]
		_: return DEFENSE_BOXES[4]

func _mission_box(mission_id: String) -> Rect2:
	match mission_id:
		"hidden": return MISSION_BOXES[0]
		"law_hack": return MISSION_BOXES[1]
		"steal_intel": return MISSION_BOXES[2]
		"syndicate_cipher", "cipher": return MISSION_BOXES[3]
		_: return MISSION_BOXES[4]

func _crew_box(role_id: String) -> Rect2:
	match role_id:
		"techie": return CREW_BOXES[1]
		"hacker": return CREW_BOXES[2]
		"gunner", "sharpshot": return CREW_BOXES[3]
		"smuggler", "runner": return CREW_BOXES[4]
		_: return CREW_BOXES[0]

func _resource_box(resource_id: String) -> Rect2:
	var key: String = resource_id
	if key == "helium3": key = "helium"
	if key == "data" or key == "data_cores": key = "cores"
	var row_value: Variant = RESOURCE_ROWS.get(key, RESOURCE_ROWS["alloy"])
	var row: Array = row_value as Array
	return row[selected_skin] as Rect2

func _scaled(source: Rect2) -> Rect2:
	var scale: Vector2 = Vector2(BOARD_SIZE.x / SOURCE_SIZE.x, BOARD_SIZE.y / SOURCE_SIZE.y)
	return Rect2(source.position * scale, source.size * scale)

func _load_preference() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		selected_skin = clampi(int((parsed as Dictionary).get("selected_skin", 0)), 0, SKIN_NAMES.size() - 1)

func _save_preference() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"selected_skin": selected_skin}))
