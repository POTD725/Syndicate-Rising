extends RefCounted
## Complete original 2.5D art library for the playable lunar base, Operations, NPCs,
## UI, story scenes, and Peacekeeper attacks. Every screen draws from this one source.

static var _cache: Dictionary = {}

static func board_texture() -> Texture2D:
	return _texture("board", _board_svg())

static func npc_atlas() -> Texture2D:
	return _texture("npc_atlas", _npc_atlas_svg())

static func systems_atlas() -> Texture2D:
	return _texture("systems_atlas", _systems_atlas_svg())

static func ui_atlas() -> Texture2D:
	return _texture("ui_atlas", _ui_atlas_svg())

static func dermapack_texture() -> Texture2D:
	return _texture("dermapack", _single_ui_svg("dermapack"))

static func cutscene_texture(key: String) -> Texture2D:
	return _texture("cutscene_" + key, _cutscene_svg(key))

static func attack_texture(key: String) -> Texture2D:
	return _texture("attack_" + key, _attack_svg(key))

static func _texture(key: String, svg: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key] as Texture2D
	var image := Image.new()
	var result := image.load_svg_from_string(svg, 1.0)
	if result != OK:
		push_error("Unable to generate Syndicate art %s: %s" % [key, error_string(result)])
		return GradientTexture2D.new()
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture

static func _defs() -> String:
	return """<defs>
<linearGradient id='space' x1='0' y1='0' x2='0' y2='1'><stop stop-color='#030711'/><stop offset='.38' stop-color='#0a1423'/><stop offset='1' stop-color='#1a2330'/></linearGradient>
<linearGradient id='moon' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#7d8795'/><stop offset='.45' stop-color='#596473'/><stop offset='1' stop-color='#353f4c'/></linearGradient>
<linearGradient id='steel' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#657f96'/><stop offset='.52' stop-color='#31485d'/><stop offset='1' stop-color='#182738'/></linearGradient>
<linearGradient id='glass' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#8bf5ff'/><stop offset='.46' stop-color='#2a86b8'/><stop offset='1' stop-color='#8547ca'/></linearGradient>
<linearGradient id='floor' x1='0' y1='0' x2='1' y2='1'><stop stop-color='#8898a8'/><stop offset='1' stop-color='#607386'/></linearGradient>
<filter id='shadow'><feGaussianBlur stdDeviation='10'/></filter>
<filter id='glow'><feGaussianBlur stdDeviation='5' result='b'/><feMerge><feMergeNode in='b'/><feMergeNode in='SourceGraphic'/></feMerge></filter>
<pattern id='grid' width='42' height='42' patternUnits='userSpaceOnUse'><path d='M42 0H0V42' fill='none' stroke='#d8e4ed' stroke-opacity='.08' stroke-width='2'/></pattern>
</defs>"""

static func _board_svg() -> String:
	return "<svg xmlns='http://www.w3.org/2000/svg' width='1024' height='1536' viewBox='0 0 1024 1536'>" + _defs() + _world_content() + "</svg>"

static func _world_content() -> String:
	var p: Array[String] = []
	p.append("<rect width='1024' height='1536' fill='url(#space)'/>")
	for i in range(150):
		var sx := (i * 89 + 31) % 1024
		var sy := (i * 47 + 17) % 390
		var sr := 1 + i % 3
		p.append("<circle cx='%d' cy='%d' r='%d' fill='#d7edff' opacity='%.2f'/>" % [sx, sy, sr, 0.28 + float(i % 4) * 0.11])
	p.append("<path d='M0 360 L100 310 L220 340 L350 280 L470 335 L590 276 L720 334 L870 286 L1024 350 V1536 H0Z' fill='#313a4a'/>")
	p.append("<path d='M0 410 L110 360 L260 392 L390 345 L520 402 L700 350 L860 398 L1024 352 V1536 H0Z' fill='url(#moon)'/>")
	for i in range(26):
		var cx := 50 + (i * 149) % 930
		var cy := 480 + (i * 97) % 1010
		var rx := 18 + (i % 5) * 11
		p.append("<ellipse cx='%d' cy='%d' rx='%d' ry='%d' fill='#202a35' opacity='.52'/><path d='M%d %d Q%d %d %d %d' fill='none' stroke='#b8c3cc' stroke-opacity='.18' stroke-width='3'/>" % [cx, cy, rx, int(rx * .46), cx-rx, cy, cx, cy-int(rx*.35), cx+rx, cy])
	p.append(_roads_svg())
	p.append("<rect x='22' y='455' width='980' height='1055' fill='url(#grid)' opacity='.35'/>")
	p.append(_station_svg())
	var buildings: Array[Dictionary] = [
		{"id":"backroom","x":52,"y":490,"w":285,"h":220,"a":"#4ee7ff","b":"#8c54d8","label":"SYNDICATE COMMAND"},
		{"id":"boss_office","x":360,"y":500,"w":235,"h":188,"a":"#ffd16a","b":"#8c54d8","label":"BOSS'S OFFICE"},
		{"id":"black_research","x":385,"y":435,"w":280,"h":220,"a":"#55f3d1","b":"#6ca6ff","label":"BLACK RESEARCH"},
		{"id":"weapons_workshop","x":690,"y":530,"w":285,"h":220,"a":"#ff9a4a","b":"#f05b6b","label":"WEAPONS WORKSHOP"},
		{"id":"signal_den","x":30,"y":735,"w":285,"h":220,"a":"#4ee7ff","b":"#e6539b","label":"HACKER TRAINING"},
		{"id":"clinic","x":365,"y":720,"w":285,"h":220,"a":"#56d6a2","b":"#4ee7ff","label":"STREET CLINIC"},
		{"id":"chop_shop","x":690,"y":785,"w":285,"h":220,"a":"#4ee7ff","b":"#8c54d8","label":"RUNNER GARAGE"},
		{"id":"tunnel","x":28,"y":1005,"w":285,"h":220,"a":"#4ee7ff","b":"#ff9a4a","label":"SMUGGLER DOCK"},
		{"id":"black_market","x":365,"y":995,"w":290,"h":225,"a":"#ffd16a","b":"#e6539b","label":"BLACK MARKET"},
		{"id":"sharpshooter_range","x":690,"y":1030,"w":285,"h":220,"a":"#f05b6b","b":"#ffd16a","label":"SHARPSHOOTER RANGE"},
		{"id":"enforcer_gym","x":175,"y":1270,"w":310,"h":235,"a":"#ff9a4a","b":"#f05b6b","label":"ENFORCER TRAINING"},
		{"id":"bunks","x":570,"y":1290,"w":285,"h":215,"a":"#72a8ff","b":"#8c54d8","label":"CREW QUARTERS"}
	]
	for building in buildings:
		p.append(_building_svg(building))
	p.append(_resource_svg("alloy", 8, 1240, "#ff9a4a", "#ffd16a"))
	p.append(_resource_svg("helium", 790, 650, "#4ee7ff", "#8c54d8"))
	p.append(_resource_svg("cores", 790, 1280, "#4ee7ff", "#e6539b"))
	p.append(_vehicle_svg("skiff", 105, 900, 0.75))
	p.append(_vehicle_svg("rover", 480, 1165, 0.78))
	p.append(_vehicle_svg("police", 820, 450, 0.70))
	p.append(_props_svg())
	return "".join(p)

