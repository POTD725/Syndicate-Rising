extends Node
## Generates and persists five lightweight, game-ready skin families for every visual item category.

signal skin_changed(index: int)

const SAVE_PATH: String = "user://syndicate_skin.json"
const CELL: int = 128
const ATLAS_SIZE: int = 1024

const SKIN_NAMES: Array[String] = [
	"Steel Syndicate", "Neon Vice", "Toxic Circuit", "Ember Cartel", "Cryo Authority"
]
const PALETTES: Array[Dictionary] = [
	{"accent":"65e8ff", "secondary":"f1c56d", "panel":"142333", "dark":"070b12", "text":"dcecff"},
	{"accent":"ff5dd8", "secondary":"9d74ff", "panel":"25152f", "dark":"08050d", "text":"ffe2fa"},
	{"accent":"a8ff4f", "secondary":"42e69b", "panel":"152a1b", "dark":"050b07", "text":"ecffd9"},
	{"accent":"ff8a3d", "secondary":"ff4f5e", "panel":"2b1912", "dark":"0e0604", "text":"fff0df"},
	{"accent":"4ec5ff", "secondary":"a8f2ff", "panel":"10263a", "dark":"040a10", "text":"e5fbff"}
]

const ITEM_IDS: Array[String] = [
	"room_backroom", "room_black_research", "room_weapons_workshop", "room_signal_den",
	"room_enforcer_gym", "room_sharpshooter_range", "room_chop_shop", "room_clinic",
	"room_bunks", "room_black_market", "room_tunnel", "room_boss_office",
	"threat_survey", "threat_patrol", "threat_cyber", "threat_riot",
	"resource_alloy", "resource_helium", "resource_cores",
	"defense_jammer", "defense_sentry", "defense_blast_doors", "defense_escape_tunnels",
	"mission_hidden", "mission_law_hack", "mission_syndicate_cipher", "mission_rescue",
	"crew_enforcer", "crew_runner", "crew_sharpshot", "crew_hacker", "station",
	"outpost", "rover", "drone", "cargo", "chat_galaxy", "chat_alliance", "chat_private", "score",
	"hideout", "operations", "save", "rotate", "zoom", "heal", "research", "weapons",
	"alert", "victory", "defeat", "shop", "inventory", "alliance", "hero", "prison",
	"cipher", "hidden_target", "construction", "power_core", "lock", "unlock", "moon_emblem", "skull"
]

var selected_skin: int = 0
var _atlas_cache: Dictionary = {}

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
	var cached: Variant = _atlas_cache.get(selected_skin)
	if cached is Texture2D:
		return cached as Texture2D
	var image: Image = Image.new()
	var load_error: Error = image.load_svg_from_string(_build_atlas_svg(), 1.0)
	if load_error != OK:
		push_error("Syndicate skin atlas could not be generated: %s" % error_string(load_error))
		return GradientTexture2D.new()
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_atlas_cache[selected_skin] = texture
	return texture

func region(item_id: String) -> Rect2:
	var index: int = ITEM_IDS.find(item_id)
	if index < 0:
		index = ITEM_IDS.size() - 1
	return Rect2(float(index % 8) * CELL, float(index / 8) * CELL, CELL, CELL)

func room_item(room_id: String) -> String:
	return "room_" + room_id

func crew_item(role_name: String) -> String:
	match role_name.to_lower():
		"runner": return "crew_runner"
		"sharpshot", "sharpshooter": return "crew_sharpshot"
		"hacker", "techie": return "crew_hacker"
		_: return "crew_enforcer"

func style_box(active: bool = false, radius: int = 10, alpha: float = 0.96) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var fill: Color = panel().lightened(0.10 if active else 0.0)
	fill.a = alpha
	style.bg_color = fill
	style.border_color = accent() if active else accent().darkened(0.42)
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(radius)
	return style

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

