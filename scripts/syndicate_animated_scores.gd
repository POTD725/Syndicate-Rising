extends "res://scripts/syndicate_skinned_scores.gd"
## Makes every roster member visibly perform a current duty instead of remaining a static card.

const Anim = preload("res://scripts/syndicate_animation_library.gd")

var roster_time: float = 0.0

func _process(delta: float) -> void:
	roster_time += delta
	super._process(delta)

func _draw_crew() -> void:
	super._draw_crew()
	var now: int = int(Time.get_unix_time_from_system())
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var id_value: String = String(member.get("id", ""))
		if not crew_rects.has(id_value):
			continue
		var rect: Rect2 = crew_rects[id_value] as Rect2
		var action: String = _member_action(member, now)
		var duty: String = _member_duty(member, now)
		var role_item: String = SyndicateSkins.crew_item(String(member.get("role", "Enforcer")))
		var position: Vector2 = rect.position + Vector2(78.0, 126.0)
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(role_item), position, roster_time, float(index) * 0.24, 1.0, 0.0 if action != "run" else 1.0, 0.72, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), action)
		Anim.draw_job_effect(self, position + Vector2(26.0, 2.0), action, roster_time, float(index) * 0.24, 0.58, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(136.0, 146.0), duty, HORIZONTAL_ALIGNMENT_LEFT, 178.0, 7, SyndicateSkins.secondary())

func _member_action(member: Dictionary, now: int) -> String:
	if SyndicateState.captured_crew_ids.has(String(member.get("id", ""))):
		return "defeated"
	if int(member.get("injured_until", 0)) > now:
		return "recover"
	if int(member.get("busy_until", 0)) > now:
		return "run"
	match String(member.get("role", "Enforcer")).to_lower():
		"runner": return "repair"
		"sharpshot", "sharpshooter": return "aim"
		"hacker", "techie": return "hack"
		_: return "train"

func _member_duty(member: Dictionary, now: int) -> String:
	if SyndicateState.captured_crew_ids.has(String(member.get("id", ""))):
		return "CAPTURED • RESCUE REQUIRED"
	if int(member.get("injured_until", 0)) > now:
		return "CLINIC RECOVERY"
	if int(member.get("busy_until", 0)) > now:
		return "RUNNING AN ACTIVE SCORE"
	match String(member.get("role", "Enforcer")).to_lower():
		"runner": return "PREPARING GETAWAY ROUTES"
		"sharpshot", "sharpshooter": return "CALIBRATING RANGE OPTICS"
		"hacker", "techie": return "CRACKING AUTHORITY NETWORKS"
		_: return "TRAINING HIDEOUT DEFENSE"

func roster_job_count() -> int:
	return SyndicateState.crew.size()
