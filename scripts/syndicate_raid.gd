extends Node2D
## Portrait tactical raid screen.

const VIEW: Vector2 = Vector2(720.0, 1280.0)
const ENEMY: Texture2D = preload("res://assets/enemies/peacekeeper_response.svg")
const PORTRAITS: Dictionary = {
	"crew_1": preload("res://assets/portraits/nyx_raze.svg"),
	"crew_2": preload("res://assets/portraits/vox_13.svg"),
	"crew_3": preload("res://assets/portraits/cinder_quell.svg"),
	"crew_4": preload("res://assets/portraits/grit_mercer.svg")
}

var crew_units: Array[Dictionary] = []
var enemy_hp: int = 1
var enemy_max_hp: int = 1
var enemy_power: int = 10
var battle_over: bool = false
var victory: bool = false
var auto_mode: bool = false
var auto_clock: float = 0.0
var turn_number: int = 1
var message: String = "Crew entering the target zone."
var combat_log: Array[String] = []
var buttons: Dictionary = {
	"strike": Rect2(20.0, 1085.0, 160.0, 70.0),
	"evade": Rect2(190.0, 1085.0, 160.0, 70.0),
	"special": Rect2(360.0, 1085.0, 160.0, 70.0),
	"auto": Rect2(530.0, 1085.0, 170.0, 70.0),
	"abort": Rect2(20.0, 1170.0, 330.0, 70.0),
	"return": Rect2(370.0, 1170.0, 330.0, 70.0)
}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	if SyndicateState.active_job.is_empty():
		get_tree().call_deferred("change_scene_to_file", "res://scenes/SyndicateScores.tscn")
		return
	for source: Dictionary in SyndicateState.active_crew():
		var unit: Dictionary = {
			"id": String(source.get("id", "")),
			"name": String(source.get("name", "Crew")),
			"role": String(source.get("role", "Enforcer")),
			"level": int(source.get("level", 1)),
			"power": int(source.get("power", 50)),
			"defense": int(source.get("defense", 10)),
			"hp": int(source.get("hp", 100)),
			"max_hp": int(source.get("max_hp", 100)),
			"special_ready": true,
			"evading": false
		}
		crew_units.append(unit)
	enemy_max_hp = int(SyndicateState.active_job.get("enemy_hp", 120))
	enemy_hp = enemy_max_hp
	enemy_power = int(SyndicateState.active_job.get("enemy_power", 14))
	message = "CONTACT // %s response team" % String(SyndicateState.active_job.get("target", "Peacekeepers"))
	_add_log("Crew entered %s." % String(SyndicateState.active_job.get("sector", "the sector")))
	SyndicateAudio.play_music("combat")
	SyndicateAudio.play_sfx("warning")

func _process(delta: float) -> void:
	if auto_mode and not battle_over:
		auto_clock += delta
		if auto_clock >= 0.8:
			auto_clock = 0.0
			_act("strike")
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
	for action_value: Variant in buttons.keys():
		if (buttons[action_value] as Rect2).has_point(pos):
			_button(String(action_value))
			return

func _button(action: String) -> void:
	if action == "return":
		if battle_over:
			if not SyndicateState.pending_cutscene.is_empty():
				get_tree().change_scene_to_file("res://scenes/SyndicateCutscene.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/SyndicateCity.tscn")
		else:
			message = "Finish or abort the score first."
			SyndicateAudio.play_sfx("warning")
		return
	if battle_over:
		return
	if action == "auto":
		auto_mode = not auto_mode
		message = "AUTO RAID ENABLED" if auto_mode else "AUTO RAID DISABLED"
		SyndicateAudio.play_sfx("click")
		return
	if action == "abort":
		_finish(false, "Crew burned the route and escaped empty-handed.")
		return
	_act(action)

