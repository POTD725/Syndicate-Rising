extends Node
## Local-first chat client state. Ready for a future online transport without pretending local messages are cross-device.

signal messages_changed(channel: String)

const CHAT_SAVE_PATH: String = "user://syndicate_rising_chat.json"
const CHANNELS: Array[String] = ["galaxy", "alliance", "private"]
const MAX_MESSAGES_PER_CHANNEL: int = 80

var player_alias: String = "CraterBoss"
var alliance_name: String = "Crater Nine Syndicate"
var backend_url: String = ""
var backend_connected: bool = false
var messages: Dictionary = {}
var private_target: String = "Nyx Raze"

func _ready() -> void:
	_reset_chat()
	load_chat()

func _reset_chat() -> void:
	messages = {
		"galaxy": [
			_message("SYSTEM", "Galaxy channel is operating in local prototype mode. Online transport is not connected.", "system"),
			_message("Moon Relay", "Peacekeeper patrol lanes shifted over Mare Imbrium.", "system")
		],
		"alliance": [
			_message("Nyx Raze", "Command is online. Mark harvest windows and raid warnings here.", "crew"),
			_message("Vox-13", "I have a quiet route beneath the Authority scanners.", "crew")
		],
		"private": [
			_message("Nyx Raze", "This private thread is stored on this device until a chat backend is connected.", "crew", "CraterBoss")
		]
	}

func post_message(channel: String, text: String, target: String = "") -> Dictionary:
	var clean_channel: String = channel.to_lower()
	var clean_text: String = text.strip_edges()
	if not CHANNELS.has(clean_channel):
		return {"ok": false, "message": "Unknown chat channel."}
	if clean_text.is_empty():
		return {"ok": false, "message": "Type a message first."}
	if clean_text.length() > 280:
		clean_text = clean_text.left(280)
	if clean_channel == "private" and target.strip_edges().is_empty():
		return {"ok": false, "message": "Private messages need a recipient."}
	var entry: Dictionary = _message(player_alias, clean_text, "player", target.strip_edges())
	var channel_messages: Array = messages.get(clean_channel, []) as Array
	channel_messages.append(entry)
	while channel_messages.size() > MAX_MESSAGES_PER_CHANNEL:
		channel_messages.pop_front()
	messages[clean_channel] = channel_messages
	if clean_channel == "private":
		private_target = target.strip_edges()
	save_chat()
	messages_changed.emit(clean_channel)
	return {
		"ok": true,
		"message": "Message saved locally." if not backend_connected else "Message sent.",
		"networked": backend_connected
	}

func get_messages(channel: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var raw: Variant = messages.get(channel.to_lower(), [])
	if raw is Array:
		for entry: Variant in raw:
			if entry is Dictionary:
				result.append(entry as Dictionary)
	return result

func set_player_alias(value: String) -> void:
	var clean: String = value.strip_edges().left(24)
	if not clean.is_empty():
		player_alias = clean
		save_chat()

func configure_backend(url: String) -> void:
	backend_url = url.strip_edges()
	backend_connected = false
	save_chat()

func connection_label() -> String:
	if backend_connected:
		return "ONLINE • LIVE MULTIPLAYER CHAT"
	return "LOCAL PROTOTYPE • MESSAGES STAY ON THIS DEVICE"

func save_chat() -> void:
	var file: FileAccess = FileAccess.open(CHAT_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"player_alias": player_alias,
		"alliance_name": alliance_name,
		"backend_url": backend_url,
		"private_target": private_target,
		"messages": messages
	}))

func load_chat() -> void:
	if not FileAccess.file_exists(CHAT_SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(CHAT_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed as Dictionary
	player_alias = String(data.get("player_alias", player_alias))
	alliance_name = String(data.get("alliance_name", alliance_name))
	backend_url = String(data.get("backend_url", ""))
	private_target = String(data.get("private_target", private_target))
	var loaded_messages: Variant = data.get("messages", messages)
	if loaded_messages is Dictionary:
		messages = loaded_messages as Dictionary
	for channel: String in CHANNELS:
		if not messages.has(channel):
			messages[channel] = []

func _message(sender: String, body: String, kind: String, target: String = "") -> Dictionary:
	return {
		"sender": sender,
		"body": body,
		"kind": kind,
		"target": target,
		"timestamp": int(Time.get_unix_time_from_system())
	}
