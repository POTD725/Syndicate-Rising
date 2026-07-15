extends "res://scripts/syndicate_full_city.gd"
## Keeps the established five-family interface switch while the city art remains canonical.

func _ready() -> void:
	super._ready()
	button_rects["skin"] = Rect2(329.0, 104.0, 86.0, 38.0)

func _action(action: String) -> void:
	if action == "skin":
		SyndicateSkins.cycle_skin()
		message = "Interface family changed to %s. The full isometric city remains active." % SyndicateSkins.skin_name()
		SyndicateAudio.play_sfx("click")
		queue_redraw()
		return
	super._action(action)

func _draw_camera_controls() -> void:
	super._draw_camera_controls()
	_draw_button(button_rects["skin"] as Rect2, "SKIN", true, 8)
