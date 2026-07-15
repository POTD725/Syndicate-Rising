extends "res://scripts/syndicate_raid.gd"
## Uses the exact displayed concept-board police, crew, cutscene, and launch-button artwork.

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
	super._draw()
	var battle_art: Rect2 = Rect2(34.0, 136.0, 652.0, 394.0)
	draw_texture_rect_region(skin_atlas, battle_art, SyndicateSkins.cutscene_region(0 if not battle_over else (4 if victory else 1)))
	var veil: Color = SyndicateSkins.dark()
	veil.a = 0.34
	draw_rect(battle_art, veil, true)
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 3, 16), battle_art)
	var target: String = String(SyndicateState.active_job.get("target", "Peacekeepers")).to_lower()
	var threat_item: String = "threat_patrol"
	if target.contains("command") or target.contains("armored"):
		threat_item = "threat_riot"
	elif target.contains("security"):
		threat_item = "threat_survey"
	var threat_rect: Rect2 = Rect2(258.0, 210.0, 204.0, 286.0)
	draw_texture_rect_region(skin_atlas, threat_rect, SyndicateSkins.region(threat_item))
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.secondary(), 3, 18), threat_rect)
	for index: int in range(crew_units.size()):
		var unit: Dictionary = crew_units[index]
		var x: float = 35.0 + float(index) * 170.0
		var role_item: String = SyndicateSkins.crew_item(String(unit.get("role", "Enforcer")))
		draw_texture_rect_region(skin_atlas, Rect2(x + 8.0, 648.0, 129.0, 129.0), SyndicateSkins.region(role_item))
	draw_style_box(_panel(Color(0.0, 0.0, 0.0, 0.0), SyndicateSkins.accent(), 3, 16), Rect2(12.0, 12.0, 696.0, 1256.0))
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 112.0), "ACTUAL DISPLAYED ART • %s" % SyndicateSkins.skin_name().to_upper(), HORIZONTAL_ALIGNMENT_RIGHT, 676.0, 9, SyndicateSkins.secondary())
	if battle_over:
		var result_item: String = "victory" if victory else "defeat"
		draw_texture_rect_region(skin_atlas, Rect2(100.0, 474.0, 92.0, 92.0), SyndicateSkins.region(result_item))

func _draw_action_button(id_value: String, label: String) -> void:
	var rect: Rect2 = buttons[id_value] as Rect2
	var enabled: bool = not battle_over or id_value == "return"
	draw_texture_rect_region(skin_atlas, rect, SyndicateSkins.button_region())
	var cover: Color = SyndicateSkins.dark()
	cover.a = 0.78 if enabled else 0.90
	draw_rect(Rect2(rect.position + Vector2(14.0, 7.0), rect.size - Vector2(28.0, 14.0)), cover, true)
	var item_id: String = "weapons"
	match id_value:
		"evade": item_id = "unlock"
		"special": item_id = "power_core"
		"auto": item_id = "operations"
		"abort": item_id = "defeat"
		"return": item_id = "victory" if battle_over and victory else "hideout"
	draw_texture_rect_region(skin_atlas, Rect2(rect.position + Vector2(8.0, 8.0), Vector2(48.0, 48.0)), SyndicateSkins.region(item_id))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(52.0, 43.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 60.0, 10, SyndicateSkins.text())
