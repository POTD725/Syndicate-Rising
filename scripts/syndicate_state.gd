extends Node
## Persistent campaign state for MoonGoons: Syndicate Rising.

signal state_changed
signal job_added(job_id: String)

const SAVE_PATH := "user://syndicate_rising_save.json"
const MAX_ROOM_LEVEL := 10
const JOB_LIMIT := 3
const FINAL_STORY_CHAPTER := 5

var credits := 650
var contraband := 20
var intel := 12
var heat := 8
var notoriety := 1
var black_tech_level := 1
var black_tech_end := 0
var story_chapter := 1
var jobs_completed := 0
var pending_cutscene := "prologue"
var intro_seen := false
var rooms: Array[Dictionary] = []
var crew: Array[Dictionary] = []
var jobs: Array[Dictionary] = []
var completed_story_jobs: Array[String] = []
var active_job: Dictionary = {}
var active_crew_ids: Array[String] = []
var next_job_at := 0
var next_heat_decay_at := 0
var job_serial := 1
var last_event := "SYNDICATE RISING // Rebuild the district and take the Moon back from underneath."

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if rooms.is_empty():
		reset_state()

func reset_state() -> void:
	var now := _now()
	credits = 650
	contraband = 20
	intel = 12
	heat = 8
	notoriety = 1
	black_tech_level = 1
	black_tech_end = 0
	story_chapter = 1
	jobs_completed = 0
	pending_cutscene = "prologue"
	intro_seen = false
	jobs.clear()
	completed_story_jobs.clear()
	active_job.clear()
	active_crew_ids.clear()
	job_serial = 1
	rooms = [
		_room("backroom", "Backroom Command", "Operations", "res://assets/buildings/backroom_command.svg", true, 0),
		_room("chop_shop", "Chop Shop", "Vehicles", "res://assets/buildings/chop_shop.svg", false, 125),
		_room("black_market", "Black Market", "Income", "res://assets/buildings/black_market.svg", false, 145),
		_room("bunks", "Safehouse Bunks", "Recovery", "res://assets/buildings/safehouse_bunks.svg", false, 105),
		_room("clinic", "Street Clinic", "Healing", "res://assets/buildings/street_clinic.svg", false, 175),
		_room("boss_office", "Boss's Office", "Crew Capacity", "res://assets/buildings/boss_office.svg", false, 215),
		_room("signal_den", "Signal Den", "Counter-Intel", "res://assets/buildings/signal_den.svg", false, 165),
		_room("tunnel", "Smuggler Tunnel", "Fence Contraband", "res://assets/buildings/smuggler_tunnel.svg", false, 155)
	]
	crew = [
		_crew_member("crew_1", "Nyx Raze", "Enforcer", 74, 108, 18, "res://assets/portraits/nyx_raze.svg"),
		_crew_member("crew_2", "Vox-13", "Runner", 87, 91, 13, "res://assets/portraits/vox_13.svg"),
		_crew_member("crew_3", "Cinder Quell", "Sharpshot", 91, 84, 15, "res://assets/portraits/cinder_quell.svg"),
		_crew_member("crew_4", "Grit Mercer", "Enforcer", 70, 112, 20, "res://assets/portraits/grit_mercer.svg")
	]
	next_job_at = now + 2
	next_heat_decay_at = now + 12
	last_event = "HIDEOUT ONLINE // Backroom Command survived the raid. Seven buildings need rebuilding."
	state_changed.emit()

