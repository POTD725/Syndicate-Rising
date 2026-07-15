extends "res://scripts/syndicate_skinned_operations.gd"
## Gives every Operations screen visible workers whose actions match the selected resource, defense, threat, or mission.

const Anim = preload("res://scripts/syndicate_animation_library.gd")

func _draw_harvest() -> void:
	super._draw_harvest()
	var jobs: Array[Dictionary] = [
		{"position":Vector2(365.0, 550.0), "role":"Enforcer", "action":"mine", "label":"CUTTING LUNAR ALLOY", "phase":0.08},
		{"position":Vector2(365.0, 682.0), "role":"Runner", "action":"pump", "label":"PUMPING HELIUM-3", "phase":0.39},
		{"position":Vector2(365.0, 814.0), "role":"Hacker", "action":"scan", "label":"EXTRACTING DATA CORES", "phase":0.72}
	]
	for job: Dictionary in jobs:
		var position: Vector2 = job.get("position", Vector2.ZERO) as Vector2
		var action: String = String(job.get("action", "mine"))
		var phase: float = float(job.get("phase", 0.0))
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item(String(job.get("role", "Runner")))), position, elapsed, phase, 1.0, 0.0, 0.96, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), action)
		Anim.draw_job_effect(self, position + Vector2(40.0, 4.0), action, elapsed, phase, 0.82, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
		Anim.draw_job_label(self, position + Vector2(-5.0, -43.0), String(job.get("label", "HARVESTING")), 158.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 7)

func _draw_threat() -> void:
	super._draw_threat()
	var threat_active: bool = not SyndicateState.active_threat.is_empty()
	var action: String = "scan" if not threat_active else "guard"
	var label: String = "MONITORING ORBIT" if not threat_active else "TRACKING ACTIVE RAID"
	Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item("Hacker")), Vector2(192.0, 806.0), elapsed, 0.24, 1.0, 0.0, 1.05, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), action)
	Anim.draw_job_effect(self, Vector2(245.0, 808.0), action, elapsed, 0.24, 0.90, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
	Anim.draw_job_label(self, Vector2(192.0, 757.0), label, 174.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 7)
	if threat_active:
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region("crew_enforcer"), Vector2(525.0, 806.0), elapsed, 0.61, -1.0, 0.0, 1.05, SyndicateSkins.secondary(), SyndicateSkins.accent(), SyndicateSkins.panel(), "guard")
		Anim.draw_job_effect(self, Vector2(475.0, 808.0), "guard", elapsed, 0.61, 0.90, SyndicateSkins.secondary(), SyndicateSkins.accent(), SyndicateSkins.panel())
		Anim.draw_job_label(self, Vector2(525.0, 757.0), "DEFENSE CREW STANDING BY", 190.0, SyndicateSkins.secondary(), SyndicateSkins.panel(), SyndicateSkins.text(), 7)

func _draw_defenses() -> void:
	super._draw_defenses()
	var jobs: Array[Dictionary] = [
		{"position":Vector2(286.0, 516.0), "action":"jam", "role":"Hacker", "label":"TUNING JAMMER", "phase":0.10},
		{"position":Vector2(286.0, 620.0), "action":"guard", "role":"Enforcer", "label":"SENTRY WATCH", "phase":0.32},
		{"position":Vector2(286.0, 724.0), "action":"repair", "role":"Enforcer", "label":"SEALING BLAST DOORS", "phase":0.56},
		{"position":Vector2(286.0, 828.0), "action":"load", "role":"Runner", "label":"CLEARING ESCAPE ROUTE", "phase":0.79}
	]
	for job: Dictionary in jobs:
		var position: Vector2 = job.get("position", Vector2.ZERO) as Vector2
		var action: String = String(job.get("action", "repair"))
		var phase: float = float(job.get("phase", 0.0))
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item(String(job.get("role", "Runner")))), position, elapsed, phase, 1.0, 0.0, 0.78, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), action)
		Anim.draw_job_effect(self, position + Vector2(34.0, 3.0), action, elapsed, phase, 0.68, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
		Anim.draw_job_label(self, position + Vector2(-28.0, -35.0), String(job.get("label", "DEFENSE DUTY")), 146.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 6)

func _draw_missions() -> void:
	super._draw_missions()
	if SyndicateState.side_mission_mode.is_empty():
		var broker_position: Vector2 = Vector2(360.0, 846.0)
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region("crew_hacker"), broker_position, elapsed, 0.21, 1.0, 0.0, 1.06, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "plan")
		Anim.draw_job_effect(self, broker_position + Vector2(50.0, 3.0), "plan", elapsed, 0.21, 0.92, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
		Anim.draw_job_label(self, broker_position + Vector2(0.0, -50.0), "MISSION BROKER BUILDING ROUTES", 220.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 7)
	else:
		var mode: String = SyndicateState.side_mission_mode
		var action: String = "hack"
		if mode == "hidden":
			action = "load"
		elif mode == "rescue":
			action = "breach"
		var infiltrator_position: Vector2 = Vector2(360.0, 1020.0)
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region(SyndicateSkins.crew_item("Runner" if mode == "hidden" else "Hacker")), infiltrator_position, elapsed, 0.48, 1.0, 0.0, 1.02, SyndicateSkins.secondary(), SyndicateSkins.accent(), SyndicateSkins.panel(), action)
		Anim.draw_job_effect(self, infiltrator_position + Vector2(48.0, 2.0), action, elapsed, 0.48, 0.88, SyndicateSkins.secondary(), SyndicateSkins.accent(), SyndicateSkins.panel())
		Anim.draw_job_label(self, infiltrator_position + Vector2(0.0, -48.0), "%s IN PROGRESS" % mode.replace("_", " ").to_upper(), 204.0, SyndicateSkins.secondary(), SyndicateSkins.panel(), SyndicateSkins.text(), 7)

func operator_job_count() -> int:
	match active_tab:
		"harvest": return 3
		"threat": return 2 if not SyndicateState.active_threat.is_empty() else 1
		"defenses": return 4
		_: return 1
