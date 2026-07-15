extends RefCounted
## Shared, strictly typed 2.5D art renderer for the city, NPCs, systems, UI, and cinematics.

static var _cache: Dictionary = {}

static func board_texture() -> Texture2D:
	return _texture("board", _board_svg())

static func npc_atlas() -> Texture2D:
	return _texture("npc", _npc_atlas_svg())

static func systems_atlas() -> Texture2D:
	return _texture("systems", _systems_atlas_svg())

static func ui_atlas() -> Texture2D:
	return _texture("ui", _ui_atlas_svg())

static func dermapack_texture() -> Texture2D:
	return _texture("dermapack", _single_ui_svg("dermapack"))

static func cutscene_texture(key: String) -> Texture2D:
	return _texture("cutscene_" + key, _cutscene_svg(key))

static func attack_texture(key: String) -> Texture2D:
	return _texture("attack_" + key, _attack_svg(key))

static func _texture(key: String, svg: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key] as Texture2D
	var image: Image = Image.new()
	var result: Error = image.load_svg_from_string(svg, 1.0)
	if result != OK:
		push_error("Unable to generate art %s: %s" % [key, error_string(result)])
		return GradientTexture2D.new()
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture

static func _defs() -> String:
	return """<defs>
<linearGradient id='space' x1='0' y1='0' x2='0' y2='1'><stop stop-color='#020611'/><stop offset='.43' stop-color='#0b1728'/><stop offset='1' stop-color='#202a38'/></linearGradient>
<linearGradient id='moon' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#8994a0'/><stop offset='.52' stop-color='#5e6a78'/><stop offset='1' stop-color='#36414e'/></linearGradient>
<linearGradient id='steel' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#7390a8'/><stop offset='.5' stop-color='#354f66'/><stop offset='1' stop-color='#17283a'/></linearGradient>
<filter id='shadow'><feGaussianBlur stdDeviation='9'/></filter>
<filter id='glow'><feGaussianBlur stdDeviation='4' result='b'/><feMerge><feMergeNode in='b'/><feMergeNode in='SourceGraphic'/></feMerge></filter>
<pattern id='grid' width='42' height='42' patternUnits='userSpaceOnUse'><path d='M42 0H0V42' fill='none' stroke='#e5edf3' stroke-opacity='.08' stroke-width='2'/></pattern>
</defs>"""

static func _board_svg() -> String:
	var parts: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='1024' height='1536' viewBox='0 0 1024 1536'>", _defs()]
	parts.append("<rect width='1024' height='1536' fill='url(#space)'/>")
	for index: int in range(145):
		var sx: int = (index * 91 + 27) % 1024
		var sy: int = (index * 53 + 19) % 390
		var radius: int = 1 + index % 3
		parts.append("<circle cx='%d' cy='%d' r='%d' fill='#e2f2ff' opacity='%.2f'/>" % [sx, sy, radius, 0.24 + float(index % 4) * 0.11])
	parts.append("<path d='M0 370 L120 315 L245 355 L365 286 L505 350 L640 290 L790 350 L920 305 L1024 350 V1536 H0Z' fill='#303b49'/>")
	parts.append("<path d='M0 420 L120 370 L270 410 L405 350 L550 415 L720 355 L875 415 L1024 365 V1536 H0Z' fill='url(#moon)'/>")
	for index: int in range(30):
		var cx: int = 45 + (index * 151) % 940
		var cy: int = 460 + (index * 103) % 1030
		var rx: int = 14 + (index % 5) * 10
		parts.append("<ellipse cx='%d' cy='%d' rx='%d' ry='%d' fill='#202936' opacity='.46'/><path d='M%d %d Q%d %d %d %d' fill='none' stroke='#c3ccd4' stroke-opacity='.18' stroke-width='3'/>" % [cx, cy, rx, int(rx * 0.48), cx - rx, cy, cx, cy - int(rx * 0.36), cx + rx, cy])
	parts.append(_roads_svg())
	parts.append("<rect x='18' y='440' width='988' height='1078' fill='url(#grid)' opacity='.32'/>")
	parts.append(_station_svg())
	var data: Array[Dictionary] = [
		{"id":"backroom","x":45,"y":500,"w":285,"h":215,"a":"#4ee7ff","b":"#8c54d8","label":"SYNDICATE COMMAND"},
		{"id":"boss_office","x":350,"y":505,"w":245,"h":190,"a":"#ffd16a","b":"#8c54d8","label":"BOSS'S OFFICE"},
		{"id":"black_research","x":380,"y":440,"w":285,"h":220,"a":"#55f3d1","b":"#6ca6ff","label":"BLACK RESEARCH"},
		{"id":"weapons_workshop","x":690,"y":540,"w":285,"h":220,"a":"#ff9a4a","b":"#f05b6b","label":"WEAPONS WORKSHOP"},
		{"id":"signal_den","x":28,"y":745,"w":285,"h":220,"a":"#4ee7ff","b":"#e6539b","label":"HACKER TRAINING"},
		{"id":"clinic","x":360,"y":730,"w":285,"h":220,"a":"#56d6a2","b":"#4ee7ff","label":"STREET CLINIC"},
		{"id":"chop_shop","x":690,"y":795,"w":285,"h":220,"a":"#4ee7ff","b":"#8c54d8","label":"RUNNER GARAGE"},
		{"id":"tunnel","x":28,"y":1015,"w":285,"h":220,"a":"#4ee7ff","b":"#ff9a4a","label":"SMUGGLER DOCK"},
		{"id":"black_market","x":360,"y":1005,"w":295,"h":225,"a":"#ffd16a","b":"#e6539b","label":"BLACK MARKET"},
		{"id":"sharpshooter_range","x":690,"y":1040,"w":285,"h":220,"a":"#f05b6b","b":"#ffd16a","label":"SHARPSHOOTER RANGE"},
		{"id":"enforcer_gym","x":170,"y":1280,"w":315,"h":230,"a":"#ff9a4a","b":"#f05b6b","label":"ENFORCER TRAINING"},
		{"id":"bunks","x":570,"y":1295,"w":285,"h":210,"a":"#72a8ff","b":"#8c54d8","label":"CREW QUARTERS"}
	]
	for building: Dictionary in data:
		parts.append(_building_svg(building))
	parts.append(_resource_prop(16, 1280, "#ff9a4a", "ALLOY"))
	parts.append(_resource_prop(835, 700, "#4ee7ff", "HE-3"))
	parts.append(_resource_prop(835, 1290, "#e6539b", "DATA"))
	parts.append(_vehicle_svg(95, 920, "#ff9a4a", 0.72))
	parts.append(_vehicle_svg(490, 1180, "#4ee7ff", 0.76))
	parts.append(_vehicle_svg(825, 470, "#6ca6ff", 0.68))
	parts.append(_props_svg())
	parts.append("</svg>")
	return "".join(parts)

