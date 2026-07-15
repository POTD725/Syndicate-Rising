extends Node2D
## Rich lunar hideout scene with a movable, zoomable, quarter-turn camera.

const VIEW: Vector2 = Vector2(720.0, 1280.0)
const WORLD_VIEW: Rect2 = Rect2(0.0, 96.0, 720.0, 874.0)
const CAMERA_PIVOT: Vector2 = Vector2(360.0, 535.0)
const EMBLEM: Texture2D = preload("res://assets/syndicate_emblem.svg")
const SURFACE_ART: Texture2D = preload("res://assets/hideout/lunar_surface_panorama.svg")
const HIDEOUT_ART: Texture2D = preload("res://assets/hideout/lunar_hideout_cutaway.svg")
const STATION_ART: Texture2D = preload("res://assets/hideout/peacekeeper_orbital_station.svg")
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
	"weapons_workshop": "Build weapons, armor, breaching gear, and illegal equipment for the crew.",
	"signal_den": "Train hackers, crack police encryption, and poison the station surveillance feed.",
	"enforcer_gym": "Harden heavy crew for room defense, raids, intimidation, and close combat.",
	"sharpshooter_range": "Calibrate lunar rifles and train ranged specialists for surgical strikes.",
	"chop_shop": "Maintain rovers, courier bikes, getaway craft, and disguised cargo haulers.",
	"clinic": "Heal wounded crew and install dangerous black-market enhancements.",
	"bunks": "House the crew, shorten recovery time, and keep morale from collapsing.",
	"black_market": "Fence contraband, buy rare equipment, and convert stolen cargo into credits.",
	"tunnel": "Launch smuggler skiffs through concealed shafts beyond the station patrol arc.",
	"boss_office": "Expand influence, crew capacity, and control over the lunar underworld."
}

var room_rects: Dictionary = {}
var button_rects: Dictionary = {}
var selected_room: String = "backroom"
var message: String = "Drag the hideout to pan. Use +/- to zoom and ROTATE to turn the view."
var elapsed: float = 0.0
var tick_clock: float = 0.0

var camera_offset: Vector2 = Vector2.ZERO
var target_camera_offset: Vector2 = Vector2.ZERO
var camera_zoom: float = 1.0
var target_camera_zoom: float = 1.0
var camera_rotation: float = 0.0
var target_camera_rotation: float = 0.0
var rotation_quadrant: int = 0
var dragging: bool = false
var drag_distance: float = 0.0
var pointer_start: Vector2 = Vector2.ZERO

