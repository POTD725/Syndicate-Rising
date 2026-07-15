extends RefCounted
## Generates the canonical isometric lunar board and DermaPack as native vector textures.
## Keeping both assets in Godot guarantees matching browser, Android, animation, and cutscene output.

static var _board_cache: Texture2D
static var _dermapack_cache: Texture2D

static func board_texture() -> Texture2D:
	if _board_cache != null:
		return _board_cache
	var image: Image = Image.new()
	var error: Error = image.load_svg_from_string(_board_svg(), 1.0)
	if error != OK:
		push_error("Unable to generate isometric lunar board: %s" % error_string(error))
		return GradientTexture2D.new()
	_board_cache = ImageTexture.create_from_image(image)
	return _board_cache

static func dermapack_texture() -> Texture2D:
	if _dermapack_cache != null:
		return _dermapack_cache
	var image: Image = Image.new()
	var error: Error = image.load_svg_from_string(_dermapack_svg(), 1.0)
	if error != OK:
		push_error("Unable to generate DermaPack wearable icon: %s" % error_string(error))
		return GradientTexture2D.new()
	_dermapack_cache = ImageTexture.create_from_image(image)
	return _dermapack_cache

static func _board_svg() -> String:
	var parts: Array[String] = []
	parts.append("<svg xmlns='http://www.w3.org/2000/svg' width='960' height='1336' viewBox='0 0 960 1336'>")
	parts.append("""<defs>
<linearGradient id='space' x1='0' y1='0' x2='0' y2='1'><stop stop-color='#020611'/><stop offset='.42' stop-color='#081426'/><stop offset='1' stop-color='#10151e'/></linearGradient>
<linearGradient id='moon' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#747b86'/><stop offset='.45' stop-color='#4b515d'/><stop offset='1' stop-color='#252c36'/></linearGradient>
<linearGradient id='steel' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#52677c'/><stop offset='.5' stop-color='#202d3b'/><stop offset='1' stop-color='#0b111a'/></linearGradient>
<linearGradient id='glass' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#80ecff'/><stop offset='.48' stop-color='#246a9a'/><stop offset='1' stop-color='#7b2cbf'/></linearGradient>
<pattern id='grid' width='34' height='34' patternUnits='userSpaceOnUse'><path d='M34 0H0V34' fill='none' stroke='#b9c7d8' stroke-opacity='.12' stroke-width='2'/></pattern>
<filter id='shadow'><feGaussianBlur stdDeviation='9'/></filter>
<filter id='glow'><feGaussianBlur stdDeviation='5' result='b'/><feMerge><feMergeNode in='b'/><feMergeNode in='SourceGraphic'/></feMerge></filter>
</defs>""")
	parts.append("<rect width='960' height='1336' fill='url(#space)'/>")
	for index: int in range(110):
		var sx: int = (index * 83 + 31) % 960
		var sy: int = (index * 47 + 19) % 360
		var sr: int = 1 + index % 3
		parts.append("<circle cx='%d' cy='%d' r='%d' fill='#d9ecff' opacity='%.2f'/>" % [sx, sy, sr, 0.24 + float(index % 4) * 0.12])
	parts.append("<circle cx='120' cy='150' r='92' fill='#566172' opacity='.48'/><circle cx='92' cy='124' r='62' fill='#8791a1' opacity='.35'/><circle cx='145' cy='172' r='21' fill='#202a38' opacity='.6'/>")
	parts.append("<path d='M0 270 C135 225 240 282 360 244 C515 195 650 240 960 176 V1336 H0 Z' fill='url(#moon)'/>")
	parts.append("<path d='M0 325 C190 270 330 337 470 284 C628 224 772 283 960 236' fill='none' stroke='#aeb9c8' stroke-opacity='.24' stroke-width='5'/>")
	for crater_index: int in range(28):
		var cx: int = 28 + (crater_index * 137) % 920
		var cy: int = 318 + (crater_index * 89) % 980
		var cr: int = 10 + (crater_index % 5) * 7
		parts.append("<ellipse cx='%d' cy='%d' rx='%d' ry='%d' fill='#171e27' opacity='.34'/><path d='M%d %d Q%d %d %d %d' fill='none' stroke='#a4adba' stroke-opacity='.15' stroke-width='3'/>" % [cx, cy, cr, int(cr * 0.55), cx - cr, cy, cx, cy - int(cr * 0.42), cx + cr, cy])
	parts.append("<path d='M84 386 L476 250 L886 392 L492 536 Z' fill='#333b47' stroke='#8e9cad' stroke-width='4'/><path d='M80 390 L482 532 L887 393' fill='none' stroke='#d3dbe5' stroke-opacity='.24' stroke-width='12'/>")
	parts.append("<path d='M58 702 L470 553 L907 711 L493 863 Z' fill='#303844' stroke='#8e9cad' stroke-width='4'/><path d='M61 706 L493 858 L907 712' fill='none' stroke='#d3dbe5' stroke-opacity='.21' stroke-width='12'/>")
	parts.append("<path d='M62 1015 L470 868 L901 1022 L491 1173 Z' fill='#2c3540' stroke='#8392a4' stroke-width='4'/><path d='M64 1018 L491 1168 L900 1024' fill='none' stroke='#d3dbe5' stroke-opacity='.18' stroke-width='12'/>")
	parts.append("<rect x='18' y='252' width='924' height='1066' fill='url(#grid)' opacity='.38'/>")
	parts.append(_station_svg())
	var buildings: Array[Dictionary] = [
		{"x":150,"y":150,"w":190,"h":118,"label":"BOSS OFFICE","kind":"boss","color":"#88464e"},
		{"x":142,"y":278,"w":220,"h":150,"label":"COMMAND CENTER","kind":"command","color":"#9d3938"},
		{"x":370,"y":300,"w":224,"h":150,"label":"RESEARCH CENTER","kind":"research","color":"#2f7c9d"},
		{"x":628,"y":343,"w":220,"h":150,"label":"WEAPONS WORKSHOP","kind":"weapons","color":"#9a652d"},
		{"x":54,"y":495,"w":244,"h":158,"label":"HACKER DEN","kind":"hacker","color":"#663e92"},
		{"x":356,"y":526,"w":235,"h":154,"label":"DERMA LAB","kind":"clinic","color":"#247d68"},
		{"x":660,"y":598,"w":230,"h":154,"label":"RUNNER GARAGE","kind":"garage","color":"#344f83"},
		{"x":50,"y":743,"w":246,"h":158,"label":"SMUGGLER DOCK","kind":"tunnel","color":"#7d5935"},
		{"x":344,"y":764,"w":252,"h":160,"label":"BLACK MARKET","kind":"market","color":"#6e425e"},
		{"x":654,"y":835,"w":236,"h":158,"label":"SHARPSHOOTER RANGE","kind":"range","color":"#8a4c35"},
		{"x":290,"y":1002,"w":264,"h":166,"label":"ENFORCER ACADEMY","kind":"gym","color":"#8d3d3a"},
		{"x":674,"y":1096,"w":220,"h":150,"label":"CREW QUARTERS","kind":"bunks","color":"#526075"}
	]
	for building: Dictionary in buildings:
		parts.append(_building_svg(int(building["x"]), int(building["y"]), int(building["w"]), int(building["h"]), String(building["label"]), String(building["kind"]), String(building["color"])))
	parts.append(_surface_props_svg())
	parts.append("</svg>")
	return "".join(parts)

