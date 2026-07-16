extends "res://scripts/syndicate_skinned_chat.gd"
## Galaxy, Alliance, and Private communications now sit over the approved city art.

const APPROVED_ART: Script = preload("res://scripts/syndicate_approved_art.gd")
var approved_ui: Texture2D
var approved_board: Texture2D

func _ready() -> void:
	approved_ui = APPROVED_ART.ui_atlas()
	approved_board = APPROVED_ART.board_texture()
	super._ready()
	var backdrop: TextureRect = TextureRect.new()
	backdrop.name = "ApprovedCityBackdrop"
	backdrop.texture = approved_board
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.55, 0.65, 0.78, 0.24)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	move_child(backdrop, 0)
	feedback_label.text = "APPROVED DASHBOARD // Communications link online."

func approved_graphics_active() -> bool:
	return APPROVED_ART.approved_graphics_active()

func _atlas_icon(item_id: String) -> AtlasTexture:
	var mapped: String = "state"
	if item_id.contains("alliance"):
		mapped = "alliance"
	elif item_id.contains("private"):
		mapped = "dermapack"
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = approved_ui
	texture.region = APPROVED_ART.ui_region(mapped)
	return texture
