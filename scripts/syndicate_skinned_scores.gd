extends "res://scripts/syndicate_scores.gd"
## Skins the score board, mission cards, crew roles, and launch controls.

var skin_atlas: Texture2D

func _ready() -> void:
	skin_atlas = SyndicateSkins.atlas()
	if not SyndicateSkins.skin_changed.is_connected(_on_skin_changed):
		SyndicateSkins.skin_changed.connect(_on_skin_changed)
	super._ready()

func _on_skin_changed(_index: int) -> void:
	skin_atlas = SyndicateSkins.atlas()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), SyndicateSkins.dark())
	for index: int in range(100):
		var star: Color = SyndicateSkins.accent()
		star.a = 0.13
		draw_circle(Vector2(fmod(float(index * 83 + 17), VIEW.x), fmod(float(index * 47 + 31), VIEW.y)), 1.0, star)
	draw_rect(Rect2(0.0, 0.0, 720.0, 126.0), SyndicateSkins.panel(), true)
	draw_texture_rect_region(skin_atlas, Rect2(610.0, 20.0, 82.0, 82.0), SyndicateSkins.region("score"))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 48.0), "SYNDICATE SCORE BOARD", HORIZONTAL_ALIGNMENT_LEFT, 570.0, 26, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 82.0), "CHAPTER %d • HEAT %d • NOTORIETY %d • %s" % [SyndicateState.story_chapter, SyndicateState.heat, SyndicateState.notoriety, SyndicateSkins.skin_name().to_upper()], HORIZONTAL_ALIGNMENT_LEFT, 580.0, 11, SyndicateSkins.secondary())
	_draw_jobs()
	_draw_crew()
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 1138.0), message, HORIZONTAL_ALIGNMENT_LEFT, 660.0, 11, SyndicateSkins.text())
	_draw_button(buttons["back"] as Rect2, "RETURN TO DISTRICT", false)
	_draw_button(buttons["run"] as Rect2, "RUN SELECTED SCORE", not selected_job.is_empty() and not selected_crew.is_empty())

func _draw_jobs() -> void:
	job_rects.clear()
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 160.0), "AVAILABLE SCORES", HORIZONTAL_ALIGNMENT_LEFT, 400.0, 16, SyndicateSkins.accent())
	if SyndicateState.jobs.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(24.0, 205.0), "Fixers are scanning. Next window in %ds." % SyndicateState.seconds_left(SyndicateState.next_job_at), HORIZONTAL_ALIGNMENT_LEFT, 650.0, 12, SyndicateSkins.text())
	for index: int in range(SyndicateState.jobs.size()):
		var job: Dictionary = SyndicateState.jobs[index]
		var id_value: String = String(job.get("id", ""))
		var rect: Rect2 = Rect2(22.0, 188.0 + float(index) * 158.0, 676.0, 142.0)
		job_rects[id_value] = rect
		var story: bool = bool(job.get("story", false))
		var active: bool = id_value == selected_job
		draw_style_box(SyndicateSkins.style_box(active, 12), rect)
		var item_id: String = "mission_law_hack" if String(job.get("target", "")).contains("Peacekeeper") else "mission_hidden"
		if story:
			item_id = "score"
		draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(10.0, 16.0), Vector2(92.0, 92.0)), SyndicateSkins.region(item_id))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(112.0, 30.0), ("STORY // " if story else "") + String(job.get("title", "SCORE")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 405.0, 15, SyndicateSkins.text())
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(112.0, 61.0), "%s • TARGET %s" % [String(job.get("sector", "Sector")), String(job.get("target", "Security"))], HORIZONTAL_ALIGNMENT_LEFT, 430.0, 10, SyndicateSkins.accent())
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(112.0, 92.0), "DIFFICULTY %d • REWARD %d CR • CARGO +%d" % [int(job.get("difficulty", 1)), int(job.get("reward", 0)), int(job.get("contraband", 1))], HORIZONTAL_ALIGNMENT_LEFT, 430.0, 10, SyndicateSkins.secondary())
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(565.0, 39.0), "%02ds" % SyndicateState.seconds_left(int(job.get("expires_at", 0))), HORIZONTAL_ALIGNMENT_CENTER, 90.0, 18, SyndicateSkins.danger())

func _draw_crew() -> void:
	crew_rects.clear()
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 678.0), "CREW ROSTER", HORIZONTAL_ALIGNMENT_LEFT, 400.0, 16, SyndicateSkins.accent())
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var id_value: String = String(member.get("id", ""))
		var column: int = index % 2
		var row: int = int(index / 2)
		var rect: Rect2 = Rect2(22.0 + float(column) * 342.0, 710.0 + float(row) * 180.0, 330.0, 160.0)
		crew_rects[id_value] = rect
		var ready: bool = SyndicateState.crew_available(member)
		var selected: bool = selected_crew.has(id_value)
		draw_style_box(SyndicateSkins.style_box(selected, 12, 0.95 if ready else 0.58), rect)
		var role_item: String = SyndicateSkins.crew_item(String(member.get("role", "Enforcer")))
		draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(10.0, 10.0), Vector2(116.0, 116.0)), SyndicateSkins.region(role_item))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 37.0), String(member.get("name", "Crew")), HORIZONTAL_ALIGNMENT_LEFT, 175.0, 14, SyndicateSkins.text())
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 66.0), "%s • L%d" % [String(member.get("role", "")), int(member.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 175.0, 10, SyndicateSkins.accent())
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 94.0), "PWR %d HP %d/%d" % [int(member.get("power", 0)), int(member.get("hp", 0)), int(member.get("max_hp", 0))], HORIZONTAL_ALIGNMENT_LEFT, 180.0, 10, SyndicateSkins.text())
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 124.0), "READY" if ready else "UNAVAILABLE", HORIZONTAL_ALIGNMENT_LEFT, 175.0, 10, SyndicateSkins.accent() if ready else SyndicateSkins.danger())

func _draw_button(rect: Rect2, label: String, active: bool) -> void:
	draw_style_box(SyndicateSkins.style_box(active, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 44.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 11, SyndicateSkins.text())
