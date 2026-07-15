extends "res://scripts/syndicate_operations_state.gd"
## Story choices and attack-cinematic queue layered over operations gameplay.

const STORY_EXTRA_SAVE: String = "user://syndicate_rising_story_extras.json"

var prologue_choice: String = ""
var crew_trust: int = 0
var pending_attack_cutscene: String = ""
var attack_cutscenes_seen: int = 0

func reset_state() -> void:
	super.reset_state()
	prologue_choice = ""
	crew_trust = 0
	pending_attack_cutscene = ""
	attack_cutscenes_seen = 0

func tick() -> void:
	var had_threat: bool = not active_threat.is_empty()
	super.tick()
	if not had_threat and not active_threat.is_empty() and pending_attack_cutscene.is_empty():
		pending_attack_cutscene = String(active_threat.get("type", "patrol"))
		state_changed.emit()

func force_threat(threat_type: String) -> void:
	super.force_threat(threat_type)
	pending_attack_cutscene = threat_type
	state_changed.emit()

func respond_to_threat(response: String) -> Dictionary:
	var result: Dictionary = super.respond_to_threat(response)
	pending_attack_cutscene = ""
	return result

func apply_prologue_choice(choice_id: String) -> Dictionary:
	if not prologue_choice.is_empty():
		return {"ok": false, "message": "The Syndicate already chose how it survived the first raid."}
	prologue_choice = choice_id
	match choice_id:
		"rescue":
			crew_trust = 3
			credits += 70
			heat = clampi(heat + 6, 0, 100)
			var clinic: Dictionary = get_room("clinic")
			if not clinic.is_empty():
				clinic["repaired"] = true
				clinic["repair_end"] = 0
			last_event = "ORIGIN CHOICE // The crew came first. The Street Clinic survived, but the Peacekeepers saw the rescue convoy."
		"salvage":
			crew_trust = 1
			lunar_alloy += 18
			helium3 += 12
			credits += 140
			heat = clampi(heat + 3, 0, 100)
			last_event = "ORIGIN CHOICE // The wreckage became walls, power cells, and the first Syndicate war chest."
		"codes":
			crew_trust = 2
			data_cores += 6
			intel += 9
			black_tech_level += 1
			heat = clampi(heat + 9, 0, 100)
			last_event = "ORIGIN CHOICE // Authority access codes were stolen before the raid smoke cleared."
		_:
			return {"ok": false, "message": "Unknown prologue choice."}
	state_changed.emit()
	return {"ok": true, "message": last_event}

func consume_attack_cutscene() -> String:
	var value: String = pending_attack_cutscene
	pending_attack_cutscene = ""
	if not value.is_empty():
		attack_cutscenes_seen += 1
	state_changed.emit()
	return value

func save_game() -> Dictionary:
	var result: Dictionary = super.save_game()
	var file: FileAccess = FileAccess.open(STORY_EXTRA_SAVE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"prologue_choice": prologue_choice,
			"crew_trust": crew_trust,
			"pending_attack_cutscene": pending_attack_cutscene,
			"attack_cutscenes_seen": attack_cutscenes_seen
		}))
	return result

func load_game() -> Dictionary:
	var result: Dictionary = super.load_game()
	if not bool(result.get("ok", false)):
		return result
	if FileAccess.file_exists(STORY_EXTRA_SAVE):
		var file: FileAccess = FileAccess.open(STORY_EXTRA_SAVE, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				var data: Dictionary = parsed as Dictionary
				prologue_choice = String(data.get("prologue_choice", ""))
				crew_trust = int(data.get("crew_trust", 0))
				pending_attack_cutscene = String(data.get("pending_attack_cutscene", ""))
				attack_cutscenes_seen = int(data.get("attack_cutscenes_seen", 0))
	if prologue_choice.is_empty():
		intro_seen = false
		pending_cutscene = "prologue"
		last_event = "ORIGIN REQUIRED // Choose how the Syndicate survived the first Peacekeeper raid."
	state_changed.emit()
	return result
