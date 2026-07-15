extends Node2D
## Three-resource harvesting, hideout defenses, Take Back threats, capture, and side missions.

const VIEW: Vector2 = Vector2(720.0, 1280.0)
const EMBLEM: Texture2D = preload("res://assets/syndicate_emblem.svg")
const HARVEST_ART: Texture2D = preload("res://assets/operations/harvest_sites.svg")
const DEFENSE_ART: Texture2D = preload("res://assets/operations/hideout_defenses.svg")
const SIDE_ART: Texture2D = preload("res://assets/operations/side_missions.svg")
const THREAT_ART: Texture2D = preload("res://assets/threats/take_back_response.svg")

var active_tab: String = "harvest"
var message: String = "Harvest the moon, fortify the hideout, and watch the Take Back response clock."
var elapsed: float = 0.0
var tick_clock: float = 0.0
var transitioning: bool = false
var button_rects: Dictionary = {}
var hidden_rects: Array[Rect2] = []
var hack_rects: Array[Rect2] = []

func _ready() -> void:
	button_rects = {
		"back": Rect2(14.0, 16.0, 88.0, 54.0),
		"chat": Rect2(510.0, 16.0, 92.0, 54.0),
		"save": Rect2(612.0, 16.0, 92.0, 54.0),
		"tab_harvest": Rect2(12.0, 105.0, 167.0, 58.0),
		"tab_threat": Rect2(188.0, 105.0, 167.0, 58.0),
		"tab_defenses": Rect2(364.0, 105.0, 167.0, 58.0),
		"tab_missions": Rect2(540.0, 105.0, 167.0, 58.0),
		"harvest_alloy": Rect2(490.0, 518.0, 190.0, 52.0),
		"harvest_helium": Rect2(490.0, 650.0, 190.0, 52.0),
		"harvest_cores": Rect2(490.0, 782.0, 190.0, 52.0),
		"view_attack": Rect2(76.0, 960.0, 568.0, 72.0),
		"def_jammer": Rect2(388.0, 486.0, 284.0, 58.0),
		"def_sentry": Rect2(388.0, 590.0, 284.0, 58.0),
		"def_doors": Rect2(388.0, 694.0, 284.0, 58.0),
		"def_escape": Rect2(388.0, 798.0, 284.0, 58.0),
		"mission_hidden": Rect2(34.0, 480.0, 204.0, 88.0),
		"mission_law": Rect2(258.0, 480.0, 204.0, 88.0),
		"mission_cipher": Rect2(482.0, 480.0, 204.0, 88.0),
		"mission_rescue": Rect2(146.0, 590.0, 428.0, 72.0),
		"abort_mission": Rect2(190.0, 1050.0, 340.0, 64.0)
	}
	hidden_rects = [
		Rect2(123.0, 345.0, 44.0, 50.0), Rect2(267.0, 350.0, 46.0, 48.0),
		Rect2(411.0, 345.0, 46.0, 50.0), Rect2(555.0, 348.0, 44.0, 48.0),
		Rect2(189.0, 548.0, 48.0, 46.0), Rect2(476.0, 550.0, 48.0, 46.0)
	]
	hack_rects = [
		Rect2(116.0, 371.0, 62.0, 62.0), Rect2(260.0, 450.0, 62.0, 62.0),
		Rect2(358.0, 343.0, 62.0, 62.0), Rect2(488.0, 452.0, 62.0, 62.0),
		Rect2(571.0, 373.0, 62.0, 62.0), Rect2(283.0, 580.0, 62.0, 62.0)
	]
	SyndicateAudio.play_music("city")
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	tick_clock += delta
	if tick_clock >= 0.25:
		tick_clock = 0.0
		SyndicateState.tick()
	if not transitioning and not SyndicateState.pending_attack_cutscene.is_empty() and not SyndicateState.active_threat.is_empty():
		transitioning = true
		get_tree().call_deferred("change_scene_to_file", "res://scenes/SyndicateAttackCutscene.tscn")
	queue_redraw()

