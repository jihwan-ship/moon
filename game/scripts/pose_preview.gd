extends Node2D
## 포즈 확인용. 모든 포즈를 격자로 늘어놓는다. (개발용, 게임에는 쓰지 않는다)

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.45, 0.45, 0.45))
	var kind := "s"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("kind="):
			kind = a.substr(5)
	var names := Poses.names(kind)
	var cols := 4 if kind == "t" else 6
	for i in names.size():
		var p := Puppet.new()
		add_child(p)
		p.setup(kind)
		p.set_pose(Poses.get_pose(kind, names[i]))
		var sc := 0.62 if kind == "t" else 0.95
		p.position = Vector2(110 + (i % cols) * (1240.0 / cols), (230 if kind == "t" else 330) + (i / cols) * (240 if kind == "t" else 360))
		p.scale = Vector2(sc, sc)
		if kind == "t":
			p.set_rank(i % 4 + 1)
		var l := Label.new()
		l.text = names[i]
		l.position = p.position + Vector2(-60, 10)
		l.add_theme_font_size_override("font_size", 18)
		add_child(l)