static func _roads_svg() -> String:
	var parts: Array[String] = []
	var centers: Array[int] = [620, 860, 1100, 1330]
	for center_y: int in centers:
		parts.append("<path d='M70 %d L512 %d L954 %d L512 %dZ' fill='#768293' stroke='#3e4a59' stroke-width='7'/>" % [center_y, center_y - 155, center_y, center_y + 155])
		parts.append("<path d='M137 %d L512 %d L887 %d L512 %dZ' fill='#606d7e' stroke='#aeb9c5' stroke-width='3'/>" % [center_y, center_y - 123, center_y, center_y + 123])
	parts.append("<path d='M455 450 L569 450 L650 1536 L374 1536Z' fill='#6a7788' stroke='#3f4b59' stroke-width='7'/>")
	for y: int in range(520, 1490, 92):
		parts.append("<path d='M469 %d H555' stroke='#dfe6ec' stroke-opacity='.76' stroke-width='8'/>")
	return "".join(parts)

static func _station_svg() -> String:
	return """<g transform='translate(105 36)'>
<ellipse cx='410' cy='250' rx='350' ry='66' fill='#000' opacity='.5' filter='url(#shadow)'/>
<path d='M30 205 L205 132 L300 180 H520 L615 132 L790 205 L655 276 H160Z' fill='#263e55' stroke='#122232' stroke-width='9'/>
<path d='M72 207 L222 155 L300 198 H520 L598 155 L748 207 L624 247 H190Z' fill='#41627d' stroke='#4ee7ff' stroke-width='5'/>
<circle cx='410' cy='203' r='142' fill='#2c465f' stroke='#132333' stroke-width='11'/><circle cx='410' cy='203' r='106' fill='#436981' stroke='#4ee7ff' stroke-width='5'/><circle cx='410' cy='203' r='66' fill='#1b3247' stroke='#8c54d8' stroke-width='6'/><circle cx='410' cy='203' r='27' fill='#4ee7ff' stroke='#132333' stroke-width='5'/>
<rect x='145' y='164' width='124' height='84' rx='18' fill='#22384d' stroke='#132333' stroke-width='7'/><rect x='551' y='164' width='124' height='84' rx='18' fill='#22384d' stroke='#132333' stroke-width='7'/>
<path d='M168 184 H246 M168 204 H246 M168 224 H246 M574 184 H652 M574 204 H652 M574 224 H652' stroke='#4ee7ff' stroke-width='5'/>
<path d='M410 64 V14' stroke='#dce6ed' stroke-width='9'/><circle cx='410' cy='12' r='12' fill='#f05b6b' stroke='#132333' stroke-width='4'/>
<text x='410' y='335' text-anchor='middle' fill='#e6f7ff' font-family='sans-serif' font-size='21' font-weight='bold'>PEACEKEEPER ORBITAL STATION</text>
</g>"""