static func _roads_svg() -> String:
	var p: Array[String] = []
	for cy in [610, 850, 1090, 1320]:
		p.append("<path d='M70 %d L512 %d L954 %d L512 %d Z' fill='#747f90' stroke='#404b5b' stroke-width='6'/>" % [cy, cy-155, cy, cy+155])
		p.append("<path d='M135 %d L512 %d L889 %d L512 %d Z' fill='#606d7e' stroke='#9aa8b5' stroke-width='3'/>" % [cy, cy-124, cy, cy+124])
	for y in range(545, 1500, 110):
		p.append("<path d='M464 %d L560 %d' stroke='#d7e0e8' stroke-opacity='.72' stroke-width='7'/>" % [y, y])
	p.append("<path d='M458 460 L566 460 L646 1536 L378 1536 Z' fill='#697687' stroke='#435060' stroke-width='6'/>")
	for x in [112, 912]:
		for y in range(510, 1480, 78):
			p.append("<path d='M%d %d V%d M%d %d H%d' stroke='#26394b' stroke-width='7'/><path d='M%d %d H%d' stroke='#8297aa' stroke-width='3'/>" % [x, y, y+48, x-24, y+12, x+24, x-20, y+30, x+20])
	return "".join(p)

static func _station_svg() -> String:
	return """<g transform='translate(110 35)'>
<ellipse cx='405' cy='245' rx='345' ry='62' fill='#000' opacity='.55' filter='url(#shadow)'/>
<path d='M35 205 L204 135 L294 182 L516 182 L608 135 L780 205 L650 270 L160 270Z' fill='#263e55' stroke='#162333' stroke-width='8'/>
<path d='M74 208 L220 158 L294 198 H516 L595 158 L744 208 L622 245 H190Z' fill='#3c5b75' stroke='#4ee7ff' stroke-width='5'/>
<circle cx='405' cy='202' r='138' fill='#2c465f' stroke='#162333' stroke-width='10'/><circle cx='405' cy='202' r='104' fill='#3f647e' stroke='#4ee7ff' stroke-width='5'/><circle cx='405' cy='202' r='65' fill='#1b3247' stroke='#8c54d8' stroke-width='6'/><circle cx='405' cy='202' r='26' fill='#4ee7ff' stroke='#162333' stroke-width='5'/>
<rect x='150' y='165' width='120' height='80' rx='18' fill='#22384d' stroke='#162333' stroke-width='7'/><rect x='540' y='165' width='120' height='80' rx='18' fill='#22384d' stroke='#162333' stroke-width='7'/>
<path d='M172 184 H248 M172 202 H248 M172 220 H248 M562 184 H638 M562 202 H638 M562 220 H638' stroke='#4ee7ff' stroke-width='5'/>
<path d='M405 64 V15' stroke='#d9e5ec' stroke-width='9'/><circle cx='405' cy='12' r='12' fill='#f05b6b' stroke='#162333' stroke-width='4'/>
<text x='405' y='332' text-anchor='middle' fill='#dff6ff' font-family='sans-serif' font-size='20' font-weight='bold'>PEACEKEEPER ORBITAL STATION</text>
</g>"""