func _act(action: String) -> void:
	var total_damage: int = 0
	match action:
		"strike":
			for unit: Dictionary in crew_units:
				if int(unit.get("hp", 0)) <= 0:
					continue
				unit["evading"] = false
				total_damage += maxi(5, int(unit.get("power", 50)) / 7) + rng.randi_range(0, 6)
			message = "Crew volley dealt %d damage." % total_damage
			_add_log("Turn %d: coordinated strike dealt %d." % [turn_number, total_damage])
			SyndicateAudio.play_sfx("hit")
		"evade":
			for unit: Dictionary in crew_units:
				if int(unit.get("hp", 0)) > 0:
					unit["evading"] = true
			message = "Crew scattered into cover."
			_add_log("Turn %d: crew entered evade stance." % turn_number)
			SyndicateAudio.play_sfx("click")
		"special":
			var used: int = 0
			for unit: Dictionary in crew_units:
				if int(unit.get("hp", 0)) <= 0 or not bool(unit.get("special_ready", false)):
					continue
				unit["special_ready"] = false
				used += 1
				var role: String = String(unit.get("role", "Enforcer"))
				if role == "Enforcer":
					total_damage += 18 + int(unit.get("level", 1))
					unit["hp"] = mini(int(unit.get("max_hp", 100)), int(unit.get("hp", 1)) + 10)
				elif role == "Runner":
					total_damage += 27 + int(unit.get("level", 1))
					unit["evading"] = true
				else:
					total_damage += 33 + int(unit.get("level", 1)) * 2
			if used == 0:
				message = "Special abilities are already spent."
				SyndicateAudio.play_sfx("warning")
				return
			message = "%d specials landed for %d damage." % [used, total_damage]
			_add_log("Turn %d: specials dealt %d." % [turn_number, total_damage])
			SyndicateAudio.play_sfx("special")
	if total_damage > 0:
		enemy_hp = maxi(0, enemy_hp - total_damage)
	if enemy_hp <= 0:
		_finish(true, "Security broken. Cargo secured.")
		return
	_enemy_turn()
	turn_number += 1

func _enemy_turn() -> void:
	var living: Array[int] = []
	for index: int in range(crew_units.size()):
		if int(crew_units[index].get("hp", 0)) > 0:
			living.append(index)
	if living.is_empty():
		_finish(false, "The response team overwhelmed the crew.")
		return
	var chosen_index: int = living[rng.randi_range(0, living.size() - 1)]
	var target: Dictionary = crew_units[chosen_index]
	var mitigation: int = int(target.get("defense", 0)) / 4
	if bool(target.get("evading", false)):
		mitigation += 12
	var damage: int = maxi(3, enemy_power + rng.randi_range(0, 7) - mitigation)
	target["hp"] = maxi(0, int(target.get("hp", 1)) - damage)
	target["evading"] = false
	_add_log("Security hit %s for %d." % [String(target.get("name", "Crew")), damage])
	SyndicateAudio.play_sfx("hit")
	var survivors: int = 0
	for unit: Dictionary in crew_units:
		if int(unit.get("hp", 0)) > 0:
			survivors += 1
	if survivors == 0:
		_finish(false, "The response team overwhelmed the crew.")

