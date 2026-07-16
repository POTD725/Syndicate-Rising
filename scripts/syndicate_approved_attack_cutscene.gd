extends "res://scripts/syndicate_full_attack_cutscene.gd"
## Survey, patrol, riot, and cyber attacks use approved matching artwork.

const APPROVED_ART: Script = preload("res://scripts/syndicate_approved_art.gd")

func _ready() -> void:
	super._ready()
	full_attack_texture = APPROVED_ART.attack_texture(threat_type)
	queue_redraw()

func approved_graphics_active() -> bool:
	return APPROVED_ART.approved_graphics_active()

func uses_isometric_board() -> bool:
	return approved_graphics_active()