static func _station_svg() -> String:
	return """<g transform='translate(548 56) rotate(-6)'>
<ellipse cx='174' cy='92' rx='192' ry='42' fill='#000' opacity='.55' filter='url(#shadow)'/>
<path d='M12 62 L56 22 H304 L354 65 L326 126 H49 Z' fill='url(#steel)' stroke='#8ca6bd' stroke-width='5'/>
<path d='M68 31 L89 6 H275 L300 31' fill='#27394b' stroke='#61829e' stroke-width='4'/>
<rect x='77' y='54' width='217' height='48' rx='15' fill='#111b27' stroke='#5fcfff' stroke-width='3'/>
<text x='186' y='75' text-anchor='middle' fill='#d9f4ff' font-family='sans-serif' font-weight='bold' font-size='17'>PEACEKEEPER</text>
<text x='186' y='95' text-anchor='middle' fill='#8bdbff' font-family='sans-serif' font-size='13'>ORBITAL STATION</text>
<path d='M25 73 L-42 48 V92 L35 102 M330 73 L411 47 V95 L322 105' fill='#1d2c3c' stroke='#678ca8' stroke-width='4'/>
<circle cx='55' cy='112' r='6' fill='#ff4767' filter='url(#glow)'/><circle cx='93' cy='112' r='6' fill='#4f91ff' filter='url(#glow)'/><circle cx='276' cy='112' r='6' fill='#4f91ff' filter='url(#glow)'/><circle cx='315' cy='112' r='6' fill='#ff4767' filter='url(#glow)'/>
<path d='M122 126 L145 162 H220 L245 126' fill='#162536' stroke='#5cbfff' stroke-width='4'/>
</g>"""

