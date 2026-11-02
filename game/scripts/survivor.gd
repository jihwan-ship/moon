extends Node2D
## 뱀서라이크 테스트판: 쫄라맨 정시우가 몰려오는 엄지척 아재 떼를 공방 무기로 버틴다.
## 정시우는 움직이기만 하고 무기는 알아서 나간다. 경험치 방울을 모아 레벨이 오르면 세 가지 중 하나를 고른다.
## 방향키/WASD(폰은 화면을 누른 채 끌기)로 움직인다. 이펙트는 카드 게임과 같은 낙서 느낌.

const ARENA := 2000.0            # 경기장 반지름(정사각형 절반 길이)
const INK := Color(0.08, 0.07, 0.07)
const PAPER := Color(0.97, 0.96, 0.93)

const WEAPONS := {
	"logic": {"name": "로직 아틀리에", "desc": "가까운 적에게 리볼버. 레벨이 오르면 더 자주, 가끔 샷건"},
	"durandal": {"name": "뒤랑달", "desc": "보는 쪽으로 커다란 초승달 베기"},
	"mook": {"name": "묵 공방", "desc": "주변을 둥글게 한 번에 베는 검기"},
	"wheels": {"name": "휠즈 인더스트리", "desc": "근처 적 무리에 대검을 내리찍는다"},
}
const PASSIVES := {
	"speed": {"name": "구보 훈련", "desc": "이동 속도 +12%"},
	"hp": {"name": "짬밥 곱빼기", "desc": "최대 체력 +25, 체력 회복"},
	"magnet": {"name": "자석 군번줄", "desc": "경험치 줍는 거리 +40%"},
	"might": {"name": "그건 그거고", "desc": "모든 무기 피해 +15%"},
}
const MAX_LV := 5

var fb: Font
var ft: Font
var world: Node2D
var fxl: Node2D
var cam: Camera2D
var player: Puppet
var ui: CanvasLayer
var hp_fill: ColorRect
var xp_fill: ColorRect
var info: Label
var panel: Control

var pos := Vector2.ZERO
var facing := 1.0
var move := Vector2.ZERO
var touch_from := Vector2.ZERO
var touching := false
var hp := 100.0
var max_hp := 100.0
var hurt_cd := 0.0
var speed := 230.0
var magnet := 150.0
var might := 1.0
var lv := 1
var xp := 0
var xp_need := 4
var kills := 0
var t := 0.0
var spawn_cd := 0.0
var boss_next := 90.0
var weapons := {"logic": 1}
var passives := {}
var cds := {}
var shot_count := 0
var enemies: Array = []
var gems: Array = []
var bullets: Array = []
var over := false
var auto := false
var aigo_cd := 0.0
var pose_name := ""


func _ready() -> void:
	randomize()
	Cfg.mode = "sium"
	for a in OS.get_cmdline_user_args():
		if a == "test=auto":
			auto = true
	fb = load("res://fonts/Pretendard-Black.ttf")
	ft = load("res://fonts/BlackHanSans.ttf")
	RenderingServer.set_default_clear_color(Color("1d1820"))
	world = Node2D.new()
	add_child(world)
	var ground := Node2D.new()
	ground.set_script(load("res://scripts/survivor_ground.gd"))
	ground.z_index = -10
	world.add_child(ground)
	player = Puppet.new()
	world.add_child(player)
	player.setup("k")
	player.scale = Vector2(0.55, 0.55)
	player.z_index = 5
	fxl = Node2D.new()
	fxl.z_index = 20
	world.add_child(fxl)
	cam = Camera2D.new()
	world.add_child(cam)
	_build_ui()
	Sfx.play_bgm("bgm")


# ---------------------------------------------------------------- 화면 위 표시

func _label(text: String, size_: int, col := Color("f3eadb"), font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else fb)
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", INK)
	return l