static func _building_svg(data: Dictionary) -> String:
	var id := String(data["id"])
	var x := int(data["x"])
	var y := int(data["y"])
	var w := int(data["w"])
	var h := int(data["h"])
	var a := String(data["a"])
	var b := String(data["b"])
	var label := String(data["label"])
	var cx := int(w * .5)
	var p: Array[String] = []
	p.append("<g transform='translate(%d %d)'>" % [x, y])
	p.append("<ellipse cx='%d' cy='%d' rx='%d' ry='31' fill='#000' opacity='.5' filter='url(#shadow)'/>" % [cx, h+21, int(w*.52)])
	p.append("<path d='M0 %d L%d 0 L%d %d L%d %d Z' fill='url(#floor)' stroke='#172433' stroke-width='6'/>" % [int(h*.56), cx, w, int(h*.56), cx, h])
	p.append("<path d='M0 %d L%d %d L%d %d L%d %d Z' fill='#4d6073' stroke='#172433' stroke-width='6'/>" % [int(h*.56), cx, h, cx, h+30, 0, int(h*.56)+30])
	p.append("<path d='M%d %d L%d %d L%d %d L%d %d Z' fill='#3b4e61' stroke='#172433' stroke-width='6'/>" % [w, int(h*.56), cx, h, cx, h+30, w, int(h*.56)+30])
	p.append("<path d='M28 %d L%d 35 L%d %d L%d %d Z' fill='#243647' stroke='#172433' stroke-width='6'/>" % [int(h*.48), cx, w-28, int(h*.48), cx, int(h*.80)])
	p.append("<path d='M35 %d L%d 48 L%d %d L%d %d Z' fill='%s' stroke='#172433' stroke-width='5'/>" % [int(h*.30), cx, w-35, int(h*.30), cx, int(h*.50), b])
	p.append("<path d='M35 %d V%d L%d %d V%d M%d %d V%d L%d %d V%d' fill='none' stroke='#dce7ee' stroke-width='10' stroke-linecap='round'/>" % [int(h*.30), int(h*.64), cx, int(h*.83), int(h*.50), w-35, int(h*.30), int(h*.64), cx, int(h*.83), int(h*.50)])
	p.append("<path d='M48 %d L%d 66 L%d %d L%d %d Z' fill='#172635' stroke='%s' stroke-width='4'/>" % [int(h*.38), cx, w-48, int(h*.38), cx, int(h*.70), a])
	p.append(_equipment_svg(id, w, h, a, b))
	for px in [42, w-54]:
		p.append("<rect x='%d' y='%d' width='12' height='70' rx='5' fill='#d8e5ec' stroke='#172433' stroke-width='3'/><circle cx='%d' cy='%d' r='7' fill='%s' filter='url(#glow)'/>" % [px, int(h*.43), px+6, int(h*.44), a])
	p.append(_npc_svg(52, int(h*.69), id.hash() % 8, 1, .55, a))
	p.append(_npc_svg(w-72, int(h*.70), (id.hash()+3) % 8, 2, .55, b))
	p.append("<rect x='18' y='%d' width='%d' height='35' rx='12' fill='#101a27' stroke='%s' stroke-width='4'/><text x='%d' y='%d' text-anchor='middle' fill='#f5fbff' font-family='sans-serif' font-size='14' font-weight='bold'>%s</text>" % [h+28, w-36, a, cx, h+51, label])
	p.append("<rect x='%d' y='9' width='52' height='30' rx='10' fill='#235e2e' stroke='#8cff84' stroke-width='3'/><text x='%d' y='30' text-anchor='middle' fill='#e3ffdc' font-family='sans-serif' font-size='14' font-weight='bold'>L24</text>" % [cx-26, cx])
	p.append("</g>")
	return "".join(p)

