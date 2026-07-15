extends "res://scripts/syndicate_feature_city.gd"
## Isometric lunar base presentation with interactive building hotspots and DermaPack navigation.

const ISO_ART: Script = preload("res://scripts/syndicate_isometric_assets.gd")
const BOARD_RECT: Rect2 = Rect2(-360.0, -500.0, 720.0, 1002.0)

var skin_atlas: Texture2D
var board_texture: Texture2D
var dermapack_texture: Texture2D
var panel_mode: String = "room"

func _ready() -> void:
	super._ready()
	skin_atlas = SyndicateSkins.atlas()
	board_texture = ISO_ART.board_texture()
	dermapack_texture = ISO_ART.dermapack_texture()
	_setup_isometric_hotspots()
	_setup_mobile_navigation()
	button_rects["skin"] = Rect2(329.0, 104.0, 96.0, 38.0)
	button_rects["operations"] = Rect2(626.0, 674.0, 82.0, 74.0)
	button_rects["save"] = Rect2(626.0, 754.0, 82.0, 74.0)
	if not SyndicateSkins.skin_changed.is_connected(_on_skin_changed):
		SyndicateSkins.skin_changed.connect(_on_skin_changed)
	message = "Tap an isometric building, drag to pan, or open the DermaPack."

func _setup_isometric_hotspots() -> void:
	# Hotspots follow the rendered three-quarter buildings in the embedded board artwork.
	room_rects = {
		"backroom": Rect2(-265.0, -365.0, 174.0, 188.0),
		"boss_office": Rect2(-248.0, -420.0, 142.0, 92.0),
		"black_research": Rect2(-96.0, -348.0, 190.0, 190.0),
		"weapons_workshop": Rect2(96.0, -304.0, 192.0, 184.0),
		"signal_den": Rect2(-356.0, -188.0, 248.0, 222.0),
		"clinic": Rect2(-116.0, -154.0, 230.0, 202.0),
		"chop_shop": Rect2(104.0, -112.0, 250.0, 226.0),
		"tunnel": Rect2(-356.0, -10.0, 250.0, 232.0),
		"black_market": Rect2(-150.0, -4.0, 266.0, 246.0),
		"sharpshooter_range": Rect2(105.0, 52.0, 250.0, 238.0),
		"enforcer_gym": Rect2(-164.0, 172.0, 298.0, 250.0),
		"bunks": Rect2(146.0, 300.0, 205.0, 142.0)
	}

func _setup_mobile_navigation() -> void:
	button_rects.erase("research")
	button_rects.erase("market")
	button_rects["scores"] = Rect2(4.0, 1166.0, 114.0, 108.0)
	button_rects["heroes"] = Rect2(122.0, 1166.0, 114.0, 108.0)
	button_rects["dermapack"] = Rect2(240.0, 1166.0, 122.0, 108.0)
	button_rects["store"] = Rect2(366.0, 1166.0, 110.0, 108.0)
	button_rects["chat"] = Rect2(480.0, 1166.0, 110.0, 108.0)
	button_rects["hideout"] = Rect2(594.0, 1166.0, 122.0, 108.0)

func _on_skin_changed(_index: int) -> void:
	skin_atlas = SyndicateSkins.atlas()
	message = "Interface changed to %s. The isometric board remains the canonical city art." % SyndicateSkins.skin_name()
	queue_redraw()

func _action(action: String) -> void:
	match action:
		"skin":
			SyndicateSkins.cycle_skin()
			SyndicateAudio.play_sfx("click")
			return
		"heroes":
			panel_mode = "heroes"
			message = "Crew roster opened. Captured and injured MoonGoons are marked here."
			SyndicateAudio.play_sfx("click")
			return
		"dermapack":
			panel_mode = "dermapack"
			message = "DermaPack opened: wearable micro-storage inventory online."
			SyndicateAudio.play_sfx("click")
			return
		"store":
			panel_mode = "room"
			selected_room = "black_market"
			message = "Black Market selected."
			SyndicateAudio.play_sfx("click")
			return
		"hideout":
			panel_mode = "room"
			selected_room = "backroom"
			target_camera_offset = Vector2.ZERO
			message = "Syndicate State view recentered."
			SyndicateAudio.play_sfx("click")
			return
		_:
			panel_mode = "room"
			super._action(action)

