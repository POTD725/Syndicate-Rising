extends "res://scripts/syndicate_operations.gd"
## Full-art Operations screen for harvesting, defenses, threats, and puzzles.

const ART: Script = preload("res://scripts/syndicate_full_art.gd")

var systems_atlas: Texture2D
var board_texture: Texture2D

func _ready() -> void:
	super._ready()
	systems_atlas = ART.systems_atlas()
	board_texture = ART.board_texture()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("050a13"))
	draw_texture_rect_region(board_texture, Rect2(0.0, 164.0, 720.0, 330.0), Rect2(130.0, 360.0, 764.0, 520.0))
	draw_rect(Rect2(0.0, 164.0, 720.0, 330.0), Color(0.01, 0.03, 0.06, 0.32), true)
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
	draw_line(Vector2(0.0, 94.0), Vector2(720.0, 94.0), Color("4ee7ff"), 2.0)
	draw_texture_rect(EMBLEM, Rect2(112.0, 12.0, 62.0, 62.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(184.0, 39.0), "SYNDICATE OPERATIONS", HORIZONTAL_ALIGNMENT_LEFT, 318.0, 22, Color("f5fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(184.0, 66.0), "ALLOY %d   HE-3 %d   DATA %d   HEAT %d" % [SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.data_cores, SyndicateState.heat], HORIZONTAL_ALIGNMENT_LEFT, 325.0, 10, Color("72ead6"))
	_draw_button(button_rects["back"] as Rect2, "BACK", false, 10)
	_draw_button(button_rects["chat"] as Rect2, "CHAT", false, 10)
	_draw_button(button_rects["save"] as Rect2, "SAVE", false, 10)

func _draw_harvest() -> void:
	draw_rect(Rect2(0.0, 430.0, 720.0, 710.0), Color("07101a", 0.97), true)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 467.0), "THREE LUNAR RESOURCE OPERATIONS", HORIZONTAL_ALIGNMENT_CENTER, 664.0, 17, Color("f3f8ff"))
	var site_ids: Array[String] = ["alloy", "helium", "cores"]
	var atlas_ids: Array[String] = ["resource_alloy", "resource_helium", "resource_cores"]
	var y_values: Array[float] = [494.0, 670.0, 846.0]
	for index: int in range(site_ids.size()):
		var site: Dictionary = SyndicateState.get_harvest_site(site_ids[index])
		var rect: Rect2 = Rect2(34.0, y_values[index], 652.0, 145.0)
		draw_style_box(_panel(Color("0e1a28"), Color("526f85"), 2, 12), rect)
		draw_texture_rect_region(systems_atlas, Rect2(rect.position + Vector2(10.0, 10.0), Vector2(122.0, 122.0)), ART.system_region(atlas_ids[index]))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(146.0, 34.0), String(site.get("name", "Harvest Site")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 315.0, 14, Color("f4f9ff"))
		var finish_at: int = int(site.get("finish_at", 0))
		var status: String = "READY"
		if finish_at > 0:
			status = "HARVESTING • %ds" % SyndicateState.harvest_seconds_left(site)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(146.0, 67.0), "%s • Yield %d • Risk +%d Heat" % [String(site.get("resource", "Resource")), int(site.get("yield", 1)), int(site.get("risk", 1))], HORIZONTAL_ALIGNMENT_LEFT, 315.0, 10, Color("9fc4d7"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(146.0, 99.0), status, HORIZONTAL_ALIGNMENT_LEFT, 315.0, 10, Color("ffca72") if finish_at > 0 else Color("6fead4"))
		_draw_button(button_rects["harvest_" + site_ids[index]] as Rect2, "DEPLOY" if finish_at <= 0 else "%ds" % SyndicateState.harvest_seconds_left(site), finish_at <= 0, 10)

func _draw_threat() -> void:
	draw_rect(Rect2(0.0, 430.0, 720.0, 710.0), Color("07101a", 0.97), true)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 467.0), "TAKE BACK PEACEKEEPER PRESSURE", HORIZONTAL_ALIGNMENT_CENTER, 664.0, 18, Color("f3f8ff"))
	var threat_type: String = "survey"
	if not SyndicateState.active_threat.is_empty():
		threat_type = String(SyndicateState.active_threat.get("type", "patrol"))
	var threat_id: String = "threat_" + threat_type
	if threat_id not in ["threat_survey", "threat_patrol", "threat_riot", "threat_cyber"]:
		threat_id = "threat_patrol"
	draw_texture_rect_region(systems_atlas, Rect2(232.0, 500.0, 256.0, 256.0), ART.system_region(threat_id))
	if SyndicateState.active_threat.is_empty():
		var next_in: int = maxi(0, SyndicateState.next_threat_at - int(Time.get_unix_time_from_system()))
		draw_string(ThemeDB.fallback_font, Vector2(72.0, 812.0), "NO ACTIVE RAID • NEXT PEACEKEEPER CHECK IN %ds" % next_in, HORIZONTAL_ALIGNMENT_CENTER, 576.0, 15, Color("72ead6"))
	else:
		var threat: Dictionary = SyndicateState.active_threat
		draw_string(ThemeDB.fallback_font, Vector2(72.0, 800.0), String(threat.get("title", "PEACEKEEPER ATTACK")).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 576.0, 19, Color("ffbd78"))
		draw_string(ThemeDB.fallback_font, Vector2(72.0, 834.0), String(threat.get("description", "Police pressure is closing on the hideout.")), HORIZONTAL_ALIGNMENT_CENTER, 576.0, 11, Color("d8e5ed"))
		_draw_button(button_rects["view_attack"] as Rect2, "ENTER ATTACK RESPONSE", true, 12)