static func _building_svg(data: Dictionary) -> String:
	var id: String = String(data["id"])
	var x: int = int(data["x"])
	var y: int = int(data["y"])
	var width: int = int(data["w"])
	var height: int = int(data["h"])
	var accent: String = String(data["a"])
	var secondary: String = String(data["b"])
	var label: String = String(data["label"])
	var center: int = int(width * 0.5)
	var parts: Array[String] = ["<g transform='translate(%d %d)'>" % [x, y]]
	parts.append("<ellipse cx='%d' cy='%d' rx='%d' ry='31' fill='#000' opacity='.48' filter='url(#shadow)'/>" % [center, height + 22, int(width * 0.52)])
	parts.append("<path d='M0 %d L%d 0 L%d %d L%d %dZ' fill='#8393a2' stroke='#152434' stroke-width='7'/>" % [int(height * 0.55), center, width, int(height * 0.55), center, height])
	parts.append("<path d='M0 %d L%d %d L%d %d L0 %dZ' fill='#506477' stroke='#152434' stroke-width='6'/><path d='M%d %d L%d %d L%d %d L%d %dZ' fill='#3b4f63' stroke='#152434' stroke-width='6'/>" % [int(height * 0.55), center, height, center, height + 30, int(height * 0.55) + 30, width, int(height * 0.55), center, height, center, height + 30, width, int(height * 0.55) + 30])
	parts.append("<path d='M28 %d L%d 35 L%d %d L%d %dZ' fill='#243647' stroke='#152434' stroke-width='6'/>" % [int(height * 0.47), center, width - 28, int(height * 0.47), center, int(height * 0.80)])
	parts.append("<path d='M36 %d L%d 48 L%d %d L%d %dZ' fill='%s' stroke='#152434' stroke-width='5'/>" % [int(height * 0.29), center, width - 36, int(height * 0.29), center, int(height * 0.50), secondary])
	parts.append("<path d='M48 %d L%d 68 L%d %d L%d %dZ' fill='#172635' stroke='%s' stroke-width='4'/>" % [int(height * 0.38), center, width - 48, int(height * 0.38), center, int(height * 0.70), accent])
	parts.append(_equipment_svg(id, width, height, accent, secondary))
	parts.append(_tiny_worker_svg(52, int(height * 0.69), 1, accent))
	parts.append(_tiny_worker_svg(width - 72, int(height * 0.70), 2, secondary))
	parts.append("<path d='M36 %d V%d L%d %d V%d M%d %d V%d L%d %d V%d' fill='none' stroke='#dce7ed' stroke-width='10' stroke-linecap='round'/>" % [int(height * 0.30), int(height * 0.64), center, int(height * 0.83), int(height * 0.50), width - 36, int(height * 0.30), int(height * 0.64), center, int(height * 0.83), int(height * 0.50)])
	parts.append("<rect x='16' y='%d' width='%d' height='36' rx='12' fill='#0e1927' stroke='%s' stroke-width='4'/><text x='%d' y='%d' text-anchor='middle' fill='#f5fbff' font-family='sans-serif' font-size='14' font-weight='bold'>%s</text>" % [height + 29, width - 32, accent, center, height + 53, label])
	parts.append("<rect x='%d' y='8' width='54' height='31' rx='10' fill='#235e2e' stroke='#8cff84' stroke-width='3'/><text x='%d' y='30' text-anchor='middle' fill='#e6ffdf' font-family='sans-serif' font-size='14' font-weight='bold'>L24</text>" % [center - 27, center])
	parts.append("</g>")
	return "".join(parts)

