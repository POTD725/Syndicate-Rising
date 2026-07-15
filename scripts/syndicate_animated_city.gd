extends "res://scripts/syndicate_skinned_city.gd"
## Adds purposeful job loops for every visible NPC and the wearable DermaPack micro-storage panel.

const Anim = preload("res://scripts/syndicate_animation_library.gd")

const SUPPORT_JOBS: Array[Dictionary] = [
	{"id":"ops_tech", "room":"backroom", "role":"Hacker", "label":"ROUTING SCORES", "action":"route", "phase":0.03, "slot":0.62},
	{"id":"lab_tech", "room":"black_research", "role":"Hacker", "label":"ANALYZING BLACK TECH", "action":"research", "phase":0.19, "slot":0.70},
	{"id":"armorer", "room":"weapons_workshop", "role":"Enforcer", "label":"FABRICATING GEAR", "action":"weld", "phase":0.36, "slot":0.58},
	{"id":"signal_runner", "room":"signal_den", "role":"Hacker", "label":"CRACKING SIGNALS", "action":"hack", "phase":0.52, "slot":0.68},
	{"id":"trainer", "room":"enforcer_gym", "role":"Enforcer", "label":"RUNNING POWER DRILLS", "action":"train", "phase":0.68, "slot":0.55},
	{"id":"range_tech", "room":"sharpshooter_range", "role":"Sharpshot", "label":"CALIBRATING TARGETS", "action":"aim", "phase":0.84, "slot":0.72},
	{"id":"mechanic", "room":"chop_shop", "role":"Runner", "label":"REPAIRING THE ROVER", "action":"repair", "phase":0.11, "slot":0.61},
	{"id":"street_medic", "room":"clinic", "role":"Hacker", "label":"RUNNING MED SCANS", "action":"heal", "phase":0.27, "slot":0.67},
	{"id":"quartermaster", "room":"bunks", "role":"Runner", "label":"CHECKING LIFE SUPPORT", "action":"scan", "phase":0.44, "slot":0.57},
	{"id":"fence_broker", "room":"black_market", "role":"Runner", "label":"SORTING CONTRABAND", "action":"trade", "phase":0.60, "slot":0.71},
	{"id":"tunnel_loader", "room":"tunnel", "role":"Enforcer", "label":"LOADING THE SKIFF", "action":"load", "phase":0.76, "slot":0.59},
	{"id":"strategist", "room":"boss_office", "role":"Hacker", "label":"PLANNING EXPANSION", "action":"plan", "phase":0.92, "slot":0.69}
]

const CREW_JOBS: Dictionary = {
	"crew_1": {"room":"weapons_workshop", "label":"WEAPON CALIBRATION", "action":"weld", "phase":0.08},
	"crew_2": {"room":"chop_shop", "label":"COURIER PREP", "action":"repair", "phase":0.31},
	"crew_3": {"room":"sharpshooter_range", "label":"TARGET DRILL", "action":"aim", "phase":0.57},
	"crew_4": {"room":"enforcer_gym", "label":"DEFENSE TRAINING", "action":"train", "phase":0.81}
}

var dermapack_open: bool = false

func _ready() -> void:
	super._ready()
	button_rects["hideout"] = Rect2(6.0, 1170.0, 112.0, 96.0)
	button_rects["scores"] = Rect2(124.0, 1170.0, 112.0, 96.0)
	button_rects["operations"] = Rect2(242.0, 1170.0, 112.0, 96.0)
	button_rects["chat"] = Rect2(360.0, 1170.0, 112.0, 96.0)
	button_rects["dermapack"] = Rect2(478.0, 1170.0, 112.0, 96.0)
	button_rects["save"] = Rect2(596.0, 1170.0, 118.0, 96.0)

func _action(action: String) -> void:
	if action == "dermapack":
		dermapack_open = not dermapack_open
		message = "DermaPack opened: wearable micro-storage online." if dermapack_open else "DermaPack sealed and locked."
		SyndicateAudio.play_sfx("click")
		queue_redraw()
		return
	if action in ["hideout", "scores", "operations", "chat"]:
		dermapack_open = false
	super._action(action)