func _build_atlas_svg() -> String:
	var palette: Dictionary = PALETTES[selected_skin]
	var a: String = "#" + String(palette.get("accent", "65e8ff"))
	var b: String = "#" + String(palette.get("secondary", "f1c56d"))
	var p: String = "#" + String(palette.get("panel", "142333"))
	var d: String = "#" + String(palette.get("dark", "070b12"))
	var t: String = "#" + String(palette.get("text", "dcecff"))
	var parts: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='1024' height='1024' viewBox='0 0 1024 1024'>"]
	for index: int in range(ITEM_IDS.size()):
		var x: int = (index % 8) * CELL
		var y: int = int(index / 8) * CELL
		parts.append("<g transform='translate(%d %d)'>" % [x, y])
		parts.append("<rect x='7' y='7' width='114' height='114' rx='20' fill='%s' fill-opacity='.96' stroke='%s' stroke-width='3'/>" % [p, a])
		parts.append("<path d='M20 98 L36 114 H92 L108 98' fill='none' stroke='%s' stroke-width='3' opacity='.75'/>" % b)
		parts.append(_glyph_svg(index, a, b, d, t))
		parts.append("</g>")
	parts.append("</svg>")
	return "".join(parts)

func _glyph_svg(index: int, a: String, b: String, d: String, t: String) -> String:
	if index < 12:
		return _room_glyph(index, a, b, d, t)
	if index < 16:
		return _threat_glyph(index - 12, a, b, d)
	if index < 19:
		return _resource_glyph(index - 16, a, b, d, t)
	if index < 23:
		return _defense_glyph(index - 19, a, b, d)
	if index < 27:
		return _mission_glyph(index - 23, a, b, d)
	if index < 31:
		return _crew_glyph(index - 27, a, b, d)
	return _utility_glyph(index, a, b, d, t)

func _room_glyph(index: int, a: String, b: String, d: String, t: String) -> String:
	var roof: int = 22 + (index % 3) * 3
	var svg: String = "<path d='M24 52 L64 %d L104 52 V99 H24 Z' fill='%s' stroke='%s' stroke-width='3'/>" % [roof, d, a]
	svg += "<rect x='36' y='61' width='18' height='18' rx='3' fill='%s'/><rect x='74' y='61' width='18' height='18' rx='3' fill='%s'/>" % [b, a]
	match index:
		1, 3:
			svg += "<circle cx='64' cy='78' r='13' fill='none' stroke='%s' stroke-width='4'/><path d='M64 59 V97 M45 78 H83' stroke='%s' stroke-width='3'/>" % [b, a]
		2, 5:
			svg += "<path d='M39 91 L89 59 M43 60 L88 91' stroke='%s' stroke-width='5' stroke-linecap='round'/>" % b
		6:
			svg += "<circle cx='45' cy='91' r='10' fill='%s' stroke='%s' stroke-width='3'/><circle cx='84' cy='91' r='10' fill='%s' stroke='%s' stroke-width='3'/>" % [d, a, d, a]
		7:
			svg += "<path d='M58 52 H70 V68 H86 V80 H70 V96 H58 V80 H42 V68 H58 Z' fill='%s'/>" % b
		8:
			svg += "<path d='M36 60 H92 V76 H36 Z M36 82 H92 V98 H36 Z' fill='%s' opacity='.55'/>" % a
		9:
			svg += "<path d='M42 92 C42 62 86 62 86 92' fill='none' stroke='%s' stroke-width='5'/><circle cx='64' cy='70' r='7' fill='%s'/>" % [b, a]
		10:
			svg += "<path d='M34 98 Q64 42 94 98' fill='%s' stroke='%s' stroke-width='4'/><path d='M48 98 Q64 70 80 98' fill='%s' opacity='.5'/>" % [d, b, a]
		11:
			svg += "<circle cx='64' cy='72' r='18' fill='%s' fill-opacity='.28' stroke='%s' stroke-width='3'/><path d='M50 95 H78 L84 104 H44 Z' fill='%s'/>" % [b, b, a]
		_:
			svg += "<circle cx='64' cy='82' r='8' fill='%s'/>" % t
	return svg

func _threat_glyph(index: int, a: String, b: String, d: String) -> String:
	match index:
		0: return "<path d='M35 65 L64 42 L93 65 L84 94 H44 Z' fill='%s' stroke='%s' stroke-width='4'/><circle cx='64' cy='69' r='12' fill='%s'/><path d='M24 59 H42 M86 59 H104' stroke='%s' stroke-width='4'/>" % [d, a, a, b]
		1: return "<circle cx='64' cy='45' r='19' fill='%s' stroke='%s' stroke-width='4'/><rect x='38' y='64' width='52' height='43' rx='10' fill='%s' stroke='%s' stroke-width='4'/><rect x='47' y='45' width='34' height='9' rx='4' fill='%s'/>" % [d, a, d, a, b]
		2: return "<rect x='33' y='41' width='24' height='24' rx='5' fill='%s'/><rect x='71' y='41' width='24' height='24' rx='5' fill='%s'/><rect x='33' y='79' width='24' height='24' rx='5' fill='%s'/><rect x='71' y='79' width='24' height='24' rx='5' fill='%s'/><path d='M45 53 L83 91 M83 53 L45 91' stroke='%s' stroke-width='3'/>" % [a, b, b, a, a]
		_: return "<path d='M31 41 H97 V100 H31 Z' fill='%s' stroke='%s' stroke-width='5'/><path d='M42 55 H86 M42 70 H86 M42 85 H86' stroke='%s' stroke-width='6'/>" % [d, b, a]