func _input(event: InputEvent) -> void:
	var pos: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		pos = mouse.position
		pressed = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		pos = touch.position
		pressed = touch.pressed
	if not pressed:
		return
	if active_tab == "missions" and not SyndicateState.side_mission_mode.is_empty():
		if SyndicateState.side_mission_mode == "hidden":
			for index: int in range(hidden_rects.size()):
				if hidden_rects[index].has_point(pos):
					var result: Dictionary = SyndicateState.submit_hidden_object(index)
					message = String(result.get("message", "Object checked."))
					SyndicateAudio.play_sfx("special" if bool(result.get("ok", false)) else "warning")
					return
		else:
			for index: int in range(hack_rects.size()):
				if hack_rects[index].has_point(pos):
					var result: Dictionary = SyndicateState.submit_hack_node(index)
					message = String(result.get("message", "Node checked."))
					SyndicateAudio.play_sfx("special" if bool(result.get("ok", false)) else "warning")
					return
	for action_value: Variant in button_rects.keys():
		var action: String = String(action_value)
		var rect: Rect2 = button_rects[action] as Rect2
		if rect.has_point(pos) and _button_is_active(action):
			_handle_action(action)
			return

func _button_is_active(action: String) -> bool:
	if action.begins_with("tab_") or action in ["back", "chat", "save"]:
		return true
	if action.begins_with("harvest_"):
		return active_tab == "harvest"
	if action == "view_attack":
		return active_tab == "threat" and not SyndicateState.active_threat.is_empty()
	if action.begins_with("def_"):
		return active_tab == "defenses"
	if action.begins_with("mission_"):
		return active_tab == "missions" and SyndicateState.side_mission_mode.is_empty()
	if action == "abort_mission":
		return active_tab == "missions" and not SyndicateState.side_mission_mode.is_empty()
	return false