static func _equipment_svg(id: String, w: int, h: int, a: String, b: String) -> String:
	var cx := int(w*.5)
	var y := int(h*.47)
	match id:
		"backroom":
			return "<circle cx='%d' cy='%d' r='34' fill='#102331' stroke='%s' stroke-width='5'/><circle cx='%d' cy='%d' r='20' fill='#21475a' stroke='%s' stroke-width='4'/><path d='M%d %d H%d M%d %d V%d' stroke='%s' stroke-width='4'/><rect x='48' y='%d' width='58' height='36' rx='6' fill='#102231' stroke='%s' stroke-width='4'/><rect x='%d' y='%d' width='58' height='36' rx='6' fill='#102231' stroke='%s' stroke-width='4'/>" % [cx,y,a,cx,y,b,cx-22,y,cx+22,cx,y-22,y+22,a,y-13,a,w-106,y-13,b]
		"black_research":
			var s := ""
			for px in [int(w*.28), int(w*.50), int(w*.72)]:
				s += "<rect x='%d' y='%d' width='38' height='62' rx='13' fill='#173142' stroke='%s' stroke-width='4'/><ellipse cx='%d' cy='%d' rx='12' ry='22' fill='%s' opacity='.72' filter='url(#glow)'/>" % [px-19,y-28,a,px,y+3,b]
			return s
		"weapons_workshop":
			return "<path d='M48 %d L128 %d M48 %d L128 %d M48 %d L128 %d' stroke='#e7edf3' stroke-width='8' stroke-linecap='round'/><rect x='%d' y='%d' width='58' height='58' rx='8' fill='#4b2d32' stroke='#172433' stroke-width='4'/><circle cx='%d' cy='%d' r='14' fill='%s' filter='url(#glow)'/>" % [y-18,y-8,y,y+10,y+18,y+28,w-110,y-31,w-81,y-2,a]
		"signal_den":
			var s := ""
			for px in [55, cx-28, w-111]:
				s += "<rect x='%d' y='%d' width='56' height='38' rx='6' fill='#102231' stroke='%s' stroke-width='4'/><path d='M%d %d H%d M%d %d H%d' stroke='%s' stroke-width='3'/>" % [px,y-18,a,px+8,y-5,px+47,px+8,y+6,px+37,b]
			return s
		"enforcer_gym":
			return "<path d='M62 %d H%d' stroke='#dce4ea' stroke-width='9'/><circle cx='58' cy='%d' r='15' fill='#27394a' stroke='#172433' stroke-width='4'/><circle cx='%d' cy='%d' r='15' fill='#27394a' stroke='#172433' stroke-width='4'/><circle cx='%d' cy='%d' r='25' fill='%s' stroke='#172433' stroke-width='4'/>" % [y+12,w-62,y+12,w-58,y+12,cx,y-18,b]
		"sharpshooter_range":
			var s := ""
			for px in [int(w*.28), int(w*.50), int(w*.72)]:
				s += "<circle cx='%d' cy='%d' r='24' fill='#f4f0e8' stroke='#172433' stroke-width='4'/><circle cx='%d' cy='%d' r='14' fill='%s'/><circle cx='%d' cy='%d' r='5' fill='%s'/>" % [px,y,px,y,b,px,y,a]
			return s
		"chop_shop":
			return "<path d='M55 %d L%d %d L%d %d L%d %d Z' fill='#334d62' stroke='#172433' stroke-width='4'/><path d='M95 %d L%d %d L%d %d L%d %d Z' fill='%s' stroke='#172433' stroke-width='3'/><circle cx='84' cy='%d' r='14' fill='#111922'/><circle cx='%d' cy='%d' r='14' fill='#111922'/>" % [y+18,cx-10,y-18,w-58,y+18,cx+10,y+49,y-4,cx,y-26,cx+55,y-2,cx+4,y+20,b,y+39,w-86,y+39]
		"clinic":
			return "<rect x='55' y='%d' width='105' height='44' rx='8' fill='#e2edf0' stroke='#172433' stroke-width='4'/><path d='M107 %d V%d M84 %d H130' stroke='%s' stroke-width='12'/><rect x='%d' y='%d' width='60' height='42' rx='7' fill='#102231' stroke='%s' stroke-width='4'/><ellipse cx='%d' cy='%d' rx='27' ry='9' fill='%s' opacity='.72'/>" % [y-22,y-34,y+22,y-6,a,w-112,y-20,b,w-82,y+23,a]
		"bunks":
			var s := ""
			for px in [48, cx-32, w-112]:
				s += "<rect x='%d' y='%d' width='64' height='17' rx='5' fill='#65788a' stroke='#172433' stroke-width='3'/><rect x='%d' y='%d' width='64' height='17' rx='5' fill='#65788a' stroke='#172433' stroke-width='3'/>" % [px,y-28,px,y+8]
			return s
		"black_market":
			var s := ""
			for row in range(2):
				for col in range(4):
					var px := 48 + col * 48
					var py := y-30 + row * 34
					s += "<rect x='%d' y='%d' width='38' height='25' rx='4' fill='%s' stroke='#172433' stroke-width='3'/><path d='M%d %d L%d %d M%d %d L%d %d' stroke='#d6b47e' stroke-width='2'/>" % [px,py,"#765338" if (row+col)%2==0 else "#3e6874",px+4,py+4,px+34,py+21,px+34,py+4,px+4,py+21]
			return s
		"tunnel":
			return "<path d='M42 %d Q%d %d %d %d' fill='none' stroke='#8193a2' stroke-width='16'/><path d='M62 %d Q%d %d %d %d' fill='none' stroke='%s' stroke-width='7'/><path d='M56 %d H%d' stroke='%s' stroke-width='6'/><rect x='40' y='%d' width='40' height='28' rx='4' fill='#765338' stroke='#172433' stroke-width='3'/><rect x='%d' y='%d' width='40' height='28' rx='4' fill='#3e6874' stroke='#172433' stroke-width='3'/>" % [y+35,cx,y-45,w-42,y+35,cx,y-28,w-62,y+35,a,y+11,w-56,b,y-30,w-80,y-30]
		"boss_office":
			return "<rect x='62' y='%d' width='%d' height='39' rx='8' fill='#56344d' stroke='#172433' stroke-width='4'/><circle cx='%d' cy='%d' r='21' fill='%s' stroke='#172433' stroke-width='4'/><path d='M%d %d V%d' stroke='%s' stroke-width='6'/><rect x='30' y='%d' width='36' height='52' rx='5' fill='#243a4d'/><rect x='%d' y='%d' width='36' height='52' rx='5' fill='#243a4d'/>" % [y-5,w-124,cx,y-32,a,cx,y-11,y+17,b,y-30,w-66,y-30]
		_:
			return "<circle cx='%d' cy='%d' r='28' fill='%s' stroke='#172433' stroke-width='5'/>" % [cx,y,a]