func tick() -> void:
	var now := _now()
	var changed := false
	for room: Dictionary in rooms:
		var repair_end := int(room.get("repair_end", 0))
		if not bool(room.get("repaired", false)) and repair_end > 0 and now >= repair_end:
			room["repaired"] = true
			room["repair_end"] = 0
			last_event = "%s rebuilt. The district has another heartbeat." % String(room.get("name", "Building"))
			changed = true
	if black_tech_end > 0 and now >= black_tech_end:
		black_tech_level += 1
		black_tech_end = 0
		last_event = "BLACK TECH COMPLETE // Network level %d unlocked." % black_tech_level
		changed = true
	for member: Dictionary in crew:
		var injured_until := int(member.get("injured_until", 0))
		if injured_until > 0 and now >= injured_until:
			member["injured_until"] = 0
			member["hp"] = int(member.get("max_hp", 100))
			last_event = "%s is patched up and back on the roster." % String(member.get("name", "Crew"))
			changed = true
	var retained: Array[Dictionary] = []
	for job: Dictionary in jobs:
		if now < int(job.get("expires_at", 0)):
			retained.append(job)
		else:
			heat = clampi(heat + 2, 0, 100)
			last_event = "A score window closed. Rivals claimed it and Heat climbed."
			changed = true
	jobs = retained
	if active_job.is_empty() and jobs.size() < JOB_LIMIT and now >= next_job_at:
		_generate_job()
		changed = true
	if now >= next_heat_decay_at:
		next_heat_decay_at = now + 12
		if heat > 0:
			var cooling := 1
			if is_room_repaired("signal_den"):
				cooling += get_room_level("signal_den") / 2
			heat = max(0, heat - cooling)
			last_event = "Signal spoofers cooled the district. Heat dropped to %d." % heat
			changed = true
	if changed:
		state_changed.emit()

func repair_or_upgrade_room(room_id: String) -> Dictionary:
	var room := get_room(room_id)
	if room.is_empty():
		return {"ok": false, "message": "Building not found."}
	if bool(room.get("repaired", false)):
		return upgrade_room(room_id)
	return repair_room(room_id)

func repair_room(room_id: String) -> Dictionary:
	var room := get_room(room_id)
	if room.is_empty():
		return {"ok": false, "message": "Building not found."}
	if bool(room.get("repaired", false)):
		return {"ok": false, "message": "That building is already online."}
	if int(room.get("repair_end", 0)) > 0:
		return {"ok": false, "message": "A salvage crew is already rebuilding it."}
	var cost := int(room.get("repair_cost", 0))
	if credits < cost:
		return {"ok": false, "message": "The rebuild needs %d credits." % cost}
	credits -= cost
	room["repair_end"] = _now() + 12
	last_event = "Salvage drones slipped into %s." % String(room.get("name", "the building"))
	state_changed.emit()
	return {"ok": true, "message": last_event}

func upgrade_room(room_id: String) -> Dictionary:
	var room := get_room(room_id)
	if room.is_empty() or not bool(room.get("repaired", false)):
		return {"ok": false, "message": "Rebuild that building before upgrading it."}
	var level := int(room.get("level", 1))
	if level >= MAX_ROOM_LEVEL:
		return {"ok": false, "message": "%s is already max level." % room.get("name", "Building")}
	var cost := 100 + level * 85
	if credits < cost:
		return {"ok": false, "message": "The level %d upgrade needs %d credits." % [level + 1, cost]}
	credits -= cost
	room["level"] = level + 1
	last_event = "%s upgraded to level %d." % [room.get("name", "Building"), level + 1]
	state_changed.emit()
	return {"ok": true, "message": last_event}

func begin_black_tech() -> Dictionary:
	if black_tech_end > 0:
		return {"ok": false, "message": "A Black Tech project is already running."}
	if not is_room_repaired("signal_den"):
		return {"ok": false, "message": "Rebuild the Signal Den first."}
	var credit_cost := 90 + black_tech_level * 45
	var intel_cost := 4 + black_tech_level * 2
	if credits < credit_cost or intel < intel_cost:
		return {"ok": false, "message": "Black Tech needs %d credits and %d intel." % [credit_cost, intel_cost]}
	credits -= credit_cost
	intel -= intel_cost
	black_tech_end = _now() + max(8, 18 - get_room_level("signal_den"))
	last_event = "Signal Den started Black Tech level %d." % (black_tech_level + 1)
	state_changed.emit()
	return {"ok": true, "message": last_event}

func fence_contraband() -> Dictionary:
	if contraband <= 0:
		return {"ok": false, "message": "No contraband is ready to fence."}
	if not is_room_repaired("tunnel"):
		return {"ok": false, "message": "Rebuild the Smuggler Tunnel first."}
	var moved := mini(contraband, 5 + black_tech_level + get_room_level("tunnel"))
	var payout := moved * (22 + black_tech_level * 3 + get_room_level("tunnel") * 2)
	contraband -= moved
	credits += payout
	heat = clampi(heat + 1, 0, 100)
	last_event = "FENCE COMPLETE // %d contraband became %d credits." % [moved, payout]
	state_changed.emit()
	return {"ok": true, "message": last_event}

