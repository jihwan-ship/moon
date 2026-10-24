class_name Fx
## 연출 도우미: 초승달 베기, 불꽃, 숫자, 충격파 등. 모두 parent 아래에 붙였다가 스스로 사라진다.

static var _add_mat: CanvasItemMaterial
static var _star: Texture2D


static func add_mat() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat


static func star_tex() -> Texture2D:
	if _star == null:
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var dx := absf(x - 15.5) / 16.0
				var dy := absf(y - 15.5) / 16.0
				var v := clampf(1.0 - (dx * dy * 14.0 + (dx + dy) * 0.55), 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, v * v))
		_star = ImageTexture.create_from_image(img)
	return _star


## 흰 초승달. 각도는 도(화면 기준, 0 = 오른쪽, 90 = 아래)
static func crescent(parent: Node, center: Vector2, r: float, a0: float, a1: float, thick: float, color := Color.WHITE, dur := 0.13) -> void:
	var root := Node2D.new()
	root.position = center
	root.z_index = 40
	parent.add_child(root)
	var glow := Polygon2D.new()
	glow.material = add_mat()
	glow.color = Color(color.r, color.g, color.b, 0.35)
	var core := Polygon2D.new()
	core.material = add_mat()
	core.color = Color(color.r, color.g, color.b, 0.95)
	var edge := Line2D.new()
	edge.width = 3.0
	edge.default_color = Color(1, 1, 1, 1)
	edge.material = add_mat()
	root.add_child(glow)
	root.add_child(core)
	root.add_child(edge)
	var build := func(p: float) -> void:
		var n := 36
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		var outer_g := PackedVector2Array()
		var inner_g := PackedVector2Array()
		var m := maxi(2, int(n * p))
		for i in m + 1:
			var t := float(i) / n
			var a := deg_to_rad(lerpf(a0, a1, t))
			var w := thick * pow(sin(PI * clampf(t / maxf(p, 0.01), 0.0, 1.0)), 0.8)
			var dir := Vector2(cos(a), sin(a))
			outer.append(dir * r)
			inner.append(dir * (r - w))
			outer_g.append(dir * (r + w * 0.6))
			inner_g.append(dir * (r - w * 1.6))
		var poly := outer.duplicate()
		var inv := inner.duplicate()
		inv.reverse()
		poly.append_array(inv)
		core.polygon = poly
		var gpoly := outer_g.duplicate()
		var ginv := inner_g.duplicate()
		ginv.reverse()
		gpoly.append_array(ginv)
		glow.polygon = gpoly
		edge.points = outer
	build.call(0.01)
	var tw := root.create_tween()
	tw.tween_method(build, 0.01, 1.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "modulate:a", 0.0, 0.28)
	tw.tween_callback(root.queue_free)
	for k in 6:
		var a := deg_to_rad(lerpf(a0, a1, randf()))
		sparkle(parent, center + Vector2(cos(a), sin(a)) * r, 0.5, dur * 0.6)


## 찌르기 궤적: 곧은 빛줄기
static func thrust(parent: Node, from: Vector2, to: Vector2, color := Color.WHITE, width := 16.0) -> void:
	var l := Line2D.new()
	l.points = PackedVector2Array([from, to])
	l.width = width
	l.default_color = color
	l.material = add_mat()
	l.z_index = 40
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.1))
	curve.add_point(Vector2(0.75, 1.0))
	curve.add_point(Vector2(1, 0.0))
	l.width_curve = curve
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "width", width * 1.5, 0.05)
	tw.tween_property(l, "modulate:a", 0.0, 0.22)
	tw.tween_callback(l.queue_free)


static func sparkle(parent: Node, pos: Vector2, size := 1.0, delay := 0.0) -> void:
	var s := Sprite2D.new()
	s.texture = star_tex()
	s.material = add_mat()
	s.position = pos
	s.scale = Vector2.ONE * 0.2 * size
	s.z_index = 41
	parent.add_child(s)
	var tw := s.create_tween()
	if delay > 0:
		s.modulate.a = 0
		tw.tween_interval(delay)
		tw.tween_property(s, "modulate:a", 1.0, 0.01)
	tw.tween_property(s, "scale", Vector2.ONE * 1.6 * size, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "rotation", 0.8, 0.3)
	tw.tween_property(s, "modulate:a", 0.0, 0.18)
	tw.tween_callback(s.queue_free)


