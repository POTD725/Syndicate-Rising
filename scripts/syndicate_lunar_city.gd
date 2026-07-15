extends Node2D
## Living lunar hideout management screen for MoonGoons: Syndicate Rising.

const VIEW: Vector2 = Vector2(720.0, 1280.0)
const EMBLEM: Texture2D = preload("res://assets/syndicate_emblem.svg")
const PORTRAITS: Dictionary = {
	"crew_1": preload("res://assets/portraits/nyx_raze.svg"),
	"crew_2": preload("res://assets/portraits/vox_13.svg"),
	"crew_3": preload("res://assets/portraits/cinder_quell.svg"),
	"crew_4": preload("res://assets/portraits/grit_mercer.svg")
}
const ROOM_IDS: Array[String] = [
	"backroom", "black_research",
	"weapons_workshop", "signal_den",
	"enforcer_gym", "sharpshooter_range",
	"chop_shop", "clinic",
	"bunks", "black_market",
	"tunnel", "boss_office"
]
const ROOM_DESCRIPTIONS: Dictionary = {
	"backroom": "Coordinate lunar scores, spoof orbital scans, and keep the Syndicate hidden beneath the crater.",
	"black_research": "Reverse-engineer stolen Peacekeeper hardware and unlock Black Tech upgrades.",
	"weapons_workshop": "Build original weapons, armor, breaching gear, and illegal equipment for the crew.",
	"signal_den": "Train hackers, crack police encryption, and poison the station's surveillance feed.",
	"enforcer_gym": "Harden heavy crew for room defense, raids, intimidation, and close combat.",
	"sharpshooter_range": "Calibrate lunar rifles and train ranged specialists for surgical strikes.",
	"chop_shop": "Maintain rovers, courier bikes, getaway craft, and disguised cargo haulers.",
	"clinic": "Heal wounded crew and install dangerous black-market enhancements.",
	"bunks": "House the crew, shorten recovery time, and keep morale from collapsing.",
	"black_market": "Fence contraband, buy rare equipment, and convert stolen cargo into credits.",
	"tunnel": "Launch smuggler skiffs through concealed shafts beyond the station's patrol arc.",
	"boss_office": "Expand influence, crew capacity, and control over the lunar underworld."
}

var room_rects: Dictionary = {}
var button_rects: Dictionary = {}
var selected_room: String = "backroom"
var message: String = "Tap a room inside the hideout to inspect it."
var elapsed: float = 0.0
var tick_clock: float = 0.0
var station_position: Vector2 = Vector2(360.0, 190.0)

