extends "res://scripts/syndicate_feature_city.gd"
## Complete playable three-quarter isometric lunar district.

const ART: Script = preload("res://scripts/syndicate_full_art.gd")
const BOARD_RECT: Rect2 = Rect2(-512.0, -700.0, 1024.0, 1536.0)

var board_texture: Texture2D
var npc_atlas: Texture2D
var ui_atlas: Texture2D
var dermapack_texture: Texture2D
var panel_mode: String = "room"
var worker_jobs: Array[Dictionary] = []

func _ready() -> void:
	super._ready()
	board_texture = ART.board_texture()
	npc_atlas = ART.npc_atlas()
	ui_atlas = ART.ui_atlas()
	dermapack_texture = ART.dermapack_texture()
	_setup_full_hotspots()
	_setup_full_navigation()
	_setup_worker_jobs()
	button_rects["operations"] = Rect2(626.0, 674.0, 82.0, 74.0)
	button_rects["save"] = Rect2(626.0, 754.0, 82.0, 74.0)
	message = "Tap a building, drag to pan, or open the DermaPack."

func _setup_full_hotspots() -> void:
	room_rects = {
		"backroom": Rect2(-470.0, -225.0, 300.0, 260.0),
		"boss_office": Rect2(-165.0, -215.0, 245.0, 225.0),
		"black_research": Rect2(-145.0, -285.0, 300.0, 265.0),
		"weapons_workshop": Rect2(165.0, -185.0, 310.0, 270.0),
		"signal_den": Rect2(-495.0, 20.0, 305.0, 275.0),
		"clinic": Rect2(-165.0, 5.0, 305.0, 275.0),
		"chop_shop": Rect2(165.0, 70.0, 310.0, 275.0),
		"tunnel": Rect2(-497.0, 290.0, 305.0, 280.0),
		"black_market": Rect2(-165.0, 280.0, 315.0, 285.0),
		"sharpshooter_range": Rect2(165.0, 315.0, 310.0, 280.0),
		"enforcer_gym": Rect2(-345.0, 555.0, 335.0, 280.0),
		"bunks": Rect2(45.0, 575.0, 310.0, 250.0)
	}

func _setup_full_navigation() -> void:
	button_rects.erase("research")
	button_rects.erase("market")
	button_rects["scores"] = Rect2(4.0, 1166.0, 114.0, 108.0)
	button_rects["heroes"] = Rect2(122.0, 1166.0, 114.0, 108.0)
	button_rects["dermapack"] = Rect2(240.0, 1166.0, 122.0, 108.0)
	button_rects["store"] = Rect2(366.0, 1166.0, 110.0, 108.0)
	button_rects["chat"] = Rect2(480.0, 1166.0, 110.0, 108.0)
	button_rects["hideout"] = Rect2(594.0, 1166.0, 122.0, 108.0)

func _setup_worker_jobs() -> void:
	worker_jobs.clear()
	var job_names: Array[String] = [
		"Hack Authority relays", "Train intrusion scripts", "Spoof orbital scans", "Decode stolen research",
		"Analyze Black Tech", "Process data cores", "Guard Syndicate Command", "Drill breach response",
		"Escort contraband", "Calibrate lunar rifles", "Watch the landing road", "Cover the market",
		"Repair runner rovers", "Maintain the power grid", "Service blast doors", "Tune smuggler engines",
		"Treat wounded crew", "Prepare illegal implants", "Deliver clinic supplies", "Load smuggler cargo",
		"Fence contraband", "Run a market courier", "Prepare escape skiff", "Mine Lunar Alloy",
		"Harvest Helium-3", "Move equipment crates", "Inspect the road grid", "Maintain landing lights",
		"Restock crew quarters", "Patrol the crater gate", "Forge Authority permits", "Test hideout defenses"
	]
	var station_points: Array[Vector2] = [
		Vector2(-370.0, 110.0), Vector2(-280.0, 175.0), Vector2(-345.0, -70.0), Vector2(-55.0, -105.0),
		Vector2(55.0, -180.0), Vector2(350.0, 610.0), Vector2(-315.0, -85.0), Vector2(-210.0, 660.0),
		Vector2(-370.0, 420.0), Vector2(285.0, 455.0), Vector2(370.0, 330.0), Vector2(55.0, 405.0),
		Vector2(280.0, 165.0), Vector2(-20.0, 130.0), Vector2(-65.0, 545.0), Vector2(-355.0, 370.0),
		Vector2(-75.0, 105.0), Vector2(-110.0, 195.0), Vector2(-205.0, 250.0), Vector2(-380.0, 395.0),
		Vector2(-70.0, 410.0), Vector2(60.0, 485.0), Vector2(-325.0, 305.0), Vector2(-445.0, 605.0),
		Vector2(395.0, 5.0), Vector2(-210.0, 65.0), Vector2(-350.0, 255.0), Vector2(330.0, -65.0),
		Vector2(125.0, 655.0), Vector2(-100.0, 745.0), Vector2(-10.0, 340.0), Vector2(175.0, 245.0)
	]
	var route_offsets: Array[Vector2] = [
		Vector2(90.0, 45.0), Vector2(-105.0, -40.0), Vector2(100.0, 60.0), Vector2(115.0, -45.0),
		Vector2(-125.0, 70.0), Vector2(-70.0, -90.0), Vector2(125.0, 80.0), Vector2(145.0, 70.0)
	]
	for index: int in range(job_names.size()):
		var role_index: int = index % 8
		var start: Vector2 = station_points[index]
		var finish: Vector2 = start + route_offsets[role_index]
		worker_jobs.append({
			"role": role_index,
			"job": job_names[index],
			"department": _department_for_role(role_index),
			"a": start,
			"b": finish,
			"speed": 0.045 + float(index % 7) * 0.006,
			"offset": float(index) / float(job_names.size())
		})

