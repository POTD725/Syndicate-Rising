extends "res://scripts/syndicate_skinned_city.gd"
## Living isometric city layer. Every visible NPC has a named job, route, workstation, and animation cycle.

var npc_jobs: Array[Dictionary] = []
var active_vehicle_count: int = 0

func _ready() -> void:
	super._ready()
	_build_npc_jobs()
	message = "Lunar district online: %d workers are performing assigned jobs." % npc_jobs.size()
	queue_redraw()

func _build_npc_jobs() -> void:
	npc_jobs = [
		_job("nyx", "Nyx Raze", "Directing district operations", "backroom", "crew_enforcer", "command", [Vector2(-238,-250), Vector2(-176,-198), Vector2(-148,-242)], 0.071, 0.02, "ff6d9e"),
		_job("vox", "Vox-13", "Cracking orbital encryption", "signal_den", "crew_hacker", "terminal", [Vector2(-244,-85), Vector2(-193,-102), Vector2(-164,-65)], 0.081, 0.24, "6deaff"),
		_job("cinder", "Cinder Quell", "Calibrating precision weapons", "sharpshooter_range", "crew_sharpshot", "target", [Vector2(195,105), Vector2(226,149), Vector2(272,177)], 0.076, 0.47, "ffc06d"),
		_job("grit", "Grit Mercer", "Training the breach team", "enforcer_gym", "crew_enforcer", "train", [Vector2(-92,238), Vector2(-28,277), Vector2(33,318)], 0.073, 0.68, "ff765f"),

		_job("research_a", "Dr. Hex", "Analyzing stolen Peacekeeper tech", "black_research", "research", "science", [Vector2(-84,-284), Vector2(-32,-248), Vector2(18,-292)], 0.064, 0.10, "55e8ff"),
		_job("research_b", "Lab Tech Miri", "Stabilizing Black Tech samples", "black_research", "research", "science", [Vector2(-56,-318), Vector2(4,-332), Vector2(52,-275)], 0.069, 0.55, "72ffd7"),
		_job("smith_a", "Forge", "Assembling pulse carbines", "weapons_workshop", "weapons", "wrench", [Vector2(126,-255), Vector2(172,-222), Vector2(231,-244)], 0.077, 0.14, "ffae4f"),
		_job("smith_b", "Rivet", "Tempering lunar armor plates", "weapons_workshop", "weapons", "wrench", [Vector2(112,-192), Vector2(176,-177), Vector2(248,-194)], 0.071, 0.62, "ff7e56"),
		_job("hacker_a", "Byte", "Spoofing police warrants", "signal_den", "crew_hacker", "terminal", [Vector2(-320,-128), Vector2(-262,-122), Vector2(-205,-155)], 0.082, 0.35, "bb70ff"),
		_job("hacker_b", "Glitch", "Mapping station patrol frequencies", "signal_den", "crew_hacker", "terminal", [Vector2(-304,-22), Vector2(-244,-42), Vector2(-188,-12)], 0.075, 0.79, "ff63de"),
		_job("medic_a", "Patch", "Treating injured MoonGoons", "clinic", "heal", "medic", [Vector2(-83,-103), Vector2(-25,-74), Vector2(44,-108)], 0.065, 0.22, "69ffd7"),
		_job("medic_b", "Suture", "Preparing illegal enhancements", "clinic", "heal", "medic", [Vector2(-70,-22), Vector2(-8,-6), Vector2(67,-46)], 0.067, 0.72, "74dfff"),
		_job("mechanic_a", "Torque", "Repairing getaway rovers", "chop_shop", "rover", "wrench", [Vector2(138,-50), Vector2(202,-32), Vector2(286,-60)], 0.083, 0.05, "7faeff"),
		_job("mechanic_b", "Axle", "Refitting smuggler engines", "chop_shop", "rover", "wrench", [Vector2(147,33), Vector2(221,58), Vector2(303,22)], 0.079, 0.48, "68d0ff"),
		_job("smuggler_a", "Latch", "Loading concealed cargo", "tunnel", "cargo", "load", [Vector2(-326,50), Vector2(-270,91), Vector2(-203,128)], 0.086, 0.18, "ffd065"),
		_job("smuggler_b", "Vanta", "Launching a masked courier skiff", "tunnel", "cargo", "smuggle", [Vector2(-319,160), Vector2(-249,184), Vector2(-183,166)], 0.088, 0.58, "ff9e56"),
		_job("market_a", "Ledger", "Fencing captured Authority gear", "black_market", "shop", "market", [Vector2(-113,55), Vector2(-45,83), Vector2(36,65)], 0.069, 0.31, "ffe173"),
		_job("market_b", "Kestrel", "Packing DermaPack mission kits", "black_market", "inventory", "carry", [Vector2(-102,151), Vector2(-23,180), Vector2(76,145)], 0.074, 0.83, "d98cff"),
		_job("marksman_a", "Sightline", "Running target acquisition drills", "sharpshooter_range", "crew_sharpshot", "target", [Vector2(161,126), Vector2(220,184), Vector2(304,218)], 0.076, 0.12, "ffcf62"),
		_job("marksman_b", "Longshot", "Zeroing lunar rifles", "sharpshooter_range", "crew_sharpshot", "target", [Vector2(145,230), Vector2(214,264), Vector2(300,258)], 0.072, 0.66, "ffef7a"),
		_job("trainer_a", "Knuckles", "Drilling enforcer formations", "enforcer_gym", "crew_enforcer", "train", [Vector2(-126,242), Vector2(-65,300), Vector2(5,347)], 0.078, 0.40, "ff7259"),
		_job("trainer_b", "Bulk", "Testing breach shields", "enforcer_gym", "defense_blast_doors", "train", [Vector2(-89,352), Vector2(-9,378), Vector2(78,350)], 0.071, 0.88, "ff9a62"),
		_job("quartermaster_a", "Cache", "Restocking Crew Quarters", "bunks", "inventory", "carry", [Vector2(171,322), Vector2(225,356), Vector2(306,377)], 0.074, 0.26, "9fcbff"),
		_job("quartermaster_b", "Rook", "Checking biometric lockers", "bunks", "lock", "terminal", [Vector2(157,397), Vector2(231,414), Vector2(317,405)], 0.068, 0.74, "9f8cff"),
		_job("guard_a", "Gate Guard One", "Patrolling the north access road", "backroom", "crew_enforcer", "guard", [Vector2(-310,-396), Vector2(-182,-406), Vector2(-38,-390), Vector2(112,-405)], 0.094, 0.08, "6fd9ff"),
		_job("guard_b", "Gate Guard Two", "Scanning incoming cargo", "tunnel", "crew_enforcer", "guard", [Vector2(-330,211), Vector2(-218,229), Vector2(-98,253)], 0.089, 0.51, "6fd9ff"),
		_job("miner_a", "Alloy Miner", "Delivering refined Lunar Alloy", "black_market", "resource_alloy", "mine", [Vector2(-338,305), Vector2(-218,278), Vector2(-105,237)], 0.084, 0.16, "8dffd6"),
		_job("miner_b", "Helium Tech", "Servicing the Helium-3 manifold", "clinic", "resource_helium", "science", [Vector2(338,-326), Vector2(283,-245), Vector2(244,-142)], 0.072, 0.59, "65dfff"),
		_job("courier_a", "Data Courier", "Moving Authority Data Cores", "signal_den", "resource_cores", "carry", [Vector2(328,320), Vector2(190,287), Vector2(61,210), Vector2(-84,146)], 0.097, 0.36, "c58cff"),
		_job("cleaner_a", "Maintenance Bot Handler", "Repairing corridor power conduits", "backroom", "power_core", "wrench", [Vector2(-12,-166), Vector2(4,-62), Vector2(-8,54), Vector2(16,170)], 0.081, 0.91, "6fffe8")
	]

