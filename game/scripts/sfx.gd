extends Node
## 효과음과 배경음 재생

var _cache := {}
var _pool: Array[AudioStreamPlayer] = []
var bgm: AudioStreamPlayer


func _ready() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	bgm = AudioStreamPlayer.new()
	bgm.volume_db = -12
	add_child(bgm)


func _stream(name_: String) -> AudioStream:
	if not _cache.has(name_):
		_cache[name_] = load("res://audio/%s.wav" % name_)
	return _cache[name_]


func play(name_: String, vol_db := 0.0, pitch_var := 0.08) -> void:
	for p in _pool:
		if not p.playing:
			p.stream = _stream(name_)
			p.volume_db = vol_db
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.play()
			return


func play_bgm(name_: String) -> void:
	var s: AudioStreamWAV = _stream(name_)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = s.data.size() / 2
	bgm.stream = s
	bgm.play()


func stop_bgm() -> void:
	bgm.stop()