static func _resource_svg(kind: String, x: int, y: int, a: String, b: String) -> String:
	var label := "LUNAR ALLOY" if kind == "alloy" else ("HELIUM-3" if kind == "helium" else "DATA CORES")
	var icon := ""
	if kind == "alloy":
		icon = "<path d='M118 30 L145 65 L118 102 L91 65Z' fill='%s' stroke='#172433' stroke-width='5'/><path d='M118 92 V190' stroke='#dce7ee' stroke-width='12'/><ellipse cx='118' cy='194' rx='70' ry='27' fill='%s' stroke='#172433' stroke-width='5'/><ellipse cx='118' cy='194' rx='43' ry='15' fill='%s'/>" % [b,a,b]
	elif kind == "helium":
		for px in [70, 118, 166]:
			icon += "<rect x='%d' y='70' width='34' height='94' rx='15' fill='#284d66' stroke='%s' stroke-width='4'/><ellipse cx='%d' cy='72' rx='17' ry='12' fill='%s'/>" % [px-17,a,px,b]
		icon += "<path d='M70 116 H166' stroke='%s' stroke-width='7'/><circle cx='118' cy='40' r='18' fill='%s' stroke='#172433' stroke-width='4'/>" % [a,a]
	else:
		icon = "<path d='M118 45 V184' stroke='#dce7ee' stroke-width='12'/><circle cx='118' cy='40' r='20' fill='%s' stroke='#172433' stroke-width='5'/><ellipse cx='118' cy='91' rx='58' ry='20' fill='none' stroke='%s' stroke-width='6'/><ellipse cx='118' cy='128' rx='47' ry='17' fill='none' stroke='%s' stroke-width='6'/><ellipse cx='118' cy='160' rx='35' ry='13' fill='none' stroke='%s' stroke-width='6'/>" % [b,a,a,a]
	return "<g transform='translate(%d %d) scale(.72)'><ellipse cx='118' cy='225' rx='105' ry='29' fill='#000' opacity='.45' filter='url(#shadow)'/><path d='M15 170 L118 115 L221 170 L118 225Z' fill='#627486' stroke='#172433' stroke-width='6'/>%s<rect x='18' y='228' width='200' height='36' rx='12' fill='#101a27' stroke='%s' stroke-width='4'/><text x='118' y='252' text-anchor='middle' fill='#f5fbff' font-family='sans-serif' font-size='15' font-weight='bold'>%s</text></g>" % [x,y,icon,a,label]

static func _vehicle_svg(kind: String, x: int, y: int, scale_value: float) -> String:
	var a := "#4ee7ff"
	var b := "#8c54d8"
	if kind == "police":
		b = "#3f78d6"
	elif kind == "skiff":
		a = "#ff9a4a"
	var body := "<path d='M18 82 L112 25 L222 83 L126 142Z' fill='#30495e' stroke='#172433' stroke-width='6'/><path d='M62 64 L112 34 L178 67 L126 101Z' fill='%s' stroke='#172433' stroke-width='4'/><rect x='90' y='42' width='66' height='28' rx='7' fill='#173449' stroke='%s' stroke-width='4'/><path d='M28 92 H210' stroke='%s' stroke-width='7'/>" % [b,a,a]
	if kind == "police":
		body += "<path d='M123 22 V4' stroke='#dce7ee' stroke-width='7'/><circle cx='123' cy='5' r='9' fill='#f05b6b'/><text x='120' y='122' text-anchor='middle' fill='#dff6ff' font-size='12' font-family='sans-serif' font-weight='bold'>POLICE</text>"
	return "<g transform='translate(%d %d) scale(%s)'><ellipse cx='120' cy='150' rx='105' ry='24' fill='#000' opacity='.46' filter='url(#shadow)'/>%s<circle cx='42' cy='105' r='15' fill='#111922' stroke='%s' stroke-width='4'/><circle cx='198' cy='105' r='15' fill='#111922' stroke='%s' stroke-width='4'/></g>" % [x,y,str(scale_value),body,a,a]

static func _props_svg() -> String:
	var p: Array[String] = []
	for pos in [[178,710],[840,770],[195,990],[805,1135],[314,1260],[725,1360]]:
		var x := int(pos[0]); var y := int(pos[1])
		p.append("<rect x='%d' y='%d' width='31' height='23' rx='4' fill='#765338' stroke='#172433' stroke-width='3'/><rect x='%d' y='%d' width='31' height='23' rx='4' fill='#3e6874' stroke='#172433' stroke-width='3'/>" % [x,y,x+30,y+14])
	for pos in [[158,510],[862,510],[132,800],[904,800],[160,1060],[875,1070],[142,1300],[908,1320]]:
		var x := int(pos[0]); var y := int(pos[1])
		p.append("<path d='M%d %d V%d' stroke='#d9e5ec' stroke-width='6'/><circle cx='%d' cy='%d' r='8' fill='#4ee7ff' filter='url(#glow)'/>" % [x,y,x,y-58,x,y-62])
	return "".join(p)

