extends Node2D
## Portrait criminal-city management screen.

const VIEW: Vector2 = Vector2(720.0, 1280.0)
const EMBLEM: Texture2D = preload("res://assets/syndicate_emblem.svg")
const BUILDINGS: Dictionary = {
	"backroom": preload("res://assets/buildings/backroom_command.svg"),
	"chop_shop": preload("res://assets/buildings/chop_shop.svg"),
	"black_market": preload("res://assets/buildings/black_market.svg"),
	"bunks": preload("res://assets/buildings/safehouse_bunks.svg"),
	"clinic": preload("res://assets/buildings/street_clinic.svg"),
	"boss_office": preload("res://assets/buildings/boss_office.svg"),
	"signal_den": preload("res://assets/buildings/signal_den.svg"),
	"tunnel": preload("res://assets/buildings/smuggler_tunnel.svg")
}
const PORTRAITS: Dictionary = {
	"crew_1": preload("res://assets/portraits/nyx_raze.svg"),
	"crew_2": preload("res://assets/portraits/vox_13.svg"),
	"crew_3": preload("res://assets/portraits/cinder_quell.svg"),
	"crew_4": preload("res://assets/portraits/grit_mercer.svg")
}

var building_rects: Dictionary = {}
var button_rects: Dictionary = {}
var selected_room: String = "backroom"
var message: String = "Tap a building to inspect it."
var elapsed: float = 0.0
var tick_clock: float = 0.0

func _ready() -> void:
	var ids: Array[String] = ["backroom", "chop_shop", "black_market", "bunks", "clinic", "boss_office", "signal_den", "tunnel"]
	for index: int in range(ids.size()):
		var column: int = index % 2
		var row: int = int(index / 2)
		building_rects[ids[index]] = Rect2(18.0 + float(column) * 351.0, 146.0 + float(row) * 194.0, 333.0, 180.0)
	button_rects = {
		"room_action": Rect2(500.0, 1055.0, 190.0, 64.0),
		"scores": Rect2(15.0, 1184.0, 126.0, 70.0),
		"tech": Rect2(156.0, 1184.0, 126.0, 70.0),
		"fence": Rect2(297.0, 1184.0, 126.0, 70.0),
		"save": Rect2(438.0, 1184.0, 126.0, 70.0),
		"load": Rect2(579.0, 1184.0, 126.0, 70.0),
		"sound": Rect2(615.0, 92.0, 85.0, 38.0)
	}
	SyndicateState.tick()
	if not SyndicateState.intro_seen and SyndicateState.pending_cutscene == "prologue":
		get_tree().call_deferred("change_scene_to_file", "res://scenes/SyndicateCutscene.tscn")
		return
	SyndicateAudio.play_music("city")
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	tick_clock += delta
	if tick_clock >= 0.25:
		tick_clock = 0.0
		SyndicateState.tick()
	queue_redraw()

func _input(event: InputEvent) -> void:
	var pos: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		pos = mouse.position
		pressed = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		pos = touch.position
		pressed = touch.pressed
	if not pressed:
		return
	for key: Variant in building_rects.keys():
		var rect: Rect2 = building_rects[key] as Rect2
		if rect.has_point(pos):
			selected_room = String(key)
			var room: Dictionary = SyndicateState.get_room(selected_room)
			message = "%s selected." % String(room.get("name", "Building"))
			SyndicateAudio.play_sfx("click")
			return
	for key: Variant in button_rects.keys():
		var button: Rect2 = button_rects[key] as Rect2
		if button.has_point(pos):
			_action(String(key))
			return

func _action(action: String) -> void:
	var result: Dictionary = {}
	match action:
		"room_action":
			result = SyndicateState.repair_or_upgrade_room(selected_room)
			SyndicateAudio.play_sfx("repair" if bool(result.get("ok", false)) else "warning")
		"scores":
			SyndicateAudio.play_sfx("accept")
			get_tree().change_scene_to_file("res://scenes/SyndicateScores.tscn")
			return
		"tech":
			result = SyndicateState.begin_black_tech()
			SyndicateAudio.play_sfx("special" if bool(result.get("ok", false)) else "warning")
		"fence":
			result = SyndicateState.fence_contraband()
			SyndicateAudio.play_sfx("accept" if bool(result.get("ok", false)) else "warning")
		"save":
			result = SyndicateState.save_game()
			SyndicateAudio.play_sfx("accept")
		"load":
			result = SyndicateState.load_game()
			SyndicateAudio.play_sfx("accept" if bool(result.get("ok", false)) else "warning")
		"sound":
			var muted: bool = SyndicateAudio.toggle_muted()
			message = "Audio muted." if muted else "Audio restored."
			return
	if not result.is_empty():
		message = String(result.get("message", "Action complete."))

