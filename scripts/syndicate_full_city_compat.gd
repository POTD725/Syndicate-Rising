extends "res://scripts/syndicate_full_city.gd"
## Keeps established compatibility controls and exposes the living workforce for tests.

var npc_jobs: Array[Dictionary] = []

func _ready() -> void:
	super._ready()
	button_rects["skin"] = Rect2(329.0, 104.0, 86.0, 38.0)
	npc_jobs = worker_jobs.duplicate(true)

func npc_job_count() -> int:
	return npc_jobs.size()

func every_npc_has_job() -> bool:
	for job: Dictionary in npc_jobs:
		if String(job.get("job", "")).is_empty():
			return false
		if not job.has("a") or not job.has("b") or not job.has("speed"):
			return false
	return not npc_jobs.is_empty()

func _action(action: String) -> void:
	if action == "skin":
		SyndicateSkins.cycle_skin()
		message = "Interface family changed to %s. The full isometric city remains active." % SyndicateSkins.skin_name()
		SyndicateAudio.play_sfx("click")
		queue_redraw()
		return
	super._action(action)

func _draw_camera_controls() -> void:
	super._draw_camera_controls()
	_draw_button(button_rects["skin"] as Rect2, "SKIN", true, 8)