func begin_job(job_id: String, crew_ids: Array[String]) -> Dictionary:
	if not active_job.is_empty():
		return {"ok": false, "message": "Another crew is already on a live score."}
	var job_index := -1
	for index in range(jobs.size()):
		if String(jobs[index].get("id", "")) == job_id:
			job_index = index
			break
	if job_index < 0:
		return {"ok": false, "message": "That score window has closed."}
	var valid_ids: Array[String] = []
	for crew_id in crew_ids:
		var member := get_crew_member(crew_id)
		if not member.is_empty() and crew_available(member):
			valid_ids.append(crew_id)
	if valid_ids.is_empty():
		return {"ok": false, "message": "Select at least one available crew member."}
	var limit := 3
	if is_room_repaired("boss_office"):
		limit = mini(4, 2 + get_room_level("boss_office"))
	if valid_ids.size() > limit:
		valid_ids.resize(limit)
	active_job = jobs[job_index].duplicate(true)
	active_crew_ids = valid_ids
	jobs.remove_at(job_index)
	for crew_id in active_crew_ids:
		get_crew_member(crew_id)["busy_until"] = _now() + 45
	heat = clampi(heat + int(active_job.get("heat_gain", 4)), 0, 100)
	last_event = "CREW DEPLOYED // %s." % String(active_job.get("title", "Underworld score"))
	state_changed.emit()
	return {"ok": true, "message": last_event}

func finish_job(victory: bool, surviving_hp: Dictionary) -> void:
	var now := _now()
	for crew_id in active_crew_ids:
		var member := get_crew_member(crew_id)
		if member.is_empty():
			continue
		var hp_value := int(surviving_hp.get(crew_id, member.get("hp", 1)))
		member["hp"] = max(1, hp_value)
		member["busy_until"] = now + 8
		if hp_value <= int(float(member.get("max_hp", 100)) * 0.25):
			var recovery := 30
			if is_room_repaired("clinic"):
				recovery = max(10, recovery - get_room_level("clinic") * 4)
			member["injured_until"] = now + recovery
	if victory and not active_job.is_empty():
		var reward := int(active_job.get("reward", 0))
		var cargo := int(active_job.get("contraband", 1))
		var difficulty := int(active_job.get("difficulty", 1))
		var market_bonus := 0
		if is_room_repaired("black_market"):
			market_bonus = get_room_level("black_market") * 8
		credits += reward + market_bonus
		contraband += cargo
		intel += difficulty
		notoriety += difficulty
		jobs_completed += 1
		for crew_id in active_crew_ids:
			var member := get_crew_member(crew_id)
			member["xp"] = int(member.get("xp", 0)) + 12 * difficulty
			_apply_crew_level(member)
		if bool(active_job.get("story", false)):
			_complete_story_job(String(active_job.get("story_id", "")), int(active_job.get("chapter", story_chapter)))
		last_event = "SCORE CLEAN // +%d credits, +%d contraband." % [reward + market_bonus, cargo]
	else:
		heat = clampi(heat + 8, 0, 100)
		last_event = "SCORE BURNED // The crew escaped, but Heat spiked to %d." % heat
	active_job.clear()
	active_crew_ids.clear()
	next_job_at = min(next_job_at, now + 5)
	save_game()
	state_changed.emit()