static func _building_svg(x: int, y: int, width: int, height: int, label: String, kind: String, accent: String) -> String:
	var roof_depth: int = 34
	var wall_height: int = height - 48
	var svg: String = "<g transform='translate(%d %d)'>" % [x, y]
	svg += "<ellipse cx='%d' cy='%d' rx='%d' ry='28' fill='#000' opacity='.47' filter='url(#shadow)'/>" % [int(width * 0.52), height + 21, int(width * 0.55)]
	svg += "<path d='M0 %d L%d 0 L%d %d L%d %d Z' fill='%s' stroke='#aeb9c5' stroke-width='4'/>" % [roof_depth, int(width * 0.48), width, roof_depth, int(width * 0.52), height, accent]
	svg += "<path d='M8 %d L%d 9 L%d %d L%d %d Z' fill='#1b2531' stroke='#657687' stroke-width='3'/>" % [roof_depth + 8, int(width * 0.48), width - 8, roof_depth + 8, int(width * 0.52), wall_height]
	svg += "<path d='M8 %d L%d %d L%d %d L%d %d Z' fill='#273544' opacity='.96'/>" % [roof_depth + 8, int(width * 0.52), wall_height, int(width * 0.52), height - 8, 8, int(height * 0.56)]
	svg += "<path d='M%d %d L%d %d L%d %d L%d %d Z' fill='#111a25'/>" % [width - 8, roof_depth + 8, int(width * 0.52), wall_height, int(width * 0.52), height - 8, width - 8, int(height * 0.58)]
	svg += "<path d='M22 %d L%d 26 L%d %d L%d %d Z' fill='#202d3b' stroke='%s' stroke-width='3'/>" % [roof_depth + 9, int(width * 0.48), width - 22, roof_depth + 9, int(width * 0.52), height - 27, accent]
	svg += _equipment_svg(kind, width, height, accent)
	for panel: int in range(4):
		var px: int = 20 + panel * int((width - 44) / 4.0)
		svg += "<rect x='%d' y='%d' width='%d' height='9' rx='3' fill='#69dfff' opacity='.42'/>" % [px, height - 33, maxi(16, int((width - 60) / 5.0))]
	svg += "<path d='M6 %d L%d %d M%d %d L%d %d' stroke='#d8e1e9' stroke-width='8' stroke-linecap='round'/>" % [int(height * 0.58), int(width * 0.52), height - 7, width - 7, int(height * 0.58), int(width * 0.52), height - 7]
	svg += "<rect x='%d' y='-22' width='%d' height='29' rx='9' fill='#07101b' stroke='%s' stroke-width='3'/><text x='%d' y='-3' text-anchor='middle' fill='#f3f8ff' font-family='sans-serif' font-weight='bold' font-size='13'>%s</text>" % [int(width * 0.08), int(width * 0.84), accent, int(width * 0.5), label]
	svg += "<rect x='%d' y='9' width='42' height='23' rx='8' fill='#235e2e' stroke='#8cff84' stroke-width='2'/><text x='%d' y='25' text-anchor='middle' fill='#d9ffd2' font-family='sans-serif' font-weight='bold' font-size='12'>L24</text>" % [int(width * 0.5) - 21, int(width * 0.5)]
	svg += "</g>"
	return svg