## 타격 불꽃: 사방으로 튀는 선
static func burst(parent: Node, pos: Vector2, color := Color(1, 0.95, 0.8), amount := 18, speed := 520.0, size := 1.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 42
	p.material = add_mat()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.35
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.damping_min = speed * 1.5
	p.damping_max = speed * 2.0
	p.scale_amount_min = 3.0 * size
	p.scale_amount_max = 7.0 * size
	p.color = color
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = grad
	parent.add_child(p)
	p.emitting = true
	sparkle(parent, pos, 1.3 * size)
	parent.get_tree().create_timer(0.8).timeout.connect(p.queue_free)


## 퍼지는 원
static func ring(parent: Node, pos: Vector2, color: Color, r0 := 20.0, r1 := 140.0, dur := 0.35, width := 8.0) -> void:
	var l := Line2D.new()
	l.width = width
	l.default_color = color
	l.material = add_mat()
	l.closed = true
	l.position = pos
	l.z_index = 39
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(Vector2(cos(a), sin(a)))
	parent.add_child(l)
	var set_r := func(r: float) -> void:
		var q := PackedVector2Array()
		for v in pts:
			q.append(v * r)
		l.points = q
	set_r.call(r0)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_method(set_r, r0, r1, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "width", 1.0, dur)
	tw.tween_property(l, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(l.queue_free)


## 총구 섬광
static func muzzle(parent: Node, pos: Vector2, dir := 1.0) -> void:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 10:
		var a := -0.5 + i / 9.0
		var r := 70.0 if i % 2 == 0 else 26.0
		pts.append(Vector2(cos(a) * r * dir, sin(a) * r * 0.9))
	pts.append(Vector2.ZERO)
	poly.polygon = pts
	poly.color = Color(1, 0.9, 0.6)
	poly.material = add_mat()
	poly.position = pos
	poly.z_index = 42
	parent.add_child(poly)
	var tw := poly.create_tween()
	tw.tween_property(poly, "scale", Vector2(1.4, 1.2), 0.05)
	tw.tween_property(poly, "modulate:a", 0.0, 0.08)
	tw.tween_callback(poly.queue_free)
	sparkle(parent, pos, 0.9)


## 폭발
static func explosion(parent: Node, pos: Vector2) -> void:
	for k in 3:
		var c := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(Vector2(cos(a), sin(a)) * (1.0 + randf() * 0.25))
		c.polygon = pts
		c.color = [Color(1, 0.95, 0.7), Color(1, 0.6, 0.2), Color(0.3, 0.28, 0.25)][k]
		c.position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 10))
		c.z_index = 42 - k
		c.scale = Vector2.ONE * 10
		parent.add_child(c)
		var tw := c.create_tween()
		tw.tween_property(c, "scale", Vector2.ONE * (90 + k * 30), 0.18 + k * 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "modulate:a", 0.0, 0.3 + k * 0.15)
		tw.tween_callback(c.queue_free)
	burst(parent, pos, Color(1, 0.75, 0.35), 40, 900.0, 1.6)
	ring(parent, pos, Color(1, 0.85, 0.6), 30, 260, 0.45, 14)


## 떠오르는 숫자나 글자
static func float_text(parent: Node, pos: Vector2, text: String, color: Color, size := 56, font: Font = null) -> void:
	var l := Label.new()
	l.text = text
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.02))
	l.add_theme_constant_override("outline_size", maxi(8, size / 5))
	l.z_index = 60
	parent.add_child(l)
	l.reset_size()
	l.pivot_offset = l.size / 2
	l.position = pos - l.size / 2
	l.scale = Vector2.ONE * 1.8
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.45)
	tw.tween_property(l, "position:y", l.position.y - 70, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)
