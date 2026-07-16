extends "res://scripts/syndicate_full_cutscene.gd"
## Story scenes use crops generated from the same approved dashboard artwork.

const APPROVED_ART: Script = preload("res://scripts/syndicate_approved_art.gd")

func _ready() -> void:
	super._ready()
	full_scene_texture = APPROVED_ART.cutscene_texture(key)
	queue_redraw()

func approved_graphics_active() -> bool:
	return APPROVED_ART.approved_graphics_active()

func uses_isometric_board() -> bool:
	return approved_graphics_active()