func _department_for_role(role_index: int) -> String:
	var departments: Array[String] = ["Cyber", "Research", "Security", "Sharpshooter", "Engineering", "Medical", "Logistics", "Surface Ops"]
	return departments[posmod(role_index, departments.size())]

func _action(action: String) -> void:
	match action:
		"heroes":
			panel_mode = "heroes"
			message = "Hero roster opened. Named MoonGoons remain assigned to district jobs."
			SyndicateAudio.play_sfx("click")
			return
		"dermapack":
			panel_mode = "dermapack"
			message = "DermaPack wearable micro-storage opened."
			SyndicateAudio.play_sfx("click")
			return
		"store":
			panel_mode = "room"
			selected_room = "black_market"
			message = "Black Market selected."
			SyndicateAudio.play_sfx("click")
			return
		"hideout":
			panel_mode = "room"
			selected_room = "backroom"
			target_camera_offset = Vector2.ZERO
			message = "Syndicate State recentered."
			SyndicateAudio.play_sfx("click")
			return
		_:
			panel_mode = "room"
			super._action(action)

func _select_room_at(world_pos: Vector2) -> void:
	for room_id: String in ROOM_IDS:
		var rect: Rect2 = room_rects.get(room_id, Rect2()) as Rect2
		if rect.has_point(world_pos):
			selected_room = room_id
			panel_mode = "room"
			var room: Dictionary = SyndicateState.get_room(room_id)
			message = "%s selected." % String(room.get("name", "Room"))
			SyndicateAudio.play_sfx("click")
			return

func _draw_world() -> void:
	draw_rect(Rect2(-950.0, -760.0, 1900.0, 1700.0), Color("030711"), true)
	draw_texture_rect(board_texture, BOARD_RECT, false)
	_draw_room_states()
	_draw_workers()
	_draw_moving_traffic()
	_draw_heat_effects()

func _draw_room_states() -> void:
	for room_id: String in ROOM_IDS:
		var room: Dictionary = SyndicateState.get_room(room_id)
		if room.is_empty():
			continue
		var rect: Rect2 = room_rects.get(room_id, Rect2()) as Rect2
		var repaired: bool = bool(room.get("repaired", false))
		var selected: bool = room_id == selected_room and panel_mode == "room"
		if not repaired:
			draw_rect(rect, Color(0.18, 0.015, 0.03, 0.60), true)
			for slash: int in range(5):
				var sx: float = rect.position.x + 12.0 + float(slash) * rect.size.x / 5.2
				draw_line(Vector2(sx, rect.position.y + 8.0), Vector2(sx + 45.0, rect.end.y - 8.0), Color("ff6681"), 3.0)
		var border: Color = Color("ffd16a") if selected else (Color(0.31, 0.93, 0.78, 0.38) if repaired else Color("ff6681"))
		draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), border, 5 if selected else 2, 14), rect)
		if selected:
			var badge: Rect2 = Rect2(rect.position + Vector2(9.0, 9.0), Vector2(minf(166.0, rect.size.x - 18.0), 30.0))
			draw_style_box(_panel(Color(0.02, 0.035, 0.06, 0.95), border, 2, 9), badge)
			draw_string(ThemeDB.fallback_font, badge.position + Vector2(5.0, 21.0), "SELECTED • LEVEL %d" % int(room.get("level", 1)), HORIZONTAL_ALIGNMENT_CENTER, badge.size.x - 10.0, 9, Color("f7fbff"))

