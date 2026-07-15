extends Node2D
## Criminal score board and crew-selection screen.

const VIEW: Vector2 = Vector2(720.0, 1280.0)
const PORTRAITS: Dictionary = {
	"crew_1": preload("res://assets/portraits/nyx_raze.svg"),
	"crew_2": preload("res://assets/portraits/vox_13.svg"),
	"crew_3": preload("res://assets/portraits/cinder_quell.svg"),
	"crew_4": preload("res://assets/portraits/grit_mercer.svg")
}

var job_rects: Dictionary = {}
var crew_rects: Dictionary = {}
var buttons: Dictionary = {
	"run": Rect2(372.0, 1168.0, 330.0, 76.0),
	"back": Rect2(18.0, 1168.0, 330.0, 76.0)
}
var selected_job: String = ""
var selected_crew: Array[String] = []
var message: String = "Select a score and assemble a crew."
var clock: float = 0.0

func _ready() -> void:
	SyndicateAudio.play_music("city")
	SyndicateState.tick()
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	if clock >= 0.25:
		clock = 0.0
		SyndicateState.tick()
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
	for id_value: Variant in job_rects.keys():
		if (job_rects[id_value] as Rect2).has_point(pos):
			selected_job = String(id_value)
			SyndicateAudio.play_sfx("click")
			return
	for id_value: Variant in crew_rects.keys():
		if (crew_rects[id_value] as Rect2).has_point(pos):
			_toggle_crew(String(id_value))
			return
	if (buttons["back"] as Rect2).has_point(pos):
		get_tree().change_scene_to_file("res://scenes/SyndicateCity.tscn")
	elif (buttons["run"] as Rect2).has_point(pos):
		var result: Dictionary = SyndicateState.begin_job(selected_job, selected_crew)
		message = String(result.get("message", "Unable to launch score."))
		if bool(result.get("ok", false)):
			SyndicateAudio.play_sfx("accept")
			get_tree().change_scene_to_file("res://scenes/SyndicateRaid.tscn")
		else:
			SyndicateAudio.play_sfx("warning")

func _toggle_crew(id_value: String) -> void:
	var member: Dictionary = SyndicateState.get_crew_member(id_value)
	if member.is_empty() or not SyndicateState.crew_available(member):
		message = "%s is unavailable." % String(member.get("name", "Crew"))
		SyndicateAudio.play_sfx("warning")
		return
	if selected_crew.has(id_value):
		selected_crew.erase(id_value)
	else:
		var crew_limit: int = 3
		if SyndicateState.is_room_repaired("boss_office"):
			crew_limit = mini(4, 2 + SyndicateState.get_room_level("boss_office"))
		if selected_crew.size() >= crew_limit:
			message = "Current crew capacity is %d." % crew_limit
			SyndicateAudio.play_sfx("warning")
			return
		selected_crew.append(id_value)
	SyndicateAudio.play_sfx("click")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("07030d"))
	for index: int in range(100):
		draw_circle(Vector2(fmod(float(index * 83 + 17), VIEW.x), fmod(float(index * 47 + 31), VIEW.y)), 1.0, Color("d6b1ff", 0.16))
	draw_rect(Rect2(0.0, 0.0, 720.0, 126.0), Color("170c20"), true)
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 48.0), "SYNDICATE SCORE BOARD", HORIZONTAL_ALIGNMENT_LEFT, 600.0, 26, Color("fff4fb"))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 82.0), "CHAPTER %d  •  HEAT %d  •  NOTORIETY %d" % [SyndicateState.story_chapter, SyndicateState.heat, SyndicateState.notoriety], HORIZONTAL_ALIGNMENT_LEFT, 620.0, 13, Color("ff8cbd"))
	_draw_jobs()
	_draw_crew()
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 1138.0), message, HORIZONTAL_ALIGNMENT_LEFT, 660.0, 11, Color("dfbdd1"))
	_draw_button(buttons["back"] as Rect2, "RETURN TO DISTRICT", false)
	_draw_button(buttons["run"] as Rect2, "RUN SELECTED SCORE", not selected_job.is_empty() and not selected_crew.is_empty())

