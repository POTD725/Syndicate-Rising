extends "res://scripts/syndicate_state.gd"
## Moon-surface hideout expansion layered over the standalone campaign state.

const LUNAR_ROOM_ORDER: Array[String] = [
	"backroom",
	"black_research",
	"weapons_workshop",
	"signal_den",
	"enforcer_gym",
	"sharpshooter_range",
	"chop_shop",
	"clinic",
	"bunks",
	"black_market",
	"tunnel",
	"boss_office"
]

func reset_state() -> void:
	super.reset_state()
	_ensure_lunar_hideout()
	last_event = "LUNAR HIDEOUT ONLINE // The Peacekeeper station is overhead. Rebuild beneath its scanners."
	state_changed.emit()

func load_game() -> Dictionary:
	var result: Dictionary = super.load_game()
	if bool(result.get("ok", false)):
		_ensure_lunar_hideout()
		last_event = "Lunar hideout loaded. Orbital telemetry reacquired."
		state_changed.emit()
	return result

func run_room_operation(room_id: String) -> Dictionary:
	if not is_room_repaired(room_id):
		return {"ok": false, "message": "Rebuild that room before assigning a crew."}
	match room_id:
		"backroom":
			return _spoof_orbital_scan()
		"black_research":
			return _begin_lunar_research()
		"weapons_workshop":
			return _craft_weapons()
		"signal_den":
			return _train_hackers()
		"enforcer_gym":
			return _train_role("Enforcer", "Enforcer drill complete")
		"sharpshooter_range":
			return _train_role("Sharpshot", "Sharpshooter calibration complete")
		"chop_shop":
			return _train_role("Runner", "Runner convoy drill complete")
		"clinic":
			return _patch_crew()
		"bunks":
			return _rest_crew()
		"black_market":
			return fence_contraband()
		"tunnel":
			return _smuggle_cargo()
		"boss_office":
			return _expand_influence()
		_:
			return {"ok": false, "message": "No operation is assigned to that room yet."}

func room_operation_label(room_id: String) -> String:
	match room_id:
		"backroom": return "SPOOF SCAN"
		"black_research": return "RESEARCH"
		"weapons_workshop": return "CRAFT GEAR"
		"signal_den": return "TRAIN HACKER"
		"enforcer_gym": return "DRILL CREW"
		"sharpshooter_range": return "CALIBRATE"
		"chop_shop": return "RUN CONVOY"
		"clinic": return "PATCH CREW"
		"bunks": return "REST CREW"
		"black_market": return "FENCE CARGO"
		"tunnel": return "SMUGGLE"
		"boss_office": return "EXPAND"
		_: return "OPERATE"

func _ensure_lunar_hideout() -> void:
	_upsert_room("backroom", "Syndicate Command", "Operations & Orbital Spoofing", 0, true)
	_upsert_room("black_research", "Black Research Lab", "Stolen Peacekeeper Technology", 190, false)
	_upsert_room("weapons_workshop", "Weapons Workshop", "Weapons, Armor & Equipment", 175, false)
	_upsert_room("signal_den", "Hacker Training Den", "Cyber Training & Counter-Intel", 165, false)
	_upsert_room("enforcer_gym", "Enforcer Training Room", "Heavy Crew Training", 150, false)
	_upsert_room("sharpshooter_range", "Sharpshooter Range", "Ranged Crew Training", 155, false)
	_upsert_room("chop_shop", "Runner Garage", "Rovers, Couriers & Getaways", 125, false)
	_upsert_room("clinic", "Street Clinic", "Healing & Illegal Enhancements", 175, false)
	_upsert_room("bunks", "Crew Quarters", "Housing, Morale & Recovery", 105, false)
	_upsert_room("black_market", "Black Market", "Income, Equipment & Fencing", 145, false)
	_upsert_room("tunnel", "Smuggler Dock", "Contraband & Secret Deployment", 155, false)
	_upsert_room("boss_office", "Boss's Office", "Influence & Crew Capacity", 215, false)
	var ordered: Array[Dictionary] = []
	for room_id: String in LUNAR_ROOM_ORDER:
		var room: Dictionary = get_room(room_id)
		if not room.is_empty():
			ordered.append(room)
	rooms = ordered

func _upsert_room(room_id: String, room_name: String, room_function: String, repair_cost: int, starts_online: bool) -> void:
	var room: Dictionary = get_room(room_id)
	if room.is_empty():
		room = _room(room_id, room_name, room_function, "", starts_online, repair_cost)
		rooms.append(room)
	else:
		room["name"] = room_name
		room["function"] = room_function
		room["repair_cost"] = repair_cost
		if starts_online:
			room["repaired"] = true
			room["repair_end"] = 0
	if not room.has("project_level"):
		room["project_level"] = 1

