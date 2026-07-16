extends "res://scripts/syndicate_full_operations.gd"
## Uses the checksum-locked approved dashboard source for all Operations art.

const APPROVED_ART: Script = preload("res://scripts/syndicate_approved_art.gd")

func _ready() -> void:
	super._ready()
	systems_atlas = APPROVED_ART.systems_atlas()
	board_texture = APPROVED_ART.board_texture()
	queue_redraw()

func approved_graphics_active() -> bool:
	return APPROVED_ART.approved_graphics_active()
