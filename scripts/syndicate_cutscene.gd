extends Node2D
## Illustrated story interstitials.

const VIEW := Vector2(720.0,1280.0)
const ART := {
	"prologue": preload("res://assets/cutscenes/crater_market_falls.svg"),
	"ghost_key": preload("res://assets/cutscenes/ghost_key_network.svg"),
	"war_room": preload("res://assets/cutscenes/take_back_dark.svg"),
	"finale": preload("res://assets/cutscenes/take_back_dark.svg")
}
const COPY := {
	"prologue": ["THE NIGHT AFTER THE RAID","Peacekeepers shattered the old network and left Crater Market bleeding neon. Backroom Command survived beneath the rubble. Nyx Raze calls the scattered crews home."],
	"ghost_key": ["THE NETWORK REMEMBERS","The Ghost Key is yours. Every stolen relay opens another door beneath the Moon, and every door leads closer to the Authority's throat."],
	"war_room": ["THE DISTRICT CHOOSES A SIDE","The Dawn Convoy burns on Mare Highway. Rival crews stop laughing. Peacekeeper Command finally says your name out loud."],
	"finale": ["CROWN THE CRATER","Eclipse Signal Tower belongs to the Syndicate. The city above still calls it darkness. Down here, it is a sunrise with sharper teeth."]
}
var key := "prologue"
var button := Rect2(60,1130,600,86)

func _ready()->void:
	key = SyndicateState.pending_cutscene
	if key.is_empty():
		get_tree().call_deferred("change_scene_to_file","res://scenes/SyndicateCity.tscn")
		return
	SyndicateAudio.play_music("cutscene")
	queue_redraw()

func _input(event:InputEvent)->void:
	var pos:=Vector2.ZERO;var pressed:=false
	if event is InputEventMouseButton:
		var mouse:=event as InputEventMouseButton;pos=mouse.position;pressed=mouse.button_index==MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		var touch:=event as InputEventScreenTouch;pos=touch.position;pressed=touch.pressed
	if pressed and button.has_point(pos):
		SyndicateState.consume_cutscene()
		SyndicateAudio.play_sfx("accept")
		get_tree().change_scene_to_file("res://scenes/SyndicateCity.tscn")

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,VIEW),Color("03020a"))
	draw_texture_rect(ART.get(key,ART["prologue"]) as Texture2D,Rect2(Vector2.ZERO,VIEW),false)
	draw_rect(Rect2(0,860,720,420),Color("05030a",0.90),true)
	var copy:Array=COPY.get(key,COPY["prologue"])
	draw_string(ThemeDB.fallback_font,Vector2(36,918),String(copy[0]),HORIZONTAL_ALIGNMENT_CENTER,648,26,Color("fff4fb"))
	_draw_wrapped(String(copy[1]),Vector2(52,976),616,15,Color("d9bdd0"))
	draw_style_box(_panel(Color("5c214b"),Color("ff8fbc"),2,12),button)
	draw_string(ThemeDB.fallback_font,button.position+Vector2(8,54),"CONTINUE INTO THE DISTRICT",HORIZONTAL_ALIGNMENT_CENTER,button.size.x-16,14,Color("fff4fb"))

func _draw_wrapped(text:String,origin:Vector2,width:float,font_size:int,color:Color)->void:
	var words:=text.split(" ");var line:="";var y:=origin.y
	for word in words:
		var candidate:=String(word) if line.is_empty() else line+" "+String(word)
		if ThemeDB.fallback_font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width and not line.is_empty():
			draw_string(ThemeDB.fallback_font,Vector2(origin.x,y),line,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,color);line=String(word);y+=font_size+9
		else: line=candidate
	if not line.is_empty(): draw_string(ThemeDB.fallback_font,Vector2(origin.x,y),line,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,color)

func _panel(fill:Color,border:Color,width:int,radius:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius);return style
