extends Node
## Original runtime-generated music and sound effects.

var muted: bool = false
var _music: AudioStreamPlayer = AudioStreamPlayer.new()
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_theme: String = ""

func _ready() -> void:
	add_child(_music)
	_music.bus = "Master"
	for _index: int in range(6):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
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
	var notes: Array[float] = []
	match theme:
		"combat":
			notes = [110.0, 146.8, 164.8, 123.5, 196.0, 164.8, 146.8, 123.5]
		"cutscene":
			notes = [82.4, 98.0, 123.5, 110.0, 82.4, 73.4, 98.0, 110.0]
		_:
			notes = [98.0, 123.5, 146.8, 110.0, 98.0, 82.4, 110.0, 123.5]
	_music.stream = _sequence(notes, 0.34, true)
	_music.volume_db = -12.0
	_music.play()

func stop_music() -> void:
	_music.stop()
	_music_theme = ""

func play_sfx(kind: String) -> void:
	if muted:
		return
	var frequency: float = 440.0
	var duration: float = 0.10
	match kind:
		"accept":
			frequency = 659.3
		"warning":
			frequency = 196.0
			duration = 0.18
		"repair":
			frequency = 329.6
			duration = 0.22
		"hit":
			frequency = 130.8
			duration = 0.12
		"special":
			frequency = 784.0
			duration = 0.28
		"victory":
			frequency = 880.0
			duration = 0.34
		"defeat":
			frequency = 92.5
			duration = 0.38
		_:
			frequency = 523.3
	var player: AudioStreamPlayer = _available_player()
	player.stream = _tone(frequency, duration, false)
	player.volume_db = -7.0
	player.play()

func _available_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			return player
	return _sfx_pool[0]

func _sequence(notes: Array[float], beat: float, looped: bool) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(float(notes.size()) * beat * float(sample_rate))
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total_samples * 2)
	for sample_index: int in range(total_samples):
		var time: float = float(sample_index) / float(sample_rate)
		var note_index: int = mini(notes.size() - 1, int(time / beat))
		var local_time: float = fmod(time, beat)
		var attack: float = minf(1.0, local_time * 18.0)
		var decay: float = maxf(0.0, 1.0 - local_time / beat)
		var envelope: float = attack * decay
		var wave: float = sin(TAU * notes[note_index] * time) * 0.22
		wave += sin(TAU * notes[note_index] * 0.5 * time) * 0.08
		bytes.encode_s16(sample_index * 2, int(clampf(wave * envelope, -1.0, 1.0) * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
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
	var notes: Array[float] = [frequency]
	return _sequence(notes, duration, looped)