func _draw_crew_activity() -> void:
	for support_index: int in range(SUPPORT_JOBS.size()):
		_draw_support_worker(SUPPORT_JOBS[support_index], support_index)
	for crew_index: int in range(SyndicateState.crew.size()):
		_draw_named_crew_job(SyndicateState.crew[crew_index], crew_index)
	for spark_index: int in range(8):
		var spark_y: float = -60.0 + fmod(elapsed * (27.0 + float(spark_index) * 3.0) + float(spark_index) * 67.0, 500.0)
		var spark_x: float = sin(elapsed * 1.8 + float(spark_index)) * 17.0
		var spark: Color = SyndicateSkins.accent()
		spark.a = 0.52
		draw_circle(Vector2(spark_x, spark_y), 1.7, spark)

func _draw_support_worker(job: Dictionary, index: int) -> void:
	var room_id: String = String(job.get("room", "backroom"))
	if not room_rects.has(room_id):
		return
	var room: Dictionary = SyndicateState.get_room(room_id)
	if room.is_empty():
		return
	var rect: Rect2 = room_rects[room_id] as Rect2
	var phase: float = float(job.get("phase", float(index) * 0.07))
	var cycle: float = fmod(elapsed * (0.075 + float(index % 4) * 0.006) + phase, 1.0)
	var pose: Dictionary = _job_pose(rect, cycle, float(job.get("slot", 0.64)))
	var position: Vector2 = pose.get("position", rect.get_center()) as Vector2
	var facing: float = float(pose.get("facing", 1.0))
	var motion: float = float(pose.get("motion", 0.0))
	var action: String = String(job.get("action", "type"))
	var label: String = String(job.get("label", "WORKING"))
	if not bool(room.get("repaired", false)):
		action = "repair"
		label = "SALVAGE REBUILD"
	var role_item: String = SyndicateSkins.crew_item(String(job.get("role", "Runner")))
	Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(role_item), position, elapsed, phase, facing, motion, 0.72, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), action)
	var effect_position: Vector2 = position + Vector2(facing * 25.0, 4.0)
	Anim.draw_job_effect(self, effect_position, action, elapsed, phase, 0.65, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
	if room_id == selected_room and cycle > 0.22 and cycle < 0.84:
		Anim.draw_job_label(self, position + Vector2(0.0, -31.0), label, 118.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 6)

func _draw_named_crew_job(member: Dictionary, index: int) -> void:
	var crew_id: String = String(member.get("id", "crew_1"))
	if SyndicateState.captured_crew_ids.has(crew_id):
		return
	var phase: float = float((index + 1) * 0.17)
	var now: int = int(Time.get_unix_time_from_system())
	var injured_until: int = int(member.get("injured_until", 0))
	var busy_until: int = int(member.get("busy_until", 0))
	var role_item: String = SyndicateSkins.crew_item(String(member.get("role", "Enforcer")))
	if busy_until > now:
		var route_x: float = -310.0 + fmod(elapsed * (38.0 + float(index) * 4.0) + float(index) * 147.0, 620.0)
		var route_position: Vector2 = Vector2(route_x, -126.0 + sin(elapsed * 2.2 + phase * TAU) * 7.0)
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(role_item), route_position, elapsed, phase, 1.0, 1.0, 0.88, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "run")
		Anim.draw_job_effect(self, route_position + Vector2(-19.0, 11.0), "run", elapsed, phase, 0.72, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
		return
	var assignment: Dictionary = CREW_JOBS.get(crew_id, CREW_JOBS["crew_1"]) as Dictionary
	var room_id: String = String(assignment.get("room", "backroom"))
	var action: String = String(assignment.get("action", "guard"))
	var label: String = String(assignment.get("label", "CREW DUTY"))
	if injured_until > now:
		room_id = "clinic"
		action = "recover"
		label = "CLINIC RECOVERY"
	if not room_rects.has(room_id):
		return
	var room: Dictionary = SyndicateState.get_room(room_id)
	if room.is_empty():
		return
	if not bool(room.get("repaired", false)):
		room_id = "backroom"
		room = SyndicateState.get_room(room_id)
		action = "repair"
		label = "SALVAGE DETAIL"
	var rect: Rect2 = room_rects[room_id] as Rect2
	var crew_phase: float = float(assignment.get("phase", phase))
	var cycle: float = fmod(elapsed * (0.09 + float(index) * 0.005) + crew_phase, 1.0)
	var pose: Dictionary = _job_pose(rect, cycle, 0.43 + float(index % 2) * 0.12)
	var position: Vector2 = (pose.get("position", rect.get_center()) as Vector2) + Vector2(0.0, -4.0)
	var facing: float = float(pose.get("facing", 1.0))
	var motion: float = float(pose.get("motion", 0.0))
	Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(role_item), position, elapsed, crew_phase, facing, motion, 0.88, SyndicateSkins.secondary(), SyndicateSkins.accent(), SyndicateSkins.panel(), action)
	Anim.draw_job_effect(self, position + Vector2(facing * 29.0, 3.0), action, elapsed, crew_phase, 0.76, SyndicateSkins.secondary(), SyndicateSkins.accent(), SyndicateSkins.panel())
	if room_id == selected_room and cycle > 0.22 and cycle < 0.84:
		Anim.draw_job_label(self, position + Vector2(0.0, -38.0), "%s • %s" % [String(member.get("name", "CREW")).to_upper(), label], 150.0, SyndicateSkins.secondary(), SyndicateSkins.panel(), SyndicateSkins.text(), 6)