func _draw_jobs() -> void:
	job_rects.clear()
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 160.0), "AVAILABLE SCORES", HORIZONTAL_ALIGNMENT_LEFT, 400.0, 16, Color("ff78b0"))
	if SyndicateState.jobs.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(24.0, 205.0), "Fixers are scanning. Next window in %ds." % SyndicateState.seconds_left(SyndicateState.next_job_at), HORIZONTAL_ALIGNMENT_LEFT, 650.0, 12, Color("a8899e"))
	for index: int in range(SyndicateState.jobs.size()):
		var job: Dictionary = SyndicateState.jobs[index]
		var id_value: String = String(job.get("id", ""))
		var rect: Rect2 = Rect2(22.0, 188.0 + float(index) * 158.0, 676.0, 142.0)
		job_rects[id_value] = rect
		var story: bool = bool(job.get("story", false))
		var border: Color = Color("fff4fb") if id_value == selected_job else (Color("ffbe68") if story else Color("b96cff"))
		draw_style_box(_panel(Color("180d21"), border, 3 if id_value == selected_job else 1, 12), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 30.0), ("STORY // " if story else "") + String(job.get("title", "SCORE")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 510.0, 16, Color("fff4fb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 61.0), "%s  •  TARGET %s" % [String(job.get("sector", "Sector")), String(job.get("target", "Security"))], HORIZONTAL_ALIGNMENT_LEFT, 600.0, 11, Color("cba7bd"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 92.0), "DIFFICULTY %d  •  REWARD %d CR  •  CARGO +%d" % [int(job.get("difficulty", 1)), int(job.get("reward", 0)), int(job.get("contraband", 1))], HORIZONTAL_ALIGNMENT_LEFT, 590.0, 11, Color("ffbd67"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(565.0, 39.0), "%02ds" % SyndicateState.seconds_left(int(job.get("expires_at", 0))), HORIZONTAL_ALIGNMENT_CENTER, 90.0, 18, Color("ff799b"))

func _draw_crew() -> void:
	crew_rects.clear()
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 678.0), "CREW ROSTER", HORIZONTAL_ALIGNMENT_LEFT, 400.0, 16, Color("ff78b0"))
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var id_value: String = String(member.get("id", ""))
		var column: int = index % 2
		var row: int = int(index / 2)
		var rect: Rect2 = Rect2(22.0 + float(column) * 342.0, 710.0 + float(row) * 180.0, 330.0, 160.0)
		crew_rects[id_value] = rect
		var ready: bool = SyndicateState.crew_available(member)
		var border: Color = Color("fff4fb") if selected_crew.has(id_value) else (Color("b96cff") if ready else Color("65424f"))
		draw_style_box(_panel(Color("170c20"), border, 3 if selected_crew.has(id_value) else 1, 12), rect)
		draw_texture_rect(PORTRAITS[id_value] as Texture2D, Rect2(rect.position + Vector2(10.0, 10.0), Vector2(116.0, 116.0)), false)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 37.0), String(member.get("name", "Crew")), HORIZONTAL_ALIGNMENT_LEFT, 175.0, 14, Color("fff4fb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 66.0), "%s  •  L%d" % [String(member.get("role", "")), int(member.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 175.0, 10, Color("ff8dbd"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 94.0), "PWR %d  HP %d/%d" % [int(member.get("power", 0)), int(member.get("hp", 0)), int(member.get("max_hp", 0))], HORIZONTAL_ALIGNMENT_LEFT, 180.0, 10, Color("caa6bb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(138.0, 124.0), "READY" if ready else "RECOVERING", HORIZONTAL_ALIGNMENT_LEFT, 175.0, 10, Color("72f0c1") if ready else Color("ff7894"))

func _draw_button(rect: Rect2, label: String, active: bool) -> void:
	draw_style_box(_panel(Color("5a2149") if active else Color("311737"), Color("ff8fbc") if active else Color("87508f"), 2 if active else 1, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 44.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 11, Color("fff4fb"))

func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
