extends RefCounted
## Loads the approved isometric board from verified text chunks and builds the matching DermaPack icon.

const BOARD_CHUNKS: Array[String] = [
	"res://assets/board/chunks/board_00.b64",
	"res://assets/board/chunks/board_01.b64",
	"res://assets/board/chunks/board_02.b64",
	"res://assets/board/chunks/board_03.b64"
]

static var _board_cache: Texture2D
static var _dermapack_cache: Texture2D

static func board_texture() -> Texture2D:
	if _board_cache != null:
		return _board_cache
	var encoded: String = ""
	for path: String in BOARD_CHUNKS:
		if not FileAccess.file_exists(path):
			push_error("Missing isometric board chunk: %s" % path)
			return GradientTexture2D.new()
		encoded += FileAccess.get_file_as_string(path).strip_edges()
	var image: Image = Image.new()
	var error: Error = image.load_jpg_from_buffer(Marshalls.base64_to_raw(encoded))
	if error != OK:
		push_error("Unable to decode isometric lunar board: %s" % error_string(error))
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
<circle cx='128' cy='95' r='13' fill='#8df5ff' opacity='.9'/>
<path d='M128 80 V110 M113 95 H143' stroke='#fff' stroke-width='4' opacity='.86'/>
<rect x='83' y='164' width='90' height='30' rx='12' fill='#0b121d' stroke='#8a5cff' stroke-width='4'/>
<rect x='94' y='173' width='22' height='12' rx='4' fill='#65edff'/><rect x='122' y='173' width='18' height='12' rx='4' fill='#a566ff'/><rect x='146' y='173' width='16' height='12' rx='4' fill='#ff9b45'/>
<circle cx='76' cy='139' r='9' fill='#ff527e' filter='url(#glow)'/><circle cx='180' cy='139' r='9' fill='#56ecff' filter='url(#glow)'/>
<path d='M54 102 L32 95 M202 102 L224 95' stroke='#88a0b7' stroke-width='7' stroke-linecap='round'/>
</svg>"""
