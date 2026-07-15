extends Node2D
## Interactive Take Back attack cinematics using shared original Peacekeeper skins.

const VIEW: Vector2 = Vector2(720.0, 1280.0)
const THREAT_ART: Texture2D = preload("res://assets/threats/take_back_response.svg")

var threat_type: String = "patrol"
var threat: Dictionary = {}
var resolved: bool = false
var result_text: String = ""
var elapsed: float = 0.0
var button_rects: Dictionary = {
	"fight": Rect2(34.0, 1018.0, 206.0, 74.0),
	"hide": Rect2(257.0, 1018.0, 206.0, 74.0),
	"counter_hack": Rect2(480.0, 1018.0, 206.0, 74.0),
	"continue": Rect2(60.0, 1122.0, 600.0, 82.0)
}

func _ready() -> void:
	threat = SyndicateState.active_threat
	threat_type = SyndicateState.pending_attack_cutscene
	if threat_type.is_empty() and not threat.is_empty():
		threat_type = String(threat.get("type", "patrol"))
	if threat.is_empty():
		get_tree().call_deferred("change_scene_to_file", "res://scenes/SyndicateOperations.tscn")
		return
	SyndicateAudio.play_music("raid")
	SyndicateAudio.play_sfx("warning")
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if not resolved:
		SyndicateState.tick()
		if SyndicateState.active_threat.is_empty():
			resolved = true
			result_text = SyndicateState.last_event
			SyndicateState.consume_attack_cutscene()
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
	if resolved:
		if (button_rects["continue"] as Rect2).has_point(pos):
			get_tree().change_scene_to_file("res://scenes/SyndicateOperations.tscn")
		return
	for action: String in ["fight", "hide", "counter_hack"]:
		if (button_rects[action] as Rect2).has_point(pos):
			var response: Dictionary = SyndicateState.respond_to_threat(action)
			resolved = true
			result_text = String(response.get("message", SyndicateState.last_event))
			SyndicateState.consume_attack_cutscene()
			SyndicateAudio.play_sfx("special" if bool(response.get("ok", false)) else "warning")
			queue_redraw()
			return

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), _background_color())
	_draw_scanlines()
	_draw_attack_art()
	draw_rect(Rect2(0.0, 720.0, 720.0, 560.0), Color("050911", 0.95), true)
	var title: String = String(threat.get("title", "TAKE BACK ATTACK")).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 776.0), title, HORIZONTAL_ALIGNMENT_CENTER, 652.0, 26, _accent_color())
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 814.0), String(threat.get("unit", "Peacekeeper Response")), HORIZONTAL_ALIGNMENT_CENTER, 652.0, 13, Color("c7dcea"))
	_draw_wrapped(String(threat.get("description", "Peacekeepers are closing on the hideout.")), Vector2(52.0, 856.0), 616.0, 15, Color("d9e3ea"))
	if not resolved:
		var remaining: int = maxi(0, int(threat.get("expires_at", 0)) - int(Time.get_unix_time_from_system()))
		draw_string(ThemeDB.fallback_font, Vector2(38.0, 960.0), "THREAT POWER %d   •   RESPONSE WINDOW %ds   •   CAPTURED CREW %d" % [int(threat.get("power", 1)), remaining, SyndicateState.captured_crew_ids.size()], HORIZONTAL_ALIGNMENT_CENTER, 644.0, 11, Color("ffbd78"))
		_draw_response_button("fight", "FIGHT", _fight_hint(), Color("653345"))
		_draw_response_button("hide", "HIDE", _hide_hint(), Color("254f58"))
		_draw_response_button("counter_hack", "COUNTER-HACK", "Costs 1 Data Core", Color("47365f"))
	else:
		draw_style_box(_panel(Color("101c29"), _accent_color(), 2, 12), Rect2(40.0, 946.0, 640.0, 142.0))
		_draw_wrapped(result_text, Vector2(62.0, 982.0), 596.0, 14, Color("eef7fb"))
		_draw_button(button_rects["continue"] as Rect2, "RETURN TO OPERATIONS", Color("284d42"), Color("75ecd5"), 14)

func _draw_attack_art() -> void:
	var source: Rect2
	match threat_type:
		"survey": source = Rect2(0.0, 0.0, 300.0, 420.0)
		"patrol": source = Rect2(300.0, 0.0, 300.0, 420.0)
		"riot": source = Rect2(600.0, 0.0, 300.0, 420.0)
		_: source = Rect2(0.0, 0.0, 900.0, 420.0)
	var art_rect: Rect2 = Rect2(60.0, 112.0, 600.0, 560.0)
	draw_texture_rect_region(THREAT_ART, art_rect, source)
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), _accent_color(), 4, 18), art_rect)
	if threat_type == "cyber":
		for index: int in range(18):
			var y: float = 135.0 + fmod(float(index * 47) + elapsed * 44.0, 500.0)
			draw_rect(Rect2(75.0, y, 570.0, 4.0), Color(1.0, 0.2, 0.45, 0.15 + float(index % 3) * 0.08), true)
		for node_index: int in range(8):
			var x: float = 120.0 + float(node_index % 4) * 150.0
			var y: float = 225.0 + float(node_index / 4) * 210.0
			draw_circle(Vector2(x, y), 18.0, Color("ff5d83", 0.75))
			draw_line(Vector2(x, y), Vector2(360.0, 390.0), Color("73e8ff", 0.35), 3.0)

func _draw_scanlines() -> void:
	for index: int in range(40):
		var y: float = float(index) * 32.0 + fmod(elapsed * 20.0, 32.0)
		draw_line(Vector2(0.0, y), Vector2(720.0, y), Color(0.35, 0.78, 1.0, 0.035), 1.0)

func _response_strength(action: String) -> int:
	match action:
		"fight": return int(SyndicateState.defenses.get("sentry", 0)) * 3 + int(SyndicateState.defenses.get("blast_doors", 0)) * 2
		"hide": return int(SyndicateState.defenses.get("jammer", 0)) * 2 + int(SyndicateState.defenses.get("escape_tunnels", 0)) * 3
		_: return int(SyndicateState.defenses.get("jammer", 0)) * 3 + SyndicateState.black_tech_level

func _fight_hint() -> String:
	return "Defense base %d" % _response_strength("fight")

func _hide_hint() -> String:
	return "Stealth base %d" % _response_strength("hide")

func _draw_response_button(action: String, title: String, subtitle: String, fill: Color) -> void:
	var rect: Rect2 = button_rects[action] as Rect2
	draw_style_box(_panel(fill, _accent_color(), 2, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 31.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 12, Color("f7fbff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 56.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 8, Color("b9cbd7"))

func _background_color() -> Color:
	match threat_type:
		"cyber": return Color("150716")
		"riot": return Color("190b0b")
		"survey": return Color("04101a")
		_: return Color("07101a")

func _accent_color() -> Color:
	match threat_type:
		"cyber": return Color("ff668e")
		"riot": return Color("ff9a59")
		"survey": return Color("69e9ff")
		_: return Color("9bd8f1")

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