func _job(id_value: String, display_name: String, task: String, room_id: String, item_id: String, tool: String, points: Array[Vector2], speed: float, phase: float, color_hex: String) -> Dictionary:
	var route: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		route.append(point)
	return {
		"id": id_value,
		"name": display_name,
		"job": task,
		"room": room_id,
		"item": item_id,
		"tool": tool,
		"route": route,
		"speed": speed,
		"phase": phase,
		"color": color_hex
	}

func _draw_crew_activity() -> void:
	for index: int in range(npc_jobs.size()):
		_draw_job_npc(npc_jobs[index], index)

func _draw_job_npc(job: Dictionary, index: int) -> void:
	var route: PackedVector2Array = job.get("route", PackedVector2Array()) as PackedVector2Array
	if route.is_empty():
		return
	var cycle: float = fmod(elapsed * float(job.get("speed", 0.07)) + float(job.get("phase", 0.0)), 1.0)
	var walking: bool = cycle < 0.72
	var travel_t: float = clampf(cycle / 0.72, 0.0, 1.0)
	var pos: Vector2 = _route_position(route, travel_t) if walking else route[route.size() - 1]
	var bob: float = sin(elapsed * 10.0 + float(index)) * (2.2 if walking else 0.8)
	pos.y += bob
	var worker_color: Color = Color(String(job.get("color", "7de8ff")))
	var leg_swing: float = sin(elapsed * 13.0 + float(index)) * (5.0 if walking else 1.0)

	# Shadow, body, animated limbs, and a job-role badge.
	draw_circle(pos + Vector2(0.0, 11.0), 7.0, Color(0.0, 0.0, 0.0, 0.42))
	draw_line(pos + Vector2(0.0, 2.0), pos + Vector2(-4.0 + leg_swing, 13.0), worker_color.darkened(0.35), 3.0)
	draw_line(pos + Vector2(0.0, 2.0), pos + Vector2(4.0 - leg_swing, 13.0), worker_color.darkened(0.35), 3.0)
	draw_rect(Rect2(pos + Vector2(-5.0, -8.0), Vector2(10.0, 13.0)), worker_color.darkened(0.22), true)
	draw_circle(pos + Vector2(0.0, -12.0), 5.0, Color("d9b38c"))
	draw_line(pos + Vector2(-4.0, -4.0), pos + Vector2(-8.0 - leg_swing * 0.35, 4.0), worker_color, 2.0)
	draw_line(pos + Vector2(4.0, -4.0), pos + Vector2(8.0 + leg_swing * 0.35, 4.0), worker_color, 2.0)
	var item_id: String = String(job.get("item", "crew_enforcer"))
	draw_texture_rect_region(skin_atlas, Rect2(pos + Vector2(8.0, -22.0), Vector2(18.0, 18.0)), SyndicateSkins.region(item_id))

	if not walking:
		_draw_job_action(String(job.get("tool", "terminal")), pos, worker_color, index)
	if fmod(elapsed + float(index) * 0.57, 8.0) < 1.45:
		_draw_job_label(pos, String(job.get("job", "Working")))