func _ready() -> void:
	for index: int in range(ROOM_IDS.size()):
		var column: int = index % 2
		var row: int = int(index / 2)
		var x: float = 18.0 if column == 0 else 382.0
		room_rects[ROOM_IDS[index]] = Rect2(x, 348.0 + float(row) * 104.0, 320.0, 94.0)
	button_rects = {
		"room_action": Rect2(475.0, 1062.0, 102.0, 56.0),
		"room_operation": Rect2(585.0, 1062.0, 117.0, 56.0),
		"sound": Rect2(625.0, 12.0, 78.0, 32.0),
		"load": Rect2(625.0, 51.0, 78.0, 32.0),
		"hideout": Rect2(8.0, 1170.0, 134.0, 96.0),
		"scores": Rect2(150.0, 1170.0, 134.0, 96.0),
		"research": Rect2(292.0, 1170.0, 134.0, 96.0),
		"market": Rect2(434.0, 1170.0, 134.0, 96.0),
		"save": Rect2(576.0, 1170.0, 136.0, 96.0)
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
	for key: Variant in room_rects.keys():
		var rect: Rect2 = room_rects[key] as Rect2
		if rect.has_point(pos):
			selected_room = String(key)
			var room: Dictionary = SyndicateState.get_room(selected_room)
			message = "%s selected." % String(room.get("name", "Room"))
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
		"room_operation":
			result = SyndicateState.run_room_operation(selected_room)
			SyndicateAudio.play_sfx("special" if bool(result.get("ok", false)) else "warning")
		"scores":
			SyndicateAudio.play_sfx("accept")
			get_tree().change_scene_to_file("res://scenes/SyndicateScores.tscn")
			return
		"research":
			selected_room = "black_research"
			message = "Black Research Lab selected."
			SyndicateAudio.play_sfx("click")
			return
		"market":
			selected_room = "black_market"
			message = "Black Market selected."
			SyndicateAudio.play_sfx("click")
			return
		"hideout":
			selected_room = "backroom"
			message = "Syndicate Command selected."
			SyndicateAudio.play_sfx("click")
			return
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
	_draw_space_and_moon()
	_draw_header()
	_draw_orbiting_station()
	_draw_lunar_surface()
	_draw_hideout_shell()
	_draw_rooms()
	_draw_corridor_activity()
	_draw_inspector()
	_draw_navigation()

func _draw_space_and_moon() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("050913"))
	for index: int in range(96):
		var x: float = fmod(float(index * 83 + 29), VIEW.x)
		var y: float = 92.0 + fmod(float(index * 47 + 17), 205.0)
		var radius: float = 0.7 + float(index % 4) * 0.35
		draw_circle(Vector2(x, y), radius, Color("b9d8ff", 0.28 + float(index % 3) * 0.12))
	draw_circle(Vector2(622.0, 162.0), 76.0, Color("17233d"))
	draw_circle(Vector2(602.0, 143.0), 55.0, Color("243557"))
	draw_circle(Vector2(581.0, 126.0), 8.0, Color("405275", 0.7))
	draw_circle(Vector2(624.0, 173.0), 12.0, Color("0e182b", 0.7))

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 96.0), Color("0a101d", 0.98), true)
	draw_line(Vector2(0.0, 96.0), Vector2(VIEW.x, 96.0), Color("5fe3ff", 0.55), 2.0)
	draw_texture_rect(EMBLEM, Rect2(10.0, 10.0, 70.0, 70.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 35.0), "MOONGOONS: SYNDICATE RISING", HORIZONTAL_ALIGNMENT_LEFT, 400.0, 22, Color("f4fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 61.0), "LUNAR HIDEOUT  •  CHAPTER %d  •  NOTORIETY %d" % [SyndicateState.story_chapter, SyndicateState.notoriety], HORIZONTAL_ALIGNMENT_LEFT, 470.0, 11, Color("b995ff"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 82.0), "CR %d   CARGO %d   INTEL %d   HEAT %d" % [SyndicateState.credits, SyndicateState.contraband, SyndicateState.intel, SyndicateState.heat], HORIZONTAL_ALIGNMENT_LEFT, 520.0, 11, Color("75efd5"))
	_draw_button(button_rects["sound"] as Rect2, "MUTE" if not SyndicateAudio.muted else "AUDIO", false, 9)
	_draw_button(button_rects["load"] as Rect2, "LOAD", false, 9)

func _draw_orbiting_station() -> void:
	var phase: float = fmod(elapsed * 0.16, TAU)
	station_position = Vector2(360.0 + cos(phase) * 245.0, 193.0 + sin(phase) * 42.0)
	draw_arc(Vector2(360.0, 193.0), 248.0, PI + 0.22, TAU - 0.22, 72, Color("5f8fd1", 0.18), 1.5, true)
	if SyndicateState.heat >= 30:
		var scan_alpha: float = clampf(0.08 + float(SyndicateState.heat) / 260.0, 0.08, 0.46)
		var scan_center: float = 360.0 + sin(elapsed * 0.7) * 215.0
		var cone: PackedVector2Array = PackedVector2Array([
			station_position + Vector2(-12.0, 22.0),
			station_position + Vector2(12.0, 22.0),
			Vector2(scan_center + 70.0, 324.0),
			Vector2(scan_center - 70.0, 324.0)
		])
		draw_colored_polygon(cone, Color(0.32, 0.82, 1.0, scan_alpha))
	var body: Rect2 = Rect2(station_position - Vector2(61.0, 18.0), Vector2(122.0, 36.0))
	draw_rect(Rect2(body.position - Vector2(62.0, -8.0), Vector2(54.0, 20.0)), Color("263d62"), true)
	draw_rect(Rect2(body.end + Vector2(8.0, -28.0), Vector2(54.0, 20.0)), Color("263d62"), true)
	draw_line(station_position - Vector2(69.0, 0.0), station_position + Vector2(69.0, 0.0), Color("81d9ff"), 5.0)
	draw_style_box(_panel(Color("18283f"), Color("85dcff"), 2, 12), body)
	draw_circle(station_position, 22.0, Color("253d5d"))
	draw_circle(station_position, 12.0, Color("71e8ff", 0.55))
	draw_line(station_position + Vector2(0.0, -18.0), station_position + Vector2(0.0, -43.0), Color("d9efff"), 3.0)
	draw_circle(station_position + Vector2(0.0, -45.0), 4.0, Color("ff6f88"))
	for light_index: int in range(5):
		var lx: float = body.position.x + 18.0 + float(light_index) * 22.0
		draw_circle(Vector2(lx, body.position.y + 26.0), 2.4, Color("ffcf6e") if light_index % 2 == 0 else Color("66e6ff"))
	draw_string(ThemeDB.fallback_font, station_position + Vector2(-88.0, -31.0), "PEACEKEEPER ORBITAL STATION", HORIZONTAL_ALIGNMENT_CENTER, 176.0, 8, Color("d7ebff", 0.88))

func _draw_lunar_surface() -> void:
	var surface: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 316.0), Vector2(64.0, 301.0), Vector2(128.0, 314.0), Vector2(198.0, 293.0),
		Vector2(271.0, 309.0), Vector2(347.0, 285.0), Vector2(424.0, 309.0), Vector2(505.0, 297.0),
		Vector2(583.0, 314.0), Vector2(654.0, 296.0), Vector2(720.0, 310.0), Vector2(720.0, 350.0), Vector2(0.0, 350.0)
	])
	draw_colored_polygon(surface, Color("3e4654"))
	draw_polyline(surface, Color("8c96a8"), 2.0, true)
	for crater_x: float in [74.0, 244.0, 531.0, 664.0]:
		draw_arc(Vector2(crater_x, 321.0), 22.0, PI, TAU, 18, Color("1e2631"), 4.0)
	_draw_surface_outpost(Vector2(102.0, 280.0))
	_draw_surface_outpost(Vector2(590.0, 277.0))
	draw_line(Vector2(354.0, 289.0), Vector2(354.0, 247.0), Color("91dfff"), 3.0)
	draw_line(Vector2(346.0, 256.0), Vector2(362.0, 256.0), Color("91dfff"), 2.0)
	draw_circle(Vector2(354.0, 245.0), 4.0, Color("ff6f88"))
	draw_string(ThemeDB.fallback_font, Vector2(18.0, 340.0), "CRATER NINE // HIDEOUT DEPTH 41M // ORBITAL THREAT %s" % _threat_label(), HORIZONTAL_ALIGNMENT_LEFT, 684.0, 9, Color("d2d9e5"))