static func _equipment_svg(id: String, width: int, height: int, accent: String, secondary: String) -> String:
	var center: int = int(width * 0.5)
	var y: int = int(height * 0.48)
	if id == "backroom":
		return "<circle cx='%d' cy='%d' r='34' fill='#102331' stroke='%s' stroke-width='5'/><circle cx='%d' cy='%d' r='19' fill='#21475a' stroke='%s' stroke-width='4'/><path d='M%d %d H%d M%d %d V%d' stroke='%s' stroke-width='4'/>" % [center, y, accent, center, y, secondary, center - 22, y, center + 22, center, y - 22, y + 22, accent]
	if id == "black_research":
		var research: String = ""
		var positions: Array[int] = [int(width * 0.28), int(width * 0.50), int(width * 0.72)]
		for px: int in positions:
			research += "<rect x='%d' y='%d' width='38' height='62' rx='13' fill='#173142' stroke='%s' stroke-width='4'/><ellipse cx='%d' cy='%d' rx='12' ry='22' fill='%s' opacity='.75' filter='url(#glow)'/>" % [px - 19, y - 28, accent, px, y + 3, secondary]
		return research
	if id == "weapons_workshop":
		return "<path d='M48 %d L132 %d M48 %d L132 %d M48 %d L132 %d' stroke='#e7edf3' stroke-width='8' stroke-linecap='round'/><rect x='%d' y='%d' width='60' height='60' rx='8' fill='#4b2d32' stroke='#152434' stroke-width='4'/><circle cx='%d' cy='%d' r='14' fill='%s' filter='url(#glow)'/>" % [y - 18, y - 8, y, y + 10, y + 18, y + 28, width - 112, y - 31, width - 82, y - 2, accent]
	if id == "signal_den":
		var terminals: String = ""
		var terminal_positions: Array[int] = [50, center - 28, width - 106]
		for px: int in terminal_positions:
			terminals += "<rect x='%d' y='%d' width='56' height='38' rx='6' fill='#102231' stroke='%s' stroke-width='4'/><path d='M%d %d H%d M%d %d H%d' stroke='%s' stroke-width='3'/>" % [px, y - 18, accent, px + 8, y - 5, px + 47, px + 8, y + 6, px + 37, secondary]
		return terminals
	if id == "clinic":
		return "<rect x='52' y='%d' width='108' height='44' rx='8' fill='#e2edf0' stroke='#152434' stroke-width='4'/><path d='M106 %d V%d M83 %d H129' stroke='%s' stroke-width='12'/><rect x='%d' y='%d' width='62' height='43' rx='7' fill='#102231' stroke='%s' stroke-width='4'/>" % [y - 22, y - 34, y + 22, y - 6, accent, width - 114, y - 20, secondary]
	if id == "chop_shop":
		return "<path d='M55 %d L%d %d L%d %d L%d %dZ' fill='#334d62' stroke='#152434' stroke-width='4'/><path d='M95 %d L%d %d L%d %d L%d %dZ' fill='%s' stroke='#152434' stroke-width='3'/><circle cx='84' cy='%d' r='14' fill='#111922'/><circle cx='%d' cy='%d' r='14' fill='#111922'/>" % [y + 18, center - 10, y - 18, width - 58, y + 18, center + 10, y + 49, y - 4, center, y - 26, center + 55, y - 2, center + 4, y + 20, secondary, y + 39, width - 86, y + 39]
	if id == "sharpshooter_range":
		var targets: String = ""
		var target_positions: Array[int] = [int(width * 0.28), int(width * 0.50), int(width * 0.72)]
		for px: int in target_positions:
			targets += "<circle cx='%d' cy='%d' r='24' fill='#f4f0e8' stroke='#152434' stroke-width='4'/><circle cx='%d' cy='%d' r='14' fill='%s'/><circle cx='%d' cy='%d' r='5' fill='%s'/>" % [px, y, px, y, secondary, px, y, accent]
		return targets
	if id == "bunks":
		var beds: String = ""
		var bed_positions: Array[int] = [46, center - 32, width - 110]
		for px: int in bed_positions:
			beds += "<rect x='%d' y='%d' width='64' height='17' rx='5' fill='#65788a' stroke='#152434' stroke-width='3'/><rect x='%d' y='%d' width='64' height='17' rx='5' fill='#65788a' stroke='#152434' stroke-width='3'/>" % [px, y - 28, px, y + 8]
		return beds
	if id == "black_market":
		var crates: String = ""
		for row: int in range(2):
			for column: int in range(4):
				var px: int = 48 + column * 48
				var py: int = y - 30 + row * 34
				var fill: String = "#765338" if (row + column) % 2 == 0 else "#3e6874"
				crates += "<rect x='%d' y='%d' width='38' height='25' rx='4' fill='%s' stroke='#152434' stroke-width='3'/>" % [px, py, fill]
		return crates
	if id == "tunnel":
		return "<path d='M42 %d Q%d %d %d %d' fill='none' stroke='#8193a2' stroke-width='16'/><path d='M62 %d Q%d %d %d %d' fill='none' stroke='%s' stroke-width='7'/><path d='M56 %d H%d' stroke='%s' stroke-width='6'/>" % [y + 35, center, y - 45, width - 42, y + 35, center, y - 28, width - 62, y + 35, accent, y + 11, width - 56, secondary]
	if id == "boss_office":
		return "<rect x='62' y='%d' width='%d' height='39' rx='8' fill='#56344d' stroke='#152434' stroke-width='4'/><circle cx='%d' cy='%d' r='21' fill='%s' stroke='#152434' stroke-width='4'/><path d='M%d %d V%d' stroke='%s' stroke-width='6'/>" % [y - 5, width - 124, center, y - 32, accent, center, y - 11, y + 17, secondary]
	return "<circle cx='%d' cy='%d' r='28' fill='%s' stroke='#152434' stroke-width='5'/><path d='M%d %d H%d' stroke='%s' stroke-width='8'/>" % [center, y, accent, center - 45, y + 15, center + 45, secondary]