func save_game() -> Dictionary:
	var data := {
		"credits": credits, "contraband": contraband, "intel": intel, "heat": heat,
		"notoriety": notoriety, "black_tech_level": black_tech_level,
		"black_tech_end": black_tech_end, "story_chapter": story_chapter,
		"jobs_completed": jobs_completed, "pending_cutscene": pending_cutscene,
		"intro_seen": intro_seen, "rooms": rooms, "crew": crew, "jobs": jobs,
		"completed_story_jobs": completed_story_jobs, "active_job": active_job,
		"active_crew_ids": active_crew_ids, "next_job_at": next_job_at,
		"next_heat_decay_at": next_heat_decay_at, "job_serial": job_serial,
		"last_event": last_event
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Save file could not be opened."}
	file.store_string(JSON.stringify(data))
	return {"ok": true, "message": "Syndicate operation saved."}

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"ok": false, "message": "No Syndicate save exists yet."}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Save file could not be read."}
	var parsed := JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "message": "The Syndicate save is invalid."}
	var data := parsed as Dictionary
	credits = int(data.get("credits", 650))
	contraband = int(data.get("contraband", 20))
	intel = int(data.get("intel", 12))
	heat = int(data.get("heat", 8))
	notoriety = int(data.get("notoriety", 1))
	black_tech_level = int(data.get("black_tech_level", 1))
	black_tech_end = int(data.get("black_tech_end", 0))
	story_chapter = int(data.get("story_chapter", 1))
	jobs_completed = int(data.get("jobs_completed", 0))
	pending_cutscene = String(data.get("pending_cutscene", ""))
	intro_seen = bool(data.get("intro_seen", false))
	rooms = _dictionary_array(data.get("rooms", []))
	crew = _dictionary_array(data.get("crew", []))
	jobs = _dictionary_array(data.get("jobs", []))
	completed_story_jobs = _string_array(data.get("completed_story_jobs", []))
	active_job = Dictionary(data.get("active_job", {}))
	active_crew_ids = _string_array(data.get("active_crew_ids", []))
	next_job_at = int(data.get("next_job_at", _now() + 4))
	next_heat_decay_at = int(data.get("next_heat_decay_at", _now() + 12))
	job_serial = int(data.get("job_serial", 1))
	last_event = "Syndicate operation loaded."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func consume_cutscene() -> String:
	var value := pending_cutscene
	pending_cutscene = ""
	if value == "prologue":
		intro_seen = true
	save_game()
	state_changed.emit()
	return value

func get_room(room_id: String) -> Dictionary:
	for room in rooms:
		if String(room.get("id", "")) == room_id:
			return room
	return {}

func get_room_level(room_id: String) -> int:
	var room := get_room(room_id)
	return int(room.get("level", 1)) if not room.is_empty() else 0

func is_room_repaired(room_id: String) -> bool:
	var room := get_room(room_id)
	return not room.is_empty() and bool(room.get("repaired", false))

func get_crew_member(crew_id: String) -> Dictionary:
	for member in crew:
		if String(member.get("id", "")) == crew_id:
			return member
	return {}

func active_crew() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for crew_id in active_crew_ids:
		var member := get_crew_member(crew_id)
		if not member.is_empty():
			result.append(member)
	return result

func crew_available(member: Dictionary) -> bool:
	var now := _now()
	return now >= int(member.get("busy_until", 0)) and now >= int(member.get("injured_until", 0))

func seconds_left(timestamp: int) -> int:
	return max(0, timestamp - _now())

func _generate_job() -> void:
	var has_story := false
	for job in jobs:
		if bool(job.get("story", false)):
			has_story = true
			break
	var template: Dictionary
	if not has_story and story_chapter <= FINAL_STORY_CHAPTER:
		template = _story_template(story_chapter)
	else:
		var templates: Array[Dictionary] = [
			{"title":"Hijack Supply Skiff","sector":"Tycho Freight Spine","difficulty":1,"target":"Peacekeepers"},
			{"title":"Crack Evidence Vault","sector":"Blueglass Ward","difficulty":2,"target":"Peacekeepers"},
			{"title":"Siphon Transit Payroll","sector":"Mare Exchange","difficulty":1,"target":"Corporate Security"},
			{"title":"Extract Captured Fixer","sector":"Dock Seven","difficulty":2,"target":"Peacekeepers"},
			{"title":"Sabotage Sensor Grid","sector":"Signal Canyon","difficulty":3,"target":"Peacekeepers"},
			{"title":"Smuggle Reactor Cores","sector":"Eclipse Foundry","difficulty":3,"target":"Customs Patrol"},
			{"title":"Raid Rival Cache","sector":"Crater Market","difficulty":2,"target":"Hollow Fang"}
		]
		template = templates[_rng.randi_range(0, templates.size() - 1)]
	_add_job(template)

