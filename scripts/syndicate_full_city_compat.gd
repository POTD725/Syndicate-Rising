extends "res://scripts/syndicate_full_city.gd"
## Approved production city wrapper. It preserves all gameplay, camera, rotation,
## worker, and compatibility hooks while replacing every procedural texture.

const APPROVED_ART: Script = preload("res://scripts/syndicate_approved_art.gd")

var npc_jobs: Array[Dictionary] = []

func _ready() -> void:
	super._ready()
	board_texture = APPROVED_ART.board_texture()
	npc_atlas = APPROVED_ART.npc_atlas()
	ui_atlas = APPROVED_ART.ui_atlas()
	dermapack_texture = APPROVED_ART.dermapack_texture()
	button_rects["skin"] = Rect2(329.0, 104.0, 86.0, 38.0)
	npc_jobs = worker_jobs.duplicate(true)
	var tools: Array[String] = ["terminal", "research", "guard", "rifle", "welder", "medical", "cargo", "mining", "courier", "hacking", "training", "maintenance"]
	for index: int in range(npc_jobs.size()):
		npc_jobs[index]["room"] = ROOM_IDS[index % ROOM_IDS.size()]
		npc_jobs[index]["tool"] = tools[index % tools.size()]
	message = "Approved lunar district loaded: 32 MoonGoons are working across the base."
	queue_redraw()

func approved_graphics_active() -> bool:
	return APPROVED_ART.approved_graphics_active()

func graphics_receipt() -> Dictionary:
	return APPROVED_ART.graphics_receipt()

func npc_job_count() -> int:
	return npc_jobs.size()

func every_npc_has_job() -> bool:
	for job: Dictionary in npc_jobs:
		if String(job.get("job", "")).is_empty():
			return false
		if String(job.get("room", "")).is_empty() or String(job.get("tool", "")).is_empty():
			return false
		if not job.has("a") or not job.has("b") or not job.has("speed"):
			return false
	return not npc_jobs.is_empty()

func _action(action: String) -> void:
	if action == "skin":
		SyndicateSkins.cycle_skin()
		message = "Dashboard trim changed to %s. Approved city graphics remain active." % SyndicateSkins.skin_name()
		SyndicateAudio.play_sfx("click")
		queue_redraw()
		return
	super._action(action)

func _draw_camera_controls() -> void:
	super._draw_camera_controls()
	_draw_button(button_rects["skin"] as Rect2, "SKIN", true, 8)
