extends Node
## Original runtime-generated music and sound effects.

var muted := false
var _music := AudioStreamPlayer.new()
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_theme := ""

func _ready() -> void:
	add_child(_music)
	_music.bus = "Master"
	for index in range(6):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_pool.append(player)

func toggle_muted() -> bool:
	muted = not muted
	_music.volume_db = -80.0 if muted else -10.0
	return muted

func play_music(theme: String) -> void:
	if muted or theme == _music_theme:
		return
	_music_theme = theme
	var notes: Array[float]
	match theme:
		"combat": notes = [110.0, 146.8, 164.8, 123.5, 196.0, 164.8, 146.8, 123.5]
		"cutscene": notes = [82.4, 98.0, 123.5, 110.0, 82.4, 73.4, 98.0, 110.0]
		_: notes = [98.0, 123.5, 146.8, 110.0, 98.0, 82.4, 110.0, 123.5]
	_music.stream = _sequence(notes, 0.34, true)
	_music.volume_db = -12.0
	_music.play()

func stop_music() -> void:
	_music.stop()
	_music_theme = ""

func play_sfx(kind: String) -> void:
	if muted:
		return
	var frequency := 440.0
	var duration := 0.10
	match kind:
		"accept": frequency = 659.3
		"warning": frequency = 196.0; duration = 0.18
		"repair": frequency = 329.6; duration = 0.22
		"hit": frequency = 130.8; duration = 0.12
		"special": frequency = 784.0; duration = 0.28
		"victory": frequency = 880.0; duration = 0.34
		"defeat": frequency = 92.5; duration = 0.38
		_: frequency = 523.3
	var player := _available_player()
	player.stream = _tone(frequency, duration, false)
	player.volume_db = -7.0
	player.play()

func _available_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return _sfx_pool[0]

func _sequence(notes: Array[float], beat: float, looped: bool) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(float(notes.size()) * beat * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	for sample_index in range(total_samples):
		var time := float(sample_index) / sample_rate
		var note_index := mini(notes.size() - 1, int(time / beat))
		var local_time := fmod(time, beat)
		var envelope := min(1.0, local_time * 18.0) * max(0.0, 1.0 - local_time / beat)
		var wave := sin(TAU * notes[note_index] * time) * 0.22
		wave += sin(TAU * notes[note_index] * 0.5 * time) * 0.08
		bytes.encode_s16(sample_index * 2, int(clampf(wave * envelope, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = total_samples
	return stream

func _tone(frequency: float, duration: float, looped: bool) -> AudioStreamWAV:
	return _sequence([frequency], duration, looped)