func _select_room_at(world_pos: Vector2) -> void:
	for room_id: String in ROOM_IDS:
		var rect: Rect2 = room_rects.get(room_id, Rect2()) as Rect2
		if rect.has_point(world_pos):
			selected_room = room_id
			panel_mode = "room"
			var room: Dictionary = SyndicateState.get_room(selected_room)
			message = "%s selected." % String(room.get("name", "Room"))
			SyndicateAudio.play_sfx("click")
			return

func _draw_world() -> void:
	# The exact generated isometric lunar board is the world layer. It is kept inside
	# the camera transform so drag, zoom, recenter, and quarter-turn rotation still work.
	draw_rect(Rect2(-900.0, -720.0, 1800.0, 1500.0), Color("03060d"), true)
	draw_texture_rect(board_texture, BOARD_RECT, false)
	var tint: Color = SyndicateSkins.accent()
	tint.a = 0.025
	draw_rect(BOARD_RECT, tint, true)
	_draw_room_states()
	_draw_crew_activity()
	_draw_ambient_effects()

func _draw_room_states() -> void:
	for room_id: String in ROOM_IDS:
		var room: Dictionary = SyndicateState.get_room(room_id)
		if room.is_empty():
			continue
		var rect: Rect2 = room_rects.get(room_id, Rect2()) as Rect2
		var repaired: bool = bool(room.get("repaired", false))
		var selected: bool = room_id == selected_room and panel_mode == "room"
		if not repaired:
			draw_rect(rect, Color(0.12, 0.015, 0.025, 0.54), true)
			for slash: int in range(4):
				var sx: float = rect.position.x + 18.0 + float(slash) * rect.size.x / 4.4
				draw_line(Vector2(sx, rect.position.y + 8.0), Vector2(sx + 42.0, rect.end.y - 8.0), SyndicateSkins.danger(), 3.0)
		var border: Color = SyndicateSkins.secondary() if selected else (Color(0.25, 0.93, 0.72, 0.42) if repaired else SyndicateSkins.danger())
		draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), border, 5 if selected else 2, 12), rect)
		if selected:
			var tag: Rect2 = Rect2(rect.position + Vector2(8.0, 8.0), Vector2(minf(150.0, rect.size.x - 16.0), 28.0))
			draw_style_box(_panel(Color(0.02, 0.04, 0.07, 0.94), border, 2, 8), tag)
			draw_string(ThemeDB.fallback_font, tag.position + Vector2(6.0, 19.0), "SELECTED • L%d" % int(room.get("level", 1)), HORIZONTAL_ALIGNMENT_CENTER, tag.size.x - 12.0, 9, SyndicateSkins.text())

func _draw_crew_activity() -> void:
	# The board already contains a lively population. These moving markers make active
	# crew state readable without covering the original workers and vehicles.
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var phase: float = fmod(elapsed * (0.08 + float(index) * 0.012) + float(index) * 0.22, 1.0)
		var x: float = -255.0 + phase * 520.0
		var y: float = 92.0 + sin(phase * TAU + float(index)) * 82.0
		var item_id: String = SyndicateSkins.crew_item(String(member.get("role", "Enforcer")))
		draw_texture_rect_region(skin_atlas, Rect2(Vector2(x - 13.0, y - 13.0), Vector2(26.0, 26.0)), SyndicateSkins.region(item_id))
		draw_circle(Vector2(x, y + 15.0), 3.0, SyndicateSkins.accent() if SyndicateState.crew_available(member) else SyndicateSkins.danger())

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 96.0), SyndicateSkins.dark(), true)
	draw_line(Vector2(0.0, 96.0), Vector2(VIEW.x, 96.0), SyndicateSkins.accent(), 2.0)
	draw_texture_rect(EMBLEM, Rect2(10.0, 10.0, 70.0, 70.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 31.0), "MOONGOONS: SYNDICATE RISING", HORIZONTAL_ALIGNMENT_LEFT, 420.0, 19, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 54.0), "CR %d  ALLOY %d  HE-3 %d  DATA %d" % [SyndicateState.credits, SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.data_cores], HORIZONTAL_ALIGNMENT_LEFT, 510.0, 9, SyndicateSkins.accent())
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 77.0), "HEAT %d  TRUST %d  CAPTURED %d  TECH L%d" % [SyndicateState.heat, SyndicateState.crew_trust, SyndicateState.captured_crew_ids.size(), SyndicateState.black_tech_level], HORIZONTAL_ALIGNMENT_LEFT, 510.0, 9, SyndicateSkins.secondary())
	_draw_button(button_rects["sound"] as Rect2, "MUTE" if not SyndicateAudio.muted else "AUDIO", false, 8)
	_draw_button(button_rects["load"] as Rect2, "LOAD", false, 8)