func _draw_surface_outpost(origin: Vector2) -> void:
	draw_rect(Rect2(origin + Vector2(-28.0, 10.0), Vector2(56.0, 26.0)), Color("202a38"), true)
	draw_arc(origin + Vector2(0.0, 10.0), 28.0, PI, TAU, 24, Color("6c7d96"), 5.0)
	draw_rect(Rect2(origin + Vector2(-7.0, -30.0), Vector2(14.0, 38.0)), Color("33465d"), true)
	draw_circle(origin + Vector2(0.0, -34.0), 5.0, Color("6beaff"))

func _draw_hideout_shell() -> void:
	draw_rect(Rect2(0.0, 350.0, VIEW.x, 626.0), Color("171b25"), true)
	for index: int in range(28):
		var rock_x: float = fmod(float(index * 113 + 31), VIEW.x)
		var rock_y: float = 357.0 + fmod(float(index * 67 + 19), 610.0)
		draw_circle(Vector2(rock_x, rock_y), 9.0 + float(index % 5) * 4.0, Color("242a36", 0.58))
	draw_style_box(_panel(Color("0a111c"), Color("546275"), 3, 12), Rect2(10.0, 340.0, 700.0, 632.0))
	draw_rect(Rect2(340.0, 348.0, 40.0, 614.0), Color("172838"), true)
	draw_line(Vector2(340.0, 348.0), Vector2(340.0, 962.0), Color("6c8198"), 2.0)
	draw_line(Vector2(380.0, 348.0), Vector2(380.0, 962.0), Color("6c8198"), 2.0)
	for floor_index: int in range(7):
		var y: float = 344.0 + float(floor_index) * 104.0
		draw_line(Vector2(12.0, y), Vector2(708.0, y), Color("485568", 0.65), 2.0)
	_draw_power_core(Vector2(360.0, 645.0))

