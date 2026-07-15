extends "res://scripts/syndicate_skinned_raid.gd"
## Adds animated combat actors, attacks, evasions, specials, and result poses over the matching raid graphics.

const Anim = preload("res://scripts/syndicate_animation_library.gd")

var combat_time: float = 0.0
var action_state: String = "advance"
var action_started_at: float = 0.0
var enemy_flash_until: float = 0.0

func _process(delta: float) -> void:
	combat_time += delta
	super._process(delta)

func _act(action: String) -> void:
	action_state = action
	action_started_at = combat_time
	super._act(action)

func _enemy_turn() -> void:
	enemy_flash_until = combat_time + 0.42
	super._enemy_turn()

func _finish(won: bool, text: String) -> void:
	action_state = "celebrate" if won else "defeated"
	action_started_at = combat_time
	super._finish(won, text)

func _draw() -> void:
	super._draw()
	_draw_animated_battlefield()

func _draw_animated_battlefield() -> void:
	var arena: Rect2 = Rect2(66.0, 168.0, 588.0, 344.0)
	var arena_fill: Color = SyndicateSkins.dark()
	arena_fill.a = 0.28
	draw_rect(arena, arena_fill, true)
	for line_index: int in range(6):
		var perspective_y: float = arena.position.y + 48.0 + float(line_index) * 49.0
		draw_line(Vector2(arena.position.x + float(line_index) * 14.0, perspective_y), Vector2(arena.end.x - float(line_index) * 14.0, perspective_y), Color(SyndicateSkins.accent(), 0.11), 1.0, true)
	var action_age: float = combat_time - action_started_at
	for index: int in range(crew_units.size()):
		var unit: Dictionary = crew_units[index]
		var alive: bool = int(unit.get("hp", 0)) > 0
		var base_position: Vector2 = Vector2(135.0 + float(index % 2) * 118.0, 300.0 + float(index / 2) * 112.0)
		var position: Vector2 = base_position
		var motion: float = 0.0
		var action: String = "guard"
		if not alive:
			action = "defeated"
		elif battle_over:
			action = "celebrate" if victory else "defeated"
		elif action_state == "strike" and action_age < 0.72:
			position.x += sin(clampf(action_age / 0.72, 0.0, 1.0) * PI) * 42.0
			action = "fight"
			motion = 1.0
		elif action_state == "evade" and action_age < 0.75:
			position.y -= sin(clampf(action_age / 0.75, 0.0, 1.0) * PI) * 26.0
			position.x -= sin(clampf(action_age / 0.75, 0.0, 1.0) * PI) * 28.0
			action = "run"
			motion = 1.0
		elif action_state == "special" and action_age < 1.0:
			action = _special_action(String(unit.get("role", "Enforcer")))
		else:
			action = "guard"
		var role_item: String = SyndicateSkins.crew_item(String(unit.get("role", "Enforcer")))
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(role_item), position, combat_time, float(index) * 0.23, 1.0, motion, 1.05, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), action)
		Anim.draw_job_effect(self, position + Vector2(35.0, 2.0), action, combat_time, float(index) * 0.23, 0.78, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
		if index == 0:
			Anim.draw_job_label(self, position + Vector2(15.0, -49.0), "CREW %s" % _action_label(action), 122.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 7)
	_draw_enemy_team(action_age)
	_draw_combat_projectiles(action_age)

func _draw_enemy_team(action_age: float) -> void:
	var enemy_count: int = 3
	for index: int in range(enemy_count):
		var base_position: Vector2 = Vector2(505.0 + float(index % 2) * 72.0, 292.0 + float(index) * 76.0)
		var position: Vector2 = base_position
		var action: String = "aim"
		var motion: float = 0.0
		if battle_over:
			action = "defeated" if victory else "celebrate"
		elif combat_time < enemy_flash_until:
			position.x -= sin(clampf((enemy_flash_until - combat_time) / 0.42, 0.0, 1.0) * PI) * 28.0
			action = "fight"
			motion = 1.0
		elif action_state in ["strike", "special"] and action_age < 0.65:
			position.x += sin(clampf(action_age / 0.65, 0.0, 1.0) * PI) * 12.0
			action = "guard"
		var threat_item: String = "threat_patrol"
		if String(SyndicateState.active_job.get("target", "")).to_lower().contains("armored"):
			threat_item = "threat_riot"
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(threat_item), position, combat_time, float(index) * 0.31, -1.0, motion, 0.96, SyndicateSkins.danger(), SyndicateSkins.secondary(), SyndicateSkins.panel(), action)
		Anim.draw_job_effect(self, position + Vector2(-32.0, 1.0), action, combat_time, float(index) * 0.31, 0.72, SyndicateSkins.danger(), SyndicateSkins.secondary(), SyndicateSkins.panel())
	if enemy_count > 0:
		Anim.draw_job_label(self, Vector2(535.0, 228.0), "PEACEKEEPER RESPONSE", 170.0, SyndicateSkins.danger(), SyndicateSkins.panel(), SyndicateSkins.text(), 7)

func _draw_combat_projectiles(action_age: float) -> void:
	if battle_over:
		return
	if action_state == "strike" and action_age < 0.58:
		for index: int in range(maxi(1, crew_units.size())):
			var start: Vector2 = Vector2(195.0 + float(index % 2) * 100.0, 305.0 + float(index / 2) * 110.0)
			var finish: Vector2 = Vector2(500.0, 330.0 + float(index % 3) * 70.0)
			var progress: float = clampf(action_age / 0.58 - float(index) * 0.05, 0.0, 1.0)
			var projectile: Vector2 = start.lerp(finish, progress)
			draw_line(start.lerp(finish, maxf(0.0, progress - 0.10)), projectile, SyndicateSkins.accent(), 4.0, true)
			draw_circle(projectile, 4.0, SyndicateSkins.secondary())
	elif action_state == "special" and action_age < 0.90:
		var center: Vector2 = Vector2(485.0, 340.0)
		for ring_index: int in range(4):
			var radius: float = (action_age * 120.0 + float(ring_index) * 23.0)
			draw_arc(center, radius, 0.0, TAU, 48, Color(SyndicateSkins.secondary(), maxf(0.0, 0.55 - action_age * 0.45)), 4.0, true)

func _special_action(role: String) -> String:
	match role.to_lower():
		"runner": return "run"
		"sharpshot", "sharpshooter": return "aim"
		"hacker", "techie": return "hack"
		_: return "fight"

func _action_label(action: String) -> String:
	match action:
		"fight": return "STRIKING"
		"run": return "EVADING"
		"aim": return "SPECIAL FIRE"
		"hack": return "SYSTEM BREACH"
		"celebrate": return "VICTORY"
		"defeated": return "DOWN"
		_: return "IN COVER"

func combat_actor_count() -> int:
	return crew_units.size() + 3