static func _tiny_worker_svg(x: int, y: int, frame: int, accent: String) -> String:
	var bob_values: Array[int] = [0, -3, 0, 3]
	var bob: int = bob_values[posmod(frame, 4)]
	return "<g transform='translate(%d %d)'><ellipse cx='0' cy='26' rx='15' ry='5' fill='#000' opacity='.42'/><path d='M-6 7 L-9 24 M6 7 L9 24' stroke='#152434' stroke-width='6'/><rect x='-11' y='%d' width='22' height='24' rx='6' fill='#344b62' stroke='#152434' stroke-width='3'/><circle cx='0' cy='%d' r='9' fill='#d5a17c' stroke='#152434' stroke-width='3'/><rect x='-8' y='%d' width='16' height='5' rx='2' fill='%s'/></g>" % [x, y, -4 + bob, -15 + bob, -3 + bob, accent]

static func _resource_prop(x: int, y: int, accent: String, label: String) -> String:
	return "<g transform='translate(%d %d) scale(.62)'><ellipse cx='118' cy='210' rx='100' ry='26' fill='#000' opacity='.44' filter='url(#shadow)'/><path d='M15 165 L118 110 L221 165 L118 220Z' fill='#637687' stroke='#152434' stroke-width='6'/><path d='M118 40 V178' stroke='#dce7ed' stroke-width='12'/><circle cx='118' cy='39' r='22' fill='%s' stroke='#152434' stroke-width='5'/><ellipse cx='118' cy='92' rx='58' ry='20' fill='none' stroke='%s' stroke-width='6'/><ellipse cx='118' cy='135' rx='43' ry='16' fill='none' stroke='%s' stroke-width='6'/><text x='118' y='252' text-anchor='middle' fill='#f5fbff' font-family='sans-serif' font-size='20' font-weight='bold'>%s</text></g>" % [x, y, accent, accent, accent, label]

static func _vehicle_svg(x: int, y: int, accent: String, scale_value: float) -> String:
	return "<g transform='translate(%d %d) scale(%s)'><ellipse cx='120' cy='150' rx='105' ry='24' fill='#000' opacity='.44' filter='url(#shadow)'/><path d='M18 82 L112 25 L222 83 L126 142Z' fill='#30495e' stroke='#152434' stroke-width='6'/><path d='M62 64 L112 34 L178 67 L126 101Z' fill='%s' stroke='#152434' stroke-width='4'/><rect x='90' y='42' width='66' height='28' rx='7' fill='#173449' stroke='%s' stroke-width='4'/><path d='M28 92 H210' stroke='%s' stroke-width='7'/><circle cx='42' cy='105' r='15' fill='#111922' stroke='%s' stroke-width='4'/><circle cx='198' cy='105' r='15' fill='#111922' stroke='%s' stroke-width='4'/></g>" % [x, y, str(scale_value), accent, accent, accent, accent, accent]

static func _props_svg() -> String:
	var parts: Array[String] = []
	var crate_positions: Array[Vector2i] = [Vector2i(170,720), Vector2i(842,785), Vector2i(190,1000), Vector2i(805,1145), Vector2i(315,1265), Vector2i(720,1370)]
	for position: Vector2i in crate_positions:
		parts.append("<rect x='%d' y='%d' width='32' height='24' rx='4' fill='#765338' stroke='#152434' stroke-width='3'/><rect x='%d' y='%d' width='32' height='24' rx='4' fill='#3e6874' stroke='#152434' stroke-width='3'/>" % [position.x, position.y, position.x + 31, position.y + 15])
	var light_positions: Array[Vector2i] = [Vector2i(155,515), Vector2i(865,515), Vector2i(130,810), Vector2i(905,810), Vector2i(160,1070), Vector2i(875,1080), Vector2i(142,1310), Vector2i(908,1330)]
	for position: Vector2i in light_positions:
		parts.append("<path d='M%d %d V%d' stroke='#dce7ed' stroke-width='6'/><circle cx='%d' cy='%d' r='8' fill='#4ee7ff' filter='url(#glow)'/>" % [position.x, position.y, position.y - 58, position.x, position.y - 62])
	return "".join(parts)

static func _npc_atlas_svg() -> String:
	var parts: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='1024' height='256' viewBox='0 0 1024 256'>", _defs()]
	var accents: Array[String] = ["#4ee7ff", "#55f3d1", "#ff9a4a", "#f05b6b", "#ffd16a", "#56d6a2", "#8c54d8", "#72a8ff"]
	for role: int in range(8):
		var row: int = int(role / 4)
		var column: int = role % 4
		for frame: int in range(4):
			var x: int = column * 256 + frame * 64 + 32
			var y: int = row * 128 + 62
			parts.append(_npc_sprite_svg(x, y, role, frame, accents[role]))
	parts.append("</svg>")
	return "".join(parts)

