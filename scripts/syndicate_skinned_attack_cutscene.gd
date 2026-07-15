extends "res://scripts/syndicate_attack_cutscene.gd"
## Uses the exact displayed concept-board attack scene and Peacekeeper unit paintings.

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
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 54.0), "ACTUAL MOONGOONS ATTACK ART • %s" % SyndicateSkins.skin_name().to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 660.0, 10, SyndicateSkins.secondary())

func _draw_attack_art() -> void:
	var background_index: int = 0
	match threat_type:
		"patrol": background_index = 1
		"cyber": background_index = 3
		"riot": background_index = 4
		_: background_index = 0
	var art_rect: Rect2 = Rect2(44.0, 104.0, 632.0, 520.0)
	draw_texture_rect_region(skin_atlas, art_rect, SyndicateSkins.cutscene_region(background_index))
	var shade: Color = SyndicateSkins.dark()
	shade.a = 0.18
	draw_rect(art_rect, shade, true)
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 4, 18), art_rect)
	var item_id: String = "threat_" + threat_type
	if threat_type.is_empty():
		item_id = "threat_patrol"
	var badge: Rect2 = Rect2(236.0, 350.0, 248.0, 268.0)
	draw_texture_rect_region(skin_atlas, badge, SyndicateSkins.region(item_id))
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.secondary(), 4, 20), badge)
	if threat_type == "cyber":
		for index: int in range(14):
			var y: float = 125.0 + fmod(float(index * 47) + elapsed * 44.0, 470.0)
			draw_rect(Rect2(58.0, y, 604.0, 3.0), Color(1.0, 0.2, 0.45, 0.13 + float(index % 3) * 0.06), true)

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
	_draw_concept_button(rect, title, subtitle)

func _draw_button(rect: Rect2, label: String, _fill: Color, _border: Color, font_size: int) -> void:
	draw_texture_rect_region(skin_atlas, rect, SyndicateSkins.button_region())
	var cover: Color = SyndicateSkins.dark()
	cover.a = 0.78
	draw_rect(Rect2(rect.position + Vector2(16.0, 8.0), rect.size - Vector2(32.0, 16.0)), cover, true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, rect.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, font_size, SyndicateSkins.text())

func _draw_concept_button(rect: Rect2, title: String, subtitle: String) -> void:
	draw_texture_rect_region(skin_atlas, rect, SyndicateSkins.button_region())
	var cover: Color = SyndicateSkins.dark()
	cover.a = 0.80
	draw_rect(Rect2(rect.position + Vector2(14.0, 7.0), rect.size - Vector2(28.0, 14.0)), cover, true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 31.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 11, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 56.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 8, SyndicateSkins.secondary())