func _finish(won: bool, text: String) -> void:
	if battle_over:
		return
	battle_over = true
	victory = won
	auto_mode = false
	message = text
	var hp_results: Dictionary = {}
	for unit: Dictionary in crew_units:
		hp_results[String(unit.get("id", ""))] = maxi(1, int(unit.get("hp", 1)))
	SyndicateState.finish_job(won, hp_results)
	SyndicateAudio.play_sfx("victory" if won else "defeat")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("05020b"))
	for index: int in range(100):
		draw_circle(Vector2(fmod(float(index * 79 + 13), VIEW.x), fmod(float(index * 53 + 29), VIEW.y)), 1.0, Color("d5b0ff", 0.17))
	draw_rect(Rect2(0.0, 0.0, 720.0, 128.0), Color("170c20"), true)
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 46.0), String(SyndicateState.active_job.get("title", "ACTIVE SCORE")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 660.0, 23, Color("fff4fb"))
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 82.0), "%s  •  TURN %d" % [String(SyndicateState.active_job.get("sector", "Sector")), turn_number], HORIZONTAL_ALIGNMENT_LEFT, 660.0, 13, Color("ff8cbd"))
	draw_texture_rect(ENEMY, Rect2(170.0, 150.0, 380.0, 380.0), false)
	_draw_bar(Rect2(100.0, 530.0, 520.0, 20.0), enemy_hp, enemy_max_hp, Color("62dfff"))
	draw_string(ThemeDB.fallback_font, Vector2(90.0, 580.0), message, HORIZONTAL_ALIGNMENT_CENTER, 540.0, 15, Color("f2d8e7"))
	for index: int in range(crew_units.size()):
		var unit: Dictionary = crew_units[index]
		var x: float = 35.0 + float(index) * 170.0
		var rect: Rect2 = Rect2(x, 640.0, 145.0, 220.0)
		draw_style_box(_panel(Color("170c20"), Color("ff6fa8") if int(unit.get("hp", 0)) > 0 else Color("65424f"), 1, 10), rect)
		draw_texture_rect(PORTRAITS[String(unit.get("id", "crew_1"))] as Texture2D, Rect2(x + 8.0, 648.0, 129.0, 129.0), false)
		draw_string(ThemeDB.fallback_font, Vector2(x + 6.0, 800.0), String(unit.get("name", "Crew")), HORIZONTAL_ALIGNMENT_CENTER, 133.0, 11, Color("fff4fb"))
		_draw_bar(Rect2(x + 12.0, 824.0, 121.0, 10.0), int(unit.get("hp", 0)), int(unit.get("max_hp", 100)), Color("ff5f91"))
		draw_string(ThemeDB.fallback_font, Vector2(x + 6.0, 852.0), "SPECIAL %s" % ("READY" if bool(unit.get("special_ready", false)) else "SPENT"), HORIZONTAL_ALIGNMENT_CENTER, 133.0, 8, Color("ffbe68"))
	draw_style_box(_panel(Color("110916"), Color("8d4aa4"), 1, 10), Rect2(20.0, 886.0, 680.0, 178.0))
	for index: int in range(mini(combat_log.size(), 6)):
		draw_string(ThemeDB.fallback_font, Vector2(34.0, 916.0 + float(index) * 23.0), combat_log[index], HORIZONTAL_ALIGNMENT_LEFT, 650.0, 10, Color("c8a7bb"))
	_draw_action_button("strike", "STRIKE")
	_draw_action_button("evade", "EVADE")
	_draw_action_button("special", "SPECIAL")
	_draw_action_button("auto", "AUTO ON" if auto_mode else "AUTO")
	_draw_action_button("abort", "ABORT SCORE")
	_draw_action_button("return", "CONTINUE" if battle_over else "RETURN")
	if battle_over:
		draw_rect(Rect2(80.0, 465.0, 560.0, 110.0), Color("173d33", 0.94) if victory else Color("4b1728", 0.94), true)
		draw_string(ThemeDB.fallback_font, Vector2(90.0, 530.0), "SCORE SECURED" if victory else "SCORE BURNED", HORIZONTAL_ALIGNMENT_CENTER, 540.0, 28, Color("72f0c1") if victory else Color("ff7995"))

func _draw_action_button(id_value: String, label: String) -> void:
	var rect: Rect2 = buttons[id_value] as Rect2
	var enabled: bool = not battle_over or id_value == "return"
	draw_style_box(_panel(Color("5a2149") if enabled else Color("251422"), Color("ff8fbc") if enabled else Color("644455"), 1, 9), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 43.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 10, Color("fff4fb"))

func _draw_bar(rect: Rect2, current: int, maximum: int, color: Color) -> void:
	draw_rect(rect, Color("120b13"), true)
	var ratio: float = 0.0 if maximum <= 0 else clampf(float(current) / float(maximum), 0.0, 1.0)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), color, true)
	draw_rect(rect, Color("f5d7e7", 0.4), false, 1.0)

func _add_log(text: String) -> void:
	combat_log.push_front(text)
	if combat_log.size() > 7:
		combat_log.resize(7)

func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
