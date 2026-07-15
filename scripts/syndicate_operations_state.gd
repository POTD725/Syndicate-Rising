extends "res://scripts/syndicate_lunar_state.gd"
## Persistent harvesting, Take Back Peacekeeper threats, hideout defenses, and side missions.

const OPS_SAVE_PATH: String = "user://syndicate_rising_operations.json"
const THREAT_LIMIT_SECONDS: int = 48

var lunar_alloy: int = 32
var helium3: int = 18
var data_cores: int = 7
var harvest_sites: Array[Dictionary] = []
var defenses: Dictionary = {}
var active_threat: Dictionary = {}
var next_threat_at: int = 0
var threat_serial: int = 0
var captured_crew_ids: Array[String] = []
var law_hack_damage: int = 0

var side_mission_mode: String = ""
var hidden_found: Array[bool] = []
var hack_sequence: Array[int] = []
var hack_progress: int = 0
var side_missions_completed: int = 0

func reset_state() -> void:
	super.reset_state()
	_reset_operations()
	last_event = "LUNAR UNDERWORLD ONLINE // Harvest carefully. Take Back Peacekeepers are searching for this hideout."
	state_changed.emit()

func tick() -> void:
	super.tick()
	var now: int = _ops_now()
	var changed: bool = false
	for site: Dictionary in harvest_sites:
		var finish_at: int = int(site.get("finish_at", 0))
		if finish_at > 0 and now >= finish_at:
			_complete_harvest(site)
			changed = true
	if active_threat.is_empty() and now >= next_threat_at:
		_generate_threat()
		changed = true
	elif not active_threat.is_empty() and now >= int(active_threat.get("expires_at", now + 1)):
		_fail_threat("The response window closed.")
		changed = true
	if law_hack_damage > 0 and now % 12 == 0:
		credits = maxi(0, credits - law_hack_damage)
		last_event = "PEACEKEEPER CYBER WARRANT // %d credits were frozen by a law-enforcement intrusion." % law_hack_damage
		changed = true
	if changed:
		state_changed.emit()

