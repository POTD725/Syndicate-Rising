extends "res://scripts/syndicate_skinned_cutscene.gd"
## Animated story scenes that reuse the active skin family, crew silhouettes, tools, and effects.

const Anim = preload("res://scripts/syndicate_animation_library.gd")

var cinematic_time: float = 0.0

func _process(delta: float) -> void:
	cinematic_time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), SyndicateSkins.dark())
	var texture: Texture2D = ART.get(key, ART["prologue"]) as Texture2D
	var pan_x: float = sin(cinematic_time * 0.17) * 12.0
	var pan_y: float = cos(cinematic_time * 0.13) * 7.0
	var zoom: float = 1.025 + sin(cinematic_time * 0.11) * 0.008
	var art_size: Vector2 = VIEW * zoom
	var art_rect: Rect2 = Rect2(Vector2((VIEW.x - art_size.x) * 0.5 + pan_x, (VIEW.y - art_size.y) * 0.5 + pan_y), art_size)
	draw_texture_rect(texture, art_rect, false)
	_draw_parallax_particles()
	_draw_cinematic_cast()
	if key == "prologue":
		_draw_prologue()
	else:
		_draw_story_interstitial()
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 3, 18), Rect2(16.0, 16.0, 688.0, 1248.0))
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 56.0), "%s • ANIMATED STORY FEED" % SyndicateSkins.skin_name().to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 648.0, 10, SyndicateSkins.secondary())

func _draw_parallax_particles() -> void:
	for index: int in range(24):
		var x: float = fmod(float(index * 83) + cinematic_time * (4.0 + float(index % 4)), 780.0) - 30.0
		var y: float = 92.0 + fmod(float(index * 131) + cinematic_time * (7.0 + float(index % 3)), 700.0)
		var mote: Color = SyndicateSkins.accent() if index % 2 == 0 else SyndicateSkins.secondary()
		mote.a = 0.10 + float(index % 4) * 0.035
		draw_circle(Vector2(x, y), 1.0 + float(index % 3) * 0.7, mote)

func _draw_cinematic_cast() -> void:
	match key:
		"prologue":
			_draw_prologue_cast()
		"ghost_key":
			_draw_network_cast()
		"war_room":
			_draw_war_room_cast()
		"finale":
			_draw_finale_cast()
		_:
			_draw_network_cast()

func _draw_prologue_cast() -> void:
	if stage == 0:
		for index: int in range(4):
			var progress: float = fmod(cinematic_time * (0.11 + float(index) * 0.006) + float(index) * 0.19, 1.0)
			var position: Vector2 = Vector2(-30.0 + progress * 805.0, 620.0 - sin(progress * PI) * (80.0 + float(index) * 11.0))
			var role: String = ["Enforcer", "Runner", "Sharpshot", "Enforcer"][index]
			Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item(role)), position, cinematic_time, float(index) * 0.21, 1.0, 1.0, 1.28, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "run")
			Anim.draw_job_effect(self, position + Vector2(-22.0, 16.0), "run", cinematic_time, float(index) * 0.21, 1.0, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
		_draw_orbital_scan(Vector2(360.0 + sin(cinematic_time * 0.7) * 150.0, 450.0), 170.0)
	elif stage == 1:
		var choice_jobs: Array[Dictionary] = [
			{"position":Vector2(155.0, 555.0), "role":"Enforcer", "action":"heal", "label":"RESCUE"},
			{"position":Vector2(360.0, 555.0), "role":"Runner", "action":"mine", "label":"SALVAGE"},
			{"position":Vector2(565.0, 555.0), "role":"Hacker", "action":"hack", "label":"ACCESS CODES"}
		]
		for index: int in range(choice_jobs.size()):
			var job: Dictionary = choice_jobs[index]
			var position: Vector2 = job.get("position", Vector2.ZERO) as Vector2
			var action: String = String(job.get("action", "type"))
			Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item(String(job.get("role", "Runner")))), position, cinematic_time, float(index) * 0.29, 1.0, 0.0, 1.20, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), action)
			Anim.draw_job_effect(self, position + Vector2(42.0, 5.0), action, cinematic_time, float(index) * 0.29, 1.0, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
			Anim.draw_job_label(self, position + Vector2(0.0, -56.0), String(job.get("label", "ORDER")), 130.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 8)
	else:
		for index: int in range(4):
			var position: Vector2 = Vector2(205.0 + float(index) * 105.0, 585.0 + sin(cinematic_time * 2.0 + float(index)) * 5.0)
			var role: String = ["Enforcer", "Runner", "Sharpshot", "Enforcer"][index]
			Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item(role)), position, cinematic_time, float(index) * 0.23, 1.0, 0.0, 1.26, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "celebrate")
			Anim.draw_job_effect(self, position + Vector2(0.0, -42.0), "celebrate", cinematic_time, float(index) * 0.23, 0.8, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())