func _draw_rooms() -> void:
	for room_id: String in ROOM_IDS:
		var room: Dictionary = SyndicateState.get_room(room_id)
		if room.is_empty():
			continue
		var rect: Rect2 = room_rects[room_id] as Rect2
		_draw_room(room_id, room, rect)

func _draw_room(room_id: String, room: Dictionary, rect: Rect2) -> void:
	var selected: bool = room_id == selected_room
	var repaired: bool = bool(room.get("repaired", false))
	var border: Color = Color("f9d16e") if selected else (Color("5bded1") if repaired else Color("8b4e58"))
	draw_style_box(_panel(Color("0d1722"), border, 3 if selected else 1, 7), rect)
	var interior: Rect2 = Rect2(rect.position + Vector2(5.0, 5.0), Vector2(rect.size.x - 10.0, 64.0))
	draw_rect(interior, Color("142536"), true)
	draw_rect(Rect2(interior.position + Vector2(0.0, 48.0), Vector2(interior.size.x, 16.0)), Color("263445"), true)
	for panel_index: int in range(4):
		var px: float = interior.position.x + 12.0 + float(panel_index) * 72.0
		draw_rect(Rect2(px, interior.position.y + 7.0, 56.0, 35.0), Color("17202c"), true)
		draw_line(Vector2(px + 4.0, interior.position.y + 13.0), Vector2(px + 48.0, interior.position.y + 13.0), Color("38536b"), 1.0)
	_draw_room_equipment(room_id, interior)
	_draw_room_door(rect, room_id)
	if not repaired:
		draw_rect(interior, Color("090c12", 0.64), true)
		draw_line(interior.position + Vector2(28.0, 6.0), interior.position + Vector2(86.0, 56.0), Color("ff7a78", 0.7), 3.0)
		draw_line(interior.position + Vector2(82.0, 10.0), interior.position + Vector2(44.0, 52.0), Color("ff7a78", 0.55), 2.0)
	var name_text: String = String(room.get("name", "ROOM")).to_upper()
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 80.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, 224.0, 10, Color("f1f6ff"))
	var status: String = "ONLINE L%d" % int(room.get("level", 1))
	if not repaired:
		status = "REBUILD %ds" % SyndicateState.seconds_left(int(room.get("repair_end", 0))) if int(room.get("repair_end", 0)) > 0 else "%d CR" % int(room.get("repair_cost", 0))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(220.0, 80.0), status, HORIZONTAL_ALIGNMENT_RIGHT, 92.0, 8, Color("6ff0d5") if repaired else Color("ff9c7d"))

