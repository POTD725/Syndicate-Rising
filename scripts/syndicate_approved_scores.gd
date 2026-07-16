extends "res://scripts/syndicate_scores.gd"
## Mission board rendered over the approved lunar city and matching mission art.

const APPROVED_ART: Script = preload("res://scripts/syndicate_approved_art.gd")
var approved_board: Texture2D
var systems_atlas: Texture2D

func _ready() -> void:
	approved_board = APPROVED_ART.board_texture()
	systems_atlas = APPROVED_ART.systems_atlas()
	super._ready()

func approved_graphics_active() -> bool:
	return APPROVED_ART.approved_graphics_active()

func _draw() -> void:
	draw_texture_rect_region(approved_board, Rect2(0.0, 0.0, VIEW.x, VIEW.y), Rect2(152.0, 180.0, 720.0, 1280.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.015, 0.025, 0.045, 0.72), true)
	draw_style_box(_panel(Color("07111f", 0.96), Color("55dfff"), 3, 14), Rect2(10.0, 10.0, 700.0, 112.0))
	draw_string(ThemeDB.fallback_font, Vector2(26.0, 49.0), "SYNDICATE MISSIONS", HORIZONTAL_ALIGNMENT_LEFT, 510.0, 25, Color("f6fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(26.0, 83.0), "CHAPTER %d  •  HEAT %d  •  NOTORIETY %d" % [SyndicateState.story_chapter, SyndicateState.heat, SyndicateState.notoriety], HORIZONTAL_ALIGNMENT_LEFT, 560.0, 12, Color("75e4ff"))
	_draw_jobs()
	_draw_crew()
	draw_style_box(_panel(Color("07111f", 0.95), Color("5c7891"), 1, 10), Rect2(18.0, 1112.0, 684.0, 42.0))
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 1139.0), message, HORIZONTAL_ALIGNMENT_LEFT, 664.0, 10, Color("d9e5ed"))
	_draw_button(buttons["back"] as Rect2, "RETURN TO DISTRICT", false)
	_draw_button(buttons["run"] as Rect2, "RUN SELECTED SCORE", not selected_job.is_empty() and not selected_crew.is_empty())

func _draw_jobs() -> void:
	job_rects.clear()
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 157.0), "AVAILABLE SCORES", HORIZONTAL_ALIGNMENT_LEFT, 400.0, 16, Color("55dfff"))
	if SyndicateState.jobs.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(24.0, 205.0), "Fixers are scanning. Next window in %ds." % SyndicateState.seconds_left(SyndicateState.next_job_at), HORIZONTAL_ALIGNMENT_LEFT, 650.0, 12, Color("c1cfda"))
	for index: int in range(SyndicateState.jobs.size()):
		var job: Dictionary = SyndicateState.jobs[index]
		var id_value: String = String(job.get("id", ""))
		var rect: Rect2 = Rect2(22.0, 183.0 + float(index) * 158.0, 676.0, 142.0)
		job_rects[id_value] = rect
		var story: bool = bool(job.get("story", false))
		var selected: bool = id_value == selected_job
		var border: Color = Color("ffd16a") if story else Color("55dfff")
		if selected:
			border = Color("ffffff")
		draw_style_box(_panel(Color("0a1725", 0.96), border, 4 if selected else 2, 12), rect)
		var target: String = String(job.get("target", "")).to_lower()
		var icon_id: String = "mission_hidden"
		if target.contains("command") or target.contains("armored"):
			icon_id = "threat_riot"
		elif target.contains("security") or target.contains("peacekeeper"):
			icon_id = "threat_patrol"
		draw_texture_rect_region(systems_atlas, Rect2(rect.position + Vector2(9.0, 15.0), Vector2(108.0, 108.0)), APPROVED_ART.system_region(icon_id))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(128.0, 29.0), ("STORY // " if story else "") + String(job.get("title", "SCORE")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 420.0, 15, Color("f6fbff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(128.0, 61.0), "%s  •  TARGET %s" % [String(job.get("sector", "Sector")), String(job.get("target", "Security"))], HORIZONTAL_ALIGNMENT_LEFT, 420.0, 10, Color("8ee7ff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(128.0, 92.0), "DIFFICULTY %d  •  REWARD %d CR  •  CARGO +%d" % [int(job.get("difficulty", 1)), int(job.get("reward", 0)), int(job.get("contraband", 1))], HORIZONTAL_ALIGNMENT_LEFT, 430.0, 10, Color("ffd16a"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(565.0, 40.0), "%02ds" % SyndicateState.seconds_left(int(job.get("expires_at", 0))), HORIZONTAL_ALIGNMENT_CENTER, 90.0, 17, Color("ff7188"))

func _draw_crew() -> void:
	crew_rects.clear()
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 674.0), "CREW ROSTER", HORIZONTAL_ALIGNMENT_LEFT, 400.0, 16, Color("55dfff"))
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var id_value: String = String(member.get("id", ""))
		var column: int = index % 2
		var row: int = int(index / 2)
		var rect: Rect2 = Rect2(22.0 + float(column) * 342.0, 704.0 + float(row) * 184.0, 330.0, 166.0)
		crew_rects[id_value] = rect
		var ready: bool = SyndicateState.crew_available(member)
		var selected: bool = selected_crew.has(id_value)
		draw_style_box(_panel(Color("0a1725", 0.96 if ready else 0.66), Color("55dfff") if selected else Color("536c80"), 3 if selected else 1, 12), rect)
		var portrait: Texture2D = PORTRAITS[id_value] as Texture2D
		draw_texture_rect(portrait, Rect2(rect.position + Vector2(10.0, 10.0), Vector2(116.0, 116.0)), false)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 38.0), String(member.get("name", "Crew")), HORIZONTAL_ALIGNMENT_LEFT, 178.0, 14, Color("f6fbff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 68.0), "%s  •  L%d" % [String(member.get("role", "")), int(member.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 178.0, 10, Color("75e4ff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 98.0), "PWR %d   HP %d/%d" % [int(member.get("power", 0)), int(member.get("hp", 0)), int(member.get("max_hp", 0))], HORIZONTAL_ALIGNMENT_LEFT, 180.0, 10, Color("d8e5ed"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 129.0), "READY" if ready else "UNAVAILABLE", HORIZONTAL_ALIGNMENT_LEFT, 178.0, 10, Color("6ff0c7") if ready else Color("ff7188"))

func _draw_button(rect: Rect2, label: String, active: bool) -> void:
	draw_style_box(_panel(Color("1b4863") if active else Color("142435"), Color("67e9ff") if active else Color("536c80"), 3 if active else 1, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 47.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 11, Color("f6fbff"))
