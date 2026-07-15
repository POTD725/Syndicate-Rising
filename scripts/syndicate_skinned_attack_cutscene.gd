extends "res://scripts/syndicate_attack_cutscene.gd"
## Uses the selected complete skin family for attack units and response controls.

var skin_atlas: Texture2D

func _ready() -> void:
	skin_atlas = SyndicateSkins.atlas()
	if not SyndicateSkins.skin_changed.is_connected(_on_skin_changed):
		SyndicateSkins.skin_changed.connect(_on_skin_changed)
	super._ready()

func _on_skin_changed(_index: int) -> void:
	skin_atlas = SyndicateSkins.atlas()
	queue_redraw()

func _draw() -> void:
	super._draw()
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 3, 14), Rect2(18.0, 18.0, 684.0, 1244.0))
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 52.0), SyndicateSkins.skin_name().to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 660.0, 11, SyndicateSkins.secondary())

func _draw_attack_art() -> void:
	super._draw_attack_art()
	var item_id: String = "threat_" + threat_type
	if threat_type.is_empty():
		item_id = "threat_patrol"
	var badge: Rect2 = Rect2(246.0, 286.0, 228.0, 228.0)
	draw_texture_rect_region(skin_atlas, badge, SyndicateSkins.region(item_id))
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.secondary(), 4, 24), badge)

func _background_color() -> Color:
	var value: Color = SyndicateSkins.dark()
	if threat_type == "cyber":
		value = value.lerp(Color("210a26"), 0.45)
	elif threat_type == "riot":
		value = value.lerp(Color("2b0b08"), 0.45)
	return value

func _accent_color() -> Color:
	return SyndicateSkins.accent()

func _draw_response_button(action: String, title: String, subtitle: String, _fill: Color) -> void:
	var rect: Rect2 = button_rects[action] as Rect2
	draw_style_box(SyndicateSkins.style_box(true, 10), rect)
	var item_id: String = "weapons"
	if action == "hide":
		item_id = "lock"
	elif action == "counter_hack":
		item_id = "cipher"
	draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(8.0, 10.0), Vector2(48.0, 48.0)), SyndicateSkins.region(item_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(52.0, 31.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 60.0, 11, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(52.0, 56.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 60.0, 8, SyndicateSkins.secondary())

func _draw_button(rect: Rect2, label: String, _fill: Color, _border: Color, font_size: int) -> void:
	draw_style_box(SyndicateSkins.style_box(true, 12), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 52.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, font_size, SyndicateSkins.text())
