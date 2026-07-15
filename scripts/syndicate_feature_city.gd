extends "res://scripts/syndicate_lunar_camera_city.gd"
## Final lunar city shell with operations, communications, and attack-cinematic routing.

var feature_transitioning: bool = false

func _ready() -> void:
	super._ready()
	button_rects.erase("research")
	button_rects.erase("market")
	button_rects["hideout"] = Rect2(8.0, 1170.0, 134.0, 96.0)
	button_rects["scores"] = Rect2(150.0, 1170.0, 134.0, 96.0)
	button_rects["operations"] = Rect2(292.0, 1170.0, 134.0, 96.0)
	button_rects["chat"] = Rect2(434.0, 1170.0, 134.0, 96.0)
	button_rects["save"] = Rect2(576.0, 1170.0, 136.0, 96.0)

func _process(delta: float) -> void:
	super._process(delta)
	if not feature_transitioning and not SyndicateState.pending_attack_cutscene.is_empty() and not SyndicateState.active_threat.is_empty():
		feature_transitioning = true
		get_tree().call_deferred("change_scene_to_file", "res://scenes/SyndicateAttackCutscene.tscn")

func _action(action: String) -> void:
	match action:
		"operations":
			SyndicateAudio.play_sfx("accept")
			get_tree().change_scene_to_file("res://scenes/SyndicateOperations.tscn")
		"chat":
			SyndicateAudio.play_sfx("accept")
			get_tree().change_scene_to_file("res://scenes/SyndicateChat.tscn")
		_:
			super._action(action)

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 96.0), Color("08111f", 0.99), true)
	draw_line(Vector2(0.0, 96.0), Vector2(VIEW.x, 96.0), Color("5fe3ff", 0.6), 2.0)
	draw_texture_rect(EMBLEM, Rect2(10.0, 10.0, 70.0, 70.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 33.0), "MOONGOONS: SYNDICATE RISING", HORIZONTAL_ALIGNMENT_LEFT, 430.0, 20, Color("f5fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 56.0), "CR %d  CARGO %d  INTEL %d  HEAT %d  TRUST %d" % [SyndicateState.credits, SyndicateState.contraband, SyndicateState.intel, SyndicateState.heat, SyndicateState.crew_trust], HORIZONTAL_ALIGNMENT_LEFT, 520.0, 9, Color("72efd5"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 78.0), "ALLOY %d  HE-3 %d  DATA %d  CAPTURED %d  TECH L%d" % [SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.data_cores, SyndicateState.captured_crew_ids.size(), SyndicateState.black_tech_level], HORIZONTAL_ALIGNMENT_LEFT, 530.0, 9, Color("c39bff"))
	_draw_button(button_rects["sound"] as Rect2, "MUTE" if not SyndicateAudio.muted else "AUDIO", false, 8)
	_draw_button(button_rects["load"] as Rect2, "LOAD", false, 8)

func _draw_navigation() -> void:
	draw_rect(Rect2(0.0, 1160.0, VIEW.x, 120.0), Color("050a12"), true)
	_draw_nav_button(button_rects["hideout"] as Rect2, "HIDEOUT", "BASE", selected_room == "backroom")
	_draw_nav_button(button_rects["scores"] as Rect2, "SCORES", "MISSIONS", false)
	_draw_nav_button(button_rects["operations"] as Rect2, "OPERATIONS", "HARVEST", false)
	_draw_nav_button(button_rects["chat"] as Rect2, "CHAT", "GALAXY", false)
	_draw_nav_button(button_rects["save"] as Rect2, "SAVE", "PROFILE", false)