func _route_position(route: PackedVector2Array, t: float) -> Vector2:
	if route.size() == 1:
		return route[0]
	var scaled: float = clampf(t, 0.0, 0.9999) * float(route.size() - 1)
	var segment: int = int(floor(scaled))
	var local_t: float = scaled - float(segment)
	return route[segment].lerp(route[mini(segment + 1, route.size() - 1)], local_t)

func _draw_job_label(pos: Vector2, text: String) -> void:
	var width: float = clampf(ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 7).x + 14.0, 70.0, 170.0)
	var rect: Rect2 = Rect2(pos + Vector2(-width * 0.5, -47.0), Vector2(width, 18.0))
	draw_style_box(_panel(Color(0.015, 0.03, 0.05, 0.90), SyndicateSkins.accent(), 1, 6), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 12.0), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, 7, SyndicateSkins.text())

func _draw_job_action(tool: String, pos: Vector2, color: Color, index: int) -> void:
	var pulse: float = 0.5 + sin(elapsed * 6.0 + float(index)) * 0.5
	match tool:
		"terminal":
			draw_rect(Rect2(pos + Vector2(10.0, -14.0), Vector2(17.0, 13.0)), Color("07131e"), true)
			draw_rect(Rect2(pos + Vector2(12.0, -12.0), Vector2(13.0, 8.0)), Color(color, 0.35 + pulse * 0.55), true)
			draw_line(pos + Vector2(8.0, -2.0), pos + Vector2(3.0, 4.0), color, 2.0)
		"science":
			draw_circle(pos + Vector2(15.0, -5.0), 7.0 + pulse * 3.0, Color(color, 0.16 + pulse * 0.24))
			draw_circle(pos + Vector2(15.0, -5.0), 3.0, color)
			draw_line(pos + Vector2(9.0, 2.0), pos + Vector2(21.0, -13.0), Color("d8fbff"), 2.0)
		"wrench":
			draw_line(pos + Vector2(8.0, -1.0), pos + Vector2(20.0, -13.0), Color("d9e5ef"), 3.0)
			for spark: int in range(3):
				var angle: float = elapsed * 5.0 + float(spark) * TAU / 3.0
				draw_line(pos + Vector2(21.0, -13.0), pos + Vector2(21.0, -13.0) + Vector2(cos(angle), sin(angle)) * (5.0 + pulse * 4.0), Color("ffcb65"), 2.0)
		"medic":
			draw_rect(Rect2(pos + Vector2(10.0, -12.0), Vector2(5.0, 18.0)), Color(color, 0.75), true)
			draw_rect(Rect2(pos + Vector2(3.0, -5.0), Vector2(19.0, 5.0)), Color(color, 0.75), true)
			draw_circle(pos + Vector2(12.0, -3.0), 13.0 + pulse * 4.0, Color(color, 0.10))
		"train":
			var bag: Vector2 = pos + Vector2(19.0, -2.0)
			draw_line(bag + Vector2(0.0, -18.0), bag + Vector2(0.0, -10.0), Color("b5c3cf"), 2.0)
			draw_circle(bag, 8.0, Color("8e263a"))
			draw_line(pos + Vector2(5.0, -2.0), bag + Vector2(-7.0 + pulse * 3.0, -2.0), color, 3.0)
		"target":
			var target: Vector2 = pos + Vector2(22.0, -5.0)
			draw_circle(target, 10.0, Color("f4efe2"))
			draw_circle(target, 6.0, Color("cf3b50"))
			draw_circle(target, 2.0 + pulse * 2.0, Color("fff4a8"))
		"carry", "load":
			draw_rect(Rect2(pos + Vector2(8.0, -5.0), Vector2(17.0, 13.0)), Color("9a6343"), true)
			draw_line(pos + Vector2(9.0, -4.0), pos + Vector2(24.0, 7.0), Color("e4bd80"), 1.0)
			draw_line(pos + Vector2(24.0, -4.0), pos + Vector2(9.0, 7.0), Color("e4bd80"), 1.0)
		"market":
			for coin: int in range(3):
				draw_circle(pos + Vector2(10.0 + float(coin) * 6.0, -4.0 - pulse * float(coin + 1) * 2.0), 3.0, Color("ffd66d"))
		"guard":
			var cone: PackedVector2Array = PackedVector2Array([pos + Vector2(7.0,-8.0), pos + Vector2(28.0,-20.0), pos + Vector2(32.0,8.0)])
			draw_colored_polygon(cone, Color(color, 0.08 + pulse * 0.12))
			draw_line(pos + Vector2(6.0, -6.0), pos + Vector2(25.0, -6.0), color, 2.0)
		"mine":
			var swing: float = -0.8 + pulse * 1.4
			draw_line(pos + Vector2(4.0, -3.0), pos + Vector2(4.0, -3.0) + Vector2(cos(swing), sin(swing)) * 20.0, Color("d5e1e9"), 3.0)
			draw_circle(pos + Vector2(22.0, 7.0), 5.0, Color("6fffcf", 0.6))
		"smuggle":
			draw_line(pos + Vector2(8.0, -12.0), pos + Vector2(26.0, -28.0), Color(color, 0.75), 3.0)
			draw_circle(pos + Vector2(28.0, -30.0), 5.0 + pulse * 3.0, Color(color, 0.22))
		"command":
			draw_arc(pos + Vector2(16.0, -4.0), 10.0 + pulse * 3.0, 0.0, TAU, 20, Color(color, 0.75), 2.0)
			draw_line(pos + Vector2(16.0, -15.0), pos + Vector2(16.0, 6.0), Color(color, 0.45), 1.0)