static func _npc_sprite_svg(x: int, y: int, role: int, frame: int, accent: String) -> String:
	var colors: Array[String] = ["#344b62", "#365365", "#4a3d4b", "#3f4657", "#3d4b55", "#365258", "#483f50", "#384a5b"]
	var bob_values: Array[int] = [0, -3, 0, 3]
	var body: String = colors[posmod(role, colors.size())]
	var bob: int = bob_values[posmod(frame, bob_values.size())]
	var left_leg: int = -8 if frame % 2 == 0 else -2
	var right_leg: int = 8 if frame % 2 == 0 else 2
	return "<g transform='translate(%d %d)'><ellipse cx='0' cy='31' rx='18' ry='6' fill='#000' opacity='.45'/><path d='M-6 9 L%d 28 M6 9 L%d 28' stroke='#152434' stroke-width='7' stroke-linecap='round'/><rect x='-13' y='%d' width='26' height='28' rx='7' fill='%s' stroke='#152434' stroke-width='4'/><rect x='-10' y='%d' width='20' height='6' rx='2' fill='%s'/><circle cx='0' cy='%d' r='11' fill='#d5a17c' stroke='#152434' stroke-width='4'/><path d='M-13 %d H13 V%d H-13Z' fill='#24374a' stroke='#152434' stroke-width='3'/><rect x='-9' y='%d' width='18' height='5' rx='2' fill='%s'/><path d='M-12 %d L-22 %d M12 %d L24 %d' stroke='%s' stroke-width='6' stroke-linecap='round'/></g>" % [x, y, left_leg, right_leg, -5 + bob, body, 1 + bob, accent, -17 + bob, -28 + bob, -18 + bob, -25 + bob, accent, 3 + bob, 15 + bob, 3 + bob, 14 + bob, body]

static func npc_region(role_index: int, frame: int) -> Rect2:
	var role: int = posmod(role_index, 8)
	var row: int = int(role / 4)
	var column: int = role % 4
	return Rect2(float(column * 256 + posmod(frame, 4) * 64), float(row * 128), 64.0, 128.0)

static func _systems_atlas_svg() -> String:
	var parts: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='1024' height='768' viewBox='0 0 1024 768'>", _defs()]
	var ids: Array[String] = _system_ids()
	for index: int in range(ids.size()):
		var x: int = (index % 4) * 256
		var y: int = int(index / 4) * 256
		parts.append(_system_cell_svg(ids[index], x, y))
	parts.append("</svg>")
	return "".join(parts)

static func _system_ids() -> Array[String]:
	return ["resource_alloy", "resource_helium", "resource_cores", "defense_jammer", "defense_sentry", "defense_blast_doors", "defense_escape_tunnels", "threat_survey", "threat_patrol", "threat_riot", "threat_cyber", "mission_hidden"]

static func system_region(id: String) -> Rect2:
	var ids: Array[String] = _system_ids()
	var index: int = maxi(0, ids.find(id))
	return Rect2(float(index % 4) * 256.0, float(int(index / 4)) * 256.0, 256.0, 256.0)