static func _npc_svg(x: int, y: int, role_index: int, frame: int, scale_value: float, accent: String) -> String:
	var body_colors := ["#344b62","#365365","#4a3d4b","#3f4657","#3d4b55","#365258","#483f50","#384a5b"]
	var body := body_colors[posmod(role_index, body_colors.size())]
	var bob := [0,-3,0,3][posmod(frame,4)]
	var leg_left := -8 if frame % 2 == 0 else -2
	var leg_right := 8 if frame % 2 == 0 else 2
	return "<g transform='translate(%d %d) scale(%s)'><ellipse cx='0' cy='31' rx='18' ry='6' fill='#000' opacity='.45'/><path d='M-6 9 L%d 28 M6 9 L%d 28' stroke='#172433' stroke-width='7' stroke-linecap='round'/><rect x='-13' y='%d' width='26' height='28' rx='7' fill='%s' stroke='#172433' stroke-width='4'/><rect x='-10' y='%d' width='20' height='6' rx='2' fill='%s'/><circle cx='0' cy='%d' r='11' fill='#d5a17c' stroke='#172433' stroke-width='4'/><path d='M-13 %d H13 V%d H-13Z' fill='#24374a' stroke='#172433' stroke-width='3'/><rect x='-9' y='%d' width='18' height='5' rx='2' fill='%s'/><path d='M-12 %d L-22 %d M12 %d L24 %d' stroke='%s' stroke-width='6' stroke-linecap='round'/></g>" % [x,y,str(scale_value),leg_left,leg_right,-5+bob,body,1+bob,accent,-17+bob,-28+bob,-18+bob,-25+bob,accent,3+bob,15+bob,3+bob,14+bob,body]

static func _npc_atlas_svg() -> String:
	var p: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='1024' height='256' viewBox='0 0 1024 256'>", _defs()]
	for role in range(8):
		var row := role / 4
		var column := role % 4
		for frame in range(4):
			var x := column * 256 + frame * 64 + 32
			var y := row * 128 + 62
			var accents := ["#4ee7ff","#55f3d1","#ff9a4a","#f05b6b","#ffd16a","#56d6a2","#8c54d8","#4ee7ff"]
			p.append(_npc_svg(x,y,role,frame,1.0,accents[role]))
	p.append("</svg>")
	return "".join(p)

static func _systems_atlas_svg() -> String:
	var p: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='1024' height='768' viewBox='0 0 1024 768'>", _defs()]
	var items := [
		["resource_alloy","#ff9a4a","#ffd16a"],["resource_helium","#4ee7ff","#8c54d8"],["resource_cores","#4ee7ff","#e6539b"],["defense_jammer","#4ee7ff","#8c54d8"],
		["defense_sentry","#f05b6b","#ff9a4a"],["defense_blast_doors","#ffd16a","#f05b6b"],["defense_escape_tunnels","#56d6a2","#4ee7ff"],["threat_survey","#4ee7ff","#6ca6ff"],
		["threat_patrol","#4ee7ff","#ffd16a"],["threat_riot","#f05b6b","#ff9a4a"],["threat_cyber","#e6539b","#4ee7ff"],["mission_hidden","#ffd16a","#8c54d8"]
	]
	for i in range(items.size()):
		var x := (i % 4) * 256
		var y := (i / 4) * 256
		p.append(_system_cell_svg(String(items[i][0]), x, y, String(items[i][1]), String(items[i][2])))
	p.append("</svg>")
	return "".join(p)

