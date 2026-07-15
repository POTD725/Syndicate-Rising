extends "res://scripts/syndicate_operations.gd"
## Applies the selected skin family to every Operations item and control.

var skin_atlas: Texture2D

func _ready() -> void:
	super._ready()
	skin_atlas = SyndicateSkins.atlas()
	button_rects["skin"] = Rect2(408.0, 16.0, 92.0, 54.0)
	if not SyndicateSkins.skin_changed.is_connected(_on_skin_changed):
		SyndicateSkins.skin_changed.connect(_on_skin_changed)

func _on_skin_changed(_index: int) -> void:
	skin_atlas = SyndicateSkins.atlas()
	message = "Operations restyled as %s." % SyndicateSkins.skin_name()
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
	draw_line(Vector2(0.0, 94.0), Vector2(720.0, 94.0), SyndicateSkins.accent(), 2.0)
	draw_texture_rect(EMBLEM, Rect2(112.0, 12.0, 62.0, 62.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(184.0, 36.0), "SYNDICATE OPERATIONS", HORIZONTAL_ALIGNMENT_LEFT, 215.0, 19, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(184.0, 62.0), "ALLOY %d  HE-3 %d  DATA %d  HEAT %d" % [SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.data_cores, SyndicateState.heat], HORIZONTAL_ALIGNMENT_LEFT, 215.0, 9, SyndicateSkins.accent())
	_draw_button(button_rects["back"] as Rect2, "BACK", false, 10)
	_draw_button(button_rects["skin"] as Rect2, "SKIN", true, 10)
	_draw_button(button_rects["chat"] as Rect2, "CHAT", false, 10)
	_draw_button(button_rects["save"] as Rect2, "SAVE", false, 10)

func _draw_harvest() -> void:
	super._draw_harvest()
	var site_ids: Array[String] = ["alloy", "helium", "cores"]
	var y_values: Array[float] = [503.0, 635.0, 767.0]
	for index: int in range(site_ids.size()):
		var item_id: String = "resource_" + site_ids[index]
		draw_texture_rect_region(skin_atlas, Rect2(400.0, y_values[index], 78.0, 78.0), SyndicateSkins.region(item_id))

func _draw_threat() -> void:
	super._draw_threat()
	var threat_type: String = "survey"
	if not SyndicateState.active_threat.is_empty():
		threat_type = String(SyndicateState.active_threat.get("type", "patrol"))
	draw_texture_rect_region(skin_atlas, Rect2(272.0, 278.0, 176.0, 176.0), SyndicateSkins.region("threat_" + threat_type))
	draw_string(ThemeDB.fallback_font, Vector2(112.0, 532.0), SyndicateSkins.skin_name().to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 496.0, 10, SyndicateSkins.secondary())

func _draw_defenses() -> void:
	super._draw_defenses()
	var ids: Array[String] = ["jammer", "sentry", "blast_doors", "escape_tunnels"]
	var ys: Array[float] = [476.0, 580.0, 684.0, 788.0]
	for index: int in range(ids.size()):
		draw_texture_rect_region(skin_atlas, Rect2(308.0, ys[index], 58.0, 58.0), SyndicateSkins.region("defense_" + ids[index]))

func _draw_mission_button(action: String, title: String, subtitle: String) -> void:
	var rect: Rect2 = button_rects[action] as Rect2
	draw_style_box(SyndicateSkins.style_box(false, 10), rect)
	var item_id: String = "mission_hidden"
	match action:
		"mission_law": item_id = "mission_law_hack"
		"mission_cipher": item_id = "mission_syndicate_cipher"
		"mission_rescue": item_id = "mission_rescue"
	draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(7.0, 10.0), Vector2(54.0, 54.0)), SyndicateSkins.region(item_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(60.0, 35.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 68.0, 9, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(60.0, 62.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 68.0, 7, SyndicateSkins.accent())

func _draw_active_side_mission() -> void:
	super._draw_active_side_mission()
	var mode: String = SyndicateState.side_mission_mode
	var item_id: String = "mission_" + mode
	if mode == "law_hack":
		item_id = "mission_law_hack"
	elif mode == "syndicate_cipher":
		item_id = "mission_syndicate_cipher"
	draw_texture_rect_region(skin_atlas, Rect2(78.0, 226.0, 82.0, 82.0), SyndicateSkins.region(item_id))

func _draw_footer() -> void:
	draw_style_box(SyndicateSkins.style_box(false, 10), Rect2(24.0, 1152.0, 672.0, 104.0))
	_draw_wrapped(message, Vector2(42.0, 1188.0), 636.0, 10, SyndicateSkins.text())

func _draw_button(rect: Rect2, label: String, active: bool, font_size: int) -> void:
	draw_style_box(SyndicateSkins.style_box(active, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, rect.size.y * 0.61), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, font_size, SyndicateSkins.text())