func save_game() -> Dictionary:
	var base_result: Dictionary = super.save_game()
	var data: Dictionary = {
		"lunar_alloy": lunar_alloy,
		"helium3": helium3,
		"data_cores": data_cores,
		"harvest_sites": harvest_sites,
		"defenses": defenses,
		"active_threat": active_threat,
		"next_threat_at": next_threat_at,
		"threat_serial": threat_serial,
		"captured_crew_ids": captured_crew_ids,
		"law_hack_damage": law_hack_damage,
		"side_mission_mode": side_mission_mode,
		"hidden_found": hidden_found,
		"hack_sequence": hack_sequence,
		"hack_progress": hack_progress,
		"side_missions_completed": side_missions_completed
	}
	var file: FileAccess = FileAccess.open(OPS_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Operations save could not be opened."}
	file.store_string(JSON.stringify(data))
	return base_result

func load_game() -> Dictionary:
	var base_result: Dictionary = super.load_game()
	if not bool(base_result.get("ok", false)):
		return base_result
	_reset_operations()
	if FileAccess.file_exists(OPS_SAVE_PATH):
		var file: FileAccess = FileAccess.open(OPS_SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				var data: Dictionary = parsed as Dictionary
				lunar_alloy = int(data.get("lunar_alloy", lunar_alloy))
				helium3 = int(data.get("helium3", helium3))
				data_cores = int(data.get("data_cores", data_cores))
				harvest_sites = _dictionary_array(data.get("harvest_sites", harvest_sites))
				var loaded_defenses: Variant = data.get("defenses", defenses)
				defenses = loaded_defenses as Dictionary if loaded_defenses is Dictionary else defenses
				var loaded_threat: Variant = data.get("active_threat", {})
				active_threat = loaded_threat as Dictionary if loaded_threat is Dictionary else {}
				next_threat_at = int(data.get("next_threat_at", next_threat_at))
				threat_serial = int(data.get("threat_serial", 0))
				captured_crew_ids = _string_array(data.get("captured_crew_ids", []))
				law_hack_damage = int(data.get("law_hack_damage", 0))
				side_mission_mode = String(data.get("side_mission_mode", ""))
				hidden_found = _bool_array(data.get("hidden_found", []))
				hack_sequence = _int_array(data.get("hack_sequence", []))
				hack_progress = int(data.get("hack_progress", 0))
				side_missions_completed = int(data.get("side_missions_completed", 0))
	_apply_capture_flags()
	last_event = "Operations network loaded. Peacekeeper threat telemetry restored."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func crew_available(member: Dictionary) -> bool:
	if bool(member.get("captured", false)):
		return false
	return super.crew_available(member)

func start_harvest(site_id: String) -> Dictionary:
	var site: Dictionary = get_harvest_site(site_id)
	if site.is_empty():
		return {"ok": false, "message": "Harvest site not found."}
	if int(site.get("finish_at", 0)) > 0:
		return {"ok": false, "message": "%s is already being harvested." % String(site.get("name", "Site"))}
	if captured_crew_ids.size() >= crew.size() - 1:
		return {"ok": false, "message": "Too many crew are captured to risk another harvesting run."}
	var duration: int = int(site.get("duration", 15))
	site["finish_at"] = _ops_now() + duration
	heat = clampi(heat + int(site.get("risk", 1)), 0, 100)
	last_event = "HARVEST DEPLOYED // %s will report in %d seconds." % [String(site.get("name", "Site")), duration]
	state_changed.emit()
	return {"ok": true, "message": last_event}

func get_harvest_site(site_id: String) -> Dictionary:
	for site: Dictionary in harvest_sites:
		if String(site.get("id", "")) == site_id:
			return site
	return {}

func harvest_seconds_left(site: Dictionary) -> int:
	return maxi(0, int(site.get("finish_at", 0)) - _ops_now())

func upgrade_defense(defense_id: String) -> Dictionary:
	if not defenses.has(defense_id):
		return {"ok": false, "message": "Defense system not found."}
	var level: int = int(defenses.get(defense_id, 0))
	if level >= 10:
		return {"ok": false, "message": "That defense is already level 10."}
	var alloy_cost: int = 5 + level * 4
	var helium_cost: int = 3 + level * 3
	var core_cost: int = 1 + level / 2
	if lunar_alloy < alloy_cost or helium3 < helium_cost or data_cores < core_cost:
		return {"ok": false, "message": "Upgrade needs %d Alloy, %d He-3, and %d Data Cores." % [alloy_cost, helium_cost, core_cost]}
	lunar_alloy -= alloy_cost
	helium3 -= helium_cost
	data_cores -= core_cost
	defenses[defense_id] = level + 1
	last_event = "%s upgraded to level %d." % [defense_name(defense_id), level + 1]
	state_changed.emit()
	return {"ok": true, "message": last_event}

func defense_name(defense_id: String) -> String:
	match defense_id:
		"jammer": return "Signal Jammer Grid"
		"sentry": return "Sentry Turret Network"
		"blast_doors": return "Armored Blast Doors"
		"escape_tunnels": return "Emergency Escape Tunnels"
		_: return "Hideout Defense"

func respond_to_threat(response: String) -> Dictionary:
	if active_threat.is_empty():
		return {"ok": false, "message": "No Peacekeeper response is currently active."}
	var threat_type: String = String(active_threat.get("type", "patrol"))
	var threat_power: int = int(active_threat.get("power", 1))
	var response_power: int = 0
	match response:
		"counter_hack":
			if data_cores < 1:
				return {"ok": false, "message": "Counter-hacking requires one Authority Data Core."}
			data_cores -= 1
			response_power = int(defenses.get("jammer", 0)) * 3 + get_room_level("signal_den") * 2 + black_tech_level
		"hide":
			response_power = int(defenses.get("jammer", 0)) * 2 + int(defenses.get("escape_tunnels", 0)) * 3 + get_room_level("backroom")
		"fight":
			response_power = int(defenses.get("sentry", 0)) * 3 + int(defenses.get("blast_doors", 0)) * 2 + _available_crew_power() / 95
		_:
			return {"ok": false, "message": "Unknown response order."}
	if threat_type == "cyber" and response == "counter_hack":
		response_power += 4
	if threat_type == "survey" and response == "hide":
		response_power += 3
	if threat_type == "riot" and response == "fight":
		response_power += 3
	if response_power >= threat_power:
		var title: String = String(active_threat.get("title", "Peacekeeper response"))
		active_threat.clear()
		law_hack_damage = 0
		heat = maxi(0, heat - 5)
		intel += 2
		data_cores += 1
		next_threat_at = _ops_now() + 28 + threat_serial * 2
		last_event = "THREAT DEFEATED // %s was driven off. One Authority Data Core recovered." % title
		state_changed.emit()
		return {"ok": true, "message": last_event}
	_fail_threat("The selected defense was overpowered.")
	return {"ok": false, "message": last_event}

func force_threat(threat_type: String) -> void:
	active_threat = _threat_template(threat_type)
	active_threat["expires_at"] = _ops_now() + THREAT_LIMIT_SECONDS
	state_changed.emit()

func start_side_mission(mode: String) -> Dictionary:
	if not side_mission_mode.is_empty():
		return {"ok": false, "message": "Finish or abort the current side mission first."}
	match mode:
		"hidden":
			side_mission_mode = mode
			hidden_found = [false, false, false, false, false, false]
			hack_sequence.clear()
			hack_progress = 0
			last_event = "SIDE MISSION // Steal five marked valuables from the Peacekeeper evidence room."
		"law_hack":
			side_mission_mode = mode
			hack_sequence = [2, 5, 1, 4, 0]
			hack_progress = 0
			hidden_found.clear()
			last_event = "SIDE MISSION // Crack the Peacekeeper warrant server in the correct relay order."
		"syndicate_cipher":
			side_mission_mode = mode
			hack_sequence = [3, 0, 5, 2, 1, 4]
			hack_progress = 0
			hidden_found.clear()
			last_event = "SIDE MISSION // Break the rival Syndicate cipher before they trace the hideout."
		"rescue":
			if captured_crew_ids.is_empty():
				return {"ok": false, "message": "No crew member is currently held by the Peacekeepers."}
			side_mission_mode = mode
			hack_sequence = [1, 4, 2, 5]
			hack_progress = 0
			hidden_found.clear()
			last_event = "RESCUE OPERATION // Crack the prisoner-transfer route and recover captured crew."
		_:
			return {"ok": false, "message": "Side mission type not found."}
	state_changed.emit()
	return {"ok": true, "message": last_event}

func abort_side_mission() -> void:
	side_mission_mode = ""
	hidden_found.clear()
	hack_sequence.clear()
	hack_progress = 0
	last_event = "Side mission aborted."
	state_changed.emit()

func submit_hidden_object(index: int) -> Dictionary:
	if side_mission_mode != "hidden":
		return {"ok": false, "message": "No hidden-object theft is active."}
	if index < 0 or index >= hidden_found.size():
		return {"ok": false, "message": "That object is not part of the target list."}
	if hidden_found[index]:
		return {"ok": false, "message": "That item was already stolen."}
	hidden_found[index] = true
	var found_count: int = hidden_found.count(true)
	if found_count >= 5:
		credits += 180
		contraband += 5
		data_cores += 2
		side_missions_completed += 1
		side_mission_mode = ""
		last_event = "HIDDEN-OBJECT SCORE COMPLETE // Evidence, access badges, and prototypes secured."
	else:
		last_event = "VALUABLE STOLEN // %d of 5 target items recovered." % found_count
	state_changed.emit()
	return {"ok": true, "message": last_event}

func submit_hack_node(index: int) -> Dictionary:
	if side_mission_mode == "" or side_mission_mode == "hidden":
		return {"ok": false, "message": "No hacking puzzle is active."}
	if hack_progress >= hack_sequence.size():
		return {"ok": false, "message": "The puzzle is already complete."}
	if index != hack_sequence[hack_progress]:
		hack_progress = 0
		heat = clampi(heat + 1, 0, 100)
		last_event = "TRACE SPIKE // Incorrect relay. Sequence reset and Heat increased."
		state_changed.emit()
		return {"ok": false, "message": last_event}
	hack_progress += 1
	if hack_progress >= hack_sequence.size():
		_complete_hack_mission()
	else:
		last_event = "RELAY ACCEPTED // %d of %d nodes cracked." % [hack_progress, hack_sequence.size()]
	state_changed.emit()
	return {"ok": true, "message": last_event}

func side_mission_instruction() -> String:
	match side_mission_mode:
		"hidden": return "Find and steal any five highlighted valuables hidden in the evidence room."
		"law_hack": return "Follow the pulsing Authority relay path. A wrong node resets the trace."
		"syndicate_cipher": return "Decode the rival Syndicate network by following the shifting cipher route."
		"rescue": return "Crack the prisoner-transfer route to recover the captured MoonGoon."
		_: return "Choose a side mission."

func _reset_operations() -> void:
	lunar_alloy = 32
	helium3 = 18
	data_cores = 7
	harvest_sites = [
		{"id":"alloy","name":"Ridge-7 Alloy Vein","resource":"Lunar Alloy","yield":9,"duration":14,"risk":2,"finish_at":0},
		{"id":"helium","name":"Mare Helium-3 Vent","resource":"Helium-3","yield":7,"duration":18,"risk":3,"finish_at":0},
		{"id":"cores","name":"Wrecked Authority Relay","resource":"Authority Data Cores","yield":3,"duration":22,"risk":4,"finish_at":0}
	]
	defenses = {"jammer":1,"sentry":1,"blast_doors":1,"escape_tunnels":1}
	active_threat.clear()
	next_threat_at = _ops_now() + 24
	threat_serial = 0
	captured_crew_ids.clear()
	law_hack_damage = 0
	side_mission_mode = ""
	hidden_found.clear()
	hack_sequence.clear()
	hack_progress = 0
	side_missions_completed = 0
	_apply_capture_flags()

func _complete_harvest(site: Dictionary) -> void:
	var amount: int = int(site.get("yield", 1)) + get_room_level("chop_shop") / 2
	match String(site.get("id", "")):
		"alloy": lunar_alloy += amount
		"helium": helium3 += amount
		"cores": data_cores += amount
	site["finish_at"] = 0
	heat = clampi(heat + int(site.get("risk", 1)), 0, 100)
	last_event = "HARVEST COMPLETE // +%d %s from %s." % [amount, String(site.get("resource", "resources")), String(site.get("name", "site"))]
	if active_threat.is_empty() and int(site.get("risk", 1)) + heat / 20 >= 5:
		next_threat_at = mini(next_threat_at, _ops_now() + 3)

func _generate_threat() -> void:
	var types: Array[String] = ["survey", "patrol", "cyber", "riot"]
	var threat_type: String = types[threat_serial % types.size()]
	active_threat = _threat_template(threat_type)
	active_threat["expires_at"] = _ops_now() + THREAT_LIMIT_SECONDS
	threat_serial += 1
	last_event = "TAKE BACK ALERT // %s" % String(active_threat.get("description", "Peacekeepers inbound."))

func _threat_template(threat_type: String) -> Dictionary:
	var power_bonus: int = heat / 18 + story_chapter / 2
	match threat_type:
		"survey":
			return {"type":"survey","title":"Survey Drone Sweep","unit":"Take Back Survey Drone","power":4 + power_bonus,"description":"A Take Back Survey Drone is mapping heat leaks above the crater."}
		"patrol":
			return {"type":"patrol","title":"Patrol Deputy Capture Team","unit":"Take Back Patrol Deputy","power":6 + power_bonus,"description":"Patrol Deputies are entering the tunnels with arrest restraints."}
		"cyber":
			return {"type":"cyber","title":"Peacekeeper Cyber Warrant","unit":"Authority Cyber Unit","power":7 + power_bonus,"description":"Law enforcement is hacking the hideout accounts and room controls."}
		_:
			return {"type":"riot","title":"Riot Vanguard Breach","unit":"Take Back Riot Vanguard","power":9 + power_bonus,"description":"A Riot Vanguard squad is cutting through the outer blast doors."}

func _fail_threat(reason: String) -> void:
	var threat_type: String = String(active_threat.get("type", "patrol"))
	var title: String = String(active_threat.get("title", "Peacekeeper response"))
	match threat_type:
		"survey":
			heat = clampi(heat + 12, 0, 100)
			intel = maxi(0, intel - 2)
		"cyber":
			law_hack_damage = 4 + int(active_threat.get("power", 1))
			credits = maxi(0, credits - 45)
		"riot":
			lunar_alloy = maxi(0, lunar_alloy - 6)
			helium3 = maxi(0, helium3 - 4)
			_damage_random_room()
		_:
			_capture_crew_member()
	active_threat.clear()
	next_threat_at = _ops_now() + 30
	last_event = "THREAT LOST // %s %s" % [title, reason]
	state_changed.emit()

func _capture_crew_member() -> void:
	for member: Dictionary in crew:
		var crew_id: String = String(member.get("id", ""))
		if not captured_crew_ids.has(crew_id):
			captured_crew_ids.append(crew_id)
			member["captured"] = true
			member["busy_until"] = _ops_now() + 86400
			last_event = "%s was captured by Take Back Patrol Deputies." % String(member.get("name", "A crew member"))
			return

func _damage_random_room() -> void:
	for room: Dictionary in rooms:
		if String(room.get("id", "")) != "backroom" and bool(room.get("repaired", false)):
			room["repaired"] = false
			room["repair_end"] = 0
			return

func _complete_hack_mission() -> void:
	var completed_mode: String = side_mission_mode
	if completed_mode == "law_hack":
		law_hack_damage = 0
		heat = maxi(0, heat - 10)
		data_cores += 3
		last_event = "LAW NETWORK CRACKED // Warrants erased and orbital pursuit routes scrambled."
	elif completed_mode == "syndicate_cipher":
		intel += 6
		contraband += 3
		notoriety += 1
		last_event = "RIVAL CIPHER BROKEN // Their caches and patrol routes belong to you now."
	elif completed_mode == "rescue":
		_release_captured_crew()
		last_event = "RESCUE COMPLETE // The prisoner transport was diverted into a Syndicate tunnel."
	side_missions_completed += 1
	side_mission_mode = ""
	hack_sequence.clear()
	hack_progress = 0

func _release_captured_crew() -> void:
	if captured_crew_ids.is_empty():
		return
	var crew_id: String = captured_crew_ids.pop_front()
	var member: Dictionary = get_crew_member(crew_id)
	if not member.is_empty():
		member["captured"] = false
		member["busy_until"] = _ops_now() + 5
		member["hp"] = maxi(1, int(member.get("max_hp", 100)) / 2)

func _apply_capture_flags() -> void:
	for member: Dictionary in crew:
		var crew_id: String = String(member.get("id", ""))
		member["captured"] = captured_crew_ids.has(crew_id)

func _available_crew_power() -> int:
	var total: int = 0
	for member: Dictionary in crew:
		if crew_available(member):
			total += int(member.get("power", 0)) + int(member.get("defense", 0))
	return total

func _bool_array(value: Variant) -> Array[bool]:
	var result: Array[bool] = []
	if value is Array:
		for item: Variant in value:
			result.append(bool(item))
	return result

func _int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item: Variant in value:
			result.append(int(item))
	return result

func _ops_now() -> int:
	return int(Time.get_unix_time_from_system())