static func _system_cell_svg(id: String, x: int, y: int, a: String, b: String) -> String:
	var icon := ""
	if id.begins_with("resource_"):
		var kind := id.trim_prefix("resource_")
		icon = _resource_svg("cores" if kind == "cores" else kind, 36, 8, a, b)
	elif id == "defense_jammer":
		icon = "<path d='M128 45 V170' stroke='#dce7ee' stroke-width='14'/><circle cx='128' cy='42' r='18' fill='%s'/><path d='M78 82 Q128 42 178 82 M57 105 Q128 35 199 105' fill='none' stroke='%s' stroke-width='7'/>" % [b,a]
	elif id == "defense_sentry":
		icon = "<rect x='116' y='112' width='24' height='78' fill='#354b5d'/><circle cx='128' cy='93' r='42' fill='#273d52' stroke='#172433' stroke-width='6'/><path d='M128 88 L212 51' stroke='%s' stroke-width='12'/><circle cx='215' cy='49' r='11' fill='%s'/>" % [a,b]
	elif id == "defense_blast_doors":
		icon = "<rect x='52' y='48' width='152' height='148' rx='12' fill='#31475a' stroke='#172433' stroke-width='7'/><path d='M74 62 L182 182 M182 62 L74 182' stroke='%s' stroke-width='10'/><path d='M90 55 V190 M128 55 V190 M166 55 V190' stroke='#61778b' stroke-width='11'/>" % a
	elif id == "defense_escape_tunnels":
		icon = "<path d='M45 178 Q128 35 211 178' fill='#293d4f' stroke='#172433' stroke-width='16'/><path d='M62 178 Q128 67 194 178' fill='none' stroke='%s' stroke-width='9'/><path d='M65 180 H191' stroke='%s' stroke-width='8'/><circle cx='92' cy='166' r='9' fill='%s'/><circle cx='128' cy='166' r='9' fill='%s'/><circle cx='164' cy='166' r='9' fill='%s'/>" % [a,b,a,a,a]
	elif id == "threat_survey":
		icon = "<circle cx='128' cy='112' r='48' fill='#273d52' stroke='%s' stroke-width='7'/><circle cx='128' cy='112' r='21' fill='%s'/><path d='M128 160 V228 M80 112 H25 M176 112 H231 M128 64 V18' stroke='%s' stroke-width='8'/><ellipse cx='26' cy='112' rx='22' ry='11' fill='#1f3345' stroke='%s' stroke-width='5'/><ellipse cx='230' cy='112' rx='22' ry='11' fill='#1f3345' stroke='%s' stroke-width='5'/>" % [a,b,a,a,a]
	elif id == "threat_patrol":
		icon = _npc_svg(90,145,2,1,1.65,a) + _npc_svg(166,145,3,2,1.65,b)
	elif id == "threat_riot":
		icon = "<rect x='82' y='80' width='93' height='120' rx='18' fill='#293e52' stroke='#172433' stroke-width='7'/><circle cx='128' cy='59' r='31' fill='#d5a17c' stroke='#172433' stroke-width='6'/><rect x='49' y='100' width='61' height='125' rx='17' fill='#1b2f43' stroke='%s' stroke-width='6'/><path d='M156 95 L220 145' stroke='%s' stroke-width='13'/>" % [a,b]
	elif id == "threat_cyber":
		icon = "<circle cx='128' cy='104' r='66' fill='#162b40' stroke='%s' stroke-width='7'/><path d='M72 82 H184 M72 106 H184 M72 130 H184 M96 52 V158 M128 38 V170 M160 52 V158' stroke='%s' stroke-width='4'/><circle cx='105' cy='92' r='10' fill='%s'/><circle cx='151' cy='92' r='10' fill='%s'/><path d='M100 133 H156' stroke='%s' stroke-width='7'/>" % [a,b,a,a,a]
	else:
		icon = "<path d='M128 35 L205 78 V166 L128 211 L51 166 V78Z' fill='#2d4458' stroke='%s' stroke-width='7'/><path d='M80 118 H176 M128 70 V170' stroke='%s' stroke-width='12'/>" % [a,b]
	return "<g transform='translate(%d %d)'><rect x='7' y='7' width='242' height='242' rx='28' fill='#101a27' stroke='%s' stroke-width='6'/>%s</g>" % [x,y,a,icon]

static func system_region(id: String) -> Rect2:
	var ids := ["resource_alloy","resource_helium","resource_cores","defense_jammer","defense_sentry","defense_blast_doors","defense_escape_tunnels","threat_survey","threat_patrol","threat_riot","threat_cyber","mission_hidden"]
	var index := maxi(0, ids.find(id))
	return Rect2(float(index % 4) * 256.0, float(index / 4) * 256.0, 256.0, 256.0)

static func npc_region(role_index: int, frame: int) -> Rect2:
	var role := posmod(role_index, 8)
	var row := role / 4
	var column := role % 4
	return Rect2(float(column * 256 + posmod(frame,4) * 64), float(row * 128), 64.0, 128.0)

static func _ui_atlas_svg() -> String:
	var ids := ["patrol","heroes","dermapack","store","alliance","state","rotate","zoom"]
	var p: Array[String] = ["<svg xmlns='http://www.w3.org/2000/svg' width='512' height='256' viewBox='0 0 512 256'>", _defs()]
	for i in range(ids.size()):
		p.append(_ui_icon_svg(ids[i], (i%4)*128, (i/4)*128))
	p.append("</svg>")
	return "".join(p)

static func ui_region(id: String) -> Rect2:
	var ids := ["patrol","heroes","dermapack","store","alliance","state","rotate","zoom"]
	var index := maxi(0, ids.find(id))
	return Rect2(float(index%4)*128.0, float(index/4)*128.0, 128.0, 128.0)

static func _single_ui_svg(id: String) -> String:
	return "<svg xmlns='http://www.w3.org/2000/svg' width='256' height='256' viewBox='0 0 128 128'>" + _defs() + _ui_icon_svg(id,0,0) + "</svg>"

