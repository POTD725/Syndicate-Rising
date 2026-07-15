extends "res://scripts/syndicate_operations.gd"
## Uses the exact displayed concept-board resources, defenses, threats, missions, frames, and buttons.

var skin_atlas: Texture2D

func _ready() -> void:
	super._ready()
	skin_atlas = SyndicateSkins.atlas()
	button_rects["skin"] = Rect2(408.0, 16.0, 92.0, 54.0)
	if not SyndicateSkins.skin_changed.is_connected(_on_skin_changed):
		SyndicateSkins.skin_changed.connect(_on_skin_changed)

func _on_skin_changed(_index: int) -> void:
	skin_atlas = SyndicateSkins.atlas()
	message = "Displayed Operations artwork changed to %s." % SyndicateSkins.skin_name()
	queue_redraw()

func _button_is_active(action: String) -> bool:
	if action == "skin":
		return true
	return super._button_is_active(action)

func _handle_action(action: String) -> void:
	if action == "skin":
		SyndicateSkins.cycle_skin()
		SyndicateAudio.play_sfx("click")
		return
	super._handle_action(action)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), SyndicateSkins.dark())
	var wash: Color = SyndicateSkins.accent()
	wash.a = 0.025
	draw_rect(Rect2(Vector2.ZERO, VIEW), wash, true)
	_draw_header()
	_draw_tabs()
	match active_tab:
		"harvest": _draw_harvest()
		"threat": _draw_threat()
		"defenses": _draw_defenses()
		_: _draw_missions()
	_draw_footer()

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, 720.0, 94.0), SyndicateSkins.panel(), true)
	draw_texture_rect_region(skin_atlas, Rect2(170.0, 7.0, 232.0, 72.0), SyndicateSkins.ui_frame_region())
	var veil: Color = SyndicateSkins.dark()
	veil.a = 0.50
	draw_rect(Rect2(170.0, 7.0, 232.0, 72.0), veil, true)
	draw_line(Vector2(0.0, 94.0), Vector2(720.0, 94.0), SyndicateSkins.accent(), 2.0)
	draw_texture_rect(EMBLEM, Rect2(112.0, 12.0, 54.0, 54.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(184.0, 35.0), "SYNDICATE OPERATIONS", HORIZONTAL_ALIGNMENT_LEFT, 215.0, 18, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(184.0, 62.0), "ALLOY %d  HE-3 %d  DATA %d  HEAT %d" % [SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.data_cores, SyndicateState.heat], HORIZONTAL_ALIGNMENT_LEFT, 215.0, 9, SyndicateSkins.accent())
	_draw_button(button_rects["back"] as Rect2, "BACK", false, 10)
	_draw_button(button_rects["skin"] as Rect2, "ART", true, 10)
	_draw_button(button_rects["chat"] as Rect2, "CHAT", false, 10)
	_draw_button(button_rects["save"] as Rect2, "SAVE", false, 10)

func _draw_harvest() -> void:
	super._draw_harvest()
	var site_ids: Array[String] = ["alloy", "helium", "cores"]
	var y_values: Array[float] = [498.0, 630.0, 762.0]
	for index: int in range(site_ids.size()):
		var item_id: String = "resource_" + site_ids[index]
		var art_rect: Rect2 = Rect2(358.0, y_values[index], 120.0, 88.0)
		draw_texture_rect_region(skin_atlas, art_rect, SyndicateSkins.region(item_id))
		draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 2, 10), art_rect)

func _draw_threat() -> void:
	super._draw_threat()
	var threat_type: String = "survey"
	if not SyndicateState.active_threat.is_empty():
		threat_type = String(SyndicateState.active_threat.get("type", "patrol"))
	var art_rect: Rect2 = Rect2(252.0, 252.0, 216.0, 248.0)
	draw_texture_rect_region(skin_atlas, art_rect, SyndicateSkins.region("threat_" + threat_type))
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.secondary(), 3, 16), art_rect)
	draw_string(ThemeDB.fallback_font, Vector2(112.0, 532.0), "ACTUAL DISPLAYED PEACEKEEPER ART", HORIZONTAL_ALIGNMENT_CENTER, 496.0, 10, SyndicateSkins.secondary())

func _draw_defenses() -> void:
	super._draw_defenses()
	var ids: Array[String] = ["jammer", "sentry", "blast_doors", "escape_tunnels"]
	var ys: Array[float] = [470.0, 574.0, 678.0, 782.0]
	for index: int in range(ids.size()):
		var art_rect: Rect2 = Rect2(280.0, ys[index], 92.0, 72.0)
		draw_texture_rect_region(skin_atlas, art_rect, SyndicateSkins.region("defense_" + ids[index]))
		draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 2, 9), art_rect)

func _draw_mission_button(action: String, title: String, subtitle: String) -> void:
	var rect: Rect2 = button_rects[action] as Rect2
	draw_style_box(SyndicateSkins.style_box(false, 10), rect)
	var item_id: String = "mission_hidden"
	match action:
		"mission_law": item_id = "mission_law_hack"
		"mission_cipher": item_id = "mission_syndicate_cipher"
		"mission_rescue": item_id = "mission_rescue"
	draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(7.0, 9.0), Vector2(62.0, 62.0)), SyndicateSkins.region(item_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(66.0, 35.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 74.0, 9, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(66.0, 62.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 74.0, 7, SyndicateSkins.accent())

func _draw_active_side_mission() -> void:
	super._draw_active_side_mission()
	var mode: String = SyndicateState.side_mission_mode
	var item_id: String = "mission_" + mode
	if mode == "law_hack":
		item_id = "mission_law_hack"
	elif mode == "syndicate_cipher":
		item_id = "mission_syndicate_cipher"
	var art_rect: Rect2 = Rect2(78.0, 226.0, 104.0, 104.0)
	draw_texture_rect_region(skin_atlas, art_rect, SyndicateSkins.region(item_id))
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.secondary(), 3, 14), art_rect)

func _draw_footer() -> void:
	draw_texture_rect_region(skin_atlas, Rect2(24.0, 1152.0, 672.0, 104.0), SyndicateSkins.ui_frame_region())
	var veil: Color = SyndicateSkins.dark()
	veil.a = 0.82
	draw_rect(Rect2(38.0, 1164.0, 644.0, 80.0), veil, true)
	_draw_wrapped(message, Vector2(48.0, 1190.0), 624.0, 10, SyndicateSkins.text())

func _draw_button(rect: Rect2, label: String, _active: bool, font_size: int) -> void:
	draw_texture_rect_region(skin_atlas, rect, SyndicateSkins.button_region())
	var cover: Color = SyndicateSkins.dark()
	cover.a = 0.79
	draw_rect(Rect2(rect.position + Vector2(12.0, 7.0), rect.size - Vector2(24.0, 14.0)), cover, true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, rect.size.y * 0.61), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, font_size, SyndicateSkins.text())