func _draw_room_equipment(room_id: String, rect: Rect2) -> void:
	var p: Vector2 = rect.position
	match room_id:
		"backroom":
			draw_circle(p + Vector2(157.0, 42.0), 23.0, Color("0b1520"))
			draw_arc(p + Vector2(157.0, 42.0), 18.0, 0.0, TAU, 28, Color("6aeaff"), 3.0)
			draw_line(p + Vector2(138.0, 42.0), p + Vector2(176.0, 42.0), Color("ffcd73"), 2.0)
			_draw_terminal(p + Vector2(32.0, 15.0), Color("60ddff"))
			_draw_terminal(p + Vector2(236.0, 15.0), Color("ff739e"))
		"black_research":
			for index: int in range(3):
				var cx: float = 72.0 + float(index) * 82.0
				draw_rect(Rect2(p + Vector2(cx, 9.0), Vector2(38.0, 43.0)), Color("0c1f26"), true)
				draw_circle(p + Vector2(cx + 19.0, 30.0), 13.0, Color("6bf7d1", 0.35))
				draw_circle(p + Vector2(cx + 19.0, 30.0), 5.0 + float(index), Color("b7fff0", 0.85))
		"weapons_workshop":
			for index: int in range(4):
				var y: float = 13.0 + float(index) * 10.0
				draw_line(p + Vector2(32.0, y), p + Vector2(128.0, y + 3.0), Color("e8edf5"), 3.0)
			draw_rect(Rect2(p + Vector2(182.0, 15.0), Vector2(88.0, 32.0)), Color("40272c"), true)
			draw_circle(p + Vector2(226.0, 31.0), 12.0, Color("ff8d56", 0.78))
		"signal_den":
			for index: int in range(3):
				_draw_terminal(p + Vector2(32.0 + float(index) * 88.0, 11.0), Color("71e7ff") if index != 1 else Color("ff6eb4"))
				draw_string(ThemeDB.fallback_font, p + Vector2(40.0 + float(index) * 88.0, 49.0), "0101", HORIZONTAL_ALIGNMENT_LEFT, 42.0, 7, Color("7bffd9"))
		"enforcer_gym":
			draw_line(p + Vector2(40.0, 18.0), p + Vector2(40.0, 52.0), Color("b5c4d8"), 4.0)
			draw_circle(p + Vector2(40.0, 47.0), 13.0, Color("7d2537"))
			draw_line(p + Vector2(116.0, 38.0), p + Vector2(205.0, 38.0), Color("d6dbe3"), 6.0)
			draw_circle(p + Vector2(112.0, 38.0), 12.0, Color("35475a"))
			draw_circle(p + Vector2(209.0, 38.0), 12.0, Color("35475a"))
		"sharpshooter_range":
			for index: int in range(3):
				var cx: float = 70.0 + float(index) * 86.0
				draw_circle(p + Vector2(cx, 27.0), 18.0, Color("f5efe2"))
				draw_circle(p + Vector2(cx, 27.0), 11.0, Color("d43e52"))
				draw_circle(p + Vector2(cx, 27.0), 4.0, Color("fff7cc"))
			draw_line(p + Vector2(54.0, 53.0), p + Vector2(254.0, 53.0), Color("9bb3c8"), 4.0)
		"chop_shop":
			draw_rect(Rect2(p + Vector2(58.0, 27.0), Vector2(194.0, 21.0)), Color("344b5e"), true)
			draw_circle(p + Vector2(91.0, 50.0), 11.0, Color("10151d"))
			draw_circle(p + Vector2(219.0, 50.0), 11.0, Color("10151d"))
			draw_rect(Rect2(p + Vector2(112.0, 12.0), Vector2(82.0, 20.0)), Color("5e324e"), true)
		"clinic":
			draw_rect(Rect2(p + Vector2(42.0, 22.0), Vector2(122.0, 30.0)), Color("d9e9ed"), true)
			draw_rect(Rect2(p + Vector2(91.0, 14.0), Vector2(24.0, 46.0)), Color("62e8d0"), true)
			draw_rect(Rect2(p + Vector2(80.0, 25.0), Vector2(46.0, 24.0)), Color("62e8d0"), true)
			_draw_terminal(p + Vector2(222.0, 13.0), Color("74e6ff"))
		"bunks":
			for index: int in range(3):
				var bx: float = 27.0 + float(index) * 94.0
				draw_rect(Rect2(p + Vector2(bx, 13.0), Vector2(72.0, 15.0)), Color("576779"), true)
				draw_rect(Rect2(p + Vector2(bx, 37.0), Vector2(72.0, 15.0)), Color("576779"), true)
				draw_circle(p + Vector2(bx + 9.0, 20.0), 5.0, Color("ffcf9a"))
		"black_market":
			for row: int in range(2):
				for column: int in range(4):
					var cpos: Vector2 = p + Vector2(32.0 + float(column) * 66.0, 10.0 + float(row) * 26.0)
					_draw_crate(cpos, Color("8a5942") if (row + column) % 2 == 0 else Color("3c6773"))
		"tunnel":
			draw_arc(p + Vector2(158.0, 56.0), 92.0, PI, TAU, 32, Color("74879b"), 8.0)
			draw_rect(Rect2(p + Vector2(70.0, 35.0), Vector2(176.0, 24.0)), Color("1b2b3c"), true)
			draw_line(p + Vector2(86.0, 47.0), p + Vector2(232.0, 47.0), Color("6ee7ff"), 3.0)
		"boss_office":
			draw_rect(Rect2(p + Vector2(74.0, 30.0), Vector2(168.0, 24.0)), Color("503044"), true)
			draw_circle(p + Vector2(158.0, 19.0), 14.0, Color("e2c478"))
			draw_texture_rect(EMBLEM, Rect2(p + Vector2(145.0, 6.0), Vector2(26.0, 26.0)), false)
			draw_rect(Rect2(p + Vector2(20.0, 11.0), Vector2(42.0, 42.0)), Color("22384d"), true)
			draw_rect(Rect2(p + Vector2(256.0, 11.0), Vector2(42.0, 42.0)), Color("22384d"), true)