static func _equipment_svg(kind: String, width: int, height: int, accent: String) -> String:
	var center_x: int = int(width * 0.50)
	var center_y: int = int(height * 0.47)
	match kind:
		"research":
			return "<circle cx='%d' cy='%d' r='23' fill='#0b1d2a' stroke='#60e8ff' stroke-width='4'/><circle cx='%d' cy='%d' r='11' fill='#66dfff' opacity='.66' filter='url(#glow)'/><rect x='%d' y='%d' width='20' height='42' rx='8' fill='#162838' stroke='#74ecff' stroke-width='3'/><rect x='%d' y='%d' width='20' height='42' rx='8' fill='#261838' stroke='#c46fff' stroke-width='3'/>" % [center_x, center_y, center_x, center_y, center_x - 62, center_y - 20, center_x + 42, center_y - 20]
		"weapons":
			return "<path d='M35 %d L%d %d M42 %d L%d %d M50 %d L%d %d' stroke='#e8edf2' stroke-width='6' stroke-linecap='round'/><rect x='%d' y='%d' width='54' height='33' rx='5' fill='#402825' stroke='#ff9e55' stroke-width='3'/>" % [center_y - 18, width - 45, center_y + 2, center_y + 3, width - 52, center_y + 23, center_y + 24, width - 60, center_y + 43, center_x - 27, center_y - 22]
		"hacker":
			var result: String = ""
			for monitor: int in range(4):
				var mx: int = 24 + monitor * int((width - 50) / 4.0)
				result += "<rect x='%d' y='%d' width='42' height='31' rx='5' fill='#080d18' stroke='#a35cff' stroke-width='3'/><path d='M%d %d H%d M%d %d H%d' stroke='#59e8ff' stroke-width='3'/>" % [mx, center_y - 27, mx + 8, center_y - 15, mx + 34, mx + 8, center_y - 7, mx + 27]
			return result
		"clinic":
			return "<rect x='%d' y='%d' width='92' height='37' rx='7' fill='#dce8eb'/><path d='M%d %d H%d M%d %d V%d' stroke='#40dcb4' stroke-width='13'/><rect x='%d' y='%d' width='44' height='38' rx='6' fill='#0b1724' stroke='#62dfff' stroke-width='3'/>" % [center_x - 73, center_y - 14, center_x - 46, center_y + 4, center_x - 7, center_x - 26, center_y - 16, center_y + 24, center_x + 37, center_y - 18]
		"garage":
			return "<path d='M35 %d H%d L%d %d H58 Z' fill='#314d68' stroke='#74caff' stroke-width='4'/><circle cx='70' cy='%d' r='13' fill='#060a0f'/><circle cx='%d' cy='%d' r='13' fill='#060a0f'/><rect x='%d' y='%d' width='61' height='31' rx='8' fill='#542b65' stroke='#d15dff' stroke-width='3'/>" % [center_y - 7, width - 36, width - 55, center_y + 32, center_y + 35, width - 72, center_y + 35, center_x - 30, center_y - 25]
		"tunnel":
			return "<path d='M28 %d Q%d %d %d %d' fill='#0a121c' stroke='#8a9aab' stroke-width='9'/><path d='M52 %d H%d' stroke='#57dfff' stroke-width='4'/><rect x='48' y='%d' width='42' height='28' fill='#8b5d3a'/><rect x='%d' y='%d' width='42' height='28' fill='#496674'/>" % [center_y + 47, center_x, center_y - 69, width - 28, center_y + 47, width - 52, center_y + 12, width - 91, center_y + 12]
		"market":
			var market_svg: String = ""
			for row: int in range(2):
				for column: int in range(4):
					var bx: int = 26 + column * int((width - 55) / 4.0)
					var by: int = center_y - 29 + row * 42
					market_svg += "<rect x='%d' y='%d' width='39' height='27' rx='4' fill='%s' stroke='#d7ae76' stroke-width='2'/><path d='M%d %d L%d %d M%d %d L%d %d' stroke='#efd2a3' stroke-width='2' opacity='.6'/>" % [bx, by, accent, bx + 4, by + 4, bx + 35, by + 23, bx + 35, by + 4, bx + 4, by + 23]
			return market_svg
		"range":
			var range_svg: String = ""
			for target: int in range(3):
				var tx: int = 45 + target * int((width - 80) / 3.0)
				range_svg += "<circle cx='%d' cy='%d' r='24' fill='#f4efe4'/><circle cx='%d' cy='%d' r='15' fill='#c83d50'/><circle cx='%d' cy='%d' r='6' fill='#fff0a2'/>" % [tx, center_y, tx, center_y, tx, center_y]
			return range_svg
		"gym":
			return "<line x1='44' y1='%d' x2='44' y2='%d' stroke='#c9d4df' stroke-width='5'/><circle cx='44' cy='%d' r='18' fill='#8e2739'/><line x1='94' y1='%d' x2='%d' y2='%d' stroke='#dbe2e8' stroke-width='9'/><circle cx='88' cy='%d' r='16' fill='#273746'/><circle cx='%d' cy='%d' r='16' fill='#273746'/>" % [center_y - 42, center_y + 43, center_y + 34, center_y + 14, width - 55, center_y + 14, center_y + 14, width - 49, center_y + 14]
		"bunks":
			var bunk_svg: String = ""
			for bunk: int in range(3):
				var bx2: int = 24 + bunk * int((width - 44) / 3.0)
				bunk_svg += "<rect x='%d' y='%d' width='52' height='18' rx='5' fill='#75869a'/><rect x='%d' y='%d' width='52' height='18' rx='5' fill='#526175'/><circle cx='%d' cy='%d' r='6' fill='#e0b488'/>" % [bx2, center_y - 25, bx2, center_y + 17, bx2 + 9, center_y - 17]
			return bunk_svg
		"boss":
			return "<rect x='%d' y='%d' width='108' height='39' rx='7' fill='#4f2e3f' stroke='#d887b6' stroke-width='3'/><circle cx='%d' cy='%d' r='22' fill='#172335' stroke='#f0cd72' stroke-width='4'/><path d='M%d %d L%d %d L%d %d Z' fill='#ffd56b'/>" % [center_x - 54, center_y, center_x, center_y - 24, center_x - 10, center_y - 25, center_x, center_y - 42, center_x + 10, center_y - 25]
		_:
			return "<rect x='%d' y='%d' width='118' height='54' rx='9' fill='#361e20' stroke='#ff6e59' stroke-width='4'/><circle cx='%d' cy='%d' r='31' fill='#101b27' stroke='#61e6ff' stroke-width='4'/><path d='M%d %d H%d M%d %d V%d' stroke='#ffca69' stroke-width='4'/>" % [center_x - 59, center_y - 14, center_x, center_y, center_x - 18, center_y, center_x + 18, center_x, center_y - 18, center_y + 18]