func _ready() -> void:
	for index: int in range(ROOM_IDS.size()):
		var column: int = index % 2
		var row: int = int(index / 2)
		var room_x: float = -339.0 if column == 0 else 34.0
		room_rects[ROOM_IDS[index]] = Rect2(room_x, -78.0 + float(row) * 85.0, 305.0, 75.0)
	button_rects = {
		"sound": Rect2(626.0, 10.0, 76.0, 30.0),
		"load": Rect2(626.0, 48.0, 76.0, 30.0),
		"zoom_out": Rect2(429.0, 104.0, 38.0, 38.0),
		"zoom_in": Rect2(471.0, 104.0, 38.0, 38.0),
		"rotate": Rect2(513.0, 104.0, 88.0, 38.0),
		"center": Rect2(605.0, 104.0, 97.0, 38.0),
		"room_action": Rect2(471.0, 1062.0, 106.0, 56.0),
		"room_operation": Rect2(585.0, 1062.0, 117.0, 56.0),
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
	var ease: float = 1.0 - exp(-10.0 * delta)
	camera_offset = camera_offset.lerp(target_camera_offset, ease)
	camera_zoom = lerpf(camera_zoom, target_camera_zoom, ease)
	camera_rotation = lerp_angle(camera_rotation, target_camera_rotation, 1.0 - exp(-8.0 * delta))
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed and WORLD_VIEW.has_point(mouse.position):
			_zoom_camera(1.12)
			return
		if mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed and WORLD_VIEW.has_point(mouse.position):
			_zoom_camera(0.89)
			return
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_begin_pointer(mouse.position)
			else:
				_finish_pointer(mouse.position)
			return
	if event is InputEventMouseMotion and dragging:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_pan_by(motion.relative)
			return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_begin_pointer(touch.position)
		else:
			_finish_pointer(touch.position)
		return
	if event is InputEventScreenDrag and dragging:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		_pan_by(drag.relative)
		return
	if event is InputEventMagnifyGesture:
		var magnify: InputEventMagnifyGesture = event as InputEventMagnifyGesture
		_zoom_camera(magnify.factor)

func _begin_pointer(pos: Vector2) -> void:
	if _handle_ui_press(pos):
		return
	if WORLD_VIEW.has_point(pos):
		dragging = true
		drag_distance = 0.0
		pointer_start = pos

func _finish_pointer(pos: Vector2) -> void:
	if not dragging:
		return
	dragging = false
	if drag_distance <= 10.0 and WORLD_VIEW.has_point(pos):
		_select_room_at(_screen_to_world(pos))

func _pan_by(relative: Vector2) -> void:
	drag_distance += relative.length()
	target_camera_offset += relative
	target_camera_offset.x = clampf(target_camera_offset.x, -300.0, 300.0)
	target_camera_offset.y = clampf(target_camera_offset.y, -260.0, 260.0)

func _handle_ui_press(pos: Vector2) -> bool:
	for key: Variant in button_rects.keys():
		var rect: Rect2 = button_rects[key] as Rect2
		if rect.has_point(pos):
			_action(String(key))
			return true
	return false

func _select_room_at(world_pos: Vector2) -> void:
	for key: Variant in room_rects.keys():
		var rect: Rect2 = room_rects[key] as Rect2
		if rect.has_point(world_pos):
			selected_room = String(key)
			var room: Dictionary = SyndicateState.get_room(selected_room)
			message = "%s selected." % String(room.get("name", "Room"))
			SyndicateAudio.play_sfx("click")
			return

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var translated: Vector2 = screen_pos - CAMERA_PIVOT - camera_offset
	translated /= camera_zoom
	return translated.rotated(-camera_rotation)

func _zoom_camera(factor: float) -> void:
	target_camera_zoom = clampf(target_camera_zoom * factor, 0.58, 1.75)
	message = "Camera zoom %d%%." % int(round(target_camera_zoom * 100.0))

func _action(action: String) -> void:
	var result: Dictionary = {}
	match action:
		"zoom_out":
			_zoom_camera(0.84)
			return
		"zoom_in":
			_zoom_camera(1.18)
			return
		"rotate":
			rotation_quadrant = (rotation_quadrant + 1) % 4
			target_camera_rotation = float(rotation_quadrant) * PI * 0.5
			if rotation_quadrant % 2 == 1 and target_camera_zoom > 0.88:
				target_camera_zoom = 0.88
			message = "View rotated to %d degrees." % (rotation_quadrant * 90)
			SyndicateAudio.play_sfx("click")
			return
		"center":
			target_camera_offset = Vector2.ZERO
			target_camera_zoom = 1.0 if rotation_quadrant % 2 == 0 else 0.88
			message = "Camera recentered."
			SyndicateAudio.play_sfx("click")
			return
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
			return
		"market":
			selected_room = "black_market"
			message = "Black Market selected."
			return
		"hideout":
			selected_room = "backroom"
			message = "Syndicate Command selected."
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
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("040812"))
	draw_set_transform(CAMERA_PIVOT + camera_offset, camera_rotation, Vector2(camera_zoom, camera_zoom))
	_draw_world()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_fixed_interface()

func _draw_world() -> void:
	_draw_deep_space()
	_draw_orbiting_station()
	draw_texture_rect(SURFACE_ART, Rect2(-500.0, -315.0, 1000.0, 292.0), false)
	_draw_surface_activity()
	draw_texture_rect(HIDEOUT_ART, Rect2(-350.0, -95.0, 700.0, 540.0), false)
	_draw_room_states()
	_draw_crew_activity()
	_draw_ambient_effects()