func _draw_room_door(rect: Rect2, room_id: String) -> void:
	var is_left: bool = ROOM_IDS.find(room_id) % 2 == 0
	var door_x: float = rect.end.x - 5.0 if is_left else rect.position.x - 11.0
	var door: Rect2 = Rect2(door_x, rect.position.y + 31.0, 16.0, 34.0)
	draw_rect(door, Color("27384a"), true)
	draw_line(door.position + Vector2(3.0, 5.0), door.position + Vector2(3.0, 29.0), Color("72eaff"), 2.0)
	draw_circle(door.position + Vector2(11.0, 17.0), 2.0, Color("ffcc68"))

func _draw_corridor_activity() -> void:
	for floor_index: int in range(6):
		var y: float = 393.0 + float(floor_index) * 104.0
		draw_circle(Vector2(360.0, y), 3.0, Color("62e6ff", 0.55))
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var lane: float = 350.0 + float(index % 2) * 20.0
		var phase: float = fmod(elapsed * (0.085 + float(index) * 0.012) + float(index) * 0.19, 1.0)
		var y: float = 370.0 + abs(sin(phase * PI)) * 555.0
		var texture: Texture2D = PORTRAITS[String(member.get("id", "crew_1"))] as Texture2D
		draw_texture_rect(texture, Rect2(Vector2(lane - 12.0, y - 12.0), Vector2(24.0, 24.0)), false)
		draw_circle(Vector2(lane, y + 14.0), 3.0, Color("64f0cc") if SyndicateState.crew_available(member) else Color("ff708c"))
	for drone_index: int in range(3):
		var drone_y: float = 378.0 + fmod(elapsed * (28.0 + float(drone_index) * 7.0) + float(drone_index) * 179.0, 530.0)
		var drone_x: float = 360.0 + sin(elapsed * 1.8 + float(drone_index)) * 9.0
		draw_circle(Vector2(drone_x, drone_y), 5.0, Color("c8d4df"))
		draw_line(Vector2(drone_x - 8.0, drone_y), Vector2(drone_x + 8.0, drone_y), Color("64e6ff"), 2.0)

func _draw_power_core(center: Vector2) -> void:
	draw_circle(center, 18.0, Color("122436"))
	draw_arc(center, 16.0, 0.0, TAU, 24, Color("64e9ff"), 3.0)
	draw_arc(center, 10.0, elapsed, elapsed + PI * 1.4, 18, Color("ff6fad"), 3.0)
	draw_circle(center, 4.0, Color("fff0a8"))