func _resource_glyph(index: int, a: String, b: String, d: String, t: String) -> String:
	match index:
		0: return "<path d='M30 92 L47 43 L73 34 L99 88 L80 105 H43 Z' fill='%s' fill-opacity='.55' stroke='%s' stroke-width='4'/><path d='M47 43 L64 87 L73 34' stroke='%s' stroke-width='3'/>" % [a, b, t]
		1: return "<rect x='36' y='39' width='56' height='64' rx='12' fill='%s' stroke='%s' stroke-width='4'/><rect x='43' y='31' width='42' height='15' rx='5' fill='%s'/><path d='M48 65 H80 M48 80 H80' stroke='%s' stroke-width='4'/>" % [d, a, b, a]
		_: return "<rect x='35' y='35' width='58' height='58' rx='13' fill='%s' stroke='%s' stroke-width='5' transform='rotate(45 64 64)'/><circle cx='64' cy='64' r='17' fill='%s' fill-opacity='.4' stroke='%s' stroke-width='4'/>" % [d, a, a, b]

func _defense_glyph(index: int, a: String, b: String, d: String) -> String:
	match index:
		0: return "<path d='M64 31 V99 M42 52 Q64 31 86 52 M34 66 Q64 38 94 66' fill='none' stroke='%s' stroke-width='5'/><circle cx='64' cy='96' r='9' fill='%s'/>" % [a, b]
		1: return "<rect x='46' y='50' width='36' height='43' rx='6' fill='%s' stroke='%s' stroke-width='4'/><path d='M64 50 V34 M51 34 H77 M82 62 L104 52' stroke='%s' stroke-width='5'/>" % [d, a, b]
		2: return "<path d='M34 33 H94 V103 H34 Z' fill='%s' stroke='%s' stroke-width='5'/><path d='M49 33 V103 M79 33 V103' stroke='%s' stroke-width='5'/>" % [d, b, a]
		_: return "<path d='M27 98 Q64 29 101 98' fill='%s' stroke='%s' stroke-width='5'/><path d='M45 98 Q64 61 83 98' fill='%s' fill-opacity='.55'/>" % [d, a, b]

func _mission_glyph(index: int, a: String, b: String, d: String) -> String:
	match index:
		0: return "<circle cx='64' cy='64' r='34' fill='%s' stroke='%s' stroke-width='4'/><path d='M45 74 Q64 48 83 74' fill='none' stroke='%s' stroke-width='5'/><circle cx='64' cy='53' r='7' fill='%s'/>" % [d, b, a, b]
		1: return "<rect x='33' y='36' width='62' height='56' rx='9' fill='%s' stroke='%s' stroke-width='4'/><path d='M43 52 H85 M43 65 H74 M43 78 H88' stroke='%s' stroke-width='4'/><path d='M81 72 L101 92' stroke='%s' stroke-width='5'/>" % [d, a, b, a]
		2: return "<circle cx='64' cy='64' r='35' fill='%s' stroke='%s' stroke-width='4'/><path d='M38 64 H90 M64 38 V90 M45 45 L83 83 M83 45 L45 83' stroke='%s' stroke-width='4'/>" % [d, a, b]
		_: return "<rect x='42' y='48' width='44' height='53' rx='8' fill='%s' stroke='%s' stroke-width='4'/><circle cx='64' cy='45' r='16' fill='%s' stroke='%s' stroke-width='4'/><path d='M31 95 L48 78 M97 95 L80 78' stroke='%s' stroke-width='5'/>" % [d, a, d, b, b]