func _draw_deep_space() -> void:
	draw_rect(Rect2(-900.0, -700.0, 1800.0, 1500.0), Color("050b16"), true)
	for index: int in range(150):
		var x: float = -820.0 + fmod(float(index * 127 + 41), 1640.0)
		var y: float = -620.0 + fmod(float(index * 79 + 29), 730.0)
		var radius: float = 0.7 + float(index % 4) * 0.45
		draw_circle(Vector2(x, y), radius, Color(0.72, 0.86, 1.0, 0.22 + float(index % 3) * 0.13))
	draw_circle(Vector2(410.0, -430.0), 116.0, Color("15243d"))
	draw_circle(Vector2(378.0, -458.0), 82.0, Color("263d60"))
	draw_circle(Vector2(355.0, -482.0), 13.0, Color("0c1628", 0.75))
	draw_circle(Vector2(423.0, -418.0), 19.0, Color("101b2d", 0.72))

func _draw_orbiting_station() -> void:
	var phase: float = fmod(elapsed * 0.13, TAU)
	var station_pos: Vector2 = Vector2(cos(phase) * 305.0, -435.0 + sin(phase) * 62.0)
	draw_arc(Vector2(0.0, -435.0), 310.0, 0.12, PI - 0.12, 72, Color(0.35, 0.61, 0.86, 0.16), 2.0, true)
	if SyndicateState.heat >= 25:
		var scan_x: float = sin(elapsed * 0.6) * 260.0
		var alpha: float = clampf(0.08 + float(SyndicateState.heat) / 250.0, 0.08, 0.48)
		var cone: PackedVector2Array = PackedVector2Array([
			station_pos + Vector2(-18.0, 28.0),
			station_pos + Vector2(18.0, 28.0),
			Vector2(scan_x + 92.0, -18.0),
			Vector2(scan_x - 92.0, -18.0)
		])
		draw_colored_polygon(cone, Color(0.3, 0.82, 1.0, alpha))
	draw_texture_rect(STATION_ART, Rect2(station_pos - Vector2(112.0, 50.0), Vector2(224.0, 100.0)), false)

func _draw_surface_activity() -> void:
	var rover_x: float = -410.0 + fmod(elapsed * 34.0, 820.0)
	draw_rect(Rect2(rover_x - 20.0, -78.0, 40.0, 13.0), Color("314b61"), true)
	draw_rect(Rect2(rover_x - 9.0, -88.0, 21.0, 11.0), Color("7b4f70"), true)
	draw_circle(Vector2(rover_x - 13.0, -63.0), 7.0, Color("070b11"))
	draw_circle(Vector2(rover_x + 13.0, -63.0), 7.0, Color("070b11"))
	draw_circle(Vector2(rover_x + 14.0, -83.0), 2.5, Color("6feaff"))
	for index: int in range(4):
		var drone_x: float = -300.0 + fmod(elapsed * (19.0 + float(index) * 3.0) + float(index) * 178.0, 600.0)
		var drone_y: float = -160.0 + sin(elapsed * 1.4 + float(index)) * 18.0
		draw_circle(Vector2(drone_x, drone_y), 5.0, Color("d9e6ee"))
		draw_line(Vector2(drone_x - 9.0, drone_y), Vector2(drone_x + 9.0, drone_y), Color("65eaff"), 2.0)

func _draw_room_states() -> void:
	for room_id: String in ROOM_IDS:
		var room: Dictionary = SyndicateState.get_room(room_id)
		if room.is_empty():
			continue
		var rect: Rect2 = room_rects[room_id] as Rect2
		var repaired: bool = bool(room.get("repaired", false))
		var selected: bool = room_id == selected_room
		if not repaired:
			draw_rect(rect, Color(0.08, 0.03, 0.05, 0.62), true)
			for slash: int in range(5):
				var sx: float = rect.position.x + 18.0 + float(slash) * 61.0
				draw_line(Vector2(sx, rect.position.y + 8.0), Vector2(sx + 42.0, rect.end.y - 8.0), Color(1.0, 0.35, 0.4, 0.38), 2.0)
		var border: Color = Color("ffd36f") if selected else (Color("67ead9") if repaired else Color("9b4f5e"))
		draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), border, 4 if selected else 2, 8), rect)
		draw_rect(Rect2(rect.position + Vector2(5.0, 55.0), Vector2(rect.size.x - 10.0, 15.0)), Color(0.025, 0.045, 0.07, 0.88), true)
		var name_text: String = String(room.get("name", "ROOM")).to_upper()
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 67.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, 208.0, 8, Color("f2f7ff"))
		var status: String = "L%d" % int(room.get("level", 1)) if repaired else "DAMAGED"
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(217.0, 67.0), status, HORIZONTAL_ALIGNMENT_RIGHT, 78.0, 8, Color("73f0da") if repaired else Color("ff9a88"))