func _handle_action(action: String) -> void:
	var result: Dictionary = {}
	match action:
		"back":
			get_tree().change_scene_to_file("res://scenes/SyndicateCity.tscn")
			return
		"chat":
			get_tree().change_scene_to_file("res://scenes/SyndicateChat.tscn")
			return
		"save":
			result = SyndicateState.save_game()
		"tab_harvest": active_tab = "harvest"
		"tab_threat": active_tab = "threat"
		"tab_defenses": active_tab = "defenses"
		"tab_missions": active_tab = "missions"
		"harvest_alloy": result = SyndicateState.start_harvest("alloy")
		"harvest_helium": result = SyndicateState.start_harvest("helium")
		"harvest_cores": result = SyndicateState.start_harvest("cores")
		"view_attack":
			if SyndicateState.pending_attack_cutscene.is_empty():
				SyndicateState.pending_attack_cutscene = String(SyndicateState.active_threat.get("type", "patrol"))
			get_tree().change_scene_to_file("res://scenes/SyndicateAttackCutscene.tscn")
			return
		"def_jammer": result = SyndicateState.upgrade_defense("jammer")
		"def_sentry": result = SyndicateState.upgrade_defense("sentry")
		"def_doors": result = SyndicateState.upgrade_defense("blast_doors")
		"def_escape": result = SyndicateState.upgrade_defense("escape_tunnels")
		"mission_hidden": result = SyndicateState.start_side_mission("hidden")
		"mission_law": result = SyndicateState.start_side_mission("law_hack")
		"mission_cipher": result = SyndicateState.start_side_mission("syndicate_cipher")
		"mission_rescue": result = SyndicateState.start_side_mission("rescue")
		"abort_mission":
			SyndicateState.abort_side_mission()
			message = SyndicateState.last_event
	if not result.is_empty():
		message = String(result.get("message", "Operation complete."))
		SyndicateAudio.play_sfx("accept" if bool(result.get("ok", false)) else "warning")
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("050a13"))
	_draw_header()
	_draw_tabs()
	match active_tab:
		"harvest": _draw_harvest()
		"threat": _draw_threat()
		"defenses": _draw_defenses()
		_: _draw_missions()
	_draw_footer()

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, 720.0, 94.0), Color("091525"), true)
	draw_texture_rect(EMBLEM, Rect2(112.0, 12.0, 62.0, 62.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(184.0, 39.0), "SYNDICATE OPERATIONS", HORIZONTAL_ALIGNMENT_LEFT, 318.0, 22, Color("f5fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(184.0, 66.0), "ALLOY %d   HE-3 %d   DATA %d   HEAT %d" % [SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.data_cores, SyndicateState.heat], HORIZONTAL_ALIGNMENT_LEFT, 325.0, 10, Color("72ead6"))
	_draw_button(button_rects["back"] as Rect2, "BACK", false, 10)
	_draw_button(button_rects["chat"] as Rect2, "CHAT", false, 10)
	_draw_button(button_rects["save"] as Rect2, "SAVE", false, 10)

func _draw_tabs() -> void:
	for tab: String in ["harvest", "threat", "defenses", "missions"]:
		var rect: Rect2 = button_rects["tab_" + tab] as Rect2
		_draw_button(rect, tab.to_upper(), active_tab == tab, 10)

func _draw_harvest() -> void:
	draw_texture_rect(HARVEST_ART, Rect2(30.0, 182.0, 660.0, 248.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 463.0), "THREE LUNAR RESOURCE OPERATIONS", HORIZONTAL_ALIGNMENT_CENTER, 664.0, 17, Color("f3f8ff"))
	var site_ids: Array[String] = ["alloy", "helium", "cores"]
	var y_values: Array[float] = [494.0, 626.0, 758.0]
	for index: int in range(site_ids.size()):
		var site: Dictionary = SyndicateState.get_harvest_site(site_ids[index])
		var rect: Rect2 = Rect2(34.0, y_values[index], 652.0, 100.0)
		draw_style_box(_panel(Color("0e1a28"), Color("526f85"), 2, 10), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 31.0), String(site.get("name", "Harvest Site")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 420.0, 13, Color("f4f9ff"))
		var finish_at: int = int(site.get("finish_at", 0))
		var status: String = "READY"
		if finish_at > 0:
			status = "HARVESTING • %ds" % SyndicateState.harvest_seconds_left(site)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 58.0), "%s • Yield %d • Risk +%d Heat" % [String(site.get("resource", "Resource")), int(site.get("yield", 1)), int(site.get("risk", 1))], HORIZONTAL_ALIGNMENT_LEFT, 425.0, 10, Color("9fc4d7"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 82.0), status, HORIZONTAL_ALIGNMENT_LEFT, 425.0, 10, Color("ffca72") if finish_at > 0 else Color("6fead4"))
		_draw_button(button_rects["harvest_" + site_ids[index]] as Rect2, "DEPLOY" if finish_at <= 0 else "%ds" % SyndicateState.harvest_seconds_left(site), finish_at <= 0, 10)

func _draw_threat() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 212.0), "TAKE BACK PEACEKEEPER PRESSURE", HORIZONTAL_ALIGNMENT_CENTER, 664.0, 18, Color("f3f8ff"))
	if SyndicateState.active_threat.is_empty():
		draw_texture_rect(THREAT_ART, Rect2(52.0, 240.0, 616.0, 288.0), false)
		var next_in: int = maxi(0, SyndicateState.next_threat_at - int(Time.get_unix_time_from_system()))
		draw_style_box(_panel(Color("0c1926"), Color("5d8298"), 2, 12), Rect2(54.0, 570.0, 612.0, 188.0))
		draw_string(ThemeDB.fallback_font, Vector2(76.0, 621.0), "NO ACTIVE RAID", HORIZONTAL_ALIGNMENT_CENTER, 568.0, 22, Color("72ead6"))
		draw_string(ThemeDB.fallback_font, Vector2(76.0, 660.0), "Next orbital response estimate: %ds" % next_in, HORIZONTAL_ALIGNMENT_CENTER, 568.0, 13, Color("c7d8e4"))
		draw_string(ThemeDB.fallback_font, Vector2(76.0, 706.0), "Harvesting and Heat can accelerate Survey Drone, Patrol Deputy, cyber-warrant, and Riot Vanguard attacks.", HORIZONTAL_ALIGNMENT_CENTER, 568.0, 10, Color("9db0bf"))
	else:
		var threat: Dictionary = SyndicateState.active_threat
		draw_texture_rect(THREAT_ART, Rect2(52.0, 240.0, 616.0, 288.0), false)
		draw_style_box(_panel(Color("201017"), Color("ff8e72"), 3, 12), Rect2(54.0, 558.0, 612.0, 330.0))
		draw_string(ThemeDB.fallback_font, Vector2(78.0, 610.0), String(threat.get("title", "TAKE BACK ATTACK")).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 564.0, 22, Color("fff0e9"))
		draw_string(ThemeDB.fallback_font, Vector2(78.0, 650.0), String(threat.get("unit", "Peacekeeper Unit")), HORIZONTAL_ALIGNMENT_CENTER, 564.0, 13, Color("ffbd82"))
		_draw_wrapped(String(threat.get("description", "Peacekeepers are closing on the hideout.")), Vector2(88.0, 700.0), 544.0, 13, Color("d9e4ea"))
		var remaining: int = maxi(0, int(threat.get("expires_at", 0)) - int(Time.get_unix_time_from_system()))
		draw_string(ThemeDB.fallback_font, Vector2(78.0, 830.0), "POWER %d • RESPONSE %ds • CAPTURED %d" % [int(threat.get("power", 1)), remaining, SyndicateState.captured_crew_ids.size()], HORIZONTAL_ALIGNMENT_CENTER, 564.0, 11, Color("ffcc74"))
		_draw_button(button_rects["view_attack"] as Rect2, "OPEN ATTACK CUTSCENE", true, 13)