func _draw_ambient_effects() -> void:
	super._draw_ambient_effects()
	_draw_building_animation_loops()
	_draw_vehicle_traffic()

func _draw_building_animation_loops() -> void:
	var pulse: float = 0.5 + sin(elapsed * 2.8) * 0.5
	# Research reactor, Hacker Den data arcs, clinic pulse, weapon sparks, and command hologram.
	draw_circle(Vector2(-15.0, -275.0), 18.0 + pulse * 8.0, Color(0.25, 0.88, 1.0, 0.08 + pulse * 0.12))
	draw_arc(Vector2(-15.0, -275.0), 12.0 + pulse * 5.0, 0.0, TAU, 24, Color("65eaff", 0.70), 2.0)
	for arc_index: int in range(4):
		var start: Vector2 = Vector2(-287.0 + float(arc_index) * 32.0, -95.0)
		var end: Vector2 = Vector2(-235.0 + sin(elapsed * 1.7 + float(arc_index)) * 34.0, -27.0)
		draw_line(start, end, Color(0.72, 0.32, 1.0, 0.25 + pulse * 0.28), 2.0)
	draw_circle(Vector2(-12.0, -68.0), 12.0 + pulse * 7.0, Color(0.25, 1.0, 0.72, 0.10 + pulse * 0.14))
	for spark: int in range(6):
		var angle: float = elapsed * 4.2 + float(spark) * TAU / 6.0
		var center: Vector2 = Vector2(203.0, -205.0)
		draw_line(center, center + Vector2(cos(angle), sin(angle)) * (6.0 + pulse * 10.0), Color("ffb95e", 0.72), 2.0)
	draw_arc(Vector2(-169.0, -228.0), 26.0 + pulse * 6.0, 0.0, TAU, 28, Color(1.0, 0.28, 0.20, 0.44), 3.0)
	# Animated doors and warning lamps.
	for door_pos: Vector2 in [Vector2(-118,-178), Vector2(100,-118), Vector2(-113,222), Vector2(136,294)]:
		var open_amount: float = 3.0 + pulse * 8.0
		draw_line(door_pos + Vector2(-open_amount, -8.0), door_pos + Vector2(-open_amount, 9.0), Color("78eaff"), 2.0)
		draw_line(door_pos + Vector2(open_amount, -8.0), door_pos + Vector2(open_amount, 9.0), Color("78eaff"), 2.0)
		draw_circle(door_pos + Vector2(0.0, -13.0), 2.5, Color("68ffb2") if pulse > 0.35 else Color("ff6a72"))

