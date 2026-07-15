extends "res://scripts/syndicate_skinned_attack_cutscene.gd"
## Attack cinematics use the same base, station, roads, rooms, lighting, and unit language as the city board.

const ISO_ART: Script = preload("res://scripts/syndicate_isometric_assets.gd")

var board_texture: Texture2D

func _ready() -> void:
	board_texture = ISO_ART.board_texture()
	super._ready()

func _draw_attack_art() -> void:
	var art_rect: Rect2 = Rect2(42.0, 94.0, 636.0, 604.0)
	draw_texture_rect_region(board_texture, art_rect, _attack_source_rect())
	draw_rect(art_rect, Color(0.01, 0.02, 0.04, 0.16), true)
	match threat_type:
		"survey": _draw_survey_attack(art_rect)
		"cyber": _draw_cyber_attack(art_rect)
		"riot": _draw_riot_attack(art_rect)
		_: _draw_patrol_attack(art_rect)
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.secondary(), 4, 18), art_rect)
	var item_id: String = "threat_" + (threat_type if not threat_type.is_empty() else "patrol")
	draw_texture_rect_region(skin_atlas, Rect2(58.0, 112.0, 76.0, 76.0), SyndicateSkins.region(item_id))

func _attack_source_rect() -> Rect2:
	match threat_type:
		"survey": return Rect2(76.0, 0.0, 790.0, 840.0)
		"cyber": return Rect2(0.0, 180.0, 790.0, 930.0)
		"riot": return Rect2(116.0, 286.0, 790.0, 930.0)
		_: return Rect2(72.0, 110.0, 790.0, 900.0)

func _draw_survey_attack(rect: Rect2) -> void:
	var sweep: float = rect.position.x + 80.0 + fmod(elapsed * 82.0, rect.size.x - 160.0)
	var cone: PackedVector2Array = PackedVector2Array([
		Vector2(rect.end.x - 118.0, rect.position.y + 38.0),
		Vector2(rect.end.x - 74.0, rect.position.y + 43.0),
		Vector2(sweep + 94.0, rect.end.y - 12.0),
		Vector2(sweep - 94.0, rect.end.y - 12.0)
	])
	draw_colored_polygon(cone, Color(0.32, 0.84, 1.0, 0.17))
	for drone_index: int in range(5):
		var phase: float = fmod(elapsed * (0.11 + float(drone_index) * 0.012) + float(drone_index) * 0.18, 1.0)
		var pos: Vector2 = Vector2(rect.position.x - 30.0, rect.position.y + 110.0 + float(drone_index) * 72.0).lerp(Vector2(rect.end.x + 30.0, rect.position.y + 70.0 + float(drone_index) * 68.0), phase)
		draw_circle(pos, 8.0, Color("dcecf5"))
		draw_line(pos + Vector2(-14.0, 0.0), pos + Vector2(14.0, 0.0), Color("69eaff"), 3.0)
		draw_circle(pos + Vector2(0.0, 3.0), 3.0, Color("ff4e68"))
		draw_line(pos + Vector2(0.0, 8.0), Vector2(pos.x + sin(elapsed + float(drone_index)) * 22.0, rect.end.y - 18.0), Color(0.33, 0.88, 1.0, 0.18), 2.0)

func _draw_patrol_attack(rect: Rect2) -> void:
	for vehicle_index: int in range(4):
		var phase: float = fmod(elapsed * (0.075 + float(vehicle_index) * 0.008) + float(vehicle_index) * 0.21, 1.0)
		var start: Vector2 = Vector2(rect.end.x + 50.0, rect.position.y + 130.0 + float(vehicle_index) * 92.0)
		var finish: Vector2 = Vector2(rect.position.x + 116.0 + float(vehicle_index) * 68.0, rect.end.y - 92.0)
		_draw_police_rover(start.lerp(finish, phase), vehicle_index)
	for deputy_index: int in range(8):
		var phase: float = fmod(elapsed * (0.085 + float(deputy_index) * 0.004) + float(deputy_index) * 0.10, 1.0)
		var pos: Vector2 = Vector2(rect.end.x - 90.0 - float(deputy_index % 3) * 28.0, rect.position.y + 160.0).lerp(Vector2(rect.position.x + 240.0 + float(deputy_index % 4) * 32.0, rect.end.y - 70.0), phase)
		_draw_attack_person(pos, Color("4f8bc4"), true, deputy_index)
		if phase > 0.76:
			var capture_ring: float = 8.0 + abs(sin(elapsed * 4.0 + float(deputy_index))) * 8.0
			draw_arc(pos, capture_ring, 0.0, TAU, 22, Color("ffbe65", 0.46), 2.0)

