extends "res://scripts/syndicate_feature_city.gd"
## Displays the exact concept-board moon base, room interiors, and crew artwork.

var skin_atlas: Texture2D

func _ready() -> void:
	super._ready()
	skin_atlas = SyndicateSkins.atlas()
	button_rects["skin"] = Rect2(329.0, 104.0, 96.0, 38.0)
	if not SyndicateSkins.skin_changed.is_connected(_on_skin_changed):
		SyndicateSkins.skin_changed.connect(_on_skin_changed)

func _on_skin_changed(_index: int) -> void:
	skin_atlas = SyndicateSkins.atlas()
	message = "Displayed artwork changed to %s." % SyndicateSkins.skin_name()
	queue_redraw()

func _action(action: String) -> void:
	if action == "skin":
		SyndicateSkins.cycle_skin()
		SyndicateAudio.play_sfx("click")
		return
	super._action(action)

func _draw_world() -> void:
	_draw_deep_space()
	_draw_orbiting_station()
	draw_texture_rect(SURFACE_ART, Rect2(-500.0, -315.0, 1000.0, 292.0), false)
	# This is the actual moon-base artwork from the concept sheet shown in chat.
	var base_rect: Rect2 = Rect2(-310.0, -286.0, 620.0, 232.0)
	draw_texture_rect_region(skin_atlas, base_rect, SyndicateSkins.base_region())
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 3, 14), base_rect)
	_draw_surface_activity()
	draw_texture_rect(HIDEOUT_ART, Rect2(-350.0, -95.0, 700.0, 540.0), false)
	_draw_room_states()
	_draw_crew_activity()
	_draw_ambient_effects()

func _draw_deep_space() -> void:
	super._draw_deep_space()
	var wash: Color = SyndicateSkins.accent()
	wash.a = 0.035
	draw_rect(Rect2(-900.0, -700.0, 1800.0, 1500.0), wash, true)

func _draw_room_states() -> void:
	for room_id: String in ROOM_IDS:
		var room: Dictionary = SyndicateState.get_room(room_id)
		if room.is_empty():
			continue
		var rect: Rect2 = room_rects[room_id] as Rect2
		var repaired: bool = bool(room.get("repaired", false))
		var selected: bool = room_id == selected_room
		# Each room now uses one of the actual displayed room-interior paintings.
		var art_rect: Rect2 = Rect2(rect.position + Vector2(5.0, 3.0), Vector2(112.0, 51.0))
		draw_texture_rect_region(skin_atlas, art_rect, SyndicateSkins.region(SyndicateSkins.room_item(room_id)))
		var glow: Color = SyndicateSkins.accent()
		glow.a = 0.16 if repaired else 0.05
		draw_rect(Rect2(rect.position + Vector2(120.0, 5.0), Vector2(rect.size.x - 126.0, 47.0)), glow, true)
		if not repaired:
			draw_rect(rect, Color(0.08, 0.03, 0.05, 0.66), true)
			for slash: int in range(5):
				var sx: float = rect.position.x + 18.0 + float(slash) * 61.0
				draw_line(Vector2(sx, rect.position.y + 8.0), Vector2(sx + 42.0, rect.end.y - 8.0), SyndicateSkins.danger(), 2.0)
		var border: Color = SyndicateSkins.secondary() if selected else (SyndicateSkins.accent() if repaired else SyndicateSkins.danger())
		draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), border, 4 if selected else 2, 8), rect)
		draw_rect(Rect2(rect.position + Vector2(5.0, 55.0), Vector2(rect.size.x - 10.0, 15.0)), SyndicateSkins.dark(), true)
		var name_text: String = String(room.get("name", "ROOM")).to_upper()
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 67.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, 208.0, 8, SyndicateSkins.text())
		var status: String = "L%d" % int(room.get("level", 1)) if repaired else "DAMAGED"
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(217.0, 67.0), status, HORIZONTAL_ALIGNMENT_RIGHT, 78.0, 8, SyndicateSkins.accent() if repaired else SyndicateSkins.danger())