func _draw_crew_activity() -> void:
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var phase: float = fmod(elapsed * (0.095 + float(index) * 0.014) + float(index) * 0.21, 1.0)
		var direction: float = 1.0 if index % 2 == 0 else -1.0
		var y: float = -45.0 + phase * 455.0
		var x: float = -8.0 + direction * 12.0
		var texture: Texture2D = PORTRAITS[String(member.get("id", "crew_1"))] as Texture2D
		draw_texture_rect(texture, Rect2(Vector2(x - 14.0, y - 14.0), Vector2(28.0, 28.0)), false)
		draw_circle(Vector2(x, y + 16.0), 3.5, Color("64f0cc") if SyndicateState.crew_available(member) else Color("ff708c"))
	for index: int in range(6):
		var spark_y: float = -60.0 + fmod(elapsed * (31.0 + float(index) * 4.0) + float(index) * 83.0, 490.0)
		var spark_x: float = sin(elapsed * 2.0 + float(index)) * 18.0
		draw_circle(Vector2(spark_x, spark_y), 2.2, Color(0.45, 0.92, 1.0, 0.75))

func _draw_ambient_effects() -> void:
	for index: int in range(8):
		var px: float = -320.0 + fmod(elapsed * (8.0 + float(index)) + float(index) * 101.0, 640.0)
		var py: float = -10.0 + sin(elapsed * 0.7 + float(index)) * 410.0
		draw_circle(Vector2(px, py), 1.6, Color(0.58, 0.83, 1.0, 0.18))

func _draw_fixed_interface() -> void:
	_draw_header()
	_draw_camera_controls()
	_draw_inspector()
	_draw_navigation()

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 96.0), Color("08111f", 0.99), true)
	draw_line(Vector2(0.0, 96.0), Vector2(VIEW.x, 96.0), Color("5fe3ff", 0.6), 2.0)
	draw_texture_rect(EMBLEM, Rect2(10.0, 10.0, 70.0, 70.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 34.0), "MOONGOONS: SYNDICATE RISING", HORIZONTAL_ALIGNMENT_LEFT, 430.0, 21, Color("f5fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 59.0), "LUNAR HIDEOUT  •  CHAPTER %d  •  NOTORIETY %d" % [SyndicateState.story_chapter, SyndicateState.notoriety], HORIZONTAL_ALIGNMENT_LEFT, 470.0, 10, Color("bd9bff"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 81.0), "CR %d   CARGO %d   INTEL %d   HEAT %d   TECH L%d" % [SyndicateState.credits, SyndicateState.contraband, SyndicateState.intel, SyndicateState.heat, SyndicateState.black_tech_level], HORIZONTAL_ALIGNMENT_LEFT, 530.0, 10, Color("72efd5"))
	_draw_button(button_rects["sound"] as Rect2, "MUTE" if not SyndicateAudio.muted else "AUDIO", false, 8)
	_draw_button(button_rects["load"] as Rect2, "LOAD", false, 8)

func _draw_camera_controls() -> void:
	draw_rect(Rect2(0.0, 96.0, VIEW.x, 52.0), Color(0.025, 0.055, 0.09, 0.92), true)
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 119.0), "DRAG TO PAN  •  WHEEL OR +/- TO ZOOM  •  VIEW %d°  •  %d%%" % [rotation_quadrant * 90, int(round(camera_zoom * 100.0))], HORIZONTAL_ALIGNMENT_LEFT, 402.0, 9, Color("bdd4e8"))
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 138.0), "PEACEKEEPER THREAT: %s" % _threat_label(), HORIZONTAL_ALIGNMENT_LEFT, 390.0, 9, Color("ffb57d") if SyndicateState.heat >= 45 else Color("79ead6"))
	_draw_button(button_rects["zoom_out"] as Rect2, "−", false, 16)
	_draw_button(button_rects["zoom_in"] as Rect2, "+", false, 16)
	_draw_button(button_rects["rotate"] as Rect2, "ROTATE", true, 8)
	_draw_button(button_rects["center"] as Rect2, "CENTER", false, 8)

