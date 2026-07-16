extends "res://scripts/syndicate_attack_cutscene.gd"
## Peacekeeper attack cinematics staged over the same isometric lunar district art.

const ART_LIBRARY: Script = preload("res://scripts/syndicate_full_art.gd")

var full_attack_texture: Texture2D

func _ready() -> void:
	super._ready()
	full_attack_texture = ART_LIBRARY.attack_texture(threat_type)

func uses_isometric_board() -> bool:
	return full_attack_texture != null and full_attack_texture.get_size().x >= 720.0

func _draw_attack_art() -> void:
	if full_attack_texture == null:
		full_attack_texture = ART_LIBRARY.attack_texture(threat_type)
	draw_texture_rect(full_attack_texture, Rect2(0.0, 54.0, 720.0, 650.0), false)
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), _accent_color(), 4, 18), Rect2(26.0, 78.0, 668.0, 600.0))
	_draw_attack_motion()

func _draw_attack_motion() -> void:
	match threat_type:
		"survey":
			var scan_x: float = 120.0 + fmod(elapsed * 92.0, 480.0)
			var cone: PackedVector2Array = PackedVector2Array([Vector2(scan_x - 18.0, 178.0), Vector2(scan_x + 18.0, 178.0), Vector2(scan_x + 108.0, 650.0), Vector2(scan_x - 108.0, 650.0)])
			draw_colored_polygon(cone, Color(0.25, 0.88, 1.0, 0.22))
		"patrol":
			for index: int in range(4):
				var phase: float = fmod(elapsed * (0.10 + float(index) * 0.012) + float(index) * 0.22, 1.0)
				var position: Vector2 = Vector2(90.0 + float(index) * 45.0, 580.0).lerp(Vector2(430.0 + float(index) * 35.0, 410.0), phase)
				draw_circle(position, 10.0, Color("29445a"))
				draw_line(position + Vector2(-8.0, -2.0), position + Vector2(12.0, -12.0), Color("4ee7ff"), 3.0)
		"riot":
			var breach: float = maxf(0.0, sin(elapsed * 3.0)) * 0.30
			draw_circle(Vector2(360.0, 472.0), 58.0 + breach * 40.0, Color(1.0, 0.26, 0.18, 0.14 + breach))
			for index: int in range(8):
				var angle: float = elapsed * 2.2 + float(index) * TAU / 8.0
				draw_line(Vector2(360.0, 472.0), Vector2(360.0, 472.0) + Vector2(cos(angle), sin(angle)) * (68.0 + breach * 25.0), Color(1.0, 0.58, 0.25, 0.55), 3.0)
		"cyber":
			for index: int in range(20):
				var y: float = 100.0 + fmod(float(index * 39) + elapsed * 65.0, 540.0)
				draw_rect(Rect2(42.0, y, 636.0, 3.0), Color(1.0, 0.20, 0.48, 0.09 + float(index % 4) * 0.04), true)
			for node_index: int in range(7):
				var x: float = 100.0 + float(node_index % 4) * 172.0
				var y: float = 245.0 + float(int(node_index / 4)) * 205.0
				draw_circle(Vector2(x, y), 12.0 + sin(elapsed * 2.0 + float(node_index)) * 3.0, Color("e6539b"))
				draw_line(Vector2(x, y), Vector2(360.0, 420.0), Color(0.30, 0.91, 1.0, 0.34), 2.0)

func _draw_response_button(action: String, title: String, subtitle: String, _fill: Color) -> void:
	var rect: Rect2 = button_rects[action] as Rect2
	var accent: Color = Color("ff9a4a")
	if action == "hide":
		accent = Color("56d6a2")
	elif action == "counter_hack":
		accent = Color("8c54d8")
	draw_style_box(_panel(Color("101c2a"), accent, 3, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 31.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 12, Color("f7fbff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 56.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 8, Color("c4d3dd"))

func _draw_button(rect: Rect2, label: String, _fill: Color, _border: Color, font_size: int) -> void:
	draw_style_box(_panel(Color("1b3145"), Color("4ee7ff"), 3, 12), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 52.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, font_size, Color("f5fbff"))