static func _system_cell_svg(id: String, x: int, y: int) -> String:
	var accent: String = "#4ee7ff"
	var secondary: String = "#8c54d8"
	if id.contains("alloy") or id.contains("sentry") or id.contains("riot"):
		accent = "#ff9a4a"
		secondary = "#f05b6b"
	elif id.contains("cores") or id.contains("cyber"):
		accent = "#e6539b"
	elif id.contains("escape"):
		accent = "#56d6a2"
	var icon: String = ""
	if id.begins_with("resource_"):
		icon = "<path d='M128 44 V188' stroke='#dce7ed' stroke-width='13'/><circle cx='128' cy='43' r='22' fill='%s' stroke='#152434' stroke-width='5'/><ellipse cx='128' cy='95' rx='61' ry='22' fill='none' stroke='%s' stroke-width='7'/><ellipse cx='128' cy='141' rx='45' ry='17' fill='none' stroke='%s' stroke-width='7'/>" % [secondary, accent, accent]
	elif id == "defense_jammer":
		icon = "<path d='M128 45 V190' stroke='#dce7ed' stroke-width='14'/><circle cx='128' cy='42' r='18' fill='%s'/><path d='M78 82 Q128 42 178 82 M57 108 Q128 35 199 108' fill='none' stroke='%s' stroke-width='7'/>" % [secondary, accent]
	elif id == "defense_sentry":
		icon = "<rect x='116' y='112' width='24' height='78' fill='#354b5d'/><circle cx='128' cy='93' r='42' fill='#273d52' stroke='#152434' stroke-width='6'/><path d='M128 88 L212 51' stroke='%s' stroke-width='12'/><circle cx='215' cy='49' r='11' fill='%s'/>" % [accent, secondary]
	elif id == "defense_blast_doors":
		icon = "<rect x='52' y='48' width='152' height='148' rx='12' fill='#31475a' stroke='#152434' stroke-width='7'/><path d='M74 62 L182 182 M182 62 L74 182' stroke='%s' stroke-width='10'/><path d='M90 55 V190 M128 55 V190 M166 55 V190' stroke='#61778b' stroke-width='11'/>" % accent
	elif id == "defense_escape_tunnels":
		icon = "<path d='M45 178 Q128 35 211 178' fill='#293d4f' stroke='#152434' stroke-width='16'/><path d='M62 178 Q128 67 194 178' fill='none' stroke='%s' stroke-width='9'/><path d='M65 180 H191' stroke='%s' stroke-width='8'/>" % [accent, secondary]
	elif id == "threat_survey":
		icon = "<circle cx='128' cy='112' r='48' fill='#273d52' stroke='%s' stroke-width='7'/><circle cx='128' cy='112' r='21' fill='%s'/><path d='M128 160 V228 M80 112 H25 M176 112 H231 M128 64 V18' stroke='%s' stroke-width='8'/>" % [accent, secondary, accent]
	elif id == "threat_patrol":
		icon = _npc_sprite_svg(92, 145, 2, 1, accent) + _npc_sprite_svg(166, 145, 3, 2, secondary)
	elif id == "threat_riot":
		icon = "<rect x='82' y='80' width='93' height='120' rx='18' fill='#293e52' stroke='#152434' stroke-width='7'/><circle cx='128' cy='59' r='31' fill='#d5a17c' stroke='#152434' stroke-width='6'/><rect x='49' y='100' width='61' height='125' rx='17' fill='#1b2f43' stroke='%s' stroke-width='6'/><path d='M156 95 L220 145' stroke='%s' stroke-width='13'/>" % [accent, secondary]
	elif id == "threat_cyber":
		icon = "<circle cx='128' cy='104' r='66' fill='#162b40' stroke='%s' stroke-width='7'/><path d='M72 82 H184 M72 106 H184 M72 130 H184 M96 52 V158 M128 38 V170 M160 52 V158' stroke='%s' stroke-width='4'/><circle cx='105' cy='92' r='10' fill='%s'/><circle cx='151' cy='92' r='10' fill='%s'/><path d='M100 133 H156' stroke='%s' stroke-width='7'/>" % [accent, secondary, accent, accent, accent]
	else:
		icon = "<path d='M128 35 L205 78 V166 L128 211 L51 166 V78Z' fill='#2d4458' stroke='%s' stroke-width='7'/><path d='M80 118 H176 M128 70 V170' stroke='%s' stroke-width='12'/>" % [accent, secondary]
	return "<g transform='translate(%d %d)'><rect x='7' y='7' width='242' height='242' rx='28' fill='#101a27' stroke='%s' stroke-width='6'/>%s</g>" % [x, y, accent, icon]

static func _ui_atlas_svg() -> String:
	var parts: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='512' height='256' viewBox='0 0 512 256'>", _defs()]
	var ids: Array[String] = _ui_ids()
	for index: int in range(ids.size()):
		parts.append(_ui_icon_svg(ids[index], (index % 4) * 128, int(index / 4) * 128))
	parts.append("</svg>")
	return "".join(parts)

static func _ui_ids() -> Array[String]:
	return ["patrol", "heroes", "dermapack", "store", "alliance", "state", "rotate", "zoom"]

static func ui_region(id: String) -> Rect2:
	var ids: Array[String] = _ui_ids()
	var index: int = maxi(0, ids.find(id))
	return Rect2(float(index % 4) * 128.0, float(int(index / 4)) * 128.0, 128.0, 128.0)

static func _single_ui_svg(id: String) -> String:
	return "<svg xmlns='http://www.w3.org/2000/svg' width='256' height='256' viewBox='0 0 128 128'>" + _defs() + _ui_icon_svg(id, 0, 0) + "</svg>"