func _draw_workers() -> void:
	for index: int in range(worker_jobs.size()):
		var job: Dictionary = worker_jobs[index]
		var phase: float = fmod(elapsed * float(job["speed"]) + float(job["offset"]), 1.0)
		var travel: float = 0.5 - cos(phase * TAU) * 0.5
		var start: Vector2 = job["a"] as Vector2
		var finish: Vector2 = job["b"] as Vector2
		var position: Vector2 = start.lerp(finish, travel)
		var frame: int = int(floor(elapsed * 7.0 + float(index))) % 4
		var source: Rect2 = ART.npc_region(int(job["role"]), frame)
		draw_texture_rect_region(npc_atlas, Rect2(position - Vector2(18.0, 42.0), Vector2(36.0, 72.0)), source)
		_draw_job_effect(position, String(job["job"]), index)

func _draw_job_effect(position: Vector2, job_name: String, index: int) -> void:
	var pulse: float = 0.55 + sin(elapsed * 4.0 + float(index)) * 0.25
	if job_name.contains("Hack") or job_name.contains("Decode") or job_name.contains("Tech") or job_name.contains("data"):
		draw_circle(position + Vector2(0.0, -39.0), 5.0, Color(0.30, 0.91, 1.0, pulse))
		draw_arc(position + Vector2(0.0, -39.0), 10.0, 0.0, TAU, 16, Color(0.48, 0.35, 0.95, pulse), 2.0)
	elif job_name.contains("Repair") or job_name.contains("Maintain") or job_name.contains("Tune") or job_name.contains("Service"):
		for spark: int in range(3):
			var angle: float = elapsed * 4.0 + float(spark) * TAU / 3.0
			draw_line(position + Vector2(5.0, -24.0), position + Vector2(5.0, -24.0) + Vector2(cos(angle), sin(angle)) * 10.0, Color(1.0, 0.70, 0.25, pulse), 2.0)
	elif job_name.contains("Treat") or job_name.contains("clinic") or job_name.contains("implants"):
		draw_line(position + Vector2(-6.0, -35.0), position + Vector2(6.0, -35.0), Color(0.35, 0.95, 0.70, pulse), 3.0)
		draw_line(position + Vector2(0.0, -41.0), position + Vector2(0.0, -29.0), Color(0.35, 0.95, 0.70, pulse), 3.0)
	elif job_name.contains("Guard") or job_name.contains("Cover") or job_name.contains("Watch") or job_name.contains("Patrol"):
		draw_arc(position + Vector2(0.0, -30.0), 14.0, -2.8, -0.35, 16, Color(1.0, 0.38, 0.48, pulse), 2.0)
	elif job_name.contains("cargo") or job_name.contains("Contraband") or job_name.contains("Restock") or job_name.contains("crates"):
		draw_rect(Rect2(position + Vector2(-7.0, -27.0), Vector2(14.0, 10.0)), Color("8b5c3d"), true)

func _draw_moving_traffic() -> void:
	var rover_phase: float = fmod(elapsed * 0.045, 1.0)
	var rover: Vector2 = Vector2(-380.0, 250.0).lerp(Vector2(365.0, 350.0), rover_phase)
	draw_circle(rover, 11.0, Color("1a2b3a"))
	draw_rect(Rect2(rover - Vector2(15.0, 8.0), Vector2(30.0, 15.0)), Color("3d5a70"), true)
	draw_line(rover + Vector2(-13.0, 0.0), rover + Vector2(13.0, 0.0), Color("4ee7ff"), 3.0)
	var drone_phase: float = fmod(elapsed * 0.075, 1.0)
	var drone: Vector2 = Vector2(390.0, -105.0).lerp(Vector2(-390.0, 30.0), drone_phase)
	draw_circle(drone, 8.0, Color("29445a"))
	draw_circle(drone, 3.5, Color("4ee7ff"))
	draw_line(drone + Vector2(-15.0, 0.0), drone + Vector2(15.0, 0.0), Color("8c54d8"), 2.0)

