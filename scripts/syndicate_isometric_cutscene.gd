extends "res://scripts/syndicate_skinned_cutscene.gd"
## Story cinematics staged directly over the same isometric lunar-city artwork used by gameplay.

const ISO_ART: Script = preload("res://scripts/syndicate_isometric_assets.gd")

var board_texture: Texture2D
var cinematic_elapsed: float = 0.0

func _ready() -> void:
	board_texture = ISO_ART.board_texture()
	super._ready()

func _process(delta: float) -> void:
	cinematic_elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("02050b"), true)
	_draw_isometric_camera_shot()
	_draw_matching_story_animation()
	var shade: float = 0.18 if key == "prologue" and stage == 0 else 0.30
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.01, 0.015, 0.03, shade), true)
	if key == "prologue":
		_draw_prologue()
	else:
		_draw_story_interstitial()
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 3, 18), Rect2(16.0, 16.0, 688.0, 1248.0))
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 56.0), "ISOMETRIC LUNAR CINEMATIC • %s" % SyndicateSkins.skin_name().to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 648.0, 10, SyndicateSkins.secondary())

func _draw_isometric_camera_shot() -> void:
	var source: Rect2 = _cinematic_source_rect()
	var drift: Vector2 = Vector2(sin(cinematic_elapsed * 0.18) * 9.0, cos(cinematic_elapsed * 0.13) * 7.0)
	var target: Rect2 = Rect2(-18.0 + drift.x, -18.0 + drift.y, 756.0, 1054.0)
	draw_texture_rect_region(board_texture, target, source)
	# Dark lunar sky extension under the board crop.
	draw_rect(Rect2(0.0, 1010.0, 720.0, 270.0), Color("030712"), true)

func _cinematic_source_rect() -> Rect2:
	match key:
		"ghost_key":
			return Rect2(0.0, 158.0, 760.0, 1060.0)
		"war_room":
			return Rect2(146.0, 110.0, 720.0, 1040.0)
		"finale":
			return Rect2(40.0, 0.0, 820.0, 1120.0)
		_:
			return Rect2(92.0, 0.0, 760.0, 1060.0)

func _draw_matching_story_animation() -> void:
	match key:
		"prologue": _draw_prologue_attack()
		"ghost_key": _draw_ghost_key_animation()
		"war_room": _draw_war_room_animation()
		"finale": _draw_finale_animation()
		_: _draw_prologue_attack()

func _draw_prologue_attack() -> void:
	var scan_x: float = 90.0 + fmod(cinematic_elapsed * 74.0, 540.0)
	var scan_cone: PackedVector2Array = PackedVector2Array([
		Vector2(530.0, 122.0), Vector2(575.0, 130.0), Vector2(scan_x + 82.0, 715.0), Vector2(scan_x - 82.0, 715.0)
	])
	draw_colored_polygon(scan_cone, Color(0.25, 0.78, 1.0, 0.13))
	for shuttle_index: int in range(3):
		var phase: float = fmod(cinematic_elapsed * (0.09 + float(shuttle_index) * 0.013) + float(shuttle_index) * 0.28, 1.0)
		var pos: Vector2 = Vector2(740.0, 188.0 + float(shuttle_index) * 72.0).lerp(Vector2(418.0, 520.0 + float(shuttle_index) * 38.0), phase)
		_draw_police_shuttle(pos, phase)
	for evacuee: int in range(7):
		var t: float = fmod(cinematic_elapsed * (0.11 + float(evacuee) * 0.006) + float(evacuee) * 0.13, 1.0)
		var pos: Vector2 = Vector2(98.0 + float(evacuee % 3) * 32.0, 742.0).lerp(Vector2(320.0, 890.0), t)
		_draw_cinematic_person(pos, Color("ff9a67") if evacuee % 2 == 0 else Color("72dfff"), true)
	var flash: float = maxf(0.0, sin(cinematic_elapsed * 4.7))
	draw_circle(Vector2(238.0, 592.0), 18.0 + flash * 30.0, Color(1.0, 0.33, 0.12, 0.08 + flash * 0.17))

func _draw_ghost_key_animation() -> void:
	var hub: Vector2 = Vector2(365.0, 448.0)
	for node_index: int in range(10):
		var angle: float = float(node_index) * TAU / 10.0 + cinematic_elapsed * 0.18
		var radius: float = 112.0 + sin(cinematic_elapsed * 1.7 + float(node_index)) * 18.0
		var node: Vector2 = hub + Vector2(cos(angle), sin(angle)) * radius
		draw_line(hub, node, Color(0.46, 0.89, 1.0, 0.20), 2.0)
		draw_circle(node, 8.0, Color(0.72, 0.34, 1.0, 0.62))
		draw_circle(node, 15.0, Color(0.46, 0.89, 1.0, 0.08))
	draw_arc(hub, 42.0 + sin(cinematic_elapsed * 2.4) * 8.0, 0.0, TAU, 36, Color("70edff", 0.78), 4.0)
	for hacker_index: int in range(4):
		var pos: Vector2 = Vector2(255.0 + float(hacker_index) * 72.0, 570.0 + sin(cinematic_elapsed * 2.0 + float(hacker_index)) * 5.0)
		_draw_cinematic_person(pos, Color("b66dff"), false)
		draw_rect(Rect2(pos + Vector2(9.0, -21.0), Vector2(24.0, 16.0)), Color("091525"), true)
		draw_rect(Rect2(pos + Vector2(12.0, -18.0), Vector2(18.0, 10.0)), Color(0.32, 0.88, 1.0, 0.35 + 0.35 * sin(cinematic_elapsed * 4.0 + float(hacker_index))), true)