func _draw_network_cast() -> void:
	for node_index: int in range(9):
		var column: int = node_index % 3
		var row: int = int(node_index / 3)
		var position: Vector2 = Vector2(190.0 + float(column) * 170.0, 260.0 + float(row) * 150.0)
		var node_color: Color = SyndicateSkins.accent() if node_index % 2 == 0 else SyndicateSkins.secondary()
		var pulse: float = 9.0 + sin(cinematic_time * 3.0 + float(node_index)) * 4.0
		draw_circle(position, pulse, Color(node_color, 0.20))
		draw_circle(position, 5.0, node_color)
		draw_line(position, Vector2(360.0, 490.0), Color(node_color, 0.25), 2.0, true)
	for index: int in range(3):
		var position: Vector2 = Vector2(215.0 + float(index) * 145.0, 650.0)
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item("Hacker" if index == 1 else "Runner")), position, cinematic_time, float(index) * 0.31, 1.0, 0.0, 1.16, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "hack")
		Anim.draw_job_effect(self, position + Vector2(37.0, 5.0), "hack", cinematic_time, float(index) * 0.31, 0.92, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())

func _draw_war_room_cast() -> void:
	var table_center: Vector2 = Vector2(360.0, 470.0)
	var table: PackedVector2Array = PackedVector2Array([
		table_center + Vector2(-115.0, -36.0), table_center + Vector2(0.0, -78.0),
		table_center + Vector2(115.0, -36.0), table_center + Vector2(0.0, 48.0)
	])
	draw_colored_polygon(table, Color(SyndicateSkins.panel(), 0.90))
	for ring_index: int in range(3):
		draw_arc(table_center, 31.0 + float(ring_index) * 19.0 + sin(cinematic_time * 2.0 + float(ring_index)) * 3.0, 0.0, TAU, 40, SyndicateSkins.accent() if ring_index % 2 == 0 else SyndicateSkins.secondary(), 2.0, true)
	for index: int in range(4):
		var angle: float = -PI * 0.75 + float(index) * PI * 0.5
		var position: Vector2 = table_center + Vector2(cos(angle), sin(angle)) * Vector2(165.0, 125.0)
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item(["Enforcer", "Runner", "Sharpshot", "Hacker"][index])), position, cinematic_time, float(index) * 0.25, -signf(cos(angle)), 0.0, 1.18, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "plan")
	Anim.draw_job_effect(self, table_center, "scan", cinematic_time, 0.3, 1.4, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())

func _draw_finale_cast() -> void:
	var beacon: Vector2 = Vector2(360.0, 350.0)
	for ring_index: int in range(5):
		var radius: float = 45.0 + float(ring_index) * 32.0 + sin(cinematic_time * 2.2 + float(ring_index)) * 8.0
		var ring_color: Color = SyndicateSkins.accent() if ring_index % 2 == 0 else SyndicateSkins.secondary()
		ring_color.a = 0.18 + float(ring_index) * 0.035
		draw_arc(beacon, radius, 0.0, TAU, 64, ring_color, 3.0, true)
	draw_line(Vector2(beacon.x, 85.0), Vector2(beacon.x, 700.0), Color(SyndicateSkins.accent(), 0.45), 12.0, true)
	for index: int in range(4):
		var position: Vector2 = Vector2(195.0 + float(index) * 110.0, 670.0)
		var role: String = ["Enforcer", "Runner", "Sharpshot", "Hacker"][index]
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item(role)), position, cinematic_time, float(index) * 0.24, 1.0, 0.0, 1.25, SyndicateSkins.secondary(), SyndicateSkins.accent(), SyndicateSkins.panel(), "celebrate")
		Anim.draw_job_effect(self, position + Vector2(0.0, -48.0), "celebrate", cinematic_time, float(index) * 0.24, 0.9, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())

func _draw_orbital_scan(position: Vector2, width_value: float) -> void:
	var alpha: float = 0.10 + (sin(cinematic_time * 2.0) + 1.0) * 0.06
	var cone: PackedVector2Array = PackedVector2Array([
		position + Vector2(-18.0, -130.0), position + Vector2(18.0, -130.0),
		position + Vector2(width_value * 0.5, 100.0), position + Vector2(-width_value * 0.5, 100.0)
	])
	draw_colored_polygon(cone, Color(SyndicateSkins.accent(), alpha))

func cinematic_actor_count() -> int:
	match key:
		"prologue": return 4 if stage != 1 else 3
		"ghost_key": return 3
		"war_room": return 4
		"finale": return 4
		_: return 3
