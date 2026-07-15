extends RefCounted
## Shared lightweight vector animation helpers for workers, crew, enemies, and cutscene actors.

static func draw_worker(
	canvas: CanvasItem,
	atlas: Texture2D,
	region: Rect2,
	position: Vector2,
	time_value: float,
	phase: float,
	facing: float,
	motion: float,
	scale_value: float,
	accent: Color,
	secondary: Color,
	panel: Color,
	action: String
) -> void:
	var direction: float = -1.0 if facing < 0.0 else 1.0
	var gait: float = sin(time_value * 8.0 + phase * TAU) * clampf(motion, 0.0, 1.0)
	var work: float = sin(time_value * 5.5 + phase * TAU)
	var bob: float = sin(time_value * (7.0 if motion > 0.2 else 3.2) + phase * TAU) * (1.7 if motion > 0.2 else 0.8) * scale_value
	var center: Vector2 = position + Vector2(0.0, bob)
	var shoulder_y: float = center.y - 12.0 * scale_value
	var hip_y: float = center.y + 4.0 * scale_value
	var foot_y: float = center.y + 19.0 * scale_value
	var limb_width: float = maxf(1.2, 2.2 * scale_value)

	var shadow: PackedVector2Array = PackedVector2Array()
	for point_index: int in range(16):
		var angle: float = TAU * float(point_index) / 16.0
		shadow.append(Vector2(center.x + cos(angle) * 12.0 * scale_value, center.y + 21.0 * scale_value + sin(angle) * 4.0 * scale_value))
	var shadow_color: Color = panel.darkened(0.65)
	shadow_color.a = 0.58
	canvas.draw_colored_polygon(shadow, shadow_color)

	var left_foot: Vector2 = Vector2(center.x - 5.0 * scale_value + gait * 4.0 * scale_value, foot_y)
	var right_foot: Vector2 = Vector2(center.x + 5.0 * scale_value - gait * 4.0 * scale_value, foot_y)
	canvas.draw_line(Vector2(center.x - 3.0 * scale_value, hip_y), left_foot, secondary, limb_width, true)
	canvas.draw_line(Vector2(center.x + 3.0 * scale_value, hip_y), right_foot, accent, limb_width, true)

	var torso: Rect2 = Rect2(center.x - 8.0 * scale_value, shoulder_y, 16.0 * scale_value, 20.0 * scale_value)
	canvas.draw_rect(torso, panel.lightened(0.12), true)
	canvas.draw_rect(torso, accent, false, maxf(1.0, 1.6 * scale_value))
	canvas.draw_circle(Vector2(center.x, shoulder_y - 6.5 * scale_value), 6.5 * scale_value, panel.lightened(0.24))
	canvas.draw_arc(Vector2(center.x, shoulder_y - 6.5 * scale_value), 6.5 * scale_value, PI, TAU, 18, secondary, maxf(1.0, 1.7 * scale_value), true)
	canvas.draw_line(Vector2(center.x - 4.3 * scale_value, shoulder_y - 6.0 * scale_value), Vector2(center.x + 4.3 * scale_value, shoulder_y - 6.0 * scale_value), accent, maxf(1.0, 1.4 * scale_value), true)

	var left_hand: Vector2 = Vector2(center.x - 12.0 * scale_value - gait * 3.0 * scale_value, center.y + gait * 5.0 * scale_value)
	var right_hand: Vector2 = Vector2(center.x + 12.0 * scale_value + gait * 3.0 * scale_value, center.y - gait * 5.0 * scale_value)
	match action:
		"type", "hack", "route", "research", "plan", "scan", "jam":
			left_hand = Vector2(center.x + direction * 10.0 * scale_value, center.y - 1.0 * scale_value + work * 1.5 * scale_value)
			right_hand = Vector2(center.x + direction * 13.0 * scale_value, center.y + 4.0 * scale_value - work * 1.5 * scale_value)
		"aim", "guard", "fight":
			left_hand = Vector2(center.x + direction * 11.0 * scale_value, center.y - 4.0 * scale_value)
			right_hand = Vector2(center.x + direction * 18.0 * scale_value, center.y - 2.0 * scale_value)
		"train":
			left_hand = Vector2(center.x - 10.0 * scale_value, center.y - (7.0 + work * 6.0) * scale_value)
			right_hand = Vector2(center.x + 10.0 * scale_value, center.y - (7.0 + work * 6.0) * scale_value)
		"load", "trade", "mine", "pump":
			left_hand = Vector2(center.x - 8.0 * scale_value, center.y + 8.0 * scale_value + work * 1.5 * scale_value)
			right_hand = Vector2(center.x + 8.0 * scale_value, center.y + 8.0 * scale_value - work * 1.5 * scale_value)
		"heal", "recover":
			left_hand = Vector2(center.x + direction * 8.0 * scale_value, center.y + 2.0 * scale_value)
			right_hand = Vector2(center.x + direction * 15.0 * scale_value, center.y + 2.0 * scale_value)
		"weld", "repair", "breach":
			left_hand = Vector2(center.x + direction * 8.0 * scale_value, center.y + 1.0 * scale_value)
			right_hand = Vector2(center.x + direction * (13.0 + work * 5.0) * scale_value, center.y + 7.0 * scale_value)
		"celebrate":
			left_hand = Vector2(center.x - 10.0 * scale_value, center.y - 15.0 * scale_value)
			right_hand = Vector2(center.x + 10.0 * scale_value, center.y - 15.0 * scale_value)
		"defeated":
			left_hand = Vector2(center.x - 12.0 * scale_value, center.y + 10.0 * scale_value)
			right_hand = Vector2(center.x + 12.0 * scale_value, center.y + 10.0 * scale_value)
		_:
			pass
	canvas.draw_line(Vector2(center.x - 6.0 * scale_value, shoulder_y + 4.0 * scale_value), left_hand, secondary, limb_width, true)
	canvas.draw_line(Vector2(center.x + 6.0 * scale_value, shoulder_y + 4.0 * scale_value), right_hand, accent, limb_width, true)
	canvas.draw_circle(left_hand, maxf(1.4, 2.0 * scale_value), secondary)
	canvas.draw_circle(right_hand, maxf(1.4, 2.0 * scale_value), accent)

	if atlas != null:
		var badge_size: float = maxf(7.0, 9.0 * scale_value)
		canvas.draw_texture_rect_region(atlas, Rect2(center.x - badge_size * 0.5, center.y - 7.0 * scale_value, badge_size, badge_size), region)