func _draw() -> void:
	_draw_background()
	_draw_header()
	_draw_buildings()
	_draw_crew_activity()
	_draw_inspector()
	_draw_navigation()

func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("07030d"))
	for index: int in range(120):
		var x: float = fmod(float(index * 97 + 23), VIEW.x)
		var y: float = fmod(float(index * 61 + 41), VIEW.y)
		draw_circle(Vector2(x, y), 0.8 + float(index % 3) * 0.45, Color("c9a9ff", 0.16))
	for row: int in range(5):
		var line_y: float = 130.0 + float(row) * 194.0
		draw_line(Vector2(0.0, line_y), Vector2(VIEW.x, line_y), Color("bb69ef", 0.10), 1.0)

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 136.0), Color("160c20", 0.98), true)
	draw_texture_rect(EMBLEM, Rect2(18.0, 14.0, 94.0, 94.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(124.0, 42.0), "MOONGOONS", HORIZONTAL_ALIGNMENT_LEFT, 330.0, 26, Color("fff4fb"))
	draw_string(ThemeDB.fallback_font, Vector2(124.0, 72.0), "SYNDICATE RISING", HORIZONTAL_ALIGNMENT_LEFT, 350.0, 20, Color("ff74ad"))
	draw_string(ThemeDB.fallback_font, Vector2(124.0, 101.0), "CHAPTER %d  •  NOTORIETY %d" % [SyndicateState.story_chapter, SyndicateState.notoriety], HORIZONTAL_ALIGNMENT_LEFT, 360.0, 12, Color("c9a4db"))
	var stats: String = "CR %d   CARGO %d   INTEL %d" % [SyndicateState.credits, SyndicateState.contraband, SyndicateState.intel]
	draw_string(ThemeDB.fallback_font, Vector2(350.0, 40.0), stats, HORIZONTAL_ALIGNMENT_RIGHT, 340.0, 13, Color("f8dcff"))
	draw_string(ThemeDB.fallback_font, Vector2(350.0, 70.0), "HEAT %d   BLACK TECH L%d" % [SyndicateState.heat, SyndicateState.black_tech_level], HORIZONTAL_ALIGNMENT_RIGHT, 340.0, 12, Color("ffbf69"))
	var tech_text: String = "READY" if SyndicateState.black_tech_end <= 0 else "%ds" % SyndicateState.seconds_left(SyndicateState.black_tech_end)
	draw_string(ThemeDB.fallback_font, Vector2(350.0, 100.0), "RESEARCH %s" % tech_text, HORIZONTAL_ALIGNMENT_RIGHT, 245.0, 11, Color("84efd2"))
	_draw_button(button_rects["sound"] as Rect2, "AUDIO OFF" if SyndicateAudio.muted else "AUDIO ON", false)

func _draw_buildings() -> void:
	for room: Dictionary in SyndicateState.rooms:
		var id: String = String(room.get("id", ""))
		var rect: Rect2 = building_rects[id] as Rect2
		var selected: bool = id == selected_room
		var repaired: bool = bool(room.get("repaired", false))
		var border: Color = Color("fff3fb") if selected else (Color("c66dff") if repaired else Color("7a3b58"))
		draw_style_box(_panel(Color("190d21"), border, 3 if selected else 1, 12), rect)
		var art_rect: Rect2 = Rect2(rect.position + Vector2(5.0, 5.0), Vector2(rect.size.x - 10.0, 128.0))
		draw_texture_rect(BUILDINGS[id] as Texture2D, art_rect, false)
		if not repaired:
			draw_rect(art_rect, Color("100710", 0.58), true)
		draw_rect(Rect2(rect.position + Vector2(0.0, 133.0), Vector2(rect.size.x, 47.0)), Color("08060c", 0.93), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(9.0, 151.0), String(room.get("name", "BUILDING")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 240.0, 11, Color("fff4fb"))
		var state_text: String = "ONLINE L%d" % int(room.get("level", 1))
		if not repaired:
			state_text = "REBUILDING %ds" % SyndicateState.seconds_left(int(room.get("repair_end", 0))) if int(room.get("repair_end", 0)) > 0 else "WRECKED • %d CR" % int(room.get("repair_cost", 0))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(9.0, 169.0), "%s  •  %s" % [String(room.get("function", "")), state_text], HORIZONTAL_ALIGNMENT_LEFT, 310.0, 9, Color("71edcf") if repaired else Color("ff9a7d"))

func _draw_crew_activity() -> void:
	var path: Array[Vector2] = [Vector2(90.0, 310.0), Vector2(620.0, 310.0), Vector2(620.0, 690.0), Vector2(90.0, 690.0), Vector2(90.0, 310.0)]
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var phase: float = fmod(elapsed * (0.11 + float(index) * 0.015) + float(index) * 0.23, 1.0)
		var segment_float: float = phase * 4.0
		var segment: int = mini(3, int(segment_float))
		var local: float = segment_float - float(segment)
		var pos: Vector2 = path[segment].lerp(path[segment + 1], local)
		var texture: Texture2D = PORTRAITS[String(member.get("id", "crew_1"))] as Texture2D
		draw_texture_rect(texture, Rect2(pos - Vector2(23.0, 23.0), Vector2(46.0, 46.0)), false)
		draw_circle(pos + Vector2(0.0, 25.0), 5.0, Color("72f0c1") if SyndicateState.crew_available(member) else Color("ff6f91"))

func _draw_inspector() -> void:
	var panel_rect: Rect2 = Rect2(18.0, 934.0, 684.0, 232.0)
	draw_style_box(_panel(Color("140b1b", 0.98), Color("a75bd0"), 2, 14), panel_rect)
	var room: Dictionary = SyndicateState.get_room(selected_room)
	var preview: Rect2 = Rect2(30.0, 950.0, 246.0, 146.0)
	draw_texture_rect(BUILDINGS[selected_room] as Texture2D, preview, false)
	draw_string(ThemeDB.fallback_font, Vector2(294.0, 974.0), String(room.get("name", "Building")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 380.0, 19, Color("fff4fb"))
	draw_string(ThemeDB.fallback_font, Vector2(294.0, 1004.0), "%s • LEVEL %d" % [String(room.get("function", "")), int(room.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 380.0, 12, Color("ff8cbd"))
	var status: String = "ONLINE" if bool(room.get("repaired", false)) else "DAMAGED"
	draw_string(ThemeDB.fallback_font, Vector2(294.0, 1033.0), "%s  •  %s" % [status, SyndicateState.last_event], HORIZONTAL_ALIGNMENT_LEFT, 390.0, 10, Color("caa9bc"))
	var action_label: String = "UPGRADE" if bool(room.get("repaired", false)) else "REBUILD"
	_draw_button(button_rects["room_action"] as Rect2, action_label, true)
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 1145.0), message, HORIZONTAL_ALIGNMENT_LEFT, 650.0, 10, Color("e1bfd3"))

func _draw_navigation() -> void:
	draw_rect(Rect2(0.0, 1172.0, VIEW.x, 108.0), Color("0d0713", 0.98), true)
	_draw_button(button_rects["scores"] as Rect2, "SCORES", true)
	_draw_button(button_rects["tech"] as Rect2, "BLACK TECH", false)
	_draw_button(button_rects["fence"] as Rect2, "FENCE", false)
	_draw_button(button_rects["save"] as Rect2, "SAVE", false)
	_draw_button(button_rects["load"] as Rect2, "LOAD", false)

func _draw_button(rect: Rect2, label: String, active: bool) -> void:
	draw_style_box(_panel(Color("5a2149") if active else Color("311737"), Color("ff8fbc") if active else Color("87508f"), 2 if active else 1, 9), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, rect.size.y * 0.58), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 10, Color("fff4fb"))

func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