func _draw_camera_controls() -> void:
	var bar: Color = SyndicateSkins.panel()
	bar.a = 0.97
	draw_rect(Rect2(0.0, 96.0, VIEW.x, 52.0), bar, true)
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 119.0), "DRAG TO PAN • VIEW %d° • %d%%" % [rotation_quadrant * 90, int(round(camera_zoom * 100.0))], HORIZONTAL_ALIGNMENT_LEFT, 305.0, 9, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 138.0), "ISOMETRIC CITY • THREAT: %s" % _threat_label(), HORIZONTAL_ALIGNMENT_LEFT, 400.0, 8, SyndicateSkins.secondary())
	_draw_button(button_rects["skin"] as Rect2, "SKIN", true, 8)
	_draw_button(button_rects["zoom_out"] as Rect2, "−", false, 16)
	_draw_button(button_rects["zoom_in"] as Rect2, "+", false, 16)
	_draw_button(button_rects["rotate"] as Rect2, "ROTATE", true, 8)
	_draw_button(button_rects["center"] as Rect2, "CENTER", false, 8)
	_draw_side_quick_button(button_rects["operations"] as Rect2, "OPERATIONS", "JOBS")
	_draw_side_quick_button(button_rects["save"] as Rect2, "SAVE", "PROFILE")

func _draw_side_quick_button(rect: Rect2, title: String, subtitle: String) -> void:
	draw_style_box(SyndicateSkins.style_box(false, 10, 0.94), rect)
	var item_id: String = "operations" if title == "OPERATIONS" else "save"
	draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(23.0, 7.0), Vector2(36.0, 36.0)), SyndicateSkins.region(item_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, 56.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, 8, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, 68.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, 7, SyndicateSkins.accent())

func _draw_inspector() -> void:
	match panel_mode:
		"heroes": _draw_heroes_panel()
		"dermapack": _draw_dermapack_panel()
		_: _draw_room_panel()

func _draw_room_panel() -> void:
	super._draw_inspector()
	var room: Dictionary = SyndicateState.get_room(selected_room)
	if not room.is_empty():
		draw_texture_rect_region(skin_atlas, Rect2(388.0, 995.0, 66.0, 66.0), SyndicateSkins.region(SyndicateSkins.room_item(selected_room)))

func _draw_heroes_panel() -> void:
	draw_rect(Rect2(0.0, 970.0, VIEW.x, 190.0), Color(0.02, 0.035, 0.06, 0.995), true)
	draw_style_box(_panel(SyndicateSkins.panel(), SyndicateSkins.accent(), 2, 12), Rect2(18.0, 982.0, 684.0, 166.0))
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1011.0), "MOONGOON HEROES", HORIZONTAL_ALIGNMENT_LEFT, 260.0, 18, SyndicateSkins.text())
	for index: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[index]
		var x: float = 34.0 + float(index) * 164.0
		var portrait: Texture2D = PORTRAITS[String(member.get("id", "crew_1"))] as Texture2D
		draw_texture_rect(portrait, Rect2(x, 1023.0, 54.0, 54.0), false)
		draw_string(ThemeDB.fallback_font, Vector2(x + 59.0, 1043.0), String(member.get("name", "Crew")), HORIZONTAL_ALIGNMENT_LEFT, 96.0, 9, SyndicateSkins.text())
		draw_string(ThemeDB.fallback_font, Vector2(x + 59.0, 1062.0), "%s • PWR %d" % [String(member.get("role", "Crew")), int(member.get("power", 0))], HORIZONTAL_ALIGNMENT_LEFT, 96.0, 7, SyndicateSkins.accent())
		var status: String = "CAPTURED" if SyndicateState.captured_crew_ids.has(String(member.get("id", ""))) else ("READY" if SyndicateState.crew_available(member) else "BUSY")
		draw_string(ThemeDB.fallback_font, Vector2(x, 1100.0), status, HORIZONTAL_ALIGNMENT_CENTER, 150.0, 8, SyndicateSkins.danger() if status == "CAPTURED" else SyndicateSkins.secondary())
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1130.0), message, HORIZONTAL_ALIGNMENT_LEFT, 650.0, 9, Color("bac9d8"))