func _draw_defenses() -> void:
	draw_rect(Rect2(0.0, 430.0, 720.0, 710.0), Color("07101a", 0.97), true)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 467.0), "HIDEOUT DEFENSE NETWORK", HORIZONTAL_ALIGNMENT_CENTER, 664.0, 18, Color("f3f8ff"))
	var ids: Array[String] = ["jammer", "sentry", "blast_doors", "escape_tunnels"]
	var atlas_ids: Array[String] = ["defense_jammer", "defense_sentry", "defense_blast_doors", "defense_escape_tunnels"]
	var labels: Array[String] = ["SIGNAL JAMMER", "SENTRY GRID", "ARMORED BLAST DOORS", "ESCAPE TUNNELS"]
	var buttons: Array[String] = ["def_jammer", "def_sentry", "def_doors", "def_escape"]
	var ys: Array[float] = [492.0, 642.0, 792.0, 942.0]
	for index: int in range(ids.size()):
		var level: int = int(SyndicateState.defenses.get(ids[index], 0))
		var rect: Rect2 = Rect2(38.0, ys[index], 644.0, 126.0)
		draw_style_box(_panel(Color("0d1927"), Color("546d82"), 2, 11), rect)
		draw_texture_rect_region(systems_atlas, Rect2(rect.position + Vector2(8.0, 7.0), Vector2(112.0, 112.0)), ART.system_region(atlas_ids[index]))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(134.0, 39.0), labels[index], HORIZONTAL_ALIGNMENT_LEFT, 260.0, 13, Color("f5fbff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(134.0, 73.0), "LEVEL %d • Raises resistance to Take Back attacks" % level, HORIZONTAL_ALIGNMENT_LEFT, 280.0, 10, Color("9fc4d7"))
		_draw_button(button_rects[buttons[index]] as Rect2, "UPGRADE", true, 10)

func _draw_missions() -> void:
	draw_rect(Rect2(0.0, 430.0, 720.0, 710.0), Color("07101a", 0.97), true)
	if not SyndicateState.side_mission_mode.is_empty():
		super._draw_active_side_mission()
		return
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 467.0), "SYNDICATE SIDE OPERATIONS", HORIZONTAL_ALIGNMENT_CENTER, 664.0, 18, Color("f3f8ff"))
	var entries: Array[Dictionary] = [
		{"button":"mission_hidden", "title":"HIDDEN OBJECT THEFT", "sub":"Find valuables inside an Authority evidence room.", "icon":"mission_hidden"},
		{"button":"mission_law", "title":"LAW NETWORK HACK", "sub":"Crack a Peacekeeper warrant network.", "icon":"threat_cyber"},
		{"button":"mission_cipher", "title":"RIVAL CIPHER", "sub":"Break a competing Syndicate code.", "icon":"resource_cores"},
		{"button":"mission_rescue", "title":"CAPTURED CREW RESCUE", "sub":"Intercept the prisoner-transfer route.", "icon":"threat_patrol"}
	]
	var positions: Array[Vector2] = [Vector2(34.0, 500.0), Vector2(258.0, 500.0), Vector2(482.0, 500.0), Vector2(146.0, 700.0)]
	for index: int in range(entries.size()):
		var entry: Dictionary = entries[index]
		var rect: Rect2 = button_rects[String(entry["button"])] as Rect2
		if index == 3:
			rect = Rect2(146.0, 700.0, 428.0, 170.0)
		else:
			rect = Rect2(positions[index], Vector2(204.0, 170.0))
		button_rects[String(entry["button"])] = rect
		draw_style_box(_panel(Color("0d1927"), Color("546d82"), 2, 12), rect)
		draw_texture_rect_region(systems_atlas, Rect2(rect.position + Vector2(rect.size.x * 0.5 - 45.0, 10.0), Vector2(90.0, 90.0)), ART.system_region(String(entry["icon"])))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 120.0), String(entry["title"]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 10, Color("f5fbff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 148.0), String(entry["sub"]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 8, Color("9fc4d7"))

func _draw_footer() -> void:
	draw_style_box(_panel(Color("101c2a"), Color("4ee7ff"), 2, 10), Rect2(24.0, 1152.0, 672.0, 104.0))
	_draw_wrapped(message, Vector2(42.0, 1188.0), 636.0, 10, Color("f5fbff"))

func _draw_button(rect: Rect2, label: String, active: bool, font_size: int) -> void:
	draw_style_box(_panel(Color("24516a") if active else Color("152333"), Color("6cf0e1") if active else Color("526b80"), 2 if active else 1, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, rect.size.y * 0.61), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, font_size, Color("f5fbff"))