func _button(text: String, pos_: Vector2, size_: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos_
	b.size = size_
	b.add_theme_font_override("font", ft)
	b.add_theme_font_size_override("font_size", 24)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("3a2210")
	sb.border_color = Color("e08a2c")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	var sbh := sb.duplicate()
	sbh.bg_color = Color("5a3416")
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.add_theme_color_override("font_color", Color("e6bd5c"))
	return b


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	var xb := ColorRect.new()
	xb.color = Color(0, 0, 0, 0.6)
	xb.position = Vector2(0, 0)
	xb.size = Vector2(1280, 14)
	ui.add_child(xb)
	xp_fill = ColorRect.new()
	xp_fill.color = Color("6fb7ff")
	xp_fill.size = Vector2(0, 14)
	ui.add_child(xp_fill)
	var hb := ColorRect.new()
	hb.color = Color(0, 0, 0, 0.6)
	hb.position = Vector2(20, 26)
	hb.size = Vector2(300, 20)
	ui.add_child(hb)
	hp_fill = ColorRect.new()
	hp_fill.color = Color("e0503f")
	hp_fill.position = Vector2(22, 28)
	hp_fill.size = Vector2(296, 16)
	ui.add_child(hp_fill)
	info = _label("", 22)
	info.position = Vector2(20, 50)
	ui.add_child(info)
	var back := _button("타이틀로", Vector2(1130, 24), Vector2(130, 44))
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(_to_title)
	ui.add_child(back)
	var hint := _label("방향키/WASD로 이동 (폰은 화면을 누른 채 끌기). 무기는 알아서 나간다.", 18, Color("cfc4b3"))
	hint.position = Vector2(0, 680)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(hint)
	var tw := hint.create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(hint, "modulate:a", 0.0, 1.0)


func _refresh_ui() -> void:
	hp_fill.size.x = 296.0 * clampf(hp / max_hp, 0, 1)
	xp_fill.size.x = 1280.0 * clampf(float(xp) / xp_need, 0, 1)
	info.text = "Lv %d   %02d:%02d   처치 %d" % [lv, int(t) / 60, int(t) % 60, kills]


func _to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


# ---------------------------------------------------------------- 입력

func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		touching = e.pressed
		touch_from = e.position
		if not e.pressed:
			move = Vector2.ZERO
	elif e is InputEventScreenDrag and touching:
		var d: Vector2 = e.position - touch_from
		move = d.limit_length(70.0) / 70.0 if d.length() > 8 else Vector2.ZERO


func _key_dir() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		d.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		d.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		d.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		d.y += 1
	return d.normalized()


# ---------------------------------------------------------------- 매 프레임

func _process(dt: float) -> void:
	if over or get_tree().paused:
		return
	t += dt
	hurt_cd -= dt
	aigo_cd -= dt
	var d := _key_dir()
	if d == Vector2.ZERO:
		d = move
	if auto:
		d = Vector2(cos(t * 0.7), sin(t * 1.1)).normalized()
	_move_player(d, dt)
	_spawn(dt)
	_update_enemies(dt)
	_update_bullets(dt)
	_update_gems(dt)
	_fire_weapons(dt)
	_refresh_ui()


func _move_player(d: Vector2, dt: float) -> void:
	pos += d * speed * dt
	pos = pos.clamp(Vector2(-ARENA, -ARENA), Vector2(ARENA, ARENA))
	player.position = pos
	if absf(d.x) > 0.1:
		facing = signf(d.x)
	player.scale.x = absf(player.scale.x) * facing
	var want := "run" if d.length() > 0.1 else "idle"
	if pose_name != want:
		pose_name = want
		player.pose(want, 0.12)
	# 달릴 때 들썩
	player.body_root.position.y = -absf(sin(t * 14.0)) * 6.0 if d.length() > 0.1 else 0.0
	cam.position = pos + Vector2(0, -40)


# ---------------------------------------------------------------- 적

func _spawn(dt: float) -> void:
	spawn_cd -= dt
	if spawn_cd <= 0:
		spawn_cd = maxf(0.3, 1.4 - t * 0.005)
		var n := 1 + int(t / 45.0)
		for k in n:
			_add_enemy(false)
	if t >= boss_next:
		boss_next += 90.0
		_add_enemy(true)


func _add_enemy(boss: bool) -> void:
	var ang := randf() * TAU
	var p := pos + Vector2.from_angle(ang) * randf_range(720, 900)
	p = p.clamp(Vector2(-ARENA, -ARENA), Vector2(ARENA, ARENA))
	var s := Sprite2D.new()
	s.texture = load("res://art/sium/thumb.png")
	s.offset = Vector2(0, -s.texture.get_height() * 0.5)
	var sc := 0.36 if boss else randf_range(0.12, 0.16)
	s.scale = Vector2.ONE * sc
	s.position = p
	s.z_index = 4
	world.add_child(s)
	var base := 8.0 + t * 0.15
	enemies.append({"node": s, "hp": base * (40.0 if boss else 1.0), "spd": (55.0 if boss else randf_range(70, 100) + t * 0.15),
		"dmg": 20.0 if boss else 6.0, "r": 70.0 if boss else 24.0, "boss": boss, "xp": 30 if boss else 1, "hit": 0.0})
	if boss:
		_float_text(p + Vector2(0, -260), "병장 짬타이거 등장!", Color("ff5a3a"), 40)


func _update_enemies(dt: float) -> void:
	for e in enemies:
		var s: Sprite2D = e["node"]
		var to := pos - s.position
		var dist := to.length()
		if dist > 1:
			s.position += to / dist * e["spd"] * dt
		s.flip_h = to.x > 0
		# 걸을 때 뒤뚱
		s.rotation = sin(t * 9.0 + s.position.x * 0.01) * 0.12
		e["hit"] = maxf(0.0, e["hit"] - dt)
		s.modulate = Color(1, 0.5, 0.5) if e["hit"] > 0 else Color.WHITE
		if dist < e["r"] + 20 and hurt_cd <= 0:
			_hurt_player(e["dmg"])
	# 서로 너무 겹치지 않게 살짝 밀어낸다
	for i in range(0, enemies.size(), 2):
		var a: Sprite2D = enemies[i]["node"]
		var j := (i + 1 + int(t * 7)) % enemies.size()
		if j == i:
			continue
		var b: Sprite2D = enemies[j]["node"]
		var dv := a.position - b.position
		if dv.length() < 30 and dv.length() > 0.1:
			a.position += dv.normalized() * 30 * dt
			b.position -= dv.normalized() * 30 * dt


func _hurt_player(dmg: float) -> void:
	hp -= dmg
	hurt_cd = 0.7
	Sfx.play("hit", -4)
	player.modulate = Color(1, 0.4, 0.4)
	var tw := player.create_tween()
	tw.tween_property(player, "modulate", Color.WHITE, 0.3)
	_shake(6)
	if hp <= 0:
		_game_over()


func _damage(e: Dictionary, dmg: float) -> void:
	if e["hp"] <= 0:
		return
	dmg *= might
	e["hp"] -= dmg
	e["hit"] = 0.12
	var s: Sprite2D = e["node"]
	_float_text(s.position + Vector2(randf_range(-10, 10), -s.texture.get_height() * s.scale.y - 10), str(int(dmg)), Color("ff4a3a"), 22)
	if aigo_cd <= 0:
		aigo_cd = 0.35
		Sfx.play(["aigo1", "aigo2"].pick_random(), -6, 0.06)
	if e["hp"] <= 0:
		kills += 1
		_drop_gem(s.position, e["xp"])
		var tw := s.create_tween().set_parallel(true)
		tw.tween_property(s, "rotation", 1.6 * (1 if randf() < 0.5 else -1), 0.25)
		tw.tween_property(s, "modulate:a", 0.0, 0.25)
		tw.chain().tween_callback(s.queue_free)


func _prune() -> void:
	enemies = enemies.filter(func(e): return e["hp"] > 0)


# ---------------------------------------------------------------- 경험치

func _drop_gem(p: Vector2, val: int) -> void:
	var g := Node2D.new()
	g.position = p
	g.z_index = 3
	var r := 7.0 if val < 5 else 14.0
	var pts := PackedVector2Array([Vector2(0, -r), Vector2(r * 0.7, 0), Vector2(0, r), Vector2(-r * 0.7, 0)])
	var f := Polygon2D.new()
	f.polygon = pts
	f.color = Color("8fd0ff")
	var l := Line2D.new()
	l.points = pts + PackedVector2Array([pts[0]])
	l.width = 3
	l.default_color = INK
	g.add_child(f)
	g.add_child(l)
	world.add_child(g)
	gems.append({"node": g, "val": val, "pull": false})


func _update_gems(dt: float) -> void:
	var left: Array = []
	for gm in gems:
		var g: Node2D = gm["node"]
		var to := pos + Vector2(0, -40) - g.position
		if to.length() < magnet:
			gm["pull"] = true
		if gm["pull"]:
			g.position += to.normalized() * minf(to.length(), 600.0 * dt)
			if to.length() < 24:
				g.queue_free()
				_gain_xp(gm["val"])
				continue
		left.append(gm)
	gems = left


func _gain_xp(v: int) -> void:
	xp += v
	if xp >= xp_need:
		xp -= xp_need
		lv += 1
		xp_need = 4 + lv * 3
		Sfx.play("fanfare", -6)
		_level_up()


func _level_up() -> void:
	var opts: Array = []
	for k in WEAPONS:
		if weapons.get(k, 0) < MAX_LV:
			opts.append(k)
	for k in PASSIVES:
		if passives.get(k, 0) < MAX_LV:
			opts.append(k)
	opts.shuffle()
	opts = opts.slice(0, 3)
	if opts.is_empty():
		return
	if auto:
		_pick(opts[0])
		return
	get_tree().paused = true
	panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(panel)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	var title := _label("레벨 업! \"그건 그거고 이건 이거니까\"", 36, Color("e6bd5c"), ft)
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	for i in opts.size():
		var k: String = opts[i]
		var info_: Dictionary = WEAPONS.get(k, PASSIVES.get(k))
		var cur: int = weapons.get(k, passives.get(k, 0))
		var head := "%s  %s" % [info_["name"], "새로!" if cur == 0 else "Lv %d → %d" % [cur, cur + 1]]
		var b := _button(head + "\n" + info_["desc"], Vector2(240, 240 + i * 120), Vector2(800, 100))
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(func(): _pick(k))
		panel.add_child(b)


func _pick(k: String) -> void:
	if WEAPONS.has(k):
		weapons[k] = weapons.get(k, 0) + 1
	else:
		passives[k] = passives.get(k, 0) + 1
		match k:
			"speed":
				speed *= 1.12
			"hp":
				max_hp += 25
				hp = max_hp
			"magnet":
				magnet *= 1.4
			"might":
				might *= 1.15
	if panel:
		panel.queue_free()
		panel = null
	get_tree().paused = false


# ---------------------------------------------------------------- 무기

func _fire_weapons(dt: float) -> void:
	for k in weapons:
		cds[k] = cds.get(k, 0.0) - dt
		if cds[k] > 0:
			continue
		var l: int = weapons[k]
		match k:
			"logic":
				cds[k] = maxf(0.3, 0.8 - 0.1 * (l - 1))
				_logic(l)
			"durandal":
				cds[k] = maxf(0.8, 1.9 - 0.22 * (l - 1))
				_durandal(l)
			"mook":
				cds[k] = maxf(1.4, 3.2 - 0.35 * (l - 1))
				_mook(l)
			"wheels":
				cds[k] = maxf(1.8, 4.2 - 0.45 * (l - 1))
				_wheels(l)
	_prune()


func _nearest(from: Vector2, max_d := 900.0) -> Dictionary:
	var best: Dictionary = {}
	var bd := max_d
	for e in enemies:
		var dd: float = (e["node"] as Sprite2D).position.distance_to(from)
		if dd < bd and e["hp"] > 0:
			bd = dd
			best = e
	return best


func _gun_origin() -> Vector2:
	return pos + Vector2(facing * 20, -60)


## 로직 아틀리에: 가까운 적에게 리볼버. 3레벨부터 두 발, 2레벨부터 세 번째마다 샷건
func _logic(l: int) -> void:
	var tgt := _nearest(pos)
	if tgt.is_empty():
		return
	shot_count += 1
	var o := _gun_origin()
	var dir := ((tgt["node"] as Sprite2D).position + Vector2(0, -30) - o).normalized()
	facing = signf(dir.x) if absf(dir.x) > 0.1 else facing
	var dmg := 8.0 + 3.0 * l
	if l >= 2 and shot_count % 3 == 0:
		Sfx.play("boom", -8)
		for k in 5:
			_bullet(o, dir.rotated(deg_to_rad(-20 + k * 10)), dmg * 0.8, 1)
		_muzzle(o, dir, true)
	else:
		Sfx.play("gun", -6)
		_bullet(o, dir, dmg, 1 + int(l >= 4))
		if l >= 3:
			_bullet(o, dir.rotated(0.12), dmg, 1)
		_muzzle(o, dir, false)


func _bullet(o: Vector2, dir: Vector2, dmg: float, pierce: int) -> void:
	var n := Line2D.new()
	n.points = PackedVector2Array([Vector2(-12, 0), Vector2(12, 0)])
	n.width = 6
	n.default_color = PAPER
	var edge := Line2D.new()
	edge.points = n.points
	edge.width = 10
	edge.default_color = INK
	edge.z_index = -1
	n.add_child(edge)
	n.position = o
	n.rotation = dir.angle()
	n.z_index = 15
	world.add_child(n)
	bullets.append({"node": n, "vel": dir * 900.0, "dmg": dmg, "pierce": pierce, "life": 0.9, "hit": []})


func _update_bullets(dt: float) -> void:
	var left: Array = []
	for b in bullets:
		var n: Line2D = b["node"]
		n.position += b["vel"] * dt
		b["life"] -= dt
		for e in enemies:
			if b["pierce"] <= 0 or e["hp"] <= 0 or b["hit"].has(e):
				continue
			var s: Sprite2D = e["node"]
			if (s.position + Vector2(0, -s.texture.get_height() * s.scale.y * 0.5)).distance_to(n.position) < e["r"] + 6:
				_damage(e, b["dmg"])
				b["hit"].append(e)
				b["pierce"] -= 1
		if b["life"] <= 0 or b["pierce"] <= 0:
			n.queue_free()
		else:
			left.append(b)
	bullets = left
	_prune()


func _muzzle(o: Vector2, dir: Vector2, big: bool) -> void:
	var tex: Texture2D = load("res://art/sium/gunfx.png")
	var s := Sprite2D.new()
	s.texture = tex
	s.position = o + dir * 30
	s.rotation = dir.angle()
	s.scale = Vector2.ONE * (0.9 if big else 0.55)
	s.z_index = 16
	fxl.add_child(s)
	var tw := s.create_tween()
	tw.tween_interval(0.06)
	tw.tween_property(s, "modulate:a", 0.0, 0.12)
	tw.tween_callback(s.queue_free)


## 뒤랑달: 보는 쪽으로 커다란 낙서 초승달. 그 안의 적을 벤다
func _durandal(l: int) -> void:
	var r := 150.0 + 22.0 * l
	var c := pos + Vector2(0, -50)
	Sfx.play("swing", -4)
	_doodle_moon(c, r, facing, 0.25)
	for e in enemies:
		var s: Sprite2D = e["node"]
		var v := s.position + Vector2(0, -30) - c
		if v.length() < r + e["r"] and v.x * facing > -20:
			_damage(e, 14.0 + 6.0 * l)
	_prune()


## 묵 공방: 주변 원 안의 적을 한 번에 베는 검기(낙서 고리와 빛줄기)
func _mook(l: int) -> void:
	var r := 170.0 + 28.0 * l
	var c := pos + Vector2(0, -50)
	Sfx.play("slash", -4)
	_doodle_ring(c, r)
	for k in 3:
		_doodle_line(c, randf_range(-50, 50) + k * 60.0, r * 1.1)
	for e in enemies:
		var s: Sprite2D = e["node"]
		if (s.position + Vector2(0, -30)).distance_to(c) < r + e["r"]:
			_damage(e, 10.0 + 5.0 * l)
	_prune()


## 휠즈 인더스트리: 근처 적 위치에 잠깐 뒤 대검을 내리찍는다(넓은 범위에 큰 피해)
func _wheels(l: int) -> void:
	var tgt := _nearest(pos, 600.0)
	var at: Vector2 = (tgt["node"] as Sprite2D).position if not tgt.is_empty() else pos + Vector2(facing * 200, 0)
	var r := 120.0 + 18.0 * l
	var mark := Line2D.new()
	mark.closed = true
	mark.width = 3
	mark.default_color = Color(1, 0.35, 0.3, 0.8)
	var pts := PackedVector2Array()
	for i in 24:
		pts.append(Vector2.from_angle(TAU * i / 24.0) * Vector2(r, r * 0.4))
	mark.points = pts
	mark.position = at
	mark.z_index = 2
	world.add_child(mark)
	await get_tree().create_timer(0.4, false).timeout
	if not is_instance_valid(mark):
		return
	mark.queue_free()
	Sfx.play("boom", -2)
	Sfx.play("heavy", -4)
	_shake(12)
	_burst(at, r)
	for e in enemies:
		if (e["node"] as Sprite2D).position.distance_to(at) < r + e["r"]:
			_damage(e, 30.0 + 14.0 * l)
	_prune()


# ---------------------------------------------------------------- 낙서 이펙트

func _fade(n: Node2D, hold: float, life: float) -> void:
	var tw := n.create_tween()
	tw.tween_interval(hold)
	tw.tween_property(n, "modulate:a", 0.0, life)
	tw.tween_callback(n.queue_free)


func _outlined(parent: Node2D, poly: PackedVector2Array, w := 4.0) -> void:
	var f := Polygon2D.new()
	f.polygon = poly
	f.color = PAPER
	var e := Line2D.new()
	e.points = poly + PackedVector2Array([poly[0]])
	e.width = w
	e.default_color = INK
	e.joint_mode = Line2D.LINE_JOINT_ROUND
	parent.add_child(f)
	parent.add_child(e)


func _doodle_moon(c: Vector2, r: float, dir: float, hold: float) -> void:
	var root := Node2D.new()
	root.position = c
	fxl.add_child(root)
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var n := 24
	for i in n + 1:
		var u := float(i) / n
		var a := deg_to_rad(lerpf(-95.0, 95.0, u))
		var v := Vector2(cos(a) * dir, sin(a))
		var w := sin(PI * u)
		outer.append(v * (r + randf_range(-4, 4) * w))
		if i > 0 and i < n:
			inner.append(v * (r - r * 0.32 * pow(w, 0.8)))
	inner.reverse()
	var poly := outer + inner
	if dir < 0:
		poly.reverse()
	_outlined(root, poly)
	root.scale = Vector2(0.85, 0.85)
	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector2.ONE, 0.06)
	_fade(root, hold, 0.25)