static func _surface_props_svg() -> String:
	return """<g opacity='.96'>
<path d='M42 344 H122 V372 H42 Z' fill='#1e3043' stroke='#5daee5' stroke-width='3'/><circle cx='57' cy='379' r='10' fill='#05080c'/><circle cx='105' cy='379' r='10' fill='#05080c'/>
<path d='M812 286 H899 V317 H812 Z' fill='#26384a' stroke='#7fc7ff' stroke-width='3'/><circle cx='829' cy='324' r='10' fill='#05080c'/><circle cx='881' cy='324' r='10' fill='#05080c'/>
<path d='M84 1190 V1129 M67 1148 H101 M76 1132 L92 1164' stroke='#69e8ff' stroke-width='5'/><circle cx='84' cy='1124' r='7' fill='#ff5e72'/>
<path d='M910 972 V896 M889 921 H931' stroke='#7bdfff' stroke-width='6'/><circle cx='910' cy='888' r='8' fill='#ff5e72'/>
<g transform='translate(30 955)'><path d='M0 47 L39 0 L79 47 Z' fill='#1c2d3d' stroke='#78bce9' stroke-width='4'/><rect x='26' y='47' width='27' height='42' fill='#132332'/><circle cx='40' cy='25' r='8' fill='#6ceaff'/></g>
<g transform='translate(831 451)'><path d='M0 47 L39 0 L79 47 Z' fill='#1c2d3d' stroke='#78bce9' stroke-width='4'/><rect x='26' y='47' width='27' height='42' fill='#132332'/><circle cx='40' cy='25' r='8' fill='#6ceaff'/></g>
</g>"""

