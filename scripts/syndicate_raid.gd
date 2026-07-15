extends Node2D
## Portrait tactical raid screen.

const VIEW:=Vector2(720.0,1280.0)
const ENEMY:Texture2D=preload("res://assets/enemies/peacekeeper_response.svg")
const PORTRAITS:={"crew_1":preload("res://assets/portraits/nyx_raze.svg"),"crew_2":preload("res://assets/portraits/vox_13.svg"),"crew_3":preload("res://assets/portraits/cinder_quell.svg"),"crew_4":preload("res://assets/portraits/grit_mercer.svg")}
var crew_units:Array[Dictionary]=[]
var enemy_hp:=1
var enemy_max_hp:=1
var enemy_power:=10
var battle_over:=false
var victory:=false
var auto_mode:=false
var auto_clock:=0.0
var turn:=1
var message:="Crew entering the target zone."
var log:Array[String]=[]
var buttons:={"strike":Rect2(20,1085,160,70),"evade":Rect2(190,1085,160,70),"special":Rect2(360,1085,160,70),"auto":Rect2(530,1085,170,70),"abort":Rect2(20,1170,330,70),"return":Rect2(370,1170,330,70)}
var rng:=RandomNumberGenerator.new()

func _ready()->void:
	rng.randomize()
	if SyndicateState.active_job.is_empty():
		get_tree().call_deferred("change_scene_to_file","res://scenes/SyndicateScores.tscn");return
	for source in SyndicateState.active_crew():
		crew_units.append({"id":String(source.get("id","")),"name":String(source.get("name","Crew")),"role":String(source.get("role","Enforcer")),"level":int(source.get("level",1)),"power":int(source.get("power",50)),"defense":int(source.get("defense",10)),"hp":int(source.get("hp",100)),"max_hp":int(source.get("max_hp",100)),"special_ready":true,"evading":false})
	enemy_max_hp=int(SyndicateState.active_job.get("enemy_hp",120));enemy_hp=enemy_max_hp;enemy_power=int(SyndicateState.active_job.get("enemy_power",14))
	message="CONTACT // %s response team" % SyndicateState.active_job.get("target","Peacekeepers")
	_add_log("Crew entered %s." % SyndicateState.active_job.get("sector","the sector"))
	SyndicateAudio.play_music("combat");SyndicateAudio.play_sfx("warning")

func _process(delta:float)->void:
	if auto_mode and not battle_over:
		auto_clock+=delta
		if auto_clock>=0.8:auto_clock=0.0;_act("strike")
	queue_redraw()

func _input(event:InputEvent)->void:
	var pos:=Vector2.ZERO;var pressed:=false
	if event is InputEventMouseButton:
		var mouse:=event as InputEventMouseButton;pos=mouse.position;pressed=mouse.button_index==MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		var touch:=event as InputEventScreenTouch;pos=touch.position;pressed=touch.pressed
	if not pressed:return
	for action in buttons:
		if (buttons[action] as Rect2).has_point(pos):_button(String(action));return

func _button(action:String)->void:
	if action=="return":
		if battle_over:
			if not SyndicateState.pending_cutscene.is_empty():get_tree().change_scene_to_file("res://scenes/SyndicateCutscene.tscn")
			else:get_tree().change_scene_to_file("res://scenes/SyndicateCity.tscn")
		else:message="Finish or abort the score first.";SyndicateAudio.play_sfx("warning")
		return
	if battle_over:return
	if action=="auto":auto_mode=not auto_mode;message="AUTO RAID ENABLED" if auto_mode else "AUTO RAID DISABLED";SyndicateAudio.play_sfx("click");return
	if action=="abort":_finish(false,"Crew burned the route and escaped empty-handed.");return
	_act(action)

func _act(action:String)->void:
	var total:=0
	match action:
		"strike":
			for unit in crew_units:
				if int(unit.get("hp",0))<=0:continue
				unit["evading"]=false;total+=max(5,int(unit.get("power",50))/7)+rng.randi_range(0,6)
			message="Crew volley dealt %d damage." % total;_add_log("Turn %d: coordinated strike dealt %d." % [turn,total]);SyndicateAudio.play_sfx("hit")
		"evade":
			for unit in crew_units:
				if int(unit.get("hp",0))>0:unit["evading"]=true
			message="Crew scattered into cover.";_add_log("Turn %d: crew entered evade stance." % turn);SyndicateAudio.play_sfx("click")
		"special":
			var used:=0
			for unit in crew_units:
				if int(unit.get("hp",0))<=0 or not bool(unit.get("special_ready",false)):continue
				unit["special_ready"]=false;used+=1
				var role:=String(unit.get("role","Enforcer"))
				if role=="Enforcer":total+=18+int(unit.get("level",1));unit["hp"]=min(int(unit.get("max_hp",100)),int(unit.get("hp",1))+10)
				elif role=="Runner":total+=27+int(unit.get("level",1));unit["evading"]=true
				else:total+=33+int(unit.get("level",1))*2
			if used==0:message="Special abilities are already spent.";SyndicateAudio.play_sfx("warning");return
			message="%d specials landed for %d damage." % [used,total];_add_log("Turn %d: specials dealt %d." % [turn,total]);SyndicateAudio.play_sfx("special")
	if total>0:enemy_hp=max(0,enemy_hp-total)
	if enemy_hp<=0:_finish(true,"Security broken. Cargo secured.");return
	_enemy_turn();turn+=1

