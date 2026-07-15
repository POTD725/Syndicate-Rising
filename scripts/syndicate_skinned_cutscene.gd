extends "res://scripts/syndicate_interactive_cutscene.gd"
## Places the exact displayed concept-board cutscene paintings into the interactive story.

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
	var art_index: int = _concept_cutscene_index()
	var art_rect: Rect2 = Rect2(40.0, 124.0, 640.0, 520.0)
	draw_texture_rect_region(skin_atlas, art_rect, SyndicateSkins.cutscene_region(art_index))
	var shade: Color = SyndicateSkins.dark()
	shade.a = 0.14
	draw_rect(art_rect, shade, true)
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 4, 18), art_rect)
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.secondary(), 2, 18), Rect2(16.0, 16.0, 688.0, 1248.0))
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 62.0), "ACTUAL MOONGOONS CONCEPT ART • %s" % SyndicateSkins.skin_name().to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 648.0, 10, SyndicateSkins.secondary())

func _concept_cutscene_index() -> int:
	if key == "ghost_key":
		return 3
	if key == "war_room":
		return 2
	if key == "finale":
		return 4
	match stage:
		0: return 4
		1: return 1
		_: return 2

func _draw_choice(choice_id: String, title: String, subtitle: String, _fill: Color) -> void:
	var rect: Rect2 = choice_rects[choice_id] as Rect2
	draw_style_box(SyndicateSkins.style_box(true, 10), rect)
	var item_id: String = "heal"
	if choice_id == "salvage":
		item_id = "construction"
	elif choice_id == "codes":
		item_id = "cipher"
	draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(10.0, 10.0), Vector2(62.0, 62.0)), SyndicateSkins.region(item_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(78.0, 34.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 94.0, 14, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(78.0, 61.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 94.0, 10, SyndicateSkins.accent())

func _draw_button(rect: Rect2, label: String, _fill: Color, _border: Color, font_size: int) -> void:
	_draw_concept_button(rect, label, font_size)

func _draw_concept_button(rect: Rect2, label: String, font_size: int) -> void:
	draw_texture_rect_region(skin_atlas, rect, SyndicateSkins.button_region())
	var cover: Color = SyndicateSkins.dark()
	cover.a = 0.78
	draw_rect(Rect2(rect.position + Vector2(16.0, 8.0), rect.size - Vector2(32.0, 16.0)), cover, true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, rect.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, font_size, SyndicateSkins.text())