static func _dermapack_svg() -> String:
	return """<svg xmlns='http://www.w3.org/2000/svg' width='256' height='256' viewBox='0 0 256 256'>
<defs>
 <linearGradient id='case' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#3a4c62'/><stop offset='.48' stop-color='#101a27'/><stop offset='1' stop-color='#050910'/></linearGradient>
 <linearGradient id='glass' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#78efff'/><stop offset='.45' stop-color='#237fae'/><stop offset='1' stop-color='#752bc7'/></linearGradient>
 <filter id='glow'><feGaussianBlur stdDeviation='4' result='b'/><feMerge><feMergeNode in='b'/><feMergeNode in='SourceGraphic'/></feMerge></filter>
</defs>
<ellipse cx='128' cy='222' rx='76' ry='15' fill='#000' opacity='.45'/>
<path d='M30 109 C20 150 41 201 83 225 L102 206 C66 178 57 143 70 111 Z' fill='#111b27' stroke='#65758a' stroke-width='7'/>
<path d='M226 109 C236 150 215 201 173 225 L154 206 C190 178 199 143 186 111 Z' fill='#111b27' stroke='#65758a' stroke-width='7'/>
<path d='M54 89 Q63 47 105 31 H151 Q193 47 202 89 L190 178 Q184 207 153 218 H103 Q72 207 66 178 Z' fill='url(#case)' stroke='#94a8bb' stroke-width='7'/>
<path d='M82 83 Q88 58 111 50 H145 Q168 58 174 83 L167 132 Q163 150 145 157 H111 Q93 150 89 132 Z' fill='#07101b' stroke='#4bc8ff' stroke-width='5'/>
<path d='M96 78 Q103 62 117 59 H139 Q153 62 160 78 L155 121 Q151 137 137 141 H119 Q105 137 101 121 Z' fill='url(#glass)' opacity='.92' filter='url(#glow)'/>
<path d='M110 74 L146 74 L151 97 L128 124 L105 97 Z' fill='#07111e' opacity='.66'/>
<circle cx='128' cy='95' r='13' fill='#8df5ff' opacity='.9'/><path d='M128 80 V110 M113 95 H143' stroke='#fff' stroke-width='4' opacity='.86'/>
<rect x='83' y='164' width='90' height='30' rx='12' fill='#0b121d' stroke='#8a5cff' stroke-width='4'/>
<rect x='94' y='173' width='22' height='12' rx='4' fill='#65edff'/><rect x='122' y='173' width='18' height='12' rx='4' fill='#a566ff'/><rect x='146' y='173' width='16' height='12' rx='4' fill='#ff9b45'/>
<circle cx='76' cy='139' r='9' fill='#ff527e' filter='url(#glow)'/><circle cx='180' cy='139' r='9' fill='#56ecff' filter='url(#glow)'/>
<path d='M54 102 L32 95 M202 102 L224 95' stroke='#88a0b7' stroke-width='7' stroke-linecap='round'/>
</svg>"""