static func _ui_icon_svg(id: String, x: int, y: int) -> String:
	var icon := ""
	match id:
		"dermapack": icon = "<rect x='34' y='28' width='60' height='74' rx='18' fill='#26384b' stroke='#dbe8ef' stroke-width='4'/><rect x='42' y='39' width='44' height='34' rx='8' fill='#102435' stroke='#4ee7ff' stroke-width='4'/><path d='M30 55 L16 47 M98 55 L112 47' stroke='#9caebe' stroke-width='6'/><rect x='45' y='80' width='38' height='15' rx='5' fill='#0d1724' stroke='#8c54d8' stroke-width='3'/>"
		"patrol": icon = "<path d='M28 88 L64 25 L100 88Z' fill='#2e4c65' stroke='#dbe8ef' stroke-width='4'/><circle cx='64' cy='61' r='18' fill='#4ee7ff' stroke='#172433' stroke-width='4'/><path d='M64 31 V100' stroke='#8c54d8' stroke-width='5'/>"
		"heroes": icon = "<circle cx='42' cy='40' r='15' fill='#d5a17c'/><circle cx='86' cy='40' r='15' fill='#d5a17c'/><rect x='22' y='55' width='40' height='43' rx='10' fill='#30485e' stroke='#4ee7ff' stroke-width='3'/><rect x='66' y='55' width='40' height='43' rx='10' fill='#3d4358' stroke='#8c54d8' stroke-width='3'/>"
		"store": icon = "<path d='M25 51 H103 L92 29 H36Z' fill='#8c54d8' stroke='#172433' stroke-width='4'/><rect x='28' y='50' width='72' height='48' rx='7' fill='#31495d' stroke='#dbe8ef' stroke-width='4'/><path d='M43 58 V90 M64 58 V90 M85 58 V90' stroke='#4ee7ff' stroke-width='9'/>"
		"alliance": icon = "<circle cx='39' cy='43' r='17' fill='#4ee7ff' stroke='#172433' stroke-width='3'/><circle cx='89' cy='43' r='17' fill='#8c54d8' stroke='#172433' stroke-width='3'/><path d='M46 58 L64 86 L82 58' stroke='#dbe8ef' stroke-width='10'/><circle cx='64' cy='90' r='14' fill='#ffd16a' stroke='#172433' stroke-width='3'/>"
		"state": icon = "<path d='M24 90 L40 32 L64 18 L88 32 L104 90 L64 109Z' fill='#2f5267' stroke='#4ee7ff' stroke-width='4'/><circle cx='64' cy='67' r='18' fill='#8c54d8' stroke='#172433' stroke-width='3'/><path d='M64 32 V98' stroke='#dbe8ef' stroke-width='5'/>"
		"rotate": icon = "<path d='M29 83 A43 43 0 1 1 100 74' fill='none' stroke='#4ee7ff' stroke-width='9'/><path d='M88 22 L112 30 L96 49Z' fill='#4ee7ff'/><circle cx='64' cy='64' r='15' fill='#8c54d8'/>"
		_: icon = "<circle cx='53' cy='53' r='29' fill='#17283a' stroke='#4ee7ff' stroke-width='6'/><path d='M75 75 L108 108' stroke='#8c54d8' stroke-width='10'/><path d='M53 37 V69 M37 53 H69' stroke='#dbe8ef' stroke-width='6'/>"
	return "<g transform='translate(%d %d)'><rect x='8' y='8' width='112' height='112' rx='25' fill='#132030' stroke='#4ee7ff' stroke-width='5'/>%s</g>" % [x,y,icon]

static func _cutscene_svg(key: String) -> String:
	var title := "CRATER MARKET IS FALLING"
	var subtitle := "The Peacekeeper station strikes from orbit while the surviving MoonGoons race for the buried command tunnel."
	var tx := -85
	var ty := -330
	var scale_value := .82
	if key == "ghost_key":
		title = "THE NETWORK REMEMBERS"
		subtitle = "The Ghost Key opens Authority relays, forgotten tunnels, and every sealed door under the moon."
		tx = -140; ty = -520; scale_value = .92
	elif key == "war_room":
		title = "THE DISTRICT CHOOSES A SIDE"
		subtitle = "Rival crews stop laughing. Peacekeeper Command finally says the Syndicate's name out loud."
		tx = -70; ty = -140; scale_value = .78
	elif key == "finale":
		title = "CROWN THE CRATER"
		subtitle = "The Syndicate controls the lunar district. Above, the station watches. Below, a new underworld rises."
		tx = -55; ty = -410; scale_value = .76
	return "<svg xmlns='http://www.w3.org/2000/svg' width='720' height='1280' viewBox='0 0 720 1280'>" + _defs() + "<g transform='translate(%d %d) scale(%s)'>%s</g><rect y='830' width='720' height='450' fill='#050911' opacity='.94'/><text x='360' y='920' text-anchor='middle' fill='#f5fbff' font-family='sans-serif' font-size='30' font-weight='bold'>%s</text><foreignObject x='55' y='955' width='610' height='150'><div xmlns='http://www.w3.org/1999/xhtml' style='font-family:sans-serif;font-size:19px;line-height:1.4;text-align:center;color:#c9d7e2'>%s</div></foreignObject><path d='M210 1180 H510' stroke='#4ee7ff' stroke-opacity='.5' stroke-width='5'/></svg>" % [tx,ty,str(scale_value),_world_content(),title,subtitle]

static func _attack_svg(key: String) -> String:
	var threat_id := "threat_survey"
	var a := "#4ee7ff"
	if key == "patrol": threat_id = "threat_patrol"
	elif key == "riot": threat_id = "threat_riot"; a = "#f05b6b"
	elif key == "cyber": threat_id = "threat_cyber"; a = "#e6539b"
	var source := system_region(threat_id)
	var icon := _system_cell_svg(threat_id,232,205,a,"#8c54d8")
	return "<svg xmlns='http://www.w3.org/2000/svg' width='720' height='720' viewBox='0 0 720 720'>" + _defs() + "<g transform='translate(-10 -230) scale(.72)'>%s</g><rect width='720' height='720' fill='#030711' opacity='.48'/>%s<path d='M110 610 H610' stroke='%s' stroke-width='6' opacity='.7'/></svg>" % [_world_content(),icon,a]