func _draw_war_room_animation() -> void:
	for light_index: int in range(12):
		var x: float = 58.0 + float(light_index) * 55.0
		var on: bool = int(cinematic_elapsed * 5.0 + float(light_index)) % 2 == 0
		draw_circle(Vector2(x, 132.0), 5.0, Color("ff405b") if on else Color("30415e"))
	for convoy_index: int in range(4):
		var phase: float = fmod(cinematic_elapsed * 0.075 + float(convoy_index) * 0.23, 1.0)
		var pos: Vector2 = Vector2(-70.0, 626.0 + float(convoy_index) * 48.0).lerp(Vector2(780.0, 470.0 + float(convoy_index) * 32.0), phase)
		_draw_armored_rover(pos, convoy_index % 2 == 0)
	var command_center: Vector2 = Vector2(344.0, 476.0)
	draw_arc(command_center, 60.0 + sin(cinematic_elapsed * 2.3) * 8.0, 0.0, TAU, 42, Color("ff6b58", 0.68), 4.0)
	draw_line(command_center + Vector2(-85.0, 0.0), command_center + Vector2(85.0, 0.0), Color("ff9b62", 0.26), 2.0)

func _draw_finale_animation() -> void:
	var tower: Vector2 = Vector2(360.0, 404.0)
	var pulse: float = 0.5 + sin(cinematic_elapsed * 2.8) * 0.5
	for ring_index: int in range(5):
		draw_arc(tower, 36.0 + float(ring_index) * 34.0 + pulse * 12.0, 0.0, TAU, 48, Color(0.55, 0.26 + float(ring_index) * 0.06, 1.0, 0.32 - float(ring_index) * 0.04), 3.0)
	draw_line(Vector2(360.0, 0.0), tower, Color(0.58, 0.34, 1.0, 0.28 + pulse * 0.22), 12.0)
	for celebration_index: int in range(12):
		var base: Vector2 = Vector2(90.0 + float(celebration_index % 6) * 105.0, 735.0 + float(celebration_index / 6) * 74.0)
		var jump: float = abs(sin(cinematic_elapsed * 3.0 + float(celebration_index))) * 13.0
		_draw_cinematic_person(base - Vector2(0.0, jump), Color("75efd5") if celebration_index % 2 == 0 else Color("ff8bc8"), false)

func _draw_police_shuttle(pos: Vector2, phase: float) -> void:
	draw_rect(Rect2(pos + Vector2(-25.0, -9.0), Vector2(50.0, 18.0)), Color("20344e"), true)
	draw_rect(Rect2(pos + Vector2(-12.0, -17.0), Vector2(26.0, 10.0)), Color("355776"), true)
	draw_line(pos + Vector2(-34.0, 2.0), pos + Vector2(34.0, 2.0), Color("78dfff"), 3.0)
	var flash: bool = int(cinematic_elapsed * 7.0 + phase * 10.0) % 2 == 0
	draw_circle(pos + Vector2(-8.0, -19.0), 4.0, Color("ff435c") if flash else Color("4f7dff"))
	draw_circle(pos + Vector2(8.0, -19.0), 4.0, Color("4f7dff") if flash else Color("ff435c"))

func _draw_armored_rover(pos: Vector2, police: bool) -> void:
	draw_rect(Rect2(pos + Vector2(-24.0, -10.0), Vector2(48.0, 20.0)), Color("1c2d43") if police else Color("5b3a27"), true)
	draw_rect(Rect2(pos + Vector2(-10.0, -18.0), Vector2(22.0, 10.0)), Color("324e69") if police else Color("8a5c38"), true)
	draw_circle(pos + Vector2(-15.0, 12.0), 7.0, Color("05080d"))
	draw_circle(pos + Vector2(15.0, 12.0), 7.0, Color("05080d"))
	if police:
		draw_circle(pos + Vector2(0.0, -20.0), 4.0, Color("ff4b67") if int(cinematic_elapsed * 6.0) % 2 == 0 else Color("4b7dff"))

func _draw_cinematic_person(pos: Vector2, color: Color, running: bool) -> void:
	var stride: float = sin(cinematic_elapsed * (10.0 if running else 4.0) + pos.x * 0.03) * (6.0 if running else 2.0)
	draw_circle(pos + Vector2(0.0, -10.0), 5.0, Color("dcb58f"))
	draw_rect(Rect2(pos + Vector2(-5.0, -5.0), Vector2(10.0, 14.0)), color.darkened(0.22), true)
	draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(-5.0 + stride, 19.0), color, 3.0)
	draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(5.0 - stride, 19.0), color, 3.0)
	draw_line(pos + Vector2(-4.0, -1.0), pos + Vector2(-8.0 - stride * 0.5, 7.0), color, 2.0)
	draw_line(pos + Vector2(4.0, -1.0), pos + Vector2(8.0 + stride * 0.5, 7.0), color, 2.0)

func uses_isometric_board() -> bool:
	return board_texture != null and board_texture.get_size().x >= 900.0