func _spoof_orbital_scan() -> Dictionary:
	if intel < 2:
		return {"ok": false, "message": "Orbital spoofing needs 2 intel."}
	intel -= 2
	heat = maxi(0, heat - 6 - get_room_level("backroom"))
	last_event = "ORBIT SPOOFED // False telemetry pulled the Peacekeeper scan away from the hideout."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func _begin_lunar_research() -> Dictionary:
	if black_tech_end > 0:
		return {"ok": false, "message": "Black Research is already decoding stolen technology."}
	if not is_room_repaired("signal_den"):
		return {"ok": false, "message": "The Hacker Training Den must be online to crack Peacekeeper encryption."}
	var credit_cost: int = 110 + black_tech_level * 50
	var intel_cost: int = 5 + black_tech_level * 2
	if credits < credit_cost or intel < intel_cost:
		return {"ok": false, "message": "Research needs %d credits and %d intel." % [credit_cost, intel_cost]}
	credits -= credit_cost
	intel -= intel_cost
	black_tech_end = _now() + maxi(8, 20 - get_room_level("black_research") - get_room_level("signal_den"))
	last_event = "BLACK RESEARCH STARTED // Peacekeeper hardware is being stripped for secrets."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func _craft_weapons() -> Dictionary:
	var room: Dictionary = get_room("weapons_workshop")
	var project_level: int = int(room.get("project_level", 1))
	var credit_cost: int = 65 + project_level * 25
	var cargo_cost: int = 2
	if credits < credit_cost or contraband < cargo_cost:
		return {"ok": false, "message": "Crafting needs %d credits and %d contraband." % [credit_cost, cargo_cost]}
	credits -= credit_cost
	contraband -= cargo_cost
	room["project_level"] = project_level + 1
	for member: Dictionary in crew:
		member["power"] = int(member.get("power", 50)) + 1
	last_event = "WEAPONS COMPLETE // Crew equipment advanced to MK %d." % int(room.get("project_level", 1))
	state_changed.emit()
	return {"ok": true, "message": last_event}

func _train_hackers() -> Dictionary:
	var room: Dictionary = get_room("signal_den")
	var training_level: int = int(room.get("project_level", 1))
	var credit_cost: int = 55 + training_level * 20
	if credits < credit_cost or intel < 3:
		return {"ok": false, "message": "Hacker training needs %d credits and 3 intel." % credit_cost}
	credits -= credit_cost
	intel -= 3
	room["project_level"] = training_level + 1
	heat = maxi(0, heat - 4)
	last_event = "HACKER CELL TRAINED // Counter-surveillance level %d is active." % int(room.get("project_level", 1))
	state_changed.emit()
	return {"ok": true, "message": last_event}

func _train_role(role_name: String, completed_text: String) -> Dictionary:
	var cost: int = 75
	if credits < cost:
		return {"ok": false, "message": "Training needs %d credits." % cost}
	credits -= cost
	var trained: int = 0
	for member: Dictionary in crew:
		if String(member.get("role", "")) == role_name:
			member["power"] = int(member.get("power", 50)) + 3
			member["defense"] = int(member.get("defense", 10)) + 1
			trained += 1
	last_event = "%s // %d crew improved." % [completed_text.to_upper(), trained]
	state_changed.emit()
	return {"ok": true, "message": last_event}

func _patch_crew() -> Dictionary:
	if credits < 60:
		return {"ok": false, "message": "The clinic needs 60 credits for supplies."}
	credits -= 60
	for member: Dictionary in crew:
		member["hp"] = int(member.get("max_hp", 100))
		member["injured_until"] = 0
	last_event = "STREET CLINIC // Every surviving crew member is patched and combat-ready."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func _rest_crew() -> Dictionary:
	var now: int = _now()
	for member: Dictionary in crew:
		member["busy_until"] = mini(int(member.get("busy_until", 0)), now + 3)
	last_event = "CREW QUARTERS // Shift rotations shortened current recovery timers."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func _smuggle_cargo() -> Dictionary:
	if credits < 45:
		return {"ok": false, "message": "A smuggling launch needs 45 credits."}
	credits -= 45
	contraband += 3 + get_room_level("tunnel")
	heat = clampi(heat + 2, 0, 100)
	last_event = "SMUGGLER DOCK // A masked cargo skiff slipped beneath the station's patrol arc."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func _expand_influence() -> Dictionary:
	var cost: int = 120 + notoriety * 10
	if credits < cost:
		return {"ok": false, "message": "Expanding influence needs %d credits." % cost}
	credits -= cost
	notoriety += 1
	last_event = "BOSS'S OFFICE // Another lunar crew now answers to the Syndicate."
	state_changed.emit()
	return {"ok": true, "message": last_event}