static func _ui_icon_svg(id: String, x: int, y: int) -> String:
	var icon: String = ""
	if id == "dermapack":
		icon = "<rect x='34' y='28' width='60' height='74' rx='18' fill='#26384b' stroke='#dbe8ef' stroke-width='4'/><rect x='42' y='39' width='44' height='34' rx='8' fill='#102435' stroke='#4ee7ff' stroke-width='4'/><path d='M30 55 L16 47 M98 55 L112 47' stroke='#9caebe' stroke-width='6'/><rect x='45' y='80' width='38' height='15' rx='5' fill='#0d1724' stroke='#8c54d8' stroke-width='3'/>"
	elif id == "patrol":
		icon = "<path d='M28 88 L64 25 L100 88Z' fill='#2e4c65' stroke='#dbe8ef' stroke-width='4'/><circle cx='64' cy='61' r='18' fill='#4ee7ff' stroke='#152434' stroke-width='4'/><path d='M64 31 V100' stroke='#8c54d8' stroke-width='5'/>"
	elif id == "heroes":
		icon = "<circle cx='42' cy='40' r='15' fill='#d5a17c'/><circle cx='86' cy='40' r='15' fill='#d5a17c'/><rect x='22' y='55' width='40' height='43' rx='10' fill='#30485e' stroke='#4ee7ff' stroke-width='3'/><rect x='66' y='55' width='40' height='43' rx='10' fill='#3d4358' stroke='#8c54d8' stroke-width='3'/>"
	elif id == "store":
		icon = "<path d='M25 51 H103 L92 29 H36Z' fill='#8c54d8' stroke='#152434' stroke-width='4'/><rect x='28' y='50' width='72' height='48' rx='7' fill='#31495d' stroke='#dbe8ef' stroke-width='4'/><path d='M43 58 V90 M64 58 V90 M85 58 V90' stroke='#4ee7ff' stroke-width='9'/>"
	elif id == "alliance":
		icon = "<circle cx='39' cy='43' r='17' fill='#4ee7ff' stroke='#152434' stroke-width='3'/><circle cx='89' cy='43' r='17' fill='#8c54d8' stroke='#152434' stroke-width='3'/><path d='M46 58 L64 86 L82 58' stroke='#dbe8ef' stroke-width='10'/><circle cx='64' cy='90' r='14' fill='#ffd16a' stroke='#152434' stroke-width='3'/>"
	elif id == "state":
		icon = "<path d='M24 90 L40 32 L64 18 L88 32 L104 90 L64 109Z' fill='#2f5267' stroke='#4ee7ff' stroke-width='4'/><circle cx='64' cy='67' r='18' fill='#8c54d8' stroke='#152434' stroke-width='3'/><path d='M64 32 V98' stroke='#dbe8ef' stroke-width='5'/>"
	elif id == "rotate":
		icon = "<path d='M29 83 A43 43 0 1 1 100 74' fill='none' stroke='#4ee7ff' stroke-width='9'/><path d='M88 22 L112 30 L96 49Z' fill='#4ee7ff'/><circle cx='64' cy='64' r='15' fill='#8c54d8'/>"
	else:
		icon = "<circle cx='53' cy='53' r='29' fill='#17283a' stroke='#4ee7ff' stroke-width='6'/><path d='M75 75 L108 108' stroke='#8c54d8' stroke-width='10'/><path d='M53 37 V69 M37 53 H69' stroke='#dbe8ef' stroke-width='6'/>"
	return "<g transform='translate(%d %d)'><rect x='8' y='8' width='112' height='112' rx='25' fill='#132030' stroke='#4ee7ff' stroke-width='5'/>%s</g>" % [x, y, icon]

static func _cutscene_svg(key: String) -> String:
	var title: String = "CRATER MARKET IS FALLING"
	var subtitle: String = "The Peacekeeper station strikes from orbit while the surviving MoonGoons race for the buried command tunnel."
	if key == "ghost_key":
		title = "THE NETWORK REMEMBERS"
		subtitle = "The Ghost Key opens Authority relays, forgotten tunnels, and every sealed door under the moon."
	elif key == "war_room":
		title = "THE DISTRICT CHOOSES A SIDE"
		subtitle = "Rival crews stop laughing. Peacekeeper Command finally says the Syndicate's name out loud."
	elif key == "finale":
		title = "CROWN THE CRATER"
		subtitle = "The Syndicate controls the lunar district. Above, the station watches. Below, a new underworld rises."
	var parts: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='720' height='1280' viewBox='0 0 720 1280'>", _defs()]
	parts.append("<rect width='720' height='1280' fill='url(#space)'/>")
	parts.append("<g transform='translate(-70 -320) scale(.78)'>" + _board_fragment() + "</g>")
	parts.append("<rect y='825' width='720' height='455' fill='#050911' opacity='.94'/><text x='360' y='912' text-anchor='middle' fill='#f5fbff' font-family='sans-serif' font-size='30' font-weight='bold'>%s</text>" % title)
	parts.append("<text x='360' y='970' text-anchor='middle' fill='#c9d7e2' font-family='sans-serif' font-size='17'>%s</text>" % subtitle.xml_escape())
	parts.append("<path d='M210 1180 H510' stroke='#4ee7ff' stroke-opacity='.5' stroke-width='5'/></svg>")
	return "".join(parts)

static func _attack_svg(key: String) -> String:
	var threat: String = "threat_" + key
	if threat not in _system_ids():
		threat = "threat_patrol"
	var parts: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='720' height='720' viewBox='0 0 720 720'>", _defs()]
	parts.append("<rect width='720' height='720' fill='url(#space)'/><g transform='translate(-5 -255) scale(.71)'>" + _board_fragment() + "</g><rect width='720' height='720' fill='#030711' opacity='.48'/>")
	parts.append(_system_cell_svg(threat, 232, 205))
	parts.append("<path d='M110 610 H610' stroke='#4ee7ff' stroke-width='6' opacity='.7'/></svg>")
	return "".join(parts)

static func _board_fragment() -> String:
	var svg: String = _board_svg()
	var start_index: int = svg.find(">") + 1
	var end_index: int = svg.rfind("</svg>")
	return svg.substr(start_index, end_index - start_index)