func _draw_dermapack_panel() -> void:
	draw_rect(Rect2(0.0, 970.0, VIEW.x, 190.0), Color(0.02, 0.035, 0.06, 0.995), true)
	draw_style_box(_panel(SyndicateSkins.panel(), SyndicateSkins.secondary(), 3, 14), Rect2(18.0, 982.0, 684.0, 166.0))
	draw_texture_rect(dermapack_texture, Rect2(34.0, 996.0, 118.0, 118.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(168.0, 1014.0), "DERMAPACK", HORIZONTAL_ALIGNMENT_LEFT, 240.0, 21, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(168.0, 1037.0), "Wearable Micro Storage System", HORIZONTAL_ALIGNMENT_LEFT, 330.0, 10, SyndicateSkins.accent())
	draw_string(ThemeDB.fallback_font, Vector2(168.0, 1064.0), "Contraband %d   Intel %d   Data Cores %d" % [SyndicateState.contraband, SyndicateState.intel, SyndicateState.data_cores], HORIZONTAL_ALIGNMENT_LEFT, 460.0, 10, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, Vector2(168.0, 1087.0), "Lunar Alloy %d   Helium-3 %d   Black Tech L%d" % [SyndicateState.lunar_alloy, SyndicateState.helium3, SyndicateState.black_tech_level], HORIZONTAL_ALIGNMENT_LEFT, 460.0, 10, SyndicateSkins.secondary())
	draw_string(ThemeDB.fallback_font, Vector2(168.0, 1112.0), "Encrypted dermal link • biometric lock • rapid mission loadout", HORIZONTAL_ALIGNMENT_LEFT, 500.0, 9, Color("bdcad8"))
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1136.0), message, HORIZONTAL_ALIGNMENT_LEFT, 650.0, 9, Color("bac9d8"))

func _draw_navigation() -> void:
	draw_rect(Rect2(0.0, 1160.0, VIEW.x, 120.0), SyndicateSkins.dark(), true)
	_draw_mobile_nav(button_rects["scores"] as Rect2, "PATROL", "MISSIONS", "score", false)
	_draw_mobile_nav(button_rects["heroes"] as Rect2, "HEROES", "CREW", "hero", panel_mode == "heroes")
	_draw_dermapack_nav(button_rects["dermapack"] as Rect2)
	_draw_mobile_nav(button_rects["store"] as Rect2, "STORE", "MARKET", "shop", selected_room == "black_market" and panel_mode == "room")
	_draw_mobile_nav(button_rects["chat"] as Rect2, "ALLIANCE", "CHAT", "alliance", false)
	_draw_mobile_nav(button_rects["hideout"] as Rect2, "STATE", "HIDEOUT", "moon_emblem", selected_room == "backroom" and panel_mode == "room")

func _draw_mobile_nav(rect: Rect2, title: String, subtitle: String, item_id: String, active: bool) -> void:
	draw_style_box(SyndicateSkins.style_box(active, 10), rect)
	draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(rect.size.x * 0.5 - 20.0, 8.0), Vector2(40.0, 40.0)), SyndicateSkins.region(item_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 72.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 10, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 91.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 7, SyndicateSkins.accent())

func _draw_dermapack_nav(rect: Rect2) -> void:
	var active: bool = panel_mode == "dermapack"
	draw_style_box(SyndicateSkins.style_box(active, 10), rect)
	draw_texture_rect(dermapack_texture, Rect2(rect.position + Vector2(rect.size.x * 0.5 - 24.0, 4.0), Vector2(48.0, 48.0)), false)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 72.0), "DERMAPACK", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 10, SyndicateSkins.text())
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 91.0), "MICRO STORAGE", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 7, SyndicateSkins.accent())

func _draw_button(rect: Rect2, label: String, active: bool, font_size: int) -> void:
	draw_style_box(SyndicateSkins.style_box(active, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, rect.size.y * 0.61), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 6.0, font_size, SyndicateSkins.text())
