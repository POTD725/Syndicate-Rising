extends "res://scripts/syndicate_skinned_attack_cutscene.gd"
## Threat-specific animated action staged with the same skin family as the live hideout.

const Anim = preload("res://scripts/syndicate_animation_library.gd")

func _draw_attack_art() -> void:
	super._draw_attack_art()
	var upper_veil: Color = SyndicateSkins.dark()
	upper_veil.a = 0.18
	draw_rect(Rect2(60.0, 112.0, 600.0, 560.0), upper_veil, true)
	match threat_type:
		"survey":
			_draw_survey_action()
		"cyber":
			_draw_cyber_action()
		"riot":
			_draw_riot_action()
		_:
			_draw_patrol_action()

func _draw_survey_action() -> void:
	var drone_position: Vector2 = Vector2(360.0 + sin(elapsed * 1.1) * 185.0, 250.0 + cos(elapsed * 1.7) * 24.0)
	draw_texture_rect_region(skin_atlas, Rect2(drone_position - Vector2(48.0, 48.0), Vector2(96.0, 96.0)), SyndicateSkins.region("threat_survey"))
	var scan_center: Vector2 = Vector2(360.0 + sin(elapsed * 0.65) * 170.0, 540.0)
	var cone: PackedVector2Array = PackedVector2Array([
		drone_position + Vector2(-13.0, 34.0), drone_position + Vector2(13.0, 34.0),
		scan_center + Vector2(92.0, 76.0), scan_center + Vector2(-92.0, 76.0)
	])
	draw_colored_polygon(cone, Color(SyndicateSkins.accent(), 0.16))
	Anim.draw_worker(self, skin_atlas, SyndicateSkins.region("crew_hacker"), Vector2(170.0, 585.0), elapsed, 0.15, 1.0, 0.0, 1.24, SyndicateSkins.secondary(), SyndicateSkins.accent(), SyndicateSkins.panel(), "jam")
	Anim.draw_job_effect(self, Vector2(225.0, 590.0), "jam", elapsed, 0.15, 1.05, SyndicateSkins.secondary(), SyndicateSkins.accent(), SyndicateSkins.panel())
	Anim.draw_job_label(self, Vector2(170.0, 528.0), "JAMMING ORBITAL SCAN", 176.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 8)

func _draw_patrol_action() -> void:
	for index: int in range(3):
		var advance: float = fmod(elapsed * (0.12 + float(index) * 0.008) + float(index) * 0.27, 1.0)
		var position: Vector2 = Vector2(710.0 - advance * 330.0, 330.0 + float(index) * 82.0)
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region("threat_patrol"), position, elapsed, float(index) * 0.28, -1.0, 1.0 if advance < 0.65 else 0.0, 1.12, SyndicateSkins.danger(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "aim")
		Anim.draw_job_effect(self, position + Vector2(-35.0, 0.0), "aim", elapsed, float(index) * 0.28, 0.86, SyndicateSkins.danger(), SyndicateSkins.secondary(), SyndicateSkins.panel())
	Anim.draw_worker(self, skin_atlas, SyndicateSkins.region("crew_enforcer"), Vector2(170.0, 495.0), elapsed, 0.18, 1.0, 0.0, 1.30, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "guard")
	Anim.draw_job_effect(self, Vector2(215.0, 495.0), "guard", elapsed, 0.18, 1.0, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
	Anim.draw_job_label(self, Vector2(170.0, 437.0), "SENTRY DEFENSE", 148.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 8)

func _draw_cyber_action() -> void:
	for node_index: int in range(12):
		var column: int = node_index % 4
		var row: int = int(node_index / 4)
		var position: Vector2 = Vector2(165.0 + float(column) * 130.0, 245.0 + float(row) * 112.0)
		var hacked: bool = fmod(elapsed * 1.2 + float(node_index) * 0.31, 2.0) > 1.0
		var node_color: Color = SyndicateSkins.danger() if hacked else SyndicateSkins.accent()
		draw_circle(position, 13.0 + sin(elapsed * 3.0 + float(node_index)) * 3.0, Color(node_color, 0.22))
		draw_rect(Rect2(position - Vector2(8.0, 8.0), Vector2(16.0, 16.0)), node_color, true)
		if node_index > 0:
			var previous_column: int = (node_index - 1) % 4
			var previous_row: int = int((node_index - 1) / 4)
			var previous: Vector2 = Vector2(165.0 + float(previous_column) * 130.0, 245.0 + float(previous_row) * 112.0)
			draw_line(previous, position, Color(node_color, 0.26), 2.0, true)
	Anim.draw_worker(self, skin_atlas, SyndicateSkins.region("crew_hacker"), Vector2(235.0, 600.0), elapsed, 0.12, 1.0, 0.0, 1.18, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "hack")
	Anim.draw_job_effect(self, Vector2(285.0, 602.0), "hack", elapsed, 0.12, 1.0, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
	Anim.draw_worker(self, skin_atlas, SyndicateSkins.region("threat_cyber"), Vector2(500.0, 600.0), elapsed, 0.63, -1.0, 0.0, 1.18, SyndicateSkins.danger(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "hack")
	Anim.draw_job_effect(self, Vector2(450.0, 602.0), "hack", elapsed, 0.63, 1.0, SyndicateSkins.danger(), SyndicateSkins.secondary(), SyndicateSkins.panel())
	Anim.draw_job_label(self, Vector2(360.0, 535.0), "COUNTER-HACK DUEL", 190.0, SyndicateSkins.accent(), SyndicateSkins.panel(), SyndicateSkins.text(), 8)

func _draw_riot_action() -> void:
	var door_rect: Rect2 = Rect2(286.0, 235.0, 148.0, 330.0)
	draw_rect(door_rect, SyndicateSkins.panel().darkened(0.25), true)
	draw_rect(door_rect, SyndicateSkins.secondary(), false, 7.0)
	for bar_index: int in range(4):
		var x: float = door_rect.position.x + 24.0 + float(bar_index) * 32.0
		draw_line(Vector2(x, door_rect.position.y), Vector2(x, door_rect.end.y), SyndicateSkins.accent().darkened(0.25), 5.0, true)
	for index: int in range(2):
		var position: Vector2 = Vector2(515.0 + float(index) * 86.0, 455.0 + float(index) * 56.0)
		Anim.draw_worker(self, skin_atlas, SyndicateSkins.region("threat_riot"), position, elapsed, float(index) * 0.42, -1.0, 0.0, 1.25, SyndicateSkins.danger(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "breach")
		Anim.draw_job_effect(self, position + Vector2(-45.0, 8.0), "breach", elapsed, float(index) * 0.42, 0.95, SyndicateSkins.danger(), SyndicateSkins.secondary(), SyndicateSkins.panel())
	Anim.draw_worker(self, skin_atlas, SyndicateSkins.region("crew_enforcer"), Vector2(198.0, 470.0), elapsed, 0.22, 1.0, 0.0, 1.28, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel(), "repair")
	Anim.draw_job_effect(self, Vector2(248.0, 475.0), "repair", elapsed, 0.22, 1.0, SyndicateSkins.accent(), SyndicateSkins.secondary(), SyndicateSkins.panel())
	Anim.draw_job_label(self, Vector2(360.0, 595.0), "BLAST DOOR BREACH", 184.0, SyndicateSkins.secondary(), SyndicateSkins.panel(), SyndicateSkins.text(), 8)

func visible_actor_job_count() -> int:
	match threat_type:
		"survey": return 2
		"cyber": return 2
		"riot": return 3
		_: return 4