func _job_pose(rect: Rect2, cycle: float, station_slot: float) -> Dictionary:
	var left_room: bool = rect.position.x < 0.0
	var door: Vector2 = Vector2(rect.end.x - 6.0, rect.position.y + rect.size.y * 0.52) if left_room else Vector2(rect.position.x + 6.0, rect.position.y + rect.size.y * 0.52)
	var station_x: float = rect.position.x + rect.size.x * station_slot
	var station: Vector2 = Vector2(station_x, rect.position.y + rect.size.y * 0.44)
	var facing: float = -1.0 if left_room else 1.0
	var position: Vector2 = station
	var motion: float = 0.0
	if cycle < 0.22:
		var travel_in: float = clampf(cycle / 0.22, 0.0, 1.0)
		position = door.lerp(station, travel_in)
		motion = 1.0
	elif cycle > 0.84:
		var travel_out: float = clampf((cycle - 0.84) / 0.16, 0.0, 1.0)
		position = station.lerp(door, travel_out)
		motion = 1.0
	else:
		position += Vector2(sin(elapsed * 1.6 + station_slot * TAU) * 2.0, 0.0)
	return {"position": position, "facing": facing, "motion": motion}

func _draw_fixed_interface() -> void:
	super._draw_fixed_interface()
	if dermapack_open:
		_draw_dermapack_panel()

func _draw_navigation() -> void:
	draw_rect(Rect2(0.0, 1160.0, VIEW.x, 120.0), SyndicateSkins.dark(), true)
	_draw_animated_nav_button(button_rects["hideout"] as Rect2, "HIDEOUT", "BASE", "hideout", selected_room == "backroom")
	_draw_animated_nav_button(button_rects["scores"] as Rect2, "SCORES", "MISSIONS", "score", false)
	_draw_animated_nav_button(button_rects["operations"] as Rect2, "OPS", "HARVEST", "operations", false)
	_draw_animated_nav_button(button_rects["chat"] as Rect2, "CHAT", "GALAXY", "chat_galaxy", false)
	_draw_animated_nav_button(button_rects["dermapack"] as Rect2, "DERMAPACK", "MICRO STORE", "dermapack", dermapack_open)
	_draw_animated_nav_button(button_rects["save"] as Rect2, "SAVE", "PROFILE", "save", false)

func _draw_animated_nav_button(rect: Rect2, title: String, subtitle: String, item_id: String, active: bool) -> void:
	draw_style_box(SyndicateSkins.style_box(active, 10), rect)
	var icon_size: float = 32.0 if title == "DERMAPACK" else 34.0
	draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(rect.size.x * 0.5 - icon_size * 0.5, 7.0), Vector2(icon_size, icon_size)), SyndicateSkins.region(item_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, 61.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, 9 if title == "DERMAPACK" else 10, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, 80.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, 7, SyndicateSkins.accent())