static func draw_job_effect(
	canvas: CanvasItem,
	position: Vector2,
	action: String,
	time_value: float,
	phase: float,
	scale_value: float,
	accent: Color,
	secondary: Color,
	panel: Color
) -> void:
	var pulse: float = 0.5 + sin(time_value * 4.0 + phase * TAU) * 0.5
	match action:
		"type", "route", "hack", "research", "plan", "scan", "jam":
			var console_rect: Rect2 = Rect2(position.x - 17.0 * scale_value, position.y - 7.0 * scale_value, 34.0 * scale_value, 18.0 * scale_value)
			canvas.draw_rect(console_rect, panel.lightened(0.08), true)
			canvas.draw_rect(console_rect, accent, false, maxf(1.0, 1.5 * scale_value))
			for line_index: int in range(3):
				var width_value: float = (9.0 + fmod(float(line_index * 7) + time_value * 9.0, 17.0)) * scale_value
				canvas.draw_line(Vector2(console_rect.position.x + 4.0 * scale_value, console_rect.position.y + (5.0 + float(line_index) * 4.0) * scale_value), Vector2(console_rect.position.x + 4.0 * scale_value + width_value, console_rect.position.y + (5.0 + float(line_index) * 4.0) * scale_value), secondary if line_index == 1 else accent, maxf(1.0, scale_value), true)
			if action in ["research", "plan", "scan", "jam"]:
				canvas.draw_arc(position + Vector2(0.0, -18.0 * scale_value), (8.0 + pulse * 4.0) * scale_value, 0.0, TAU, 24, secondary, maxf(1.0, 1.3 * scale_value), true)
		"weld", "repair", "breach":
			canvas.draw_line(position + Vector2(-12.0, 10.0) * scale_value, position + Vector2(13.0, -5.0) * scale_value, secondary, maxf(1.0, 2.2 * scale_value), true)
			for spark_index: int in range(5):
				var spark_angle: float = float(spark_index) * 1.2 + time_value * 5.0
				var spark_length: float = (4.0 + float(spark_index % 3) * 2.0) * scale_value
				var spark_origin: Vector2 = position + Vector2(13.0, -5.0) * scale_value
				canvas.draw_line(spark_origin, spark_origin + Vector2(cos(spark_angle), sin(spark_angle)) * spark_length, accent, maxf(1.0, scale_value), true)
		"aim", "guard", "fight":
			var beam_length: float = (28.0 + pulse * 15.0) * scale_value
			canvas.draw_line(position, position + Vector2(beam_length, -2.0 * scale_value), accent, maxf(1.0, 1.4 * scale_value), true)
			canvas.draw_circle(position + Vector2(beam_length, -2.0 * scale_value), 2.5 * scale_value, secondary)
		"train":
			var lift_y: float = (-4.0 - pulse * 8.0) * scale_value
			canvas.draw_line(position + Vector2(-16.0, lift_y), position + Vector2(16.0, lift_y), secondary, maxf(1.0, 2.5 * scale_value), true)
			canvas.draw_circle(position + Vector2(-18.0, lift_y), 4.5 * scale_value, panel.lightened(0.18))
			canvas.draw_circle(position + Vector2(18.0, lift_y), 4.5 * scale_value, panel.lightened(0.18))
		"load", "trade":
			var crate_offset: float = sin(time_value * 2.4 + phase * TAU) * 3.0 * scale_value
			var crate: Rect2 = Rect2(position.x - 11.0 * scale_value + crate_offset, position.y - 9.0 * scale_value, 22.0 * scale_value, 18.0 * scale_value)
			canvas.draw_rect(crate, panel.lightened(0.18), true)
			canvas.draw_rect(crate, secondary, false, maxf(1.0, 1.4 * scale_value))
			canvas.draw_line(crate.position, crate.end, accent, maxf(1.0, scale_value), true)
		"mine":
			var rock: PackedVector2Array = PackedVector2Array([
				position + Vector2(-16.0, 9.0) * scale_value,
				position + Vector2(-8.0, -9.0) * scale_value,
				position + Vector2(9.0, -11.0) * scale_value,
				position + Vector2(17.0, 7.0) * scale_value,
				position + Vector2(3.0, 13.0) * scale_value
			])
			canvas.draw_colored_polygon(rock, panel.lightened(0.22))
			canvas.draw_line(position + Vector2(-20.0, -17.0) * scale_value, position, accent, maxf(1.0, 2.0 * scale_value), true)
			canvas.draw_circle(position, 3.0 * scale_value + pulse * 2.0 * scale_value, secondary)
		"pump":
			var tank: Rect2 = Rect2(position.x - 10.0 * scale_value, position.y - 14.0 * scale_value, 20.0 * scale_value, 28.0 * scale_value)
			canvas.draw_rect(tank, panel.lightened(0.12), true)
			canvas.draw_rect(tank, accent, false, maxf(1.0, 1.5 * scale_value))
			for bubble_index: int in range(3):
				var bubble_y: float = position.y + 12.0 * scale_value - fmod(time_value * (9.0 + float(bubble_index) * 2.0) + float(bubble_index) * 8.0, 38.0) * scale_value
				canvas.draw_circle(Vector2(position.x + (float(bubble_index) - 1.0) * 7.0 * scale_value, bubble_y), (2.0 + float(bubble_index) * 0.5) * scale_value, secondary)
		"heal", "recover":
			canvas.draw_arc(position, (10.0 + pulse * 5.0) * scale_value, 0.0, TAU, 24, accent, maxf(1.0, 1.5 * scale_value), true)
			canvas.draw_line(position + Vector2(-5.0, 0.0) * scale_value, position + Vector2(5.0, 0.0) * scale_value, secondary, maxf(1.0, 2.2 * scale_value), true)
			canvas.draw_line(position + Vector2(0.0, -5.0) * scale_value, position + Vector2(0.0, 5.0) * scale_value, secondary, maxf(1.0, 2.2 * scale_value), true)
		"run":
			for dust_index: int in range(3):
				var dust: Color = secondary
				dust.a = 0.30 - float(dust_index) * 0.07
				canvas.draw_circle(position + Vector2(-8.0 - float(dust_index) * 5.0, 8.0 + float(dust_index)) * scale_value, (3.0 - float(dust_index) * 0.5) * scale_value, dust)
		"celebrate":
			for burst_index: int in range(8):
				var burst_angle: float = TAU * float(burst_index) / 8.0 + time_value
				canvas.draw_line(position, position + Vector2(cos(burst_angle), sin(burst_angle)) * (10.0 + pulse * 5.0) * scale_value, secondary if burst_index % 2 == 0 else accent, maxf(1.0, scale_value), true)
		_:
			canvas.draw_circle(position, (3.0 + pulse * 2.0) * scale_value, accent)

static func draw_job_label(
	canvas: CanvasItem,
	position: Vector2,
	label: String,
	width_value: float,
	accent: Color,
	panel: Color,
	text_color: Color,
	font_size: int = 7
) -> void:
	var rect: Rect2 = Rect2(position.x - width_value * 0.5, position.y - 16.0, width_value, 20.0)
	var fill: Color = panel
	fill.a = 0.93
	canvas.draw_rect(rect, fill, true)
	canvas.draw_rect(rect, accent, false, 1.0)
	canvas.draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 14.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, font_size, text_color)
