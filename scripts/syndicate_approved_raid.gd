extends "res://scripts/syndicate_raid.gd"
## Tactical score combat uses the same approved lunar city and Peacekeeper art.

const APPROVED_ART: Script = preload("res://scripts/syndicate_approved_art.gd")
var approved_board: Texture2D
var attack_texture: Texture2D

func _ready() -> void:
	approved_board = APPROVED_ART.board_texture()
	super._ready()
	var target: String = String(SyndicateState.active_job.get("target", "Peacekeepers")).to_lower()
	var attack_key: String = "patrol"
	if target.contains("command") or target.contains("armored"):
		attack_key = "riot"
	elif target.contains("network") or target.contains("cyber"):
		attack_key = "cyber"
	elif target.contains("security"):
		attack_key = "survey"
	attack_texture = APPROVED_ART.attack_texture(attack_key)

func approved_graphics_active() -> bool:
	return APPROVED_ART.approved_graphics_active()

func _draw() -> void:
	draw_texture_rect_region(approved_board, Rect2(0.0, 0.0, VIEW.x, VIEW.y), Rect2(152.0, 120.0, 720.0, 1280.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.025, 0.045, 0.70), true)
	draw_style_box(_panel(Color("07111f", 0.96), Color("55dfff"), 3, 14), Rect2(10.0, 10.0, 700.0, 110.0))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 47.0), String(SyndicateState.active_job.get("title", "ACTIVE SCORE")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 650.0, 22, Color("f6fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 82.0), "%s  •  TURN %d" % [String(SyndicateState.active_job.get("sector", "Sector")), turn_number], HORIZONTAL_ALIGNMENT_LEFT, 650.0, 12, Color("7de5ff"))

	draw_texture_rect(attack_texture, Rect2(68.0, 132.0, 584.0, 410.0), false)
	draw_style_box(_panel(Color(0, 0, 0, 0), Color("ff6f82"), 4, 18), Rect2(68.0, 132.0, 584.0, 410.0))
	_draw_bar(Rect2(100.0, 554.0, 520.0, 20.0), enemy_hp, enemy_max_hp, Color("62dfff"))
	draw_style_box(_panel(Color("07111f", 0.92), Color("5d758a"), 1, 9), Rect2(75.0, 586.0, 570.0, 48.0))
	draw_string(ThemeDB.fallback_font, Vector2(86.0, 616.0), message, HORIZONTAL_ALIGNMENT_CENTER, 548.0, 12, Color("e4eef5"))

	for index: int in range(crew_units.size()):
		var unit: Dictionary = crew_units[index]
		var x: float = 35.0 + float(index) * 170.0
		var rect: Rect2 = Rect2(x, 650.0, 145.0, 218.0)
		var alive: bool = int(unit.get("hp", 0)) > 0
		draw_style_box(_panel(Color("0a1725", 0.97), Color("55dfff") if alive else Color("65424f"), 2, 10), rect)
		draw_texture_rect(PORTRAITS[String(unit.get("id", "crew_1"))] as Texture2D, Rect2(x + 8.0, 658.0, 129.0, 129.0), false)
		draw_string(ThemeDB.fallback_font, Vector2(x + 6.0, 808.0), String(unit.get("name", "Crew")), HORIZONTAL_ALIGNMENT_CENTER, 133.0, 10, Color("f6fbff"))
		_draw_bar(Rect2(x + 12.0, 832.0, 121.0, 10.0), int(unit.get("hp", 0)), int(unit.get("max_hp", 100)), Color("64e6b3"))
		draw_string(ThemeDB.fallback_font, Vector2(x + 6.0, 858.0), "SPECIAL %s" % ("READY" if bool(unit.get("special_ready", false)) else "SPENT"), HORIZONTAL_ALIGNMENT_CENTER, 133.0, 8, Color("ffd16a"))

	draw_style_box(_panel(Color("07111f", 0.95), Color("526d82"), 1, 10), Rect2(20.0, 884.0, 680.0, 180.0))
	for index: int in range(mini(combat_log.size(), 6)):
		draw_string(ThemeDB.fallback_font, Vector2(34.0, 914.0 + float(index) * 23.0), combat_log[index], HORIZONTAL_ALIGNMENT_LEFT, 650.0, 10, Color("cbd8e2"))
	_draw_action_button("strike", "STRIKE")
	_draw_action_button("evade", "EVADE")
	_draw_action_button("special", "SPECIAL")
	_draw_action_button("auto", "AUTO ON" if auto_mode else "AUTO")
	_draw_action_button("abort", "ABORT SCORE")
	_draw_action_button("return", "CONTINUE" if battle_over else "RETURN")
	if battle_over:
		draw_style_box(_panel(Color("143d32", 0.96) if victory else Color("4b1728", 0.96), Color("6ff0c7") if victory else Color("ff7188"), 4, 14), Rect2(80.0, 466.0, 560.0, 112.0))
		draw_string(ThemeDB.fallback_font, Vector2(90.0, 532.0), "SCORE SECURED" if victory else "SCORE BURNED", HORIZONTAL_ALIGNMENT_CENTER, 540.0, 27, Color("79f3cd") if victory else Color("ff8aa0"))

func _draw_action_button(id_value: String, label: String) -> void:
	var rect: Rect2 = buttons[id_value] as Rect2
	var enabled: bool = not battle_over or id_value == "return"
	var accent: Color = Color("55dfff")
	if id_value == "abort":
		accent = Color("ff7188")
	elif id_value == "special":
		accent = Color("b56cff")
	elif id_value == "strike":
		accent = Color("ff9a4a")
	draw_style_box(_panel(Color("173047", 0.96) if enabled else Color("17212d", 0.58), accent, 3 if enabled else 1, 9), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 44.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 10, Color("f6fbff"))