func _crew_glyph(index: int, a: String, b: String, d: String) -> String:
	var svg: String = "<circle cx='64' cy='47' r='22' fill='%s' stroke='%s' stroke-width='4'/><path d='M31 105 Q34 72 64 72 Q94 72 97 105' fill='%s' stroke='%s' stroke-width='4'/>" % [d, a, d, b]
	match index:
		0: svg += "<path d='M46 50 H82' stroke='%s' stroke-width='6'/><path d='M42 88 H86' stroke='%s' stroke-width='7'/>" % [b, a]
		1: svg += "<path d='M48 51 H80 M38 92 L90 78' stroke='%s' stroke-width='5'/><circle cx='90' cy='78' r='7' fill='%s'/>" % [a, b]
		2: svg += "<path d='M43 52 L84 44 M36 92 L98 62' stroke='%s' stroke-width='5'/><circle cx='98' cy='62' r='5' fill='%s'/>" % [b, a]
		_: svg += "<path d='M46 51 H82' stroke='%s' stroke-width='5'/><rect x='48' y='82' width='32' height='21' rx='4' fill='%s' fill-opacity='.45' stroke='%s' stroke-width='2'/>" % [a, a, b]
	return svg

func _utility_glyph(index: int, a: String, b: String, d: String, t: String) -> String:
	match index:
		31: return "<path d='M25 60 H103 V82 H25 Z' fill='%s' stroke='%s' stroke-width='4'/><circle cx='64' cy='71' r='20' fill='%s' stroke='%s' stroke-width='4'/><path d='M64 40 V102 M13 71 H115' stroke='%s' stroke-width='4'/>" % [d, a, d, b, a]
		32, 40: return "<path d='M26 96 L42 45 L64 31 L86 45 L102 96 Z' fill='%s' stroke='%s' stroke-width='4'/><rect x='50' y='66' width='28' height='30' fill='%s' fill-opacity='.45'/>" % [d, a, b]
		33: return "<rect x='30' y='57' width='68' height='30' rx='8' fill='%s' stroke='%s' stroke-width='4'/><circle cx='45' cy='93' r='10' fill='%s' stroke='%s' stroke-width='3'/><circle cx='83' cy='93' r='10' fill='%s' stroke='%s' stroke-width='3'/>" % [d, a, d, b, d, b]
		34: return "<circle cx='64' cy='64' r='16' fill='%s' fill-opacity='.5' stroke='%s' stroke-width='4'/><path d='M24 64 H48 M80 64 H104 M64 24 V48 M64 80 V104' stroke='%s' stroke-width='4'/>" % [a, b, a]
		35: return "<path d='M29 49 H99 V99 H29 Z' fill='%s' stroke='%s' stroke-width='4'/><path d='M29 64 H99 M47 49 V99 M81 49 V99' stroke='%s' stroke-width='3'/>" % [d, a, b]
		36, 37, 38: return "<path d='M29 40 H99 V83 H60 L45 99 V83 H29 Z' fill='%s' stroke='%s' stroke-width='4'/><circle cx='48' cy='61' r='5' fill='%s'/><circle cx='64' cy='61' r='5' fill='%s'/><circle cx='80' cy='61' r='5' fill='%s'/>" % [d, a, b, a, b]
		39: return "<circle cx='64' cy='64' r='35' fill='%s' stroke='%s' stroke-width='4'/><path d='M42 77 L55 61 L67 71 L87 45' fill='none' stroke='%s' stroke-width='6'/><circle cx='87' cy='45' r='7' fill='%s'/>" % [d, a, b, a]
		41: return "<path d='M28 96 L42 43 H86 L100 96 Z' fill='%s' stroke='%s' stroke-width='4'/><circle cx='64' cy='69' r='20' fill='none' stroke='%s' stroke-width='4'/><path d='M64 49 V89 M44 69 H84' stroke='%s' stroke-width='4'/>" % [d, a, b, a]
		42: return "<rect x='34' y='32' width='60' height='72' rx='7' fill='%s' stroke='%s' stroke-width='4'/><rect x='45' y='38' width='38' height='22' fill='%s'/><circle cx='64' cy='84' r='11' fill='%s'/>" % [d, a, b, a]
		43: return "<path d='M35 46 A36 36 0 1 1 36 84' fill='none' stroke='%s' stroke-width='7'/><path d='M27 45 L48 39 L42 61 Z' fill='%s'/>" % [a, b]
		44: return "<circle cx='56' cy='57' r='26' fill='none' stroke='%s' stroke-width='5'/><path d='M75 76 L101 102 M56 45 V69 M44 57 H68' stroke='%s' stroke-width='6'/>" % [a, b]
		45: return "<path d='M56 31 H72 V55 H96 V71 H72 V95 H56 V71 H32 V55 H56 Z' fill='%s' stroke='%s' stroke-width='3'/>" % [a, b]
		46: return "<circle cx='64' cy='64' r='30' fill='%s' stroke='%s' stroke-width='4'/><circle cx='64' cy='64' r='12' fill='%s'/><path d='M64 28 V42 M64 86 V100 M28 64 H42 M86 64 H100' stroke='%s' stroke-width='5'/>" % [d, a, b, b]
		47: return "<path d='M28 86 L92 46 M38 42 L99 83' stroke='%s' stroke-width='8' stroke-linecap='round'/><circle cx='64' cy='64' r='13' fill='%s'/>" % [a, b]
		48: return "<path d='M64 26 L104 101 H24 Z' fill='%s' stroke='%s' stroke-width='5'/><path d='M64 48 V77' stroke='%s' stroke-width='7'/><circle cx='64' cy='90' r='5' fill='%s'/>" % [d, a, b, b]
		49: return "<path d='M30 72 L52 93 L99 39' fill='none' stroke='%s' stroke-width='10' stroke-linecap='round' stroke-linejoin='round'/>" % a
		50: return "<path d='M34 34 L94 94 M94 34 L34 94' stroke='%s' stroke-width='10' stroke-linecap='round'/>" % b
		51, 52: return "<path d='M31 46 H97 L88 95 H40 Z' fill='%s' stroke='%s' stroke-width='4'/><path d='M45 46 Q64 22 83 46' fill='none' stroke='%s' stroke-width='4'/>" % [d, a, b]
		53, 54: return "<circle cx='50' cy='50' r='17' fill='%s' stroke='%s' stroke-width='4'/><circle cx='80' cy='50' r='17' fill='%s' stroke='%s' stroke-width='4'/><path d='M28 101 Q32 73 52 73 M100 101 Q96 73 76 73' fill='none' stroke='%s' stroke-width='5'/>" % [d, a, d, b, a]
		55: return "<rect x='28' y='32' width='72' height='72' rx='8' fill='%s' stroke='%s' stroke-width='4'/><path d='M42 32 V104 M58 32 V104 M74 32 V104 M90 32 V104' stroke='%s' stroke-width='4'/>" % [d, a, b]
		56: return "<path d='M35 42 H93 V98 H35 Z' fill='%s' stroke='%s' stroke-width='4'/><path d='M45 55 H82 M45 68 H74 M45 81 H88' stroke='%s' stroke-width='4'/>" % [d, a, b]
		57: return "<circle cx='64' cy='64' r='37' fill='none' stroke='%s' stroke-width='4'/><circle cx='64' cy='64' r='22' fill='none' stroke='%s' stroke-width='4'/><circle cx='64' cy='64' r='7' fill='%s'/>" % [a, b, a]
		58: return "<path d='M30 97 H98 M39 97 V63 H89 V97 M48 63 V40 H80 V63' fill='none' stroke='%s' stroke-width='5'/><path d='M32 40 H96' stroke='%s' stroke-width='6'/>" % [a, b]
		59: return "<circle cx='64' cy='64' r='34' fill='%s' stroke='%s' stroke-width='5'/><path d='M70 30 L46 68 H63 L58 99 L84 58 H67 Z' fill='%s'/>" % [d, a, b]
		60, 61: return "<rect x='38' y='57' width='52' height='45' rx='8' fill='%s' stroke='%s' stroke-width='4'/><path d='M48 57 V48 Q48 29 64 29 Q80 29 80 48 V57' fill='none' stroke='%s' stroke-width='5'/>" % [d, a, b]
		62: return "<circle cx='64' cy='64' r='38' fill='%s' fill-opacity='.25' stroke='%s' stroke-width='4'/><path d='M43 37 Q72 44 79 70 Q64 90 38 81 Q29 57 43 37 Z' fill='%s' fill-opacity='.55'/>" % [a, a, b]
		_: return "<path d='M38 48 Q64 24 90 48 V80 Q80 104 64 105 Q48 104 38 80 Z' fill='%s' stroke='%s' stroke-width='4'/><circle cx='52' cy='65' r='7' fill='%s'/><circle cx='76' cy='65' r='7' fill='%s'/><path d='M52 87 H76' stroke='%s' stroke-width='5'/>" % [d, a, b, b, a]