func _enemy_turn()->void:
	var living:Array[int]=[]
	for index in range(crew_units.size()):
		if int(crew_units[index].get("hp",0))>0:living.append(index)
	if living.is_empty():_finish(false,"The response team overwhelmed the crew.");return
	var target:=crew_units[living[rng.randi_range(0,living.size()-1)]]
	var mitigation:=int(target.get("defense",0))/4+(12 if bool(target.get("evading",false)) else 0)
	var damage:=max(3,enemy_power+rng.randi_range(0,7)-mitigation)
	target["hp"]=max(0,int(target.get("hp",1))-damage);target["evading"]=false
	_add_log("Security hit %s for %d." % [target.get("name","Crew"),damage]);SyndicateAudio.play_sfx("hit")
	var survivors:=0
	for unit in crew_units:
		if int(unit.get("hp",0))>0:survivors+=1
	if survivors==0:_finish(false,"The response team overwhelmed the crew.")

func _finish(won:bool,text:String)->void:
	if battle_over:return
	battle_over=true;victory=won;auto_mode=false;message=text
	var hp_results:={}
	for unit in crew_units:hp_results[String(unit.get("id",""))]=max(1,int(unit.get("hp",1)))
	SyndicateState.finish_job(won,hp_results);SyndicateAudio.play_sfx("victory" if won else "defeat")

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,VIEW),Color("05020b"))
	for index in range(100):draw_circle(Vector2(fmod(float(index*79+13),VIEW.x),fmod(float(index*53+29),VIEW.y)),1.0,Color("d5b0ff",0.17))
	draw_rect(Rect2(0,0,720,128),Color("170c20"),true)
	draw_string(ThemeDB.fallback_font,Vector2(22,46),String(SyndicateState.active_job.get("title","ACTIVE SCORE")).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,660,23,Color("fff4fb"))
	draw_string(ThemeDB.fallback_font,Vector2(22,82),"%s  •  TURN %d" % [SyndicateState.active_job.get("sector","Sector"),turn],HORIZONTAL_ALIGNMENT_LEFT,660,13,Color("ff8cbd"))
	draw_texture_rect(ENEMY,Rect2(170,150,380,380),false)
	_draw_bar(Rect2(100,530,520,20),enemy_hp,enemy_max_hp,Color("62dfff"))
	draw_string(ThemeDB.fallback_font,Vector2(90,580),message,HORIZONTAL_ALIGNMENT_CENTER,540,15,Color("f2d8e7"))
	for index in range(crew_units.size()):
		var unit:=crew_units[index];var x:=35+index*170.0;var rect:=Rect2(x,640,145,220)
		draw_style_box(_panel(Color("170c20"),Color("ff6fa8") if int(unit.get("hp",0))>0 else Color("65424f"),1,10),rect)
		draw_texture_rect(PORTRAITS[String(unit.get("id","crew_1"))] as Texture2D,Rect2(x+8,648,129,129),false)
		draw_string(ThemeDB.fallback_font,Vector2(x+6,800),String(unit.get("name","Crew")),HORIZONTAL_ALIGNMENT_CENTER,133,11,Color("fff4fb"))
		_draw_bar(Rect2(x+12,824,121,10),int(unit.get("hp",0)),int(unit.get("max_hp",100)),Color("ff5f91"))
		draw_string(ThemeDB.fallback_font,Vector2(x+6,852),"SPECIAL %s" % ("READY" if bool(unit.get("special_ready",false)) else "SPENT"),HORIZONTAL_ALIGNMENT_CENTER,133,8,Color("ffbe68"))
	draw_style_box(_panel(Color("110916"),Color("8d4aa4"),1,10),Rect2(20,886,680,178))
	for index in range(mini(log.size(),6)):draw_string(ThemeDB.fallback_font,Vector2(34,916+index*23),log[index],HORIZONTAL_ALIGNMENT_LEFT,650,10,Color("c8a7bb"))
	_draw_button("strike","STRIKE");_draw_button("evade","EVADE");_draw_button("special","SPECIAL");_draw_button("auto","AUTO ON" if auto_mode else "AUTO");_draw_button("abort","ABORT SCORE");_draw_button("return","CONTINUE" if battle_over else "RETURN")
	if battle_over:
		draw_rect(Rect2(80,465,560,110),Color("173d33",0.94) if victory else Color("4b1728",0.94),true)
		draw_string(ThemeDB.fallback_font,Vector2(90,530),"SCORE SECURED" if victory else "SCORE BURNED",HORIZONTAL_ALIGNMENT_CENTER,540,28,Color("72f0c1") if victory else Color("ff7995"))

func _draw_button(id:String,label:String)->void:
	var rect:=buttons[id] as Rect2;var enabled:=not battle_over or id=="return"
	draw_style_box(_panel(Color("5a2149") if enabled else Color("251422"),Color("ff8fbc") if enabled else Color("644455"),1,9),rect)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(4,43),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-8,10,Color("fff4fb"))

func _draw_bar(rect:Rect2,current:int,maximum:int,color:Color)->void:
	draw_rect(rect,Color("120b13"),true);var ratio:=0.0 if maximum<=0 else clampf(float(current)/maximum,0,1);draw_rect(Rect2(rect.position,Vector2(rect.size.x*ratio,rect.size.y)),color,true);draw_rect(rect,Color("f5d7e7",0.4),false,1)

func _add_log(text:String)->void:log.push_front(text);if log.size()>7:log.resize(7)
func _panel(fill:Color,border:Color,width:int,radius:int)->StyleBoxFlat:var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);return style