func _draw_inspector() -> void:
	draw_rect(Rect2(0.0, 970.0, VIEW.x, 190.0), Color("060d17", 0.995), true)
	draw_line(Vector2(0.0, 970.0), Vector2(VIEW.x, 970.0), Color("69839b"), 2.0)
	var panel_rect: Rect2 = Rect2(18.0, 982.0, 684.0, 166.0)
	draw_style_box(_panel(Color("0a1421"), Color("6f879e"), 2, 12), panel_rect)
	var room: Dictionary = SyndicateState.get_room(selected_room)
	if room.is_empty():
		return
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1010.0), String(room.get("name", "Room")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 420.0, 18, Color("f5f8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1034.0), "%s  •  LEVEL %d  •  EQUIPMENT MK %d" % [String(room.get("function", "")), int(room.get("level", 1)), int(room.get("project_level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 635.0, 10, Color("70ead5"))
	draw_multiline_string(ThemeDB.fallback_font, Vector2(34.0, 1058.0), String(ROOM_DESCRIPTIONS.get(selected_room, "Syndicate room.")), HORIZONTAL_ALIGNMENT_LEFT, 420.0, 10, 2, Color("c6d1df"))
	var repaired: bool = bool(room.get("repaired", false))
	var action_label: String = "UPGRADE" if repaired else "REBUILD"
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1128.0), message, HORIZONTAL_ALIGNMENT_LEFT, 430.0, 9, Color("aec0d2"))
	_draw_button(button_rects["room_action"] as Rect2, action_label, true, 9)
	_draw_button(button_rects["room_operation"] as Rect2, SyndicateState.room_operation_label(selected_room), repaired, 8)

func _draw_navigation() -> void:
	draw_rect(Rect2(0.0, 1160.0, VIEW.x, 120.0), Color("050a12"), true)
	_draw_nav_button(button_rects["hideout"] as Rect2, "HIDEOUT", "BASE", selected_room == "backroom")
	_draw_nav_button(button_rects["scores"] as Rect2, "SCORES", "MISSIONS", false)
	_draw_nav_button(button_rects["research"] as Rect2, "RESEARCH", "BLACK TECH", selected_room == "black_research")
	_draw_nav_button(button_rects["market"] as Rect2, "MARKET", "CARGO", selected_room == "black_market")
	_draw_nav_button(button_rects["save"] as Rect2, "SAVE", "OPERATION", false)

func _draw_nav_button(rect: Rect2, title: String, subtitle: String, active: bool) -> void:
	draw_style_box(_panel(Color("183149") if active else Color("101a28"), Color("61e5e1") if active else Color("53677d"), 2 if active else 1, 10), rect)
	draw_circle(rect.position + Vector2(rect.size.x * 0.5, 26.0), 12.0, Color(0.4, 0.93, 0.9, 0.3) if active else Color(0.4, 0.45, 0.52, 0.18))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 59.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 11, Color("f5f9ff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 78.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 8, Color("8fa7bd"))

func _threat_label() -> String:
	if SyndicateState.heat >= 75:
		return "RAID IMMINENT"
	if SyndicateState.heat >= 45:
		return "ACTIVE ORBITAL SCAN"
	if SyndicateState.heat >= 20:
		return "PATROL WATCH"
	return "LOW PROFILE"

func _draw_button(rect: Rect2, label: String, active: bool, font_size: int) -> void:
	draw_style_box(_panel(Color("24516a") if active else Color("152333"), Color("6cf0e1") if active else Color("526b80"), 2 if active else 1, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, rect.size.y * 0.61), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, font_size, Color("f3f8ff"))

func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