func _draw_inspector() -> void:
	var panel_rect: Rect2 = Rect2(18.0, 980.0, 684.0, 174.0)
	draw_style_box(_panel(Color("0a111d", 0.99), Color("778ba2"), 2, 12), panel_rect)
	var room: Dictionary = SyndicateState.get_room(selected_room)
	if room.is_empty():
		return
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1010.0), String(room.get("name", "Room")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 420.0, 18, Color("f4f7ff"))
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1034.0), "%s  •  LEVEL %d  •  EQUIPMENT MK %d" % [String(room.get("function", "")), int(room.get("level", 1)), int(room.get("project_level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 632.0, 10, Color("70ead5"))
	draw_multiline_string(ThemeDB.fallback_font, Vector2(34.0, 1058.0), String(ROOM_DESCRIPTIONS.get(selected_room, "Syndicate room.")), HORIZONTAL_ALIGNMENT_LEFT, 420.0, 11, 2, Color("c4cedc"))
	var repaired: bool = bool(room.get("repaired", false))
	var status: String = "ONLINE" if repaired else "DAMAGED"
	var action_label: String = "UPGRADE" if repaired else "REBUILD"
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1128.0), "%s // %s" % [status, message], HORIZONTAL_ALIGNMENT_LEFT, 430.0, 9, Color("ffca7a") if not repaired else Color("a9c0d8"))
	_draw_button(button_rects["room_action"] as Rect2, action_label, true, 9)
	_draw_button(button_rects["room_operation"] as Rect2, SyndicateState.room_operation_label(selected_room), repaired, 8)

func _draw_navigation() -> void:
	_draw_nav_button(button_rects["hideout"] as Rect2, "HIDEOUT", "BASE", selected_room == "backroom")
	_draw_nav_button(button_rects["scores"] as Rect2, "SCORES", "MISSIONS", false)
	_draw_nav_button(button_rects["research"] as Rect2, "RESEARCH", "BLACK TECH", selected_room == "black_research")
	_draw_nav_button(button_rects["market"] as Rect2, "MARKET", "CARGO", selected_room == "black_market")
	_draw_nav_button(button_rects["save"] as Rect2, "SAVE", "OPERATION", false)

func _draw_nav_button(rect: Rect2, title: String, subtitle: String, active: bool) -> void:
	draw_style_box(_panel(Color("183149") if active else Color("101a28"), Color("61e5e1") if active else Color("53677d"), 2 if active else 1, 10), rect)
	draw_circle(rect.position + Vector2(rect.size.x * 0.5, 26.0), 12.0, Color("67e6e1", 0.28) if active else Color("6a7484", 0.18))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 59.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 11, Color("f5f9ff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 78.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 8, Color("8fa7bd"))

func _draw_terminal(origin: Vector2, glow: Color) -> void:
	draw_rect(Rect2(origin, Vector2(54.0, 31.0)), Color("0a111a"), true)
	draw_rect(Rect2(origin + Vector2(4.0, 4.0), Vector2(46.0, 19.0)), Color(glow, 0.32), true)
	draw_line(origin + Vector2(8.0, 10.0), origin + Vector2(42.0, 10.0), glow, 2.0)
	draw_line(origin + Vector2(8.0, 16.0), origin + Vector2(31.0, 16.0), glow, 2.0)
	draw_line(origin + Vector2(27.0, 31.0), origin + Vector2(27.0, 39.0), Color("7b8795"), 3.0)

func _draw_crate(origin: Vector2, color: Color) -> void:
	draw_rect(Rect2(origin, Vector2(48.0, 20.0)), color, true)
	draw_line(origin + Vector2(4.0, 4.0), origin + Vector2(44.0, 16.0), Color("d1b38d", 0.6), 2.0)
	draw_line(origin + Vector2(44.0, 4.0), origin + Vector2(4.0, 16.0), Color("d1b38d", 0.6), 2.0)

func _threat_label() -> String:
	if SyndicateState.heat >= 75:
		return "RAID IMMINENT"
	if SyndicateState.heat >= 45:
		return "ACTIVE SCAN"
	if SyndicateState.heat >= 20:
		return "PATROL WATCH"
	return "LOW PROFILE"

func _draw_button(rect: Rect2, label: String, active: bool, font_size: int) -> void:
	draw_style_box(_panel(Color("24516a") if active else Color("152333"), Color("6cf0e1") if active else Color("526b80"), 2 if active else 1, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, rect.size.y * 0.59), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, font_size, Color("f3f8ff"))

func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
