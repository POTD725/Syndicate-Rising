extends "res://scripts/syndicate_chat.gd"
## Skins the complete communications interface and its three channel icons.

var skin_atlas: Texture2D
var skin_button: Button

func _ready() -> void:
	super._ready()
	skin_atlas = SyndicateSkins.atlas()
	skin_button = Button.new()
	skin_button.text = "SKIN"
	skin_button.position = Vector2(604.0, 18.0)
	skin_button.size = Vector2(98.0, 56.0)
	skin_button.pressed.connect(_cycle_skin)
	add_child(skin_button)
	if not SyndicateSkins.skin_changed.is_connected(_on_skin_changed):
		SyndicateSkins.skin_changed.connect(_on_skin_changed)
	_apply_skin()

func _cycle_skin() -> void:
	SyndicateSkins.cycle_skin()
	feedback_label.text = "Communications skin changed to %s." % SyndicateSkins.skin_name()

func _on_skin_changed(_index: int) -> void:
	skin_atlas = SyndicateSkins.atlas()
	_apply_skin()

func _apply_skin() -> void:
	var color_rects: Array[ColorRect] = []
	_collect_color_rects(self, color_rects)
	for index: int in range(color_rects.size()):
		color_rects[index].color = SyndicateSkins.dark() if index == 0 else SyndicateSkins.panel()
	var buttons: Array[Button] = []
	_collect_buttons(self, buttons)
	for button: Button in buttons:
		button.add_theme_stylebox_override("normal", SyndicateSkins.style_box(false, 8))
		button.add_theme_stylebox_override("hover", SyndicateSkins.style_box(true, 8))
		button.add_theme_stylebox_override("pressed", SyndicateSkins.style_box(true, 8))
		button.add_theme_stylebox_override("disabled", SyndicateSkins.style_box(true, 8, 0.55))
		button.add_theme_color_override("font_color", SyndicateSkins.text())
		button.add_theme_color_override("font_hover_color", SyndicateSkins.text())
	for channel: String in ["galaxy", "alliance", "private"]:
		var tab: Button = tab_buttons[channel] as Button
		tab.icon = _atlas_icon("chat_" + channel)
		tab.expand_icon = true
	channel_title.add_theme_color_override("font_color", SyndicateSkins.accent())
	status_label.add_theme_color_override("font_color", SyndicateSkins.secondary())
	feedback_label.add_theme_color_override("font_color", SyndicateSkins.accent())
	queue_redraw()

func _atlas_icon(item_id: String) -> AtlasTexture:
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = skin_atlas
	texture.region = SyndicateSkins.region(item_id)
	return texture

func _kind_color(kind: String) -> Color:
	match kind:
		"system": return SyndicateSkins.secondary()
		"crew": return SyndicateSkins.accent().lerp(Color("c99cff"), 0.45)
		_: return SyndicateSkins.accent()

func _collect_buttons(node: Node, output: Array[Button]) -> void:
	for child: Node in node.get_children():
		if child is Button:
			output.append(child as Button)
		_collect_buttons(child, output)

func _collect_color_rects(node: Node, output: Array[ColorRect]) -> void:
	for child: Node in node.get_children():
		if child is ColorRect:
			output.append(child as ColorRect)
		_collect_color_rects(child, output)