func _doodle_ring(c: Vector2, r: float) -> void:
	for k in 2:
		var l := Line2D.new()
		l.closed = true
		l.width = 9.0 - k * 4
		l.default_color = INK if k == 0 else PAPER
		var pts := PackedVector2Array()
		for i in 40:
			pts.append(Vector2.from_angle(TAU * i / 40.0) * (r + randf_range(-5, 5)) * Vector2(1, 0.75))
		l.points = pts
		l.position = c
		fxl.add_child(l)
		_fade(l, 0.25, 0.35)


func _doodle_line(c: Vector2, deg: float, half: float) -> void:
	var d := Vector2.from_angle(deg_to_rad(deg)) * half
	var root := Node2D.new()
	fxl.add_child(root)
	for k in 2:
		var l := Line2D.new()
		l.points = PackedVector2Array([c - d, c + d])
		l.width = 10.0 if k == 0 else 4.0
		l.default_color = INK if k == 0 else PAPER
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0.1))
		curve.add_point(Vector2(0.5, 1.0))
		curve.add_point(Vector2(1, 0.1))
		l.width_curve = curve
		root.add_child(l)
	_fade(root, 0.15, 0.3)


func _burst(at: Vector2, r: float) -> void:
	for k in 14:
		var a := deg_to_rad(randf_range(-170, -10))
		var dir := Vector2.from_angle(a)
		var len := randf_range(0.5, 1.0) * r * 1.4
		var w := randf_range(10, 18)
		var nrm := dir.orthogonal()
		var sp := Node2D.new()
		sp.position = at + Vector2(randf_range(-r * 0.4, r * 0.4), 0)
		fxl.add_child(sp)
		_outlined(sp, PackedVector2Array([nrm * w * 0.5, dir * len, -nrm * w * 0.5]), 3.0)
		sp.scale = Vector2.ZERO
		var tw := sp.create_tween()
		tw.tween_property(sp, "scale", Vector2.ONE, 0.06)
		tw.tween_interval(0.2)
		tw.tween_property(sp, "modulate:a", 0.0, 0.25)
		tw.tween_callback(sp.queue_free)