func _draw_vehicle_traffic() -> void:
	active_vehicle_count = 5
	var road_t: float = fmod(elapsed * 0.055, 1.0)
	_draw_rover(Vector2(-335.0, -360.0).lerp(Vector2(318.0, -375.0), road_t), Color("315b85"), true)
	_draw_rover(Vector2(316.0, 286.0).lerp(Vector2(-330.0, 255.0), fmod(road_t + 0.48, 1.0)), Color("452f65"), false)
	var cargo_t: float = fmod(elapsed * 0.072, 1.0)
	var cargo_pos: Vector2 = Vector2(-302.0, 205.0).lerp(Vector2(286.0, 95.0), cargo_t)
	draw_rect(Rect2(cargo_pos + Vector2(-13.0, -6.0), Vector2(26.0, 12.0)), Color("755138"), true)
	draw_circle(cargo_pos + Vector2(-9.0, 8.0), 5.0, Color("070b11"))
	draw_circle(cargo_pos + Vector2(9.0, 8.0), 5.0, Color("070b11"))
	for drone_index: int in range(2):
		var phase: float = fmod(elapsed * (0.09 + float(drone_index) * 0.015) + float(drone_index) * 0.5, 1.0)
		var drone_pos: Vector2 = Vector2(-290.0, -445.0 + float(drone_index) * 35.0).lerp(Vector2(300.0, -410.0 + float(drone_index) * 24.0), phase)
		draw_circle(drone_pos, 6.0, Color("dce9f1"))
		draw_line(drone_pos + Vector2(-11.0, 0.0), drone_pos + Vector2(11.0, 0.0), Color("64e9ff"), 2.0)
		draw_circle(drone_pos + Vector2(0.0, 2.0), 2.0, Color("ff5e72") if drone_index == 0 else Color("70f1ff"))

func _draw_rover(pos: Vector2, body: Color, police_lights: bool) -> void:
	draw_rect(Rect2(pos + Vector2(-18.0, -8.0), Vector2(36.0, 16.0)), body, true)
	draw_rect(Rect2(pos + Vector2(-9.0, -15.0), Vector2(20.0, 9.0)), body.lightened(0.2), true)
	draw_circle(pos + Vector2(-12.0, 10.0), 6.0, Color("05080d"))
	draw_circle(pos + Vector2(12.0, 10.0), 6.0, Color("05080d"))
	if police_lights:
		var flash: bool = fmod(elapsed * 5.0, 2.0) < 1.0
		draw_circle(pos + Vector2(-4.0, -17.0), 3.0, Color("ff405e") if flash else Color("4f79ff"))
		draw_circle(pos + Vector2(4.0, -17.0), 3.0, Color("4f79ff") if flash else Color("ff405e"))

func npc_job_count() -> int:
	return npc_jobs.size()

func every_npc_has_job() -> bool:
	for job: Dictionary in npc_jobs:
		if String(job.get("job", "")).is_empty() or (job.get("route", PackedVector2Array()) as PackedVector2Array).is_empty():
			return false
	return true