func _draw_cyber_attack(rect: Rect2) -> void:
	var hub: Vector2 = rect.get_center()
	for node_index: int in range(16):
		var column: int = node_index % 4
		var row: int = int(node_index / 4)
		var node: Vector2 = rect.position + Vector2(104.0 + float(column) * 145.0, 115.0 + float(row) * 112.0)
		var infected: bool = int(elapsed * 4.0 + float(node_index)) % 3 != 0
		draw_line(node, hub, Color(0.38, 0.88, 1.0, 0.15), 2.0)
		draw_circle(node, 13.0 + sin(elapsed * 3.0 + float(node_index)) * 3.0, Color("ff4e89", 0.72) if infected else Color("68eaff", 0.72))
		draw_circle(node, 23.0, Color(1.0, 0.22, 0.48, 0.06) if infected else Color(0.32, 0.86, 1.0, 0.06))
	for line_index: int in range(24):
		var y: float = rect.position.y + fmod(float(line_index * 37) + elapsed * 66.0, rect.size.y)
		draw_rect(Rect2(rect.position.x + 8.0, y, rect.size.x - 16.0, 3.0), Color(1.0, 0.18, 0.45, 0.06 + float(line_index % 3) * 0.04), true)
	draw_arc(hub, 52.0 + sin(elapsed * 2.6) * 11.0, 0.0, TAU, 36, Color("c65cff", 0.84), 4.0)

func _draw_riot_attack(rect: Rect2) -> void:
	var door_center: Vector2 = Vector2(rect.get_center().x, rect.end.y - 86.0)
	var impact: float = maxf(0.0, sin(elapsed * 3.6))
	draw_circle(door_center, 26.0 + impact * 46.0, Color(1.0, 0.32, 0.10, 0.08 + impact * 0.19))
	draw_line(door_center + Vector2(-62.0, 0.0), door_center + Vector2(62.0, 0.0), Color("ff8a55", 0.38 + impact * 0.40), 8.0)
	for riot_index: int in range(12):
		var column: int = riot_index % 4
		var row: int = int(riot_index / 4)
		var march: float = fmod(elapsed * 0.11 + float(row) * 0.12, 1.0)
		var start: Vector2 = Vector2(rect.position.x + 140.0 + float(column) * 105.0, rect.position.y + 85.0 + float(row) * 82.0)
		var finish: Vector2 = Vector2(door_center.x - 120.0 + float(column) * 80.0, door_center.y - 45.0 - float(row) * 28.0)
		var pos: Vector2 = start.lerp(finish, march)
		_draw_attack_person(pos, Color("324b66"), true, riot_index)
		draw_rect(Rect2(pos + Vector2(-13.0, -10.0), Vector2(10.0, 23.0)), Color(0.20, 0.35, 0.48, 0.82), true)

func _draw_police_rover(pos: Vector2, index: int) -> void:
	draw_rect(Rect2(pos + Vector2(-28.0, -11.0), Vector2(56.0, 22.0)), Color("182a40"), true)
	draw_rect(Rect2(pos + Vector2(-12.0, -20.0), Vector2(26.0, 11.0)), Color("2d4f6b"), true)
	draw_circle(pos + Vector2(-18.0, 14.0), 8.0, Color("05080d"))
	draw_circle(pos + Vector2(18.0, 14.0), 8.0, Color("05080d"))
	var flash: bool = int(elapsed * 7.0 + float(index)) % 2 == 0
	draw_circle(pos + Vector2(-6.0, -22.0), 4.0, Color("ff3f5e") if flash else Color("4f7fff"))
	draw_circle(pos + Vector2(6.0, -22.0), 4.0, Color("4f7fff") if flash else Color("ff3f5e"))

func _draw_attack_person(pos: Vector2, color: Color, walking: bool, index: int) -> void:
	var stride: float = sin(elapsed * (11.0 if walking else 4.0) + float(index)) * (6.0 if walking else 2.0)
	draw_circle(pos + Vector2(0.0, -11.0), 5.0, Color("d8b18e"))
	draw_rect(Rect2(pos + Vector2(-6.0, -6.0), Vector2(12.0, 15.0)), color, true)
	draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(-5.0 + stride, 20.0), color.lightened(0.15), 3.0)
	draw_line(pos + Vector2(0.0, 8.0), pos + Vector2(5.0 - stride, 20.0), color.lightened(0.15), 3.0)
	draw_line(pos + Vector2(-5.0, -2.0), pos + Vector2(-10.0 - stride * 0.4, 7.0), color, 2.0)
	draw_line(pos + Vector2(5.0, -2.0), pos + Vector2(10.0 + stride * 0.4, 7.0), color, 2.0)

func uses_isometric_board() -> bool:
	return board_texture != null and board_texture.get_size().x >= 900.0
