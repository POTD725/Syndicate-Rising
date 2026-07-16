extends "res://scripts/syndicate_interactive_cutscene.gd"
## Interactive prologue and story interstitials rendered from the same isometric city art.

const ART_LIBRARY: Script = preload("res://scripts/syndicate_full_art.gd")

var full_scene_texture: Texture2D
var cinematic_elapsed: float = 0.0

func _ready() -> void:
	super._ready()
	full_scene_texture = ART_LIBRARY.cutscene_texture(key)

func uses_isometric_board() -> bool:
	return full_scene_texture != null and full_scene_texture.get_size().x >= 720.0

func _process(delta: float) -> void:
	cinematic_elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("030711"))
	var drift: float = sin(cinematic_elapsed * 0.18) * 8.0
	draw_texture_rect(full_scene_texture, Rect2(-8.0 + drift, -4.0, 736.0, 1292.0), false)
	_draw_cinematic_activity()
	if key == "prologue":
		_draw_prologue()
	else:
		_draw_story_interstitial()

func _draw_cinematic_activity() -> void:
	var station_pulse: float = 0.20 + sin(cinematic_elapsed * 2.2) * 0.08
	draw_circle(Vector2(360.0, 162.0), 74.0 + sin(cinematic_elapsed) * 3.0, Color(0.25, 0.85, 1.0, station_pulse))
	for index: int in range(5):
		var phase: float = fmod(cinematic_elapsed * (0.035 + float(index) * 0.004) + float(index) * 0.2, 1.0)
		var start: Vector2 = Vector2(90.0 + float(index) * 118.0, 720.0 - float(index % 2) * 60.0)
		var finish: Vector2 = Vector2(560.0 - float(index) * 76.0, 530.0 + float(index % 3) * 40.0)
		var position: Vector2 = start.lerp(finish, phase)
		draw_circle(position, 5.0, Color("4ee7ff"))
		draw_line(position + Vector2(-9.0, 0.0), position + Vector2(9.0, 0.0), Color("8c54d8"), 2.0)
	if key == "prologue" and stage == 0:
		var flash: float = maxf(0.0, sin(cinematic_elapsed * 2.8)) * 0.18
		draw_rect(Rect2(0.0, 0.0, 720.0, 830.0), Color(1.0, 0.28, 0.18, flash), true)

func _draw_button(rect: Rect2, label: String, _fill: Color, _border: Color, font_size: int) -> void:
	draw_style_box(_panel(Color("1b3145"), Color("4ee7ff"), 3, 12), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 52.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, font_size, Color("f5fbff"))

func _draw_choice(choice_id: String, title: String, subtitle: String, _fill: Color) -> void:
	var rect: Rect2 = choice_rects[choice_id] as Rect2
	var accent: Color = Color("56d6a2")
	if choice_id == "salvage":
		accent = Color("ff9a4a")
	elif choice_id == "codes":
		accent = Color("8c54d8")
	draw_style_box(_panel(Color("101c2a"), accent, 3, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 34.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36.0, 14, Color("f8fbff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 61.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36.0, 10, Color("c4d3dd"))