func _draw_crew_activity() -> void:
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var phase: float = fmod(elapsed * (0.095 + float(index) * 0.014) + float(index) * 0.21, 1.0)
		var direction: float = 1.0 if index % 2 == 0 else -1.0
		var y: float = -45.0 + phase * 455.0
		var x: float = -8.0 + direction * 12.0
		var item_id: String = SyndicateSkins.crew_item(String(member.get("role", "Enforcer")))
		draw_texture_rect_region(skin_atlas, Rect2(Vector2(x - 19.0, y - 23.0), Vector2(38.0, 46.0)), SyndicateSkins.region(item_id))
		draw_circle(Vector2(x, y + 26.0), 3.5, SyndicateSkins.accent() if SyndicateState.crew_available(member) else SyndicateSkins.danger())
	for index: int in range(6):
		var spark_y: float = -60.0 + fmod(elapsed * (31.0 + float(index) * 4.0) + float(index) * 83.0, 490.0)
		var spark_x: float = sin(elapsed * 2.0 + float(index)) * 18.0
		var spark: Color = SyndicateSkins.accent()
		spark.a = 0.74
		draw_circle(Vector2(spark_x, spark_y), 2.2, spark)

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 96.0), SyndicateSkins.dark(), true)
	draw_line(Vector2(0.0, 96.0), Vector2(VIEW.x, 96.0), SyndicateSkins.accent(), 2.0)
	draw_texture_rect(EMBLEM, Rect2(10.0, 10.0, 70.0, 70.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 33.0), "MOONGOONS: SYNDICATE RISING", HORIZONTAL_ALIGNMENT_LEFT, 430.0, 20, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 56.0), "CR %d  CARGO %d  INTEL %d  HEAT %d  TRUST %d" % [SyndicateState.credits, SyndicateState.contraband, SyndicateState.intel, SyndicateState.heat, SyndicateState.crew_trust], HORIZONTAL_ALIGNMENT_LEFT, 520.0, 9, SyndicateSkins.accent())
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 78.0), "ALLOY %d  HE-3 %d  DATA %d  CAPTURED %d  TECH L%d" % [SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.data_cores, SyndicateState.captured_crew_ids.size(), SyndicateState.black_tech_level], HORIZONTAL_ALIGNMENT_LEFT, 530.0, 9, SyndicateSkins.secondary())
	_draw_button(button_rects["sound"] as Rect2, "MUTE" if not SyndicateAudio.muted else "AUDIO", false, 8)
	_draw_button(button_rects["load"] as Rect2, "LOAD", false, 8)

func _draw_camera_controls() -> void:
	var bar: Color = SyndicateSkins.panel()
	bar.a = 0.97
	draw_rect(Rect2(0.0, 96.0, VIEW.x, 52.0), bar, true)
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 119.0), "DRAG TO PAN • VIEW %d° • %d%%" % [rotation_quadrant * 90, int(round(camera_zoom * 100.0))], HORIZONTAL_ALIGNMENT_LEFT, 305.0, 9, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 138.0), "%s • THREAT: %s" % [SyndicateSkins.skin_name().to_upper(), _threat_label()], HORIZONTAL_ALIGNMENT_LEFT, 400.0, 8, SyndicateSkins.secondary())
	_draw_button(button_rects["skin"] as Rect2, "ART", true, 8)
	_draw_button(button_rects["zoom_out"] as Rect2, "−", false, 16)
	_draw_button(button_rects["zoom_in"] as Rect2, "+", false, 16)
	_draw_button(button_rects["rotate"] as Rect2, "ROTATE", true, 8)
	_draw_button(button_rects["center"] as Rect2, "CENTER", false, 8)

func _draw_inspector() -> void:
	super._draw_inspector()
	var room: Dictionary = SyndicateState.get_room(selected_room)
	if not room.is_empty():
		draw_texture_rect_region(skin_atlas, Rect2(376.0, 991.0, 80.0, 72.0), SyndicateSkins.region(SyndicateSkins.room_item(selected_room)))

func _draw_navigation() -> void:
	draw_rect(Rect2(0.0, 1160.0, VIEW.x, 120.0), SyndicateSkins.dark(), true)
	_draw_nav_button(button_rects["hideout"] as Rect2, "HIDEOUT", "BASE", selected_room == "backroom")
	_draw_nav_button(button_rects["scores"] as Rect2, "SCORES", "MISSIONS", false)
	_draw_nav_button(button_rects["operations"] as Rect2, "OPERATIONS", "HARVEST", false)
	_draw_nav_button(button_rects["chat"] as Rect2, "CHAT", "GALAXY", false)
	_draw_nav_button(button_rects["save"] as Rect2, "SAVE", "PROFILE", false)

func _draw_nav_button(rect: Rect2, title: String, subtitle: String, active: bool) -> void:
	var item_id: String = "skull"
	match title:
		"HIDEOUT": item_id = "hideout"
		"SCORES": item_id = "score"
		"OPERATIONS": item_id = "operations"
		"CHAT": item_id = "chat_galaxy"
		"SAVE": item_id = "save"
	draw_style_box(SyndicateSkins.style_box(active, 10), rect)
	draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(rect.size.x * 0.5 - 20.0, 5.0), Vector2(40.0, 42.0)), SyndicateSkins.region(item_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 63.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 11, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 82.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 8, SyndicateSkins.accent())

func _draw_button(rect: Rect2, label: String, active: bool, font_size: int) -> void:
	draw_style_box(SyndicateSkins.style_box(active, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, rect.size.y * 0.61), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, font_size, SyndicateSkins.text())
