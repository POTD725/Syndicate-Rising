extends Control
## Galaxy, Alliance, and Private chat client UI.

var current_channel: String = "galaxy"
var tab_buttons: Dictionary = {}
var message_list: VBoxContainer
var scroll: ScrollContainer
var input_line: LineEdit
var target_line: LineEdit
var status_label: Label
var channel_title: Label
var feedback_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_interface()
	SyndicateChat.messages_changed.connect(_on_messages_changed)
	_refresh_channel()

func _build_interface() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color("050a13")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var header: ColorRect = ColorRect.new()
	header.color = Color("0a1728")
	header.position = Vector2(0.0, 0.0)
	header.size = Vector2(720.0, 96.0)
	add_child(header)

	var back_button: Button = Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(14.0, 18.0)
	back_button.size = Vector2(90.0, 56.0)
	back_button.pressed.connect(_go_back)
	add_child(back_button)

	var title: Label = Label.new()
	title.text = "MOONGOONS COMMUNICATIONS"
	title.position = Vector2(122.0, 16.0)
	title.size = Vector2(470.0, 34.0)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f4fbff"))
	add_child(title)

	status_label = Label.new()
	status_label.position = Vector2(122.0, 52.0)
	status_label.size = Vector2(570.0, 28.0)
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color("ffca72"))
	add_child(status_label)

	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.position = Vector2(20.0, 112.0)
	tabs.size = Vector2(680.0, 58.0)
	tabs.add_theme_constant_override("separation", 12)
	add_child(tabs)
	for channel: String in ["galaxy", "alliance", "private"]:
		var button: Button = Button.new()
		button.text = channel.to_upper()
		button.custom_minimum_size = Vector2(218.0, 56.0)
		button.pressed.connect(_switch_channel.bind(channel))
		tab_buttons[channel] = button
		tabs.add_child(button)

	channel_title = Label.new()
	channel_title.position = Vector2(28.0, 187.0)
	channel_title.size = Vector2(664.0, 38.0)
	channel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	channel_title.add_theme_font_size_override("font_size", 18)
	channel_title.add_theme_color_override("font_color", Color("72ead7"))
	add_child(channel_title)

	scroll = ScrollContainer.new()
	scroll.position = Vector2(28.0, 234.0)
	scroll.size = Vector2(664.0, 690.0)
	add_child(scroll)

	message_list = VBoxContainer.new()
	message_list.custom_minimum_size = Vector2(634.0, 680.0)
	message_list.add_theme_constant_override("separation", 10)
	scroll.add_child(message_list)

	target_line = LineEdit.new()
	target_line.position = Vector2(28.0, 944.0)
	target_line.size = Vector2(664.0, 50.0)
	target_line.placeholder_text = "Private recipient or crew name"
	target_line.text = SyndicateChat.private_target
	add_child(target_line)

	input_line = LineEdit.new()
	input_line.position = Vector2(28.0, 1008.0)
	input_line.size = Vector2(528.0, 60.0)
	input_line.placeholder_text = "Type a message, maximum 280 characters"
	input_line.max_length = 280
	input_line.text_submitted.connect(_submit_from_line)
	add_child(input_line)

	var send_button: Button = Button.new()
	send_button.text = "SEND"
	send_button.position = Vector2(568.0, 1008.0)
	send_button.size = Vector2(124.0, 60.0)
	send_button.pressed.connect(_send_message)
	add_child(send_button)

	feedback_label = Label.new()
	feedback_label.position = Vector2(30.0, 1082.0)
	feedback_label.size = Vector2(660.0, 56.0)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.add_theme_font_size_override("font_size", 10)
	feedback_label.add_theme_color_override("font_color", Color("a9bdca"))
	add_child(feedback_label)

	var notice: Label = Label.new()
	notice.position = Vector2(30.0, 1152.0)
	notice.size = Vector2(660.0, 92.0)
	notice.text = "Galaxy, Alliance, and Private channels are fully usable on this device. Cross-device delivery will activate when a secure MoonGoons chat backend is connected."
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size", 11)
	notice.add_theme_color_override("font_color", Color("8ea6b8"))
	add_child(notice)

func _switch_channel(channel: String) -> void:
	current_channel = channel
	_refresh_channel()

func _refresh_channel() -> void:
	status_label.text = SyndicateChat.connection_label()
	target_line.visible = current_channel == "private"
	for channel_value: Variant in tab_buttons.keys():
		var channel: String = String(channel_value)
		var button: Button = tab_buttons[channel] as Button
		button.disabled = channel == current_channel
	match current_channel:
		"galaxy": channel_title.text = "GALAXY CHAT • ALL MOONGOONS SECTORS"
		"alliance": channel_title.text = "ALLIANCE CHAT • %s" % SyndicateChat.alliance_name.to_upper()
		_: channel_title.text = "PRIVATE CHAT • DIRECT THREAD"
	for child: Node in message_list.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = SyndicateChat.get_messages(current_channel)
	for entry: Dictionary in entries:
		message_list.add_child(_make_message_card(entry))
	call_deferred("_scroll_to_bottom")

func _make_message_card(entry: Dictionary) -> Control:
	var card: VBoxContainer = VBoxContainer.new()
	card.custom_minimum_size = Vector2(620.0, 72.0)
	card.add_theme_constant_override("separation", 4)

	var header: Label = Label.new()
	var sender: String = String(entry.get("sender", "Unknown"))
	var target: String = String(entry.get("target", ""))
	header.text = sender if target.is_empty() else "%s  →  %s" % [sender, target]
	header.add_theme_font_size_override("font_size", 12)
	var kind: String = String(entry.get("kind", "player"))
	header.add_theme_color_override("font_color", _kind_color(kind))
	card.add_child(header)

	var body: Label = Label.new()
	body.text = String(entry.get("body", ""))
	body.custom_minimum_size = Vector2(610.0, 38.0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 11)
	body.add_theme_color_override("font_color", Color("d7e3ea"))
	card.add_child(body)

	var divider: HSeparator = HSeparator.new()
	card.add_child(divider)
	return card

func _kind_color(kind: String) -> Color:
	match kind:
		"system": return Color("ffcb72")
		"crew": return Color("ba93ff")
		_: return Color("72ead7")

func _submit_from_line(_text: String) -> void:
	_send_message()

func _send_message() -> void:
	var target: String = target_line.text if current_channel == "private" else ""
	var result: Dictionary = SyndicateChat.post_message(current_channel, input_line.text, target)
	feedback_label.text = String(result.get("message", ""))
	feedback_label.add_theme_color_override("font_color", Color("72ead7") if bool(result.get("ok", false)) else Color("ff8e82"))
	if bool(result.get("ok", false)):
		input_line.clear()
		_refresh_channel()

func _on_messages_changed(channel: String) -> void:
	if channel == current_channel:
		_refresh_channel()

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/SyndicateCity.tscn")