func _draw_defenses() -> void:
	draw_texture_rect(DEFENSE_ART, Rect2(30.0, 182.0, 660.0, 206.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 430.0), "HIDEOUT DEFENSE NETWORK", HORIZONTAL_ALIGNMENT_CENTER, 664.0, 18, Color("f4f9ff"))
	var ids: Array[String] = ["jammer", "sentry", "blast_doors", "escape_tunnels"]
	var labels: Array[String] = ["SIGNAL JAMMER GRID", "SENTRY TURRET NETWORK", "ARMORED BLAST DOORS", "EMERGENCY ESCAPE TUNNELS"]
	var hints: Array[String] = ["Counters scans and hacking", "Fights capture and breach teams", "Slows Riot Vanguard attacks", "Reduces capture and improves hiding"]
	var ys: Array[float] = [466.0, 570.0, 674.0, 778.0]
	var actions: Array[String] = ["def_jammer", "def_sentry", "def_doors", "def_escape"]
	for index: int in range(ids.size()):
		var level: int = int(SyndicateState.defenses.get(ids[index], 0))
		var rect: Rect2 = Rect2(36.0, ys[index], 648.0, 82.0)
		draw_style_box(_panel(Color("0e1927"), Color("58768b"), 2, 10), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(17.0, 31.0), "%s • LEVEL %d" % [labels[index], level], HORIZONTAL_ALIGNMENT_LEFT, 330.0, 12, Color("f4f9ff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(17.0, 59.0), hints[index], HORIZONTAL_ALIGNMENT_LEFT, 330.0, 9, Color("9fb8c8"))
		_draw_button(button_rects[actions[index]] as Rect2, "UPGRADE", true, 10)
	draw_string(ThemeDB.fallback_font, Vector2(42.0, 908.0), "Upgrade currency: Lunar Alloy + Helium-3 + Authority Data Cores", HORIZONTAL_ALIGNMENT_CENTER, 636.0, 11, Color("ffca74"))

func _draw_missions() -> void:
	if SyndicateState.side_mission_mode.is_empty():
		draw_texture_rect(SIDE_ART, Rect2(30.0, 182.0, 660.0, 248.0), false)
		draw_string(ThemeDB.fallback_font, Vector2(28.0, 458.0), "SIDE MISSIONS", HORIZONTAL_ALIGNMENT_CENTER, 664.0, 18, Color("f4f9ff"))
		_draw_mission_button("mission_hidden", "HIDDEN-OBJECT THEFT", "Steal evidence-room valuables")
		_draw_mission_button("mission_law", "LAW NETWORK HACK", "Erase warrants and pursuit routes")
		_draw_mission_button("mission_cipher", "RIVAL CIPHER", "Crack another Syndicate network")
		_draw_button(button_rects["mission_rescue"] as Rect2, "RESCUE CAPTURED CREW (%d)" % SyndicateState.captured_crew_ids.size(), not SyndicateState.captured_crew_ids.is_empty(), 11)
		draw_string(ThemeDB.fallback_font, Vector2(40.0, 720.0), "Completed side missions: %d" % SyndicateState.side_missions_completed, HORIZONTAL_ALIGNMENT_CENTER, 640.0, 12, Color("75ead6"))
	else:
		_draw_active_side_mission()

func _draw_mission_button(action: String, title: String, subtitle: String) -> void:
	var rect: Rect2 = button_rects[action] as Rect2
	draw_style_box(_panel(Color("142237"), Color("6f88a1"), 2, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9.0, 35.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 18.0, 10, Color("f4f8ff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9.0, 62.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 18.0, 7, Color("a8b9c8"))

func _draw_active_side_mission() -> void:
	var mode: String = SyndicateState.side_mission_mode
	var source: Rect2 = Rect2(0.0, 0.0, 320.0, 360.0)
	if mode == "law_hack" or mode == "rescue":
		source = Rect2(320.0, 0.0, 320.0, 360.0)
	elif mode == "syndicate_cipher":
		source = Rect2(640.0, 0.0, 320.0, 360.0)
	draw_texture_rect_region(SIDE_ART, Rect2(58.0, 205.0, 604.0, 520.0), source)
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), Color("73e5ff"), 3, 14), Rect2(58.0, 205.0, 604.0, 520.0))
	draw_string(ThemeDB.fallback_font, Vector2(52.0, 772.0), mode.replace("_", " ").to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 616.0, 20, Color("f5f9ff"))
	_draw_wrapped(SyndicateState.side_mission_instruction(), Vector2(70.0, 820.0), 580.0, 12, Color("c4d3df"))
	if mode == "hidden":
		for index: int in range(hidden_rects.size()):
			var found: bool = index < SyndicateState.hidden_found.size() and SyndicateState.hidden_found[index]
			var rect: Rect2 = hidden_rects[index]
			if found:
				draw_style_box(_panel(Color(0.2, 0.8, 0.65, 0.30), Color("73f0d4"), 3, 8), rect)
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, 29.0), "TAKEN", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, 7, Color("eafff9"))
		var found_count: int = SyndicateState.hidden_found.count(true)
		draw_string(ThemeDB.fallback_font, Vector2(70.0, 915.0), "TARGETS STOLEN %d / 5" % found_count, HORIZONTAL_ALIGNMENT_CENTER, 580.0, 12, Color("ffcb73"))
	else:
		for index: int in range(hack_rects.size()):
			var rect: Rect2 = hack_rects[index]
			var accepted: bool = index in SyndicateState.hack_sequence.slice(0, SyndicateState.hack_progress)
			var pulse: float = 0.5 + sin(elapsed * 4.0 + float(index)) * 0.22
			var fill: Color = Color(0.3, 0.9, 0.75, 0.36) if accepted else Color(0.16, 0.28, 0.42, 0.42 + pulse * 0.12)
			draw_style_box(_panel(fill, Color("73e7ff") if not accepted else Color("75f0d5"), 3, 31), rect)
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, 38.0), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, 14, Color("f4fbff"))
		draw_string(ThemeDB.fallback_font, Vector2(70.0, 915.0), "NODES CRACKED %d / %d" % [SyndicateState.hack_progress, SyndicateState.hack_sequence.size()], HORIZONTAL_ALIGNMENT_CENTER, 580.0, 12, Color("ffcb73"))
	_draw_button(button_rects["abort_mission"] as Rect2, "ABORT SIDE MISSION", false, 11)

func _draw_footer() -> void:
	draw_style_box(_panel(Color("0b1522"), Color("526e83"), 2, 10), Rect2(24.0, 1152.0, 672.0, 104.0))
	_draw_wrapped(message, Vector2(42.0, 1188.0), 636.0, 10, Color("c5d4df"))

func _draw_button(rect: Rect2, label: String, active: bool, font_size: int) -> void:
	draw_style_box(_panel(Color("24516a") if active else Color("152333"), Color("6cf0e1") if active else Color("526b80"), 2 if active else 1, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, rect.size.y * 0.61), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, font_size, Color("f3f8ff"))

func _draw_wrapped(text: String, origin: Vector2, width: float, font_size: int, color: Color) -> void:
	var words: PackedStringArray = text.split(" ")
	var line: String = ""
	var y: float = origin.y
	for word: String in words:
		var candidate: String = word if line.is_empty() else line + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > width and not line.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
			line = word
			y += float(font_size + 8)
		else:
			line = candidate
	if not line.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
