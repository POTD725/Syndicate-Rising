extends Node2D
## Criminal score board and crew-selection screen.

const VIEW := Vector2(720.0, 1280.0)
const PORTRAITS := {
	"crew_1": preload("res://assets/portraits/nyx_raze.svg"),
	"crew_2": preload("res://assets/portraits/vox_13.svg"),
	"crew_3": preload("res://assets/portraits/cinder_quell.svg"),
	"crew_4": preload("res://assets/portraits/grit_mercer.svg")
}
var job_rects: Dictionary = {}
var crew_rects: Dictionary = {}
var buttons := {"run":Rect2(372,1168,330,76),"back":Rect2(18,1168,330,76)}
var selected_job := ""
var selected_crew: Array[String] = []
var message := "Select a score and assemble a crew."
var clock := 0.0

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
	var pos := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		pos = mouse.position
		pressed = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		pos = touch.position
		pressed = touch.pressed
	if not pressed:
		return
	for id in job_rects:
		if (job_rects[id] as Rect2).has_point(pos):
			selected_job = String(id)
			SyndicateAudio.play_sfx("click")
			return
	for id in crew_rects:
		if (crew_rects[id] as Rect2).has_point(pos):
			_toggle_crew(String(id))
			return
	if buttons["back"].has_point(pos):
		get_tree().change_scene_to_file("res://scenes/SyndicateCity.tscn")
	elif buttons["run"].has_point(pos):
		var result := SyndicateState.begin_job(selected_job, selected_crew)
		message = String(result.get("message", "Unable to launch score."))
		if bool(result.get("ok", false)):
			SyndicateAudio.play_sfx("accept")
			get_tree().change_scene_to_file("res://scenes/SyndicateRaid.tscn")
		else:
			SyndicateAudio.play_sfx("warning")

func _toggle_crew(id: String) -> void:
	var member := SyndicateState.get_crew_member(id)
	if member.is_empty() or not SyndicateState.crew_available(member):
		message = "%s is unavailable." % member.get("name", "Crew")
		SyndicateAudio.play_sfx("warning")
		return
	if selected_crew.has(id):
		selected_crew.erase(id)
	else:
		var limit := 3
		if SyndicateState.is_room_repaired("boss_office"):
			limit = mini(4, 2 + SyndicateState.get_room_level("boss_office"))
		if selected_crew.size() >= limit:
			message = "Current crew capacity is %d." % limit
			SyndicateAudio.play_sfx("warning")
			return
		selected_crew.append(id)
	SyndicateAudio.play_sfx("click")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("07030d"))
	for index in range(100):
		draw_circle(Vector2(fmod(float(index*83+17),VIEW.x),fmod(float(index*47+31),VIEW.y)),1.0,Color("d6b1ff",0.16))
	draw_rect(Rect2(0,0,720,126),Color("170c20"),true)
	draw_string(ThemeDB.fallback_font,Vector2(24,48),"SYNDICATE SCORE BOARD",HORIZONTAL_ALIGNMENT_LEFT,600,26,Color("fff4fb"))
	draw_string(ThemeDB.fallback_font,Vector2(24,82),"CHAPTER %d  •  HEAT %d  •  NOTORIETY %d" % [SyndicateState.story_chapter,SyndicateState.heat,SyndicateState.notoriety],HORIZONTAL_ALIGNMENT_LEFT,620,13,Color("ff8cbd"))
	_draw_jobs()
	_draw_crew()
	draw_string(ThemeDB.fallback_font,Vector2(28,1138),message,HORIZONTAL_ALIGNMENT_LEFT,660,11,Color("dfbdd1"))
	_draw_button(buttons["back"],"RETURN TO DISTRICT",false)
	_draw_button(buttons["run"],"RUN SELECTED SCORE",not selected_job.is_empty() and not selected_crew.is_empty())

func _draw_jobs() -> void:
	job_rects.clear()
	draw_string(ThemeDB.fallback_font,Vector2(24,160),"AVAILABLE SCORES",HORIZONTAL_ALIGNMENT_LEFT,400,16,Color("ff78b0"))
	if SyndicateState.jobs.is_empty():
		draw_string(ThemeDB.fallback_font,Vector2(24,205),"Fixers are scanning. Next window in %ds." % SyndicateState.seconds_left(SyndicateState.next_job_at),HORIZONTAL_ALIGNMENT_LEFT,650,12,Color("a8899e"))
	for index in range(SyndicateState.jobs.size()):
		var job := SyndicateState.jobs[index]
		var id := String(job.get("id",""))
		var rect := Rect2(22,188+index*158,676,142)
		job_rects[id]=rect
		var story := bool(job.get("story",false))
		var border := Color("fff4fb") if id==selected_job else (Color("ffbe68") if story else Color("b96cff"))
		draw_style_box(_panel(Color("180d21"),border,3 if id==selected_job else 1,12),rect)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(16,30),("STORY // " if story else "")+String(job.get("title","SCORE")).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,510,16,Color("fff4fb"))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(16,61),"%s  •  TARGET %s" % [job.get("sector","Sector"),job.get("target","Security")],HORIZONTAL_ALIGNMENT_LEFT,600,11,Color("cba7bd"))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(16,92),"DIFFICULTY %d  •  REWARD %d CR  •  CARGO +%d" % [job.get("difficulty",1),job.get("reward",0),job.get("contraband",1)],HORIZONTAL_ALIGNMENT_LEFT,590,11,Color("ffbd67"))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(565,39),"%02ds" % SyndicateState.seconds_left(int(job.get("expires_at",0))),HORIZONTAL_ALIGNMENT_CENTER,90,18,Color("ff799b"))

func _draw_crew() -> void:
	crew_rects.clear()
	draw_string(ThemeDB.fallback_font,Vector2(24,678),"CREW ROSTER",HORIZONTAL_ALIGNMENT_LEFT,400,16,Color("ff78b0"))
	for index in range(SyndicateState.crew.size()):
		var member := SyndicateState.crew[index]
		var id := String(member.get("id",""))
		var column := index%2
		var row := index/2
		var rect := Rect2(22+column*342,710+row*180,330,160)
		crew_rects[id]=rect
		var ready := SyndicateState.crew_available(member)
		var border := Color("fff4fb") if selected_crew.has(id) else (Color("b96cff") if ready else Color("65424f"))
		draw_style_box(_panel(Color("170c20"),border,3 if selected_crew.has(id) else 1,12),rect)
		draw_texture_rect(PORTRAITS[id] as Texture2D,Rect2(rect.position+Vector2(10,10),Vector2(116,116)),false)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(138,37),String(member.get("name","Crew")),HORIZONTAL_ALIGNMENT_LEFT,175,14,Color("fff4fb"))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(138,66),"%s  •  L%d" % [member.get("role",""),member.get("level",1)],HORIZONTAL_ALIGNMENT_LEFT,175,10,Color("ff8dbd"))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(138,94),"PWR %d  HP %d/%d" % [member.get("power",0),member.get("hp",0),member.get("max_hp",0)],HORIZONTAL_ALIGNMENT_LEFT,180,10,Color("caa6bb"))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(138,124),"READY" if ready else "RECOVERING",HORIZONTAL_ALIGNMENT_LEFT,175,10,Color("72f0c1") if ready else Color("ff7894"))

func _draw_button(rect:Rect2,label:String,active:bool)->void:
	draw_style_box(_panel(Color("5a2149") if active else Color("311737"),Color("ff8fbc") if active else Color("87508f"),2 if active else 1,10),rect)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(4,44),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-8,11,Color("fff4fb"))

func _panel(fill:Color,border:Color,width:int,radius:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);return style