func _float_text(p: Vector2, text: String, col: Color, size_: int) -> void:
	var l := _label(text, size_, col, ft)
	l.position = p - Vector2(80, 0)
	l.size = Vector2(160, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 30
	world.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 40, 0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.chain().tween_callback(l.queue_free)


func _shake(a: float) -> void:
	var tw := cam.create_tween()
	for i in 4:
		tw.tween_property(cam, "offset", Vector2(randf_range(-a, a), randf_range(-a, a)), 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.03)


# ---------------------------------------------------------------- 끝

func _game_over() -> void:
	over = true
	Sfx.stop_bgm()
	Sfx.play("defeat")
	player.pose("hurt", 0.2)
	if auto:
		print("SURV over t=%.1f lv=%d kills=%d" % [t, lv, kills])
		get_tree().quit()
		return
	var p := Control.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(p)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(bg)
	var l := _label("버틴 시간 %02d:%02d   레벨 %d   처치 %d" % [int(t) / 60, int(t) % 60, lv, kills], 34, Color("f3eadb"), ft)
	l.position = Vector2(0, 260)
	l.size = Vector2(1280, 50)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	var t2 := _label("그건 그거고 이건 이거니까...", 28, Color("e6bd5c"), ft)
	t2.position = Vector2(0, 200)
	t2.size = Vector2(1280, 50)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(t2)
	var again := _button("다시 하기", Vector2(420, 360), Vector2(200, 64))
	again.pressed.connect(func(): get_tree().reload_current_scene())
	p.add_child(again)
	var back := _button("타이틀로", Vector2(660, 360), Vector2(200, 64))
	back.pressed.connect(_to_title)
	p.add_child(back)