func _draw_dermapack_panel() -> void:
	var panel_rect: Rect2 = Rect2(38.0, 186.0, 644.0, 742.0)
	draw_style_box(SyndicateSkins.style_box(true, 20, 0.992), panel_rect)
	var veil: Color = SyndicateSkins.dark()
	veil.a = 0.32
	draw_rect(Rect2(0.0, 148.0, VIEW.x, 822.0), veil, true)
	draw_style_box(SyndicateSkins.style_box(true, 20, 0.992), panel_rect)
	draw_texture_rect_region(skin_atlas, Rect2(62.0, 218.0, 172.0, 172.0), SyndicateSkins.region("dermapack"))
	draw_string(ThemeDB.fallback_font, Vector2(254.0, 250.0), "DERMAPACK", HORIZONTAL_ALIGNMENT_LEFT, 390.0, 31, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(254.0, 284.0), "WEARABLE MICRO-STORAGE SYSTEM", HORIZONTAL_ALIGNMENT_LEFT, 390.0, 13, SyndicateSkins.accent())
	draw_string(ThemeDB.fallback_font, Vector2(254.0, 314.0), "Forearm mount • biometric lock • vacuum sealed", HORIZONTAL_ALIGNMENT_LEFT, 390.0, 10, SyndicateSkins.secondary())
	draw_string(ThemeDB.fallback_font, Vector2(254.0, 344.0), "Six compressed microcells keep field gear within one hand movement.", HORIZONTAL_ALIGNMENT_LEFT, 390.0, 9, SyndicateSkins.text())
	var cells: Array[Dictionary] = [
		{"name":"MEDGEL", "item":"heal", "value":maxi(1, SyndicateState.get_room_level("clinic"))},
		{"name":"BREACH KIT", "item":"weapons", "value":maxi(1, SyndicateState.get_room_level("weapons_workshop"))},
		{"name":"DATA SHARDS", "item":"cipher", "value":SyndicateState.data_cores},
		{"name":"MICRO DRONES", "item":"drone", "value":maxi(1, SyndicateState.black_tech_level)},
		{"name":"CONTRABAND", "item":"cargo", "value":SyndicateState.contraband},
		{"name":"EMERGENCY CHARGE", "item":"power_core", "value":SyndicateState.helium3}
	]
	for index: int in range(cells.size()):
		var column: int = index % 2
		var row: int = int(index / 2)
		var cell_rect: Rect2 = Rect2(66.0 + float(column) * 304.0, 430.0 + float(row) * 128.0, 286.0, 108.0)
		draw_style_box(SyndicateSkins.style_box(false, 12, 0.90), cell_rect)
		var cell: Dictionary = cells[index]
		draw_texture_rect_region(skin_atlas, Rect2(cell_rect.position + Vector2(10.0, 10.0), Vector2(82.0, 82.0)), SyndicateSkins.region(String(cell.get("item", "cargo"))))
		draw_string(ThemeDB.fallback_font, cell_rect.position + Vector2(104.0, 42.0), String(cell.get("name", "MICROCELL")), HORIZONTAL_ALIGNMENT_LEFT, 162.0, 11, SyndicateSkins.text())
		draw_string(ThemeDB.fallback_font, cell_rect.position + Vector2(104.0, 75.0), "STORED %d" % int(cell.get("value", 0)), HORIZONTAL_ALIGNMENT_LEFT, 162.0, 10, SyndicateSkins.accent())
	var lock_pulse: float = 0.5 + sin(elapsed * 3.0) * 0.5
	draw_circle(Vector2(356.0, 836.0), 13.0 + lock_pulse * 4.0, Color(SyndicateSkins.accent(), 0.18))
	draw_texture_rect_region(skin_atlas, Rect2(336.0, 816.0, 40.0, 40.0), SyndicateSkins.region("lock"))
	draw_string(ThemeDB.fallback_font, Vector2(100.0, 884.0), "DERMAPACK SEALED • TAP DERMAPACK AGAIN TO CLOSE", HORIZONTAL_ALIGNMENT_CENTER, 520.0, 10, SyndicateSkins.secondary())

func npc_job_count() -> int:
	var visible_crew: int = 0
	for member: Dictionary in SyndicateState.crew:
		if not SyndicateState.captured_crew_ids.has(String(member.get("id", ""))):
			visible_crew += 1
	return SUPPORT_JOBS.size() + visible_crew

func all_visible_npcs_have_jobs() -> bool:
	for job: Dictionary in SUPPORT_JOBS:
		if String(job.get("room", "")).is_empty() or String(job.get("action", "")).is_empty() or String(job.get("label", "")).is_empty():
			return false
	for member: Dictionary in SyndicateState.crew:
		var crew_id: String = String(member.get("id", ""))
		if not SyndicateState.captured_crew_ids.has(crew_id) and not CREW_JOBS.has(crew_id):
			return false
	return true