func _story_template(chapter: int) -> Dictionary:
	match chapter:
		1: return {"title":"Steal the Ghost Key","sector":"Crater Market Relay","difficulty":1,"target":"Peacekeepers","story":true,"story_id":"ghost_key","chapter":1}
		2: return {"title":"Break Blueglass Records","sector":"Blueglass Evidence Vault","difficulty":2,"target":"Peacekeepers","story":true,"story_id":"blueglass","chapter":2}
		3: return {"title":"Hijack the Dawn Convoy","sector":"Mare Highway","difficulty":3,"target":"Armored Patrol","story":true,"story_id":"dawn_convoy","chapter":3}
		4: return {"title":"Blackout the Precinct","sector":"Authority Grid Seven","difficulty":3,"target":"Peacekeepers","story":true,"story_id":"blackout","chapter":4}
		_: return {"title":"Crown the Crater","sector":"Eclipse Signal Tower","difficulty":4,"target":"Peacekeeper Command","story":true,"story_id":"crater_crown","chapter":5}

func _add_job(template: Dictionary) -> void:
	var difficulty := int(template.get("difficulty", 1))
	var job_id := "job_%04d" % job_serial
	job_serial += 1
	var response_bonus := heat / 12
	var job := {
		"id": job_id, "title": String(template.get("title", "Underworld Score")),
		"sector": String(template.get("sector", "Unknown Sector")),
		"target": String(template.get("target", "Peacekeepers")),
		"difficulty": difficulty, "reward": 75 + difficulty * 60 + notoriety * 4,
		"contraband": 1 + difficulty, "heat_gain": 3 + difficulty * 2,
		"expires_at": _now() + max(32, 62 - heat / 2) + _rng.randi_range(0, 18),
		"enemy_hp": 72 + difficulty * 58 + response_bonus * 5,
		"enemy_power": 10 + difficulty * 5 + response_bonus,
		"story": bool(template.get("story", false)),
		"story_id": String(template.get("story_id", "")),
		"chapter": int(template.get("chapter", 0))
	}
	jobs.append(job)
	next_job_at = _now() + _rng.randi_range(17, 25)
	last_event = "NEW SCORE // %s in %s." % [job.get("title", "Score"), job.get("sector", "Sector")]
	job_added.emit(job_id)

func _complete_story_job(story_id: String, chapter: int) -> void:
	if story_id.is_empty() or completed_story_jobs.has(story_id):
		return
	completed_story_jobs.append(story_id)
	if chapter >= story_chapter:
		story_chapter = mini(FINAL_STORY_CHAPTER + 1, chapter + 1)
	match chapter:
		1: pending_cutscene = "ghost_key"
		3: pending_cutscene = "war_room"
		5: pending_cutscene = "finale"
		_: pending_cutscene = ""

func _apply_crew_level(member: Dictionary) -> void:
	var level := int(member.get("level", 1))
	var needed := level * 80
	while int(member.get("xp", 0)) >= needed and level < 20:
		member["xp"] = int(member.get("xp", 0)) - needed
		level += 1
		member["level"] = level
		member["power"] = int(member.get("power", 50)) + 5
		member["max_hp"] = int(member.get("max_hp", 100)) + 6
		member["hp"] = int(member.get("max_hp", 100))
		member["defense"] = int(member.get("defense", 10)) + 2
		needed = level * 80

func _room(id_value: String, name_value: String, function_value: String, art_value: String, repaired_value: bool, cost_value: int) -> Dictionary:
	return {"id":id_value,"name":name_value,"function":function_value,"art":art_value,"level":1,"repaired":repaired_value,"repair_cost":cost_value,"repair_end":0}

func _crew_member(id_value: String, name_value: String, role_value: String, power_value: int, hp_value: int, defense_value: int, portrait_value: String) -> Dictionary:
	return {"id":id_value,"name":name_value,"role":role_value,"rarity":"Common","level":1,"power":power_value,"max_hp":hp_value,"hp":hp_value,"defense":defense_value,"xp":0,"portrait":portrait_value,"busy_until":0,"injured_until":0}

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				result.append(item)
	return result

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result

func _now() -> int:
	return int(Time.get_unix_time_from_system())