func _draw_heat_effects() -> void:
	if SyndicateState.heat < 22:
		return
	var scan_x: float = sin(elapsed * 0.65) * 360.0
	var alpha: float = clampf(float(SyndicateState.heat) / 220.0, 0.10, 0.48)
	var cone: PackedVector2Array = PackedVector2Array([Vector2(scan_x - 30.0, -420.0), Vector2(scan_x + 30.0, -420.0), Vector2(scan_x + 190.0, 720.0), Vector2(scan_x - 190.0, 720.0)])
	draw_colored_polygon(cone, Color(0.25, 0.82, 1.0, alpha))
	if SyndicateState.heat >= 70:
		draw_string(ThemeDB.fallback_font, Vector2(-170.0, -330.0), "ORBITAL RAID WARNING", HORIZONTAL_ALIGNMENT_CENTER, 340.0, 22, Color("ff6681"))

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 96.0), Color("07101d", 0.99), true)
	draw_line(Vector2(0.0, 96.0), Vector2(VIEW.x, 96.0), Color("4ee7ff"), 2.0)
	draw_texture_rect(EMBLEM, Rect2(10.0, 10.0, 70.0, 70.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 31.0), "MOONGOONS: SYNDICATE RISING", HORIZONTAL_ALIGNMENT_LEFT, 420.0, 19, Color("f5fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 54.0), "CR %d  ALLOY %d  HE-3 %d  DATA %d" % [SyndicateState.credits, SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.data_cores], HORIZONTAL_ALIGNMENT_LEFT, 510.0, 9, Color("4ee7ff"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 77.0), "HEAT %d  TRUST %d  CAPTURED %d  TECH L%d" % [SyndicateState.heat, SyndicateState.crew_trust, SyndicateState.captured_crew_ids.size(), SyndicateState.black_tech_level], HORIZONTAL_ALIGNMENT_LEFT, 510.0, 9, Color("c39bff"))
	_draw_button(button_rects["sound"] as Rect2, "MUTE" if not SyndicateAudio.muted else "AUDIO", false, 8)
	_draw_button(button_rects["load"] as Rect2, "LOAD", false, 8)

func _draw_camera_controls() -> void:
	draw_rect(Rect2(0.0, 96.0, VIEW.x, 52.0), Color("101b2a", 0.98), true)
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 119.0), "DRAG TO PAN • VIEW %d° • %d%%" % [rotation_quadrant * 90, int(round(camera_zoom * 100.0))], HORIZONTAL_ALIGNMENT_LEFT, 332.0, 9, Color("f5fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 138.0), "LIVING LUNAR DISTRICT • 32 ACTIVE JOBS • %s" % _threat_label(), HORIZONTAL_ALIGNMENT_LEFT, 390.0, 8, Color("c39bff"))
	_draw_button(button_rects["zoom_out"] as Rect2, "−", false, 16)
	_draw_button(button_rects["zoom_in"] as Rect2, "+", false, 16)
	_draw_button(button_rects["rotate"] as Rect2, "ROTATE", true, 8)
	_draw_button(button_rects["center"] as Rect2, "CENTER", false, 8)
	_draw_side_quick_button(button_rects["operations"] as Rect2, "OPERATIONS", "JOBS", "patrol")
	_draw_side_quick_button(button_rects["save"] as Rect2, "SAVE", "PROFILE", "state")

func _draw_side_quick_button(rect: Rect2, title: String, subtitle: String, icon_id: String) -> void:
	draw_style_box(_panel(Color("152434"), Color("536b80"), 2, 10), rect)
	draw_texture_rect_region(ui_atlas, Rect2(rect.position + Vector2(23.0, 7.0), Vector2(36.0, 36.0)), ART.ui_region(icon_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, 56.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, 8, Color("f5fbff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, 68.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, 7, Color("4ee7ff"))

func _draw_inspector() -> void:
	match panel_mode:
		"heroes": _draw_heroes_panel()
		"dermapack": _draw_dermapack_panel()
		_: super._draw_inspector()

func _draw_heroes_panel() -> void:
	draw_rect(Rect2(0.0, 970.0, VIEW.x, 190.0), Color("07101d", 0.995), true)
	draw_style_box(_panel(Color("101c2a"), Color("4ee7ff"), 2, 12), Rect2(18.0, 982.0, 684.0, 166.0))
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1011.0), "MOONGOON HEROES", HORIZONTAL_ALIGNMENT_LEFT, 260.0, 18, Color("f5fbff"))
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var x: float = 34.0 + float(index) * 164.0
		var portrait: Texture2D = PORTRAITS[String(member.get("id", "crew_1"))] as Texture2D
		draw_texture_rect(portrait, Rect2(x, 1023.0, 54.0, 54.0), false)
		draw_string(ThemeDB.fallback_font, Vector2(x + 60.0, 1042.0), String(member.get("name", "Crew")), HORIZONTAL_ALIGNMENT_LEFT, 94.0, 10, Color("f5fbff"))
		draw_string(ThemeDB.fallback_font, Vector2(x + 60.0, 1061.0), String(member.get("role", "MoonGoon")), HORIZONTAL_ALIGNMENT_LEFT, 94.0, 8, Color("4ee7ff"))
		var status: String = "CAPTURED" if SyndicateState.captured_crew_ids.has(String(member.get("id", ""))) else ("READY" if SyndicateState.crew_available(member) else "BUSY")
		draw_string(ThemeDB.fallback_font, Vector2(x, 1100.0), status, HORIZONTAL_ALIGNMENT_CENTER, 145.0, 9, Color("ff6681") if status == "CAPTURED" else Color("72efd5"))

func _draw_dermapack_panel() -> void:
	draw_rect(Rect2(0.0, 970.0, VIEW.x, 190.0), Color("07101d", 0.995), true)
	draw_style_box(_panel(Color("101c2a"), Color("8c54d8"), 2, 12), Rect2(18.0, 982.0, 684.0, 166.0))
	draw_texture_rect(dermapack_texture, Rect2(32.0, 994.0, 132.0, 132.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(178.0, 1014.0), "DERMAPACK MICRO-STORAGE", HORIZONTAL_ALIGNMENT_LEFT, 480.0, 18, Color("f5fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(178.0, 1038.0), "Wearable dermal-link inventory • biometric lock active", HORIZONTAL_ALIGNMENT_LEFT, 480.0, 9, Color("4ee7ff"))
	var lines: Array[String] = [
		"Contraband %d   Intel %d   Data Cores %d" % [SyndicateState.contraband, SyndicateState.intel, SyndicateState.data_cores],
		"Lunar Alloy %d   Helium-3 %d   Black Tech L%d" % [SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.black_tech_level],
		"Portable loadout slots synchronize with missions and raids."
	]
	for index: int in range(lines.size()):
		draw_string(ThemeDB.fallback_font, Vector2(178.0, 1070.0 + float(index) * 23.0), lines[index], HORIZONTAL_ALIGNMENT_LEFT, 490.0, 10, Color("d3deea"))

func _draw_navigation() -> void:
	draw_rect(Rect2(0.0, 1160.0, VIEW.x, 120.0), Color("050a12"), true)
	_draw_nav(button_rects["scores"] as Rect2, "PATROL", "MISSIONS", "patrol", false)
	_draw_nav(button_rects["heroes"] as Rect2, "HEROES", "CREW", "heroes", panel_mode == "heroes")
	_draw_nav(button_rects["dermapack"] as Rect2, "DERMAPACK", "STORAGE", "dermapack", panel_mode == "dermapack")
	_draw_nav(button_rects["store"] as Rect2, "STORE", "MARKET", "store", selected_room == "black_market")
	_draw_nav(button_rects["chat"] as Rect2, "ALLIANCE", "CHAT", "alliance", false)
	_draw_nav(button_rects["hideout"] as Rect2, "STATE", "BASE", "state", selected_room == "backroom" and panel_mode == "room")

func _draw_nav(rect: Rect2, title: String, subtitle: String, icon_id: String, active: bool) -> void:
	draw_style_box(_panel(Color("183149") if active else Color("101a28"), Color("4ee7ff") if active else Color("53677d"), 2 if active else 1, 10), rect)
	draw_texture_rect_region(ui_atlas, Rect2(rect.position + Vector2(rect.size.x * 0.5 - 22.0, 7.0), Vector2(44.0, 44.0)), ART.ui_region(icon_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 67.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 10, Color("f5fbff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 87.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 7, Color("4ee7ff"))

func _draw_button(rect: Rect2, label: String, active: bool, font_size: int) -> void:
	draw_style_box(_panel(Color("24516a") if active else Color("152333"), Color("6cf0e1") if active else Color("526b80"), 2 if active else 1, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, rect.size.y * 0.61), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, font_size, Color("f5fbff"))
