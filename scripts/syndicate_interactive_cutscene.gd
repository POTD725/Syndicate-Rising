extends Node2D
## Interactive origin cutscene plus illustrated campaign interstitials.

const VIEW: Vector2 = Vector2(720.0, 1280.0)
const ART: Dictionary = {
	"prologue": preload("res://assets/cutscenes/syndicate_origin.svg"),
	"ghost_key": preload("res://assets/cutscenes/ghost_key_network.svg"),
	"war_room": preload("res://assets/cutscenes/take_back_dark.svg"),
	"finale": preload("res://assets/cutscenes/take_back_dark.svg")
}
const COPY: Dictionary = {
	"ghost_key": ["THE NETWORK REMEMBERS", "The Ghost Key is yours. Every stolen relay opens another door beneath the Moon, and every door leads closer to the Authority's throat."],
	"war_room": ["THE DISTRICT CHOOSES A SIDE", "The Dawn Convoy burns on Mare Highway. Rival crews stop laughing. Peacekeeper Command finally says your name out loud."],
	"finale": ["CROWN THE CRATER", "Eclipse Signal Tower belongs to the Syndicate. The city above still calls it darkness. Down here, it is a sunrise with sharper teeth."]
}

var key: String = "prologue"
var stage: int = 0
var result_text: String = ""
var continue_button: Rect2 = Rect2(60.0, 1138.0, 600.0, 82.0)
var choice_rects: Dictionary = {
	"rescue": Rect2(48.0, 936.0, 624.0, 82.0),
	"salvage": Rect2(48.0, 1028.0, 624.0, 82.0),
	"codes": Rect2(48.0, 1120.0, 624.0, 82.0)
}

func _ready() -> void:
	key = SyndicateState.pending_cutscene
	if key.is_empty():
		get_tree().call_deferred("change_scene_to_file", "res://scenes/SyndicateCity.tscn")
		return
	SyndicateAudio.play_music("cutscene")
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
	if key != "prologue":
		if continue_button.has_point(pos):
			_finish_cutscene()
		return
	if stage == 0 and continue_button.has_point(pos):
		stage = 1
		SyndicateAudio.play_sfx("accept")
		queue_redraw()
		return
	if stage == 1:
		for choice_value: Variant in choice_rects.keys():
			var choice_id: String = String(choice_value)
			var rect: Rect2 = choice_rects[choice_id] as Rect2
			if rect.has_point(pos):
				var result: Dictionary = SyndicateState.apply_prologue_choice(choice_id)
				result_text = String(result.get("message", "The Syndicate survives."))
				if bool(result.get("ok", false)):
					stage = 2
					SyndicateAudio.play_sfx("special")
				queue_redraw()
				return
	if stage == 2 and continue_button.has_point(pos):
		_finish_cutscene()

func _finish_cutscene() -> void:
	SyndicateState.consume_cutscene()
	SyndicateAudio.play_sfx("accept")
	get_tree().change_scene_to_file("res://scenes/SyndicateCity.tscn")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("03020a"))
	var texture: Texture2D = ART.get(key, ART["prologue"]) as Texture2D
	draw_texture_rect(texture, Rect2(Vector2.ZERO, VIEW), false)
	if key == "prologue":
		_draw_prologue()
	else:
		_draw_story_interstitial()

func _draw_prologue() -> void:
	if stage == 0:
		draw_rect(Rect2(0.0, 848.0, 720.0, 432.0), Color("050811", 0.92), true)
		draw_string(ThemeDB.fallback_font, Vector2(36.0, 904.0), "CRATER MARKET IS FALLING", HORIZONTAL_ALIGNMENT_CENTER, 648.0, 25, Color("fff4e8"))
		_draw_wrapped("The Peacekeeper station fires from orbit while Patrol Deputies sweep the ruins below. Nyx, Vox-13, Cinder, and Grit reach the buried command tunnel. There is time for one order before the crater locks down.", Vector2(52.0, 958.0), 616.0, 15, Color("d7c6d2"))
		_draw_button(continue_button, "GIVE THE FIRST ORDER", Color("5c214b"), Color("ff8fbc"), 14)
	elif stage == 1:
		draw_rect(Rect2(0.0, 856.0, 720.0, 424.0), Color("050811", 0.96), true)
		draw_string(ThemeDB.fallback_font, Vector2(36.0, 902.0), "HOW DID THE SYNDICATE BEGIN?", HORIZONTAL_ALIGNMENT_CENTER, 648.0, 23, Color("fff4e8"))
		_draw_choice("rescue", "RESCUE THE SURVIVORS", "Clinic repaired • Crew Trust +3 • More Heat", Color("24566b"))
		_draw_choice("salvage", "STRIP THE AUTHORITY WRECKAGE", "+18 Alloy • +12 Helium-3 • +140 Credits", Color("57472a"))
		_draw_choice("codes", "STEAL THE STATION ACCESS CODES", "+6 Data Cores • +9 Intel • Black Tech +1 • High Heat", Color("563267"))
	else:
		draw_rect(Rect2(0.0, 850.0, 720.0, 430.0), Color("050811", 0.95), true)
		draw_string(ThemeDB.fallback_font, Vector2(36.0, 908.0), "THE FIRST ORDER", HORIZONTAL_ALIGNMENT_CENTER, 648.0, 25, Color("fff1b8"))
		_draw_wrapped(result_text, Vector2(54.0, 968.0), 612.0, 15, Color("d8e7ee"))
		draw_string(ThemeDB.fallback_font, Vector2(44.0, 1085.0), "Crew Trust %d   •   Heat %d   •   Alloy %d   •   He-3 %d   •   Data Cores %d" % [SyndicateState.crew_trust, SyndicateState.heat, SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.data_cores], HORIZONTAL_ALIGNMENT_CENTER, 632.0, 11, Color("72ead7"))
		_draw_button(continue_button, "ENTER THE LUNAR HIDEOUT", Color("284d42"), Color("78efd8"), 14)

func _draw_choice(choice_id: String, title: String, subtitle: String, fill: Color) -> void:
	var rect: Rect2 = choice_rects[choice_id] as Rect2
	draw_style_box(_panel(fill, Color("77dfe8"), 2, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 34.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36.0, 14, Color("f8fbff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 61.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36.0, 10, Color("b9c9d5"))

func _draw_story_interstitial() -> void:
	draw_rect(Rect2(0.0, 860.0, 720.0, 420.0), Color("05030a", 0.90), true)
	var copy_value: Variant = COPY.get(key, COPY["ghost_key"])
	var copy: Array = copy_value as Array
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 918.0), String(copy[0]), HORIZONTAL_ALIGNMENT_CENTER, 648.0, 26, Color("fff4fb"))
	_draw_wrapped(String(copy[1]), Vector2(52.0, 976.0), 616.0, 15, Color("d9bdd0"))
	_draw_button(continue_button, "CONTINUE INTO THE DISTRICT", Color("5c214b"), Color("ff8fbc"), 14)

func _draw_button(rect: Rect2, label: String, fill: Color, border: Color, font_size: int) -> void:
	draw_style_box(_panel(fill, border, 2, 12), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 52.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, font_size, Color("fff4fb"))

func _draw_wrapped(text: String, origin: Vector2, width: float, font_size: int, color: Color) -> void:
	var words: PackedStringArray = text.split(" ")
	var line: String = ""
	var y: float = origin.y
	for word: String in words:
		var candidate: String = word if line.is_empty() else line + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > width and not line.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
			line = word
			y += float(font_size + 9)
		else:
			line = candidate
	if not line.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
