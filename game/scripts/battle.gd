extends Node2D
## 전투 장면: 상태, 턴 흐름, 합 판정, 연출을 모두 맡는다.

const GROUND := 500.0
const HOME := {"s": 360.0, "t": 920.0}
const SCALE := {"s": 0.84, "t": 0.86}
const CONTACT := 150.0

var cards := GameData.player_cards()
var tcards := GameData.tiger_cards()
var fb: Font = preload("res://fonts/Pretendard-Black.ttf")
var fr: Font = preload("res://fonts/Pretendard-SemiBold.ttf")
var ft: Font = preload("res://fonts/BlackHanSans.ttf")

# 상태
var P := {}
var T := {}
var phase := 0
var deck: Array = []
var discard: Array = []
var hand: Array = []
var slots: Array = []
var intents: Array = []
var busy := true
var turn_no := 0
var test_mode := ""

# 노드
var cam: Camera2D
var world: Node2D
var fxl: Node2D
var dim: ColorRect
var pup := {}
var shadow := {}
var ui: CanvasLayer
var hud := {}
var hand_box: Control
var slot_views: Array = []
var intent_views: Array = []
var lines: Control
var go_btn: Button
var banner_s: Banner
var banner_t: Banner
var bubble := {}
var dialog: Control
var dialog_name: Label
var dialog_text: Label
var overlay: Control
var toast: Label

signal dialog_next
signal mode_chosen(mode: String)


# ---------------------------------------------------------------- 준비

func _ready() -> void:
	randomize()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("test="):
			test_mode = a.substr(5)
	_build_world()
	_build_ui()
	if test_mode != "":
		_run_test()
	else:
		_title()


func _build_world() -> void:
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	world = Node2D.new()
	add_child(world)
	var bd := Node2D.new()
	bd.set_script(load("res://scripts/backdrop.gd"))
	bd.z_index = -50
	world.add_child(bd)
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0)
	dim.position = Vector2(-1000, -800)
	dim.size = Vector2(3400, 2400)
	dim.z_index = 2
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(dim)
	for who in ["s", "t"]:
		var sh := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(Vector2(cos(a) * 80, sin(a) * 14))
		sh.polygon = pts
		sh.color = Color(0, 0, 0, 0.35)
		sh.position = Vector2(HOME[who], GROUND + 4)
		sh.z_index = 5
		world.add_child(sh)
		shadow[who] = sh
		_make_puppet(who, false)
	fxl = Node2D.new()
	fxl.z_index = 30
	world.add_child(fxl)


## 캐릭터를 만든다. 롤랑 모드면 신병 대신 롤랑 자세 그림을 쓴다
func _make_puppet(who: String, roland: bool) -> void:
	if pup.has(who):
		pup[who].queue_free()
	var p: Node2D = SpritePuppet.new() if roland else Puppet.new()
	p.z_index = 10
	world.add_child(p)
	p.setup(who)
	p.position = Vector2(HOME[who], GROUND)
	if roland:
		p.scale = Vector2.ONE
	else:
		p.scale = Vector2(SCALE[who] * (1 if who == "s" else -1), SCALE[who])
	pup[who] = p
	# 숨쉬기
	var tw := p.create_tween().set_loops()
	var b: Node2D = p.body_root
	var d := 0.9 + (0.2 if who == "t" else 0.0)
	tw.tween_property(b, "scale:y", 1.018, d).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "scale:y", 1.0, d).set_trans(Tween.TRANS_SINE)


func _label(text: String, size_: int, col := Color("f3eadb"), font: Font = null, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else fr)
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _bar(parent: Control, pos: Vector2, w: float, col: Color, right := false) -> Dictionary:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.05, 0.9)
	bg.position = pos
	bg.size = Vector2(w, 16)
	parent.add_child(bg)
	var fg := ColorRect.new()
	fg.color = col
	fg.size = Vector2(w - 4, 12)
	fg.position = Vector2(2, 2)
	bg.add_child(fg)
	var lag := ColorRect.new()
	lag.color = Color(1, 1, 1, 0.6)
	lag.size = fg.size
	lag.position = fg.position
	bg.add_child(lag)
	bg.move_child(lag, 0)
	var num := _label("", 14, Color.WHITE, fb, 4)
	num.position = Vector2(w + 6, -3) if not right else Vector2(-56, -3)
	num.size = Vector2(50, 20)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if not right else HORIZONTAL_ALIGNMENT_RIGHT
	bg.add_child(num)
	return {"bg": bg, "fg": fg, "lag": lag, "num": num, "w": w - 4, "right": right}


func _set_bar(b: Dictionary, v: float, mx: float) -> void:
	var f := clampf(v / maxf(mx, 1), 0, 1)
	var fg: ColorRect = b["fg"]
	var lag: ColorRect = b["lag"]
	fg.size.x = b["w"] * f
	if b["right"]:
		fg.position.x = 2 + b["w"] * (1 - f)
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(lag, "size:x", fg.size.x, 0.35)
	if b["right"]:
		tw.parallel().tween_property(lag, "position:x", fg.position.x, 0.35)
	(b["num"] as Label).text = str(int(v))


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	hud["root"] = root
	# 위쪽 상태 띠
	var top := ColorRect.new()
	top.color = Color(0.05, 0.04, 0.035, 0.82)
	top.size = Vector2(1280, 66)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	hud["top"] = top
	var sname := _label(Cfg.player_title(), 20, Color("f3eadb"), fb)
	hud["s_name"] = sname
	sname.position = Vector2(20, 6)
	top.add_child(sname)
	hud["s_hp"] = _bar(top, Vector2(20, 34), 230, Color("d23b35"))
	hud["s_mt"] = _bar(top, Vector2(20, 52), 160, Color("e8c23a"))
	hud["s_mt"]["bg"].size.y = 10
	hud["s_mt"]["fg"].size.y = 6
	hud["s_mt"]["lag"].size.y = 6
	var tname := _label("짬타이거", 20, Color("f3eadb"), fb)
	tname.position = Vector2(1110, 6)
	tname.size = Vector2(150, 26)
	tname.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(tname)
	hud["t_name"] = tname
	hud["t_hp"] = _bar(top, Vector2(1030, 34), 230, Color("d23b35"), true)
	hud["t_mt"] = _bar(top, Vector2(1100, 52), 160, Color("e8c23a"), true)
	hud["t_mt"]["bg"].size.y = 10
	hud["t_mt"]["fg"].size.y = 6
	hud["t_mt"]["lag"].size.y = 6
	var mid := _label("", 22, Color("e6bd5c"), ft)
	mid.position = Vector2(440, 6)
	mid.size = Vector2(400, 30)
	mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(mid)
	hud["mid"] = mid
	var ranks := _label("", 14, Color("b9ad9a"))
	ranks.position = Vector2(440, 38)
	ranks.size = Vector2(400, 20)
	ranks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(ranks)
	hud["ranks"] = ranks
	var schips := _label("", 13, Color("ffb16a"))
	schips.position = Vector2(300, 38)
	top.add_child(schips)
	hud["s_chips"] = schips
	var tchips := _label("", 13, Color("ffb16a"))
	tchips.position = Vector2(780, 38)
	tchips.size = Vector2(230, 20)
	tchips.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(tchips)
	hud["t_chips"] = tchips
	# 배치 칸과 의도 사이 선
	lines = Control.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.draw.connect(_draw_lines)
	root.add_child(lines)
	# 손패
	hand_box = Control.new()
	hand_box.position = Vector2(0, 580)
	hand_box.size = Vector2(1280, 208)
	hand_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hand_box)
	# 기력
	var en := Control.new()
	en.position = Vector2(26, 612)
	en.size = Vector2(150, 90)
	en.mouse_filter = Control.MOUSE_FILTER_IGNORE
	en.draw.connect(func(): _draw_energy(en))
	root.add_child(en)
	hud["energy"] = en
	# 투지
	var fo := Control.new()
	fo.position = Vector2(26, 560)
	fo.size = Vector2(150, 40)
	fo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fo.draw.connect(func(): _draw_focus(fo))
	root.add_child(fo)
	hud["focus"] = fo
	# 합 시작 버튼
	go_btn = Button.new()
	go_btn.text = "합 시작!"
	go_btn.position = Vector2(1100, 610)
	go_btn.size = Vector2(160, 80)
	go_btn.add_theme_font_override("font", ft)
	go_btn.add_theme_font_size_override("font_size", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("3a2210")
	sb.border_color = Color("e08a2c")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0.88, 0.54, 0.17, 0.4)
	sb.shadow_size = 10
	var sbh := sb.duplicate()
	sbh.bg_color = Color("5a3416")
	var sbd := sb.duplicate()
	sbd.bg_color = Color("2a2018")
	sbd.border_color = Color("6d5a3a")
	sbd.shadow_size = 0
	go_btn.add_theme_stylebox_override("normal", sb)
	go_btn.add_theme_stylebox_override("hover", sbh)
	go_btn.add_theme_stylebox_override("pressed", sbh)
	go_btn.add_theme_stylebox_override("disabled", sbd)
	go_btn.add_theme_color_override("font_color", Color("e6bd5c"))
	go_btn.add_theme_color_override("font_hover_color", Color("fff0c0"))
	go_btn.pressed.connect(_on_go)
	root.add_child(go_btn)
	# 합 띠
	banner_s = Banner.new()
	banner_s.position = Vector2(30, 84)
	banner_s.size = Vector2(420, 100)
	banner_s.visible = false
	banner_s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner_s)
	banner_t = Banner.new()
	banner_t.right = true
	banner_t.position = Vector2(830, 84)
	banner_t.size = Vector2(420, 100)
	banner_t.visible = false
	banner_t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner_t)
	# 말풍선
	for who in ["s", "t"]:
		var b := PanelContainer.new()
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color(0.98, 0.96, 0.9)
		bsb.border_color = Color("1c1712")
		bsb.set_border_width_all(3)
		bsb.set_corner_radius_all(12)
		bsb.content_margin_left = 14
		bsb.content_margin_right = 14
		bsb.content_margin_top = 6
		bsb.content_margin_bottom = 8
		b.add_theme_stylebox_override("panel", bsb)
		var l := _label("", 18, Color("1c1712"), fb)
		b.add_child(l)
		b.visible = false
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(b)
		bubble[who] = b
	# 안내 문구
	toast = _label("", 20, Color("fff0c0"), fb, 6)
	toast.position = Vector2(240, 470)
	toast.size = Vector2(800, 30)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(toast)
	# 대화 상자
	dialog = Control.new()
	dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog.visible = false
	root.add_child(dialog)
	var dpanel := Panel.new()
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = Color(0.06, 0.05, 0.045, 0.94)
	dsb.border_color = Color("e08a2c")
	dsb.border_width_top = 3
	dpanel.add_theme_stylebox_override("panel", dsb)
	dpanel.position = Vector2(0, 598)
	dpanel.size = Vector2(1280, 122)
	dpanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(dpanel)
	dialog_name = _label("", 24, Color("e6bd5c"), ft)
	dialog_name.position = Vector2(80, 604)
	dialog.add_child(dialog_name)
	dialog_text = _label("", 24, Color("f3eadb"), fr)
	dialog_text.position = Vector2(80, 638)
	dialog_text.size = Vector2(1000, 76)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.add_child(dialog_text)
	var hint := _label("▼ 눌러서 계속", 15, Color("8a7f70"))
	hint.position = Vector2(1120, 694)
	dialog.add_child(hint)
	dialog.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			if dialog_text.visible_ratio < 1.0:
				dialog_text.visible_ratio = 1.0
			else:
				dialog_next.emit())
	# 덮개(제목, 결과)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	root.add_child(overlay)
	_set_planning_ui(false)


# ---------------------------------------------------------------- 그리기 도우미

func _draw_energy(c: Control) -> void:
	if P.is_empty():
		return
	var avail := _avail_energy()
	c.draw_string(fb, Vector2(0, 14), "기력", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("b9ad9a"))
	for i in P["max_energy"]:
		var ctr := Vector2(20 + i * 36, 44)
		if i < avail:
			c.draw_circle(ctr, 15, Color("e6bd5c"))
			c.draw_circle(ctr + Vector2(-4, -4), 5, Color(1, 1, 0.9, 0.7))
		elif i < P["energy"]:
			c.draw_arc(ctr, 14, 0, TAU, 20, Color("e6bd5c"), 2.5)
		else:
			c.draw_arc(ctr, 14, 0, TAU, 20, Color("5a4a2a"), 2.5)
	c.draw_string(fb, Vector2(0, 84), "덱 %d · 버림 %d" % [deck.size(), discard.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("8a7f70"))


func _draw_focus(c: Control) -> void:
	if P.is_empty():
		return
	var mx: int = GameData.PLAYER["focus_max"]
	c.draw_string(fb, Vector2(0, 14), "투지", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("b9ad9a"))
	for i in mx:
		var r := Rect2(40 + i * 13, 3, 10, 14)
		c.draw_rect(r, Color("ff7a3a") if i < P["focus"] else Color("3a2a20"))
	if P["focus"] >= mx:
		c.draw_string(fb, Vector2(0, 36), "총력 사격 준비!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffb16a"))


func _draw_lines() -> void:
	if not lines.visible:
		return
	for i in intent_views.size():
		var iv: CardView = intent_views[i]
		var a := iv.position + Vector2(iv.size.x / 2, iv.size.y)
		var has_slot: bool = i < slot_views.size() and slots[i] != ""
		var col := Color("e08a2c") if has_slot else Color("ff4f93")
		var b: Vector2
		if i < slot_views.size():
			var sv: CardView = slot_views[i]
			b = sv.position + Vector2(sv.size.x / 2, sv.size.y)
		else:
			b = Vector2(HOME["s"], 300)
		var mid := (a + b) / 2 + Vector2(0, 50)
		var pts := PackedVector2Array()
		for k in 25:
			var t := k / 24.0
			pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
		if has_slot:
			lines.draw_polyline(pts, Color(col, 0.25), 10)
			lines.draw_polyline(pts, col, 4)
		else:
			for k in range(0, 24, 2):
				lines.draw_line(pts[k], pts[k + 1], col, 3)
		lines.draw_circle(b, 6, col)
		lines.draw_circle(a, 6, col)
	for i in range(intent_views.size(), slot_views.size()):
		if slots[i] == "":
			continue
		var sv: CardView = slot_views[i]
		var a := sv.position + Vector2(sv.size.x / 2, sv.size.y)
		var b := Vector2(HOME["t"], 300)
		lines.draw_line(a, b, Color("8fe8ff"), 3)
		lines.draw_circle(b, 6, Color("8fe8ff"))


# ---------------------------------------------------------------- 흐름

func wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, false).timeout


func _title() -> void:
	busy = true
	hud["top"].visible = false
	overlay.visible = true
	for c in overlay.get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	var t := _label("짬타이거", 120, Color("e8913c"), ft, 18)
	t.position = Vector2(0, 150)
	t.size = Vector2(1280, 150)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(t)
	var sub := _label("이병 %s의 전입 첫날" % Cfg.PLAYER_NAME, 32, Color("f3eadb"), fb, 8)
	sub.position = Vector2(0, 300)
	sub.size = Vector2(1280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(sub)
	var roland_ok := SpritePuppet.available()
	var b := _button("작전 개시", Vector2(540 - (120 if roland_ok else 0), 420))
	overlay.add_child(b)
	b.pressed.connect(func(): mode_chosen.emit("soldier"))
	if roland_ok:
		var rb := _button("롤랑 모드", Vector2(660, 420))
		overlay.add_child(rb)
		rb.pressed.connect(func(): mode_chosen.emit("roland"))
	var tw := create_tween().set_loops()
	tw.tween_property(t, "position:y", 140.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(t, "position:y", 150.0, 1.2).set_trans(Tween.TRANS_SINE)
	var mode: String = await mode_chosen
	tw.kill()
	Sfx.play("click")
	_set_mode(mode)
	Sfx.play_bgm("bgm")
	overlay.visible = false
	_new_game()
	await _dialogue(GameData.INTRO_ROLAND if mode == "roland" else GameData.INTRO)
	_start_turn()


func _set_mode(mode: String) -> void:
	Cfg.mode = mode
	_make_puppet("s", mode == "roland")
	(hud["s_name"] as Label).text = Cfg.player_title()


func _button(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(200, 64)
	b.add_theme_font_override("font", ft)
	b.add_theme_font_size_override("font_size", 28)
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


func _dialogue(lines_: Array) -> void:
	dialog.visible = true
	_set_planning_ui(false)
	for ln in lines_:
		var who: String = ln[0]
		dialog_name.text = {"s": Cfg.player_title(), "t": "짬타이거", "": ""}[who]
		dialog_text.text = Cfg.fmt(ln[1])
		dialog_text.visible_ratio = 0
		var tw := create_tween()
		tw.tween_property(dialog_text, "visible_ratio", 1.0, 0.02 * dialog_text.text.length())
		if who == "t":
			Sfx.play("meow", -6)
			pup["t"].pose("command" if "!" in ln[1] else "idle", 0.2)
		elif who == "s":
			pup["s"].pose("cheer" if "!" in ln[1] else "idle", 0.2)
		await dialog_next
		Sfx.play("click", -8)
	dialog.visible = false
	pup["s"].pose("idle", 0.2)
	pup["t"].pose("idle", 0.2)


func _new_game() -> void:
	var pl: Dictionary = GameData.PLAYER
	P = {"hp": pl["hp"], "max_hp": pl["hp"], "mental": pl["mental"], "max_mental": pl["mental"], "broken": false, "skip": false,
		"energy": pl["energy"], "max_energy": pl["energy"], "status": {}, "pending": {}, "focus": 0}
	var roland := Cfg.mode == "roland"
	cards = GameData.roland_cards() if roland else GameData.player_cards()
	if roland:
		P["energy"] = 4
		P["max_energy"] = 4
	deck = (GameData.ROLAND_DECK if roland else GameData.DECK).duplicate()
	deck.shuffle()
	discard = []
	hand = []
	phase = 0
	turn_no = 0
	_setup_tiger()
	hud["top"].visible = true
	pup["s"].pose("idle", 0.01)
	pup["t"].pose("idle", 0.01)
	for who in ["s", "t"]:
		pup[who].position.x = HOME[who]
		shadow[who].position.x = HOME[who]
	_refresh_hud()


func _setup_tiger() -> void:
	var ph: Dictionary = GameData.PHASES[phase]
	T = {"hp": ph["hp"], "max_hp": ph["hp"], "mental": ph["mental"], "max_mental": ph["mental"], "broken": false, "skip": false,
		"ammo": ph["ammo"], "max_ammo": ph["ammo"]}
	pup["t"].set_rank(ph["n"])


func _draw_cards(n: int) -> void:
	for k in n:
		if deck.is_empty():
			if discard.is_empty():
				return
			deck = discard.duplicate()
			deck.shuffle()
			discard = []
		hand.append(deck.pop_back())


func _start_turn() -> void:
	turn_no += 1
	P["status"] = P["pending"]
	P["pending"] = {}
	P["skip"] = P["broken"]
	T["skip"] = T["broken"]
	P["energy"] = maxi(0, P["max_energy"] - (1 if P["status"].has("pushup") else 0))
	discard.append_array(hand)
	hand = []
	_draw_cards(GameData.PLAYER["hand"])
	if P["focus"] >= GameData.PLAYER["focus_max"] and not hand.has("ult"):
		hand.append("ult")
	slots = []
	var nslots: int = 0 if P["skip"] else GameData.PLAYER["slots"]
	for i in nslots:
		slots.append("")
	intents = []
	if not T["skip"]:
		for id_ in _tiger_choose(GameData.PHASES[phase]["intents"]):
			intents.append({"id": id_, "def": tcards[id_], "used": false, "broken": false})
	busy = false
	_refresh_hud()
	_rebuild_planning()
	_set_planning_ui(true)
	if P["status"].has("pushup"):
		say("s", GameData.LINES["s_pushup"].pick_random())
	if P["skip"]:
		show_toast("멘탈이 무너져 이번 턴은 움직일 수 없다! 합 시작을 누르세요.")
	elif T["skip"]:
		show_toast("짬타이거가 멍해졌다! 마음껏 공격하자.")
	else:
		show_toast("책장을 눌러 칸에 놓으세요. 같은 줄의 적 행동과 합을 겨룹니다.")


func _tiger_choose(n: int) -> Array:
	var ph: Dictionary = GameData.PHASES[phase]
	var pool: Array = ph["pool"]
	var out: Array = []
	var ammo: int = T["ammo"]
	var ate := false
	for i in n:
		if pool.has("k2") and ammo < 3 and not out.has("supply"):
			out.append("supply")
			continue
		var opts: Array = []
		var w: Array = []
		for id_ in pool:
			if id_ == "k2" and ammo < 3:
				continue
			if id_ == "eat" and ate:
				continue
			opts.append(id_)
			if id_ == "eat":
				w.append(2.5 if T["hp"] < T["max_hp"] * 0.5 else 0.7)
			elif id_ in ["k2", "pushup", "duck"]:
				w.append(1.4)
			else:
				w.append(1.0)
		var total := 0.0
		for x in w:
			total += x
		var r := randf() * total
		var pick: String = opts[-1]
		for k in opts.size():
			r -= w[k]
			if r <= 0:
				pick = opts[k]
				break
		if pick == "k2":
			ammo -= 3
		if pick == "eat":
			ate = true
		out.append(pick)
	return out


func _avail_energy() -> int:
	var used := 0
	for s in slots:
		if s != "":
			used += cards[s]["cost"]
	return P.get("energy", 0) - used


# ---------------------------------------------------------------- 배치 화면

func _set_planning_ui(on: bool) -> void:
	hand_box.visible = on
	go_btn.visible = on
	lines.visible = on
	hud["energy"].visible = on
	hud["focus"].visible = on
	for v in slot_views + intent_views:
		v.visible = on
	if not on:
		toast.text = ""
	lines.queue_redraw()


func _rebuild_planning() -> void:
	for v in slot_views + intent_views:
		v.queue_free()
	slot_views = []
	intent_views = []
	var root: Control = hud["root"]
	for i in intents.size():
		var cv := CardView.new()
		cv.setup(intents[i]["id"], intents[i]["def"], true, true)
		cv.position = Vector2(HOME["t"] + (i - (intents.size() - 1) / 2.0) * 128 - 59, 82)
		root.add_child(cv)
		intent_views.append(cv)
	for i in slots.size():
		var cv := CardView.new()
		if slots[i] != "":
			cv.setup(slots[i], cards[slots[i]], false, true)
		else:
			cv.setup("", {"name": "빈 칸 %d" % (i + 1), "dice": [], "cost": 0}, false, true)
			cv.modulate = Color(1, 1, 1, 0.5)
		cv.position = Vector2(HOME["s"] + (i - (slots.size() - 1) / 2.0) * 128 - 59, 82)
		cv.pressed.connect(_on_slot.bind(i))
		root.add_child(cv)
		slot_views.append(cv)
	_rebuild_hand()
	lines.queue_redraw()
	hud["energy"].queue_redraw()
	hud["focus"].queue_redraw()


func _rebuild_hand() -> void:
	for c in hand_box.get_children():
		c.queue_free()
	var n := hand.size()
	var avail := _avail_energy()
	var step := minf(140.0, 760.0 / maxf(n, 1))
	var x0 := 640.0 - (step * (n - 1)) / 2.0 - 75
	for i in n:
		var id_: String = hand[i]
		var cv := CardView.new()
		cv.setup(id_, cards[id_])
		cv.no_evade = P["status"].has("duck")
		cv.bonus = 2 if P["status"].has("song") else 0
		cv.position = Vector2(x0 + i * step, 8 + absf(i - (n - 1) / 2.0) * 4)
		cv.base_y = cv.position.y
		cv.rotation = deg_to_rad((i - (n - 1) / 2.0) * 2.5)
		cv.disabled = cards[id_]["cost"] > avail or slots.find("") < 0
		cv.pressed.connect(_on_hand.bind(i))
		hand_box.add_child(cv)


func _on_hand(i: int) -> void:
	if busy or i >= hand.size():
		return
	var id_: String = hand[i]
	var free := slots.find("")
	if free < 0:
		show_toast("빈 칸이 없다. 위의 칸을 눌러 책장을 빼자.")
		return
	if cards[id_]["cost"] > _avail_energy():
		show_toast("기력이 부족하다!")
		return
	Sfx.play("card")
	slots[free] = id_
	hand.remove_at(i)
	_rebuild_planning()


func _on_slot(i: int) -> void:
	if busy or slots[i] == "":
		return
	Sfx.play("card", -4)
	hand.append(slots[i])
	slots[i] = ""
	_rebuild_planning()


func show_toast(t: String) -> void:
	toast.text = t
	toast.modulate.a = 1.0


func say(who: String, text: String, dur := 1.6) -> void:
	var b: PanelContainer = bubble[who]
	var l: Label = b.get_child(0)
	l.text = Cfg.fmt(text)
	b.reset_size()
	var p: Node2D = pup[who]
	var screen := get_viewport().get_canvas_transform() * (p.global_position + Vector2(0, -330))
	b.position = screen - Vector2(b.size.x / 2, b.size.y)
	b.position.x = clampf(b.position.x, 10, 1270 - b.size.x)
	b.visible = true
	b.scale = Vector2(0.6, 0.6)
	b.pivot_offset = Vector2(b.size.x / 2, b.size.y)
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(dur)
	tw.tween_callback(func(): b.visible = false)


# ---------------------------------------------------------------- 상단 표시

func _refresh_hud() -> void:
	if P.is_empty():
		return
	_set_bar(hud["s_hp"], P["hp"], P["max_hp"])
	_set_bar(hud["s_mt"], P["mental"], P["max_mental"])
	_set_bar(hud["t_hp"], T["hp"], T["max_hp"])
	_set_bar(hud["t_mt"], T["mental"], T["max_mental"])
	var ph: Dictionary = GameData.PHASES[phase]
	(hud["t_name"] as Label).text = "%s 짬타이거" % ph["rank"]
	(hud["mid"] as Label).text = "제 %d막 · %d턴" % [phase + 1, turn_no]
	var rk := ""
	for i in GameData.PHASES.size():
		var r: String = GameData.PHASES[i]["rank"]
		rk += ("[%s]" % r if i == phase else r) + ("  " if i < 3 else "")
	(hud["ranks"] as Label).text = rk
	var sc := ""
	if P["broken"]:
		sc += "멘탈 붕괴  "
	for k in P["status"]:
		sc += GameData.STATUS[k]["name"] + "  "
	for k in P["pending"]:
		sc += "다음 턴: " + GameData.STATUS[k]["name"] + "  "
	(hud["s_chips"] as Label).text = sc
	var tc := ""
	if T["max_ammo"] > 0:
		tc += "탄약 " + "■".repeat(T["ammo"]) + "□".repeat(T["max_ammo"] - T["ammo"]) + "  "
	if T["broken"]:
		tc += "멍때림"
	(hud["t_chips"] as Label).text = tc
	hud["energy"].queue_redraw()
	hud["focus"].queue_redraw()


# ---------------------------------------------------------------- 합 진행

func _on_go() -> void:
	if busy:
		return
	busy = true
	Sfx.play("click")
	P["energy"] = _avail_energy()
	_set_planning_ui(false)
	var n := maxi(slots.size(), intents.size())
	var any := false
	for i in n:
		var sid: String = slots[i] if i < slots.size() else ""
		var it = intents[i] if i < intents.size() else null
		if sid == "" and it == null:
			continue
		if not any:
			await _enter_combat()
			any = true
		await _exchange(sid, it)
		_refresh_hud()
		if P["hp"] <= 0 or T["hp"] <= 0:
			break
	if any:
		await _leave_combat()
	await _end_turn()


func _enter_combat() -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "zoom", Vector2(1.45, 1.45), 0.4)
	tw.tween_property(cam, "position", Vector2(640, 330), 0.4)
	tw.tween_property(dim, "color:a", 0.45, 0.4)
	await tw.finished


func _leave_combat() -> void:
	banner_s.visible = false
	banner_t.visible = false
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "zoom", Vector2.ONE, 0.4)
	tw.tween_property(cam, "position", Vector2(640, 360), 0.4)
	tw.tween_property(dim, "color:a", 0.0, 0.4)
	for who in ["s", "t"]:
		tw.tween_property(pup[who], "position:x", HOME[who], 0.4)
		tw.tween_property(shadow[who], "position:x", HOME[who], 0.4)
		if not _side(who)["broken"]:
			pup[who].pose("idle", 0.3)
	await tw.finished


func _side(who: String) -> Dictionary:
	return P if who == "s" else T


func _other(who: String) -> String:
	return "t" if who == "s" else "s"


func _dir(who: String) -> float:
	return 1.0 if who == "s" else -1.0


func _slide(who: String, x: float, t := 0.12, trans := Tween.TRANS_QUAD) -> void:
	var tw := create_tween().set_parallel(true).set_trans(trans).set_ease(Tween.EASE_OUT)
	tw.tween_property(pup[who], "position:x", x, t)
	tw.tween_property(shadow[who], "position:x", x, t)


func _hop(who: String, h: float, t: float) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_QUAD)
	tw.tween_property(pup[who], "position:y", GROUND - h, t / 2).set_ease(Tween.EASE_OUT)
	tw.tween_property(pup[who], "position:y", GROUND, t / 2).set_ease(Tween.EASE_IN)


func _body(who: String) -> Vector2:
	return pup[who].position + Vector2(0, -150)


func _shake(amount: float, t: float) -> void:
	var tw := create_tween()
	var steps := int(t / 0.03)
	for k in steps:
		var f := 1.0 - float(k) / steps
		tw.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amount * f, 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.03)


func _hitstop(t := 0.07) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(t, true, false, true).timeout
	Engine.time_scale = 1.0


func _flash(who: String, col := Color(1, 0.35, 0.3)) -> void:
	var p: Node2D = pup[who]
	p.modulate = Color(3, 3, 3)
	var tw := create_tween()
	tw.tween_property(p, "modulate", col, 0.05)
	tw.tween_property(p, "modulate", Color.WHITE, 0.3)


func _dice_of(who: String, def: Dictionary) -> Array:
	var q: Array = []
	for dd in def.get("dice", []):
		if who == "s" and P["status"].has("duck") and dd["t"] == "evade":
			continue
		q.append(dd)
	return q


func _exchange(sid: String, it) -> void:
	if sid != "" and P["broken"]:
		sid = ""
	if it != null and T["broken"]:
		it = null
	if sid == "" and it == null:
		return
	var sdef: Dictionary = cards[sid] if sid != "" else {}
	var tdef: Dictionary = it["def"] if it != null else {}
	var A := {"who": "s", "def": sdef, "q": _dice_of("s", sdef), "i": 0, "id": sid, "hit": false}
	var B := {"who": "t", "def": tdef, "q": _dice_of("t", tdef), "i": 0, "id": it["id"] if it != null else "", "ref": it, "hit": false}
	if it != null:
		it["used"] = true
	# 띠
	if sid != "":
		banner_s.show_card(sdef["name"], A["q"], CardView.type_color(sdef, false))
	else:
		banner_s.visible = false
	if it != null:
		banner_t.show_card(tdef["name"], B["q"], Color("8e9b54"))
	else:
		banner_t.visible = false
	await _use_effects(A, B)
	# 맞닿는 거리로 돌진
	var c := (HOME["s"] + HOME["t"]) / 2.0
	for who in ["s", "t"]:
		if not _side(who)["broken"]:
			pup[who].pose("run", 0.12)
		_slide(who, c - _dir(who) * CONTACT, 0.22, Tween.TRANS_CUBIC)
	await wait(0.24)
	for who in ["s", "t"]:
		if not _side(who)["broken"]:
			pup[who].pose("idle", 0.15)
	await wait(0.12)
	while P["hp"] > 0 and T["hp"] > 0:
		var a_has: bool = A["i"] < A["q"].size() and not P["broken"]
		var b_has: bool = B["i"] < B["q"].size() and not T["broken"] and not B.get("destroyed", false)
		if a_has and b_has:
			await _pair(A, B)
		elif a_has:
			await _one_sided(A, B)
		elif b_has:
			await _one_sided(B, A)
		else:
			break
		_refresh_hud()
	await wait(0.2)


## 책장을 쓰는 순간의 효과(회복, 탄약 등)
func _use_effects(A: Dictionary, B: Dictionary) -> void:
	var sdef: Dictionary = A["def"]
	if sdef.has("heal"):
		P["hp"] = mini(P["max_hp"], P["hp"] + sdef["heal"])
		P["mental"] = mini(P["max_mental"], P["mental"] + sdef.get("mental", 0))
		pup["s"].pose("eat", 0.2)
		Sfx.play("heal")
		Fx.float_text(fxl, _body("s") + Vector2(0, -80), "+%d" % sdef["heal"], Color("6fe08f"), 52, fb)
		say("s", "냠냠... 힘이 난다!")
		_refresh_hud()
		await wait(0.7)
	if sdef.has("buff"):
		P["pending"]["song"] = true
		pup["s"].pose("cheer", 0.2)
		Sfx.play("fanfare", -10)
		say("s", "멸공의 횃불~!")
		await wait(0.7)
	var tid: String = B["id"]
	if tid == "k2":
		T["ammo"] = maxi(0, T["ammo"] - 3)
		say("t", GameData.LINES["t_k2"].pick_random(), 1.0)
	elif tid == "supply":
		T["ammo"] = T["max_ammo"]
		pup["t"].pose("supply", 0.2)
		say("t", GameData.LINES["t_supply"][0])
		await wait(0.7)
	elif tid == "eat":
		pup["t"].pose("eat", 0.2)
		say("t", GameData.LINES["t_eat"].pick_random(), 1.0)
		await wait(0.4)
	elif tid in ["pushup", "duck"]:
		Sfx.play("whistle", -4)
		say("t", "엎드려뻗쳐!" if tid == "pushup" else "오리걸음 실시!", 1.0)
	elif A["id"] != "" and randf() < 0.3:
		say("s", GameData.LINES["s_attack"].pick_random(), 1.0)
	_refresh_hud()


func _roll(side: Dictionary, dd: Dictionary) -> int:
	var v := randi_range(dd["min"], dd["max"])
	if side["who"] == "s" and P["status"].has("song"):
		v += 2
	return v


func _is_atk(dd: Dictionary) -> bool:
	return GameData.DICE[dd["t"]]["atk"]


func _banner(who: String) -> Banner:
	return banner_s if who == "s" else banner_t


func _pair(A: Dictionary, B: Dictionary) -> void:
	var da: Dictionary = A["q"][A["i"]]
	var db: Dictionary = B["q"][B["i"]]
	var va := _roll(A, da)
	var vb := _roll(B, db)
	banner_s.set_value(va, da["t"])
	banner_t.set_value(vb, db["t"])
	Sfx.play("card", -6)
	await wait(0.32)
	var use_a := true
	var use_b := true
	var ka := _is_atk(da)
	var kb := _is_atk(db)
	if ka and kb:
		# 둘 다 휘두른다
		_strike("t", B, db)
		await _strike("s", A, da)
		if va > vb:
			await _hit(A, B, va, da)
			_win_focus(A, 1)
		elif vb > va:
			await _hit(B, A, vb, db)
		else:
			await _tie()
	elif ka:
		var r: Array = await _atk_vs_def(A, B, va, vb, da, db)
		use_a = r[0]
		use_b = r[1]
	elif kb:
		var r: Array = await _atk_vs_def(B, A, vb, va, db, da)
		use_b = r[0]
		use_a = r[1]
	else:
		_guard("s")
		_guard("t")
		Sfx.play("block")
		if da["t"] == "block" and db["t"] == "block" and va != vb:
			var w := A if va > vb else B
			var l := B if va > vb else A
			_stagger_hit(l, absi(va - vb))
			if w["who"] == "s":
				_win_focus(A, 1)
		await wait(0.35)
	if A.get("ult", false) or A["def"].get("ult", false):
		if va > vb and ka:
			B["destroyed"] = true
			Fx.float_text(fxl, _body("t") + Vector2(0, -120), "주사위 파괴!", Color("ffb16a"), 40, fb)
	if use_a:
		A["i"] += 1
	if use_b:
		B["i"] += 1
	banner_s.spent = A["i"]
	banner_t.spent = B["i"]
	banner_s.queue_redraw()
	banner_t.queue_redraw()
	await _reset_pair()


func _reset_pair() -> void:
	await wait(0.25)
	var c := (HOME["s"] + HOME["t"]) / 2.0
	for who in ["s", "t"]:
		if not _side(who)["broken"]:
			pup[who].pose("idle", 0.2)
		_slide(who, c - _dir(who) * CONTACT, 0.2, Tween.TRANS_SINE)
	await wait(0.22)


## X 공격, Y 수비. [X 주사위 소모, Y 주사위 소모]
func _atk_vs_def(X: Dictionary, Y: Dictionary, vx: int, vy: int, dx: Dictionary, dy: Dictionary) -> Array:
	await _strike(X["who"], X, dx)
	if dy["t"] == "block":
		if vx > vy:
			await _hit(X, Y, vx - vy, dx)
			if X["who"] == "s":
				_win_focus(X, 1)
			return [true, true]
		_guard(Y["who"])
		Sfx.play("block")
		Fx.ring(fxl, _body(Y["who"]) + Vector2(_dir(Y["who"]) * 60, 0), Color(0.6, 0.8, 1), 20, 150, 0.35, 10)
		_shake(6, 0.12)
		_slide(X["who"], pup[X["who"]].position.x - _dir(X["who"]) * 50, 0.18)
		if vy > vx:
			_stagger_hit(X, vy - vx)
			if Y["who"] == "s":
				_win_focus(Y, 1)
				var bonus: int = Y["def"].get("block_energy", 0)
				if bonus > 0:
					P["energy"] = mini(P["max_energy"], P["energy"] + bonus)
					Fx.float_text(fxl, _body("s") + Vector2(0, -100), "기력 +1", Color("e6bd5c"), 30, fb)
		else:
			Fx.float_text(fxl, _body(Y["who"]) + Vector2(0, -90), "막았다!", Color("9fd0ff"), 34, fb)
		await wait(0.35)
		return [true, true]
	# 회피
	if vy > vx:
		pup[Y["who"]].pose("evade", 0.1)
		Sfx.play("dodge")
		_slide(Y["who"], pup[Y["who"]].position.x - _dir(Y["who"]) * 120, 0.16, Tween.TRANS_CUBIC)
		var ys: Dictionary = _side(Y["who"])
		if not ys["broken"]:
			ys["mental"] = mini(ys["max_mental"], ys["mental"] + vy)
		Fx.float_text(fxl, _body(Y["who"]) + Vector2(0, -90), "회피!", Color("8fe8ff"), 38, fb)
		if Y["who"] == "s":
			_win_focus(Y, 1)
		await wait(0.4)
		return [true, false]
	if vx > vy:
		await _hit(X, Y, vx, dx)
		if X["who"] == "s":
			_win_focus(X, 1)
		return [true, true]
	await _tie()
	return [true, true]


func _one_sided(X: Dictionary, Y: Dictionary) -> void:
	var dx: Dictionary = X["q"][X["i"]]
	X["i"] += 1
	_banner(X["who"]).spent = X["i"]
	if not _is_atk(dx):
		return
	var v := _roll(X, dx)
	_banner(X["who"]).set_value(v, dx["t"])
	if _banner(Y["who"]).visible:
		_banner(Y["who"]).value = -1
		_banner(Y["who"]).queue_redraw()
	await wait(0.28)
	await _strike(X["who"], X, dx)
	await _hit(X, Y, v, dx)
	await _reset_pair()


func _win_focus(side: Dictionary, n: int) -> void:
	if side["who"] != "s":
		return
	P["focus"] = mini(GameData.PLAYER["focus_max"], P["focus"] + n)


# ---------------------------------------------------------------- 공격 동작

## 준비 동작부터 맞는 순간까지 재생한다. 맞는 순간에 돌아온다.
func _strike(who: String, side: Dictionary, dd: Dictionary) -> void:
	var p = pup[who]
	var anim: String = side["def"].get("anim", "")
	if anim.begins_with("r_") and who == "s":
		if not _side(who)["broken"]:
			await _strike_roland(anim, side, dd)
		return
	if anim == "":
		anim = "claw" if who == "t" else ("stab" if dd["t"] == "pierce" else "butt")
	if _side(who)["broken"]:
		return
	var x0: float = p.position.x
	var dir := _dir(who)
	match anim:
		"stab":
			p.pose("stab_wind", 0.1)
			await wait(0.11)
			Sfx.play("swing")
			p.pose("stab", 0.06, Tween.TRANS_BACK)
			_slide(who, x0 + dir * 60, 0.07)
			await wait(0.06)
			Fx.thrust(fxl, _body(who) + Vector2(dir * 40, -10), _body(who) + Vector2(dir * 300, -6), Color(1, 1, 1), 18)
		"butt":
			p.pose("butt_wind", 0.12)
			await wait(0.13)
			Sfx.play("swing")
			p.pose("butt", 0.07, Tween.TRANS_BACK)
			_slide(who, x0 + dir * 50, 0.08)
			await wait(0.06)
			Fx.crescent(fxl, _body(who) + Vector2(dir * 90, -10), 150, -100 if dir > 0 else -80, 70 if dir > 0 else 250, 26)
		"fire":
			p.pose("aim", 0.1)
			await wait(0.12)
			Sfx.play("gun")
			p.pose("recoil", 0.05)
			var muzzle: Vector2 = _body(who) + Vector2(dir * 180, -14)
			Fx.muzzle(fxl, muzzle, dir)
			Fx.thrust(fxl, muzzle, _body(_other(who)) + Vector2(0, randf_range(-20, 20)), Color(1, 0.9, 0.6), 6)
			await wait(0.04)
		"throw":
			p.pose("throw_wind", 0.14)
			await wait(0.16)
			Sfx.play("swing")
			p.pose("throw", 0.08, Tween.TRANS_BACK)
			var g := Sprite2D.new()
			g.texture = load("res://art/parts/s_grenade.png")
			g.scale = Vector2(0.5, 0.5)
			g.position = _body(who) + Vector2(dir * 40, -80)
			g.z_index = 45
			fxl.add_child(g)
			var target := _body(_other(who))
			var tw := create_tween().set_parallel(true)
			tw.tween_property(g, "position:x", target.x, 0.38)
			tw.tween_property(g, "rotation", 8.0, 0.38)
			var tw2 := create_tween()
			tw2.tween_property(g, "position:y", target.y - 160, 0.19).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw2.tween_property(g, "position:y", target.y, 0.19).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await wait(0.38)
			g.queue_free()
			Sfx.play("boom")
			Fx.explosion(fxl, target)
		"punch":
			p.pose("punch_wind", 0.1)
			await wait(0.11)
			Sfx.play("swing")
			p.pose("punch", 0.05, Tween.TRANS_BACK)
			_slide(who, x0 + dir * 50, 0.06)
			await wait(0.05)
			Fx.ring(fxl, _body(_other(who)) + Vector2(-dir * 30, -20), Color(1, 0.9, 0.7), 10, 70, 0.2, 8)
		"claw":
			p.pose("claw_wind", 0.12)
			await wait(0.13)
			Sfx.play("swing")
			p.pose("claw", 0.06, Tween.TRANS_BACK)
			_slide(who, x0 + dir * 50, 0.07)
			await wait(0.05)
			for k in 3:
				Fx.crescent(fxl, _body(_other(who)) + Vector2(-dir * 40 + k * 18 * dir, -20 + k * 14), 120, 200 if dir < 0 else -20, 290 if dir < 0 else -110, 12, Color(1, 0.75, 0.45), 0.1)
		"shoot":
			p.pose("aim", 0.1)
			await wait(0.12)
			Sfx.play("gun")
			p.pose("recoil", 0.05)
			var mz: Vector2 = _body(who) + Vector2(dir * 190, -14)
			Fx.muzzle(fxl, mz, dir)
			Fx.thrust(fxl, mz, _body(_other(who)) + Vector2(0, randf_range(-20, 20)), Color(1, 0.9, 0.6), 6)
			await wait(0.04)
		"baton":
			p.pose("baton_wind", 0.13)
			await wait(0.14)
			Sfx.play("swing")
			p.pose("baton", 0.07, Tween.TRANS_BACK)
			_slide(who, x0 + dir * 50, 0.08)
			await wait(0.06)
			Fx.crescent(fxl, _body(who) + Vector2(dir * 90, -20), 160, -110 if dir > 0 else -70, 60 if dir > 0 else 240, 24, Color(1, 0.85, 0.7))
		"command":
			p.pose("command", 0.1)
			Sfx.play("whistle", -6)
			await wait(0.14)
			p.pose("punch", 0.06, Tween.TRANS_BACK)
			_slide(who, x0 + dir * 50, 0.07)
			await wait(0.05)
			Fx.ring(fxl, _body(_other(who)), Color(1, 0.8, 0.3), 20, 180, 0.3, 10)
		_:
			p.pose("stab", 0.08)
			await wait(0.08)


func _hit(X: Dictionary, Y: Dictionary, value: int, dd: Dictionary) -> void:
	var yw: String = Y["who"]
	var ys := _side(yw)
	var mult := 2 if ys["broken"] else 1
	var real := value * mult
	ys["hp"] = maxi(0, ys["hp"] - real)
	var is_max: bool = value >= dd["max"]
	Y["hit"] = true
	if Y.has("ref") and Y["ref"] != null and Y["ref"]["def"].get("gimmick", "") == "heal":
		Y["ref"]["broken"] = true
	# 연출
	var heavy := is_max or real >= 12
	Sfx.play("heavy" if dd["t"] == "blunt" and heavy else ("slash" if dd["t"] != "blunt" else "hit"))
	Fx.burst(fxl, _body(yw) + Vector2(0, -10), Color(1, 0.95, 0.8) if X["who"] == "s" else Color(1, 0.7, 0.6), 22, 600.0, 1.2 if heavy else 0.9)
	_flash(yw)
	if not ys["broken"]:
		pup[yw].pose("hurt", 0.06)
	_hitstop(0.09 if heavy else 0.05)
	_shake(14 if heavy else 7, 0.25 if heavy else 0.15)
	_slide(yw, pup[yw].position.x - _dir(yw) * (150 if heavy else 100), 0.24, Tween.TRANS_CUBIC)
	_hop(yw, 30 if heavy else 16, 0.24)
	Fx.float_text(fxl, _body(yw) + Vector2(randf_range(-20, 20), -110), str(real), Color("ff4a3a"), 64 if heavy else 52, fb)
	if is_max:
		Fx.float_text(fxl, _body(yw) + Vector2(0, -190), "최대 피해!", Color("ff3b2f"), 40, ft)
	if mult > 1:
		Fx.float_text(fxl, _body(yw) + Vector2(0, -160), "멘탈 붕괴 ×2", Color("ffb16a"), 26, fb)
	# 멘탈
	var mb: int = X["def"].get("mental_bonus", 0)
	_stagger_hit(Y, value + mb, false)
	# 얼차려
	var on_hit: String = X["def"].get("on_hit", "")
	if on_hit != "" and yw == "s" and not X.get("applied", false):
		X["applied"] = true
		P["pending"][on_hit] = true
		Fx.float_text(fxl, _body("s") + Vector2(0, -220), GameData.STATUS[on_hit]["name"] + "!", Color("ffb16a"), 34, ft)
	if yw == "s" and randf() < 0.35:
		say("s", GameData.LINES["s_hurt"].pick_random(), 0.9)
	elif yw == "t" and randf() < 0.3:
		Sfx.play("meow", -4)
		say("t", GameData.LINES["t_hurt"].pick_random(), 0.9)
	await wait(0.28)


func _stagger_hit(Y: Dictionary, n: int, show := true) -> void:
	var ys := _side(Y["who"])
	if ys["broken"]:
		return
	ys["mental"] = maxi(0, ys["mental"] - n)
	if show:
		Fx.float_text(fxl, _body(Y["who"]) + Vector2(0, -80), "-%d" % n, Color("e8c23a"), 40, fb)
	if ys["mental"] <= 0:
		ys["broken"] = true
		Sfx.play("break")
		pup[Y["who"]].pose("dizzy" if Y["who"] == "t" else "hurt", 0.2)
		Fx.float_text(fxl, _body(Y["who"]) + Vector2(0, -240), "멘탈 붕괴!" if Y["who"] == "s" else "멍때림!", Color("e8c23a"), 46, ft)
		if Y["who"] == "t":
			say("t", GameData.LINES["t_break"][0])


func _guard(who: String) -> void:
	if not _side(who)["broken"]:
		pup[who].pose("block" if who == "s" else "guard", 0.08)


func _tie() -> void:
	Sfx.play("clash")
	var c: Vector2 = (pup["s"].position + pup["t"].position) / 2 + Vector2(0, -160)
	Fx.burst(fxl, c, Color(1, 0.95, 0.7), 26, 700.0, 1.3)
	Fx.ring(fxl, c, Color(1, 0.9, 0.6), 10, 120, 0.25, 8)
	_hitstop(0.06)
	_shake(8, 0.15)
	for who in ["s", "t"]:
		_slide(who, pup[who].position.x - _dir(who) * 70, 0.2, Tween.TRANS_CUBIC)
	Fx.float_text(fxl, c + Vector2(0, -60), "합!", Color("fff0c0"), 44, ft)
	await wait(0.35)


# ---------------------------------------------------------------- 턴 끝

func _end_turn() -> void:
	# 짬밥 회복
	for it in intents:
		if it["def"].get("gimmick", "") != "heal" or not it["used"]:
			continue
		if not it["broken"] and not T["broken"] and T["hp"] > 0:
			var amt := int(round(T["max_hp"] * 0.2))
			T["hp"] = mini(T["max_hp"], T["hp"] + amt)
			pup["t"].pose("eat", 0.2)
			Sfx.play("heal")
			Fx.float_text(fxl, _body("t") + Vector2(0, -100), "+%d" % amt, Color("6fe08f"), 52, fb)
			say("t", GameData.LINES["t_ate"][0])
			await wait(0.9)
			pup["t"].pose("idle", 0.2)
		elif T["hp"] > 0:
			say("s", GameData.LINES["s_eat_block"].pick_random())
			await wait(0.6)
	for side in [P, T]:
		if side["skip"]:
			side["broken"] = false
			side["skip"] = false
			side["mental"] = side["max_mental"]
	_refresh_hud()
	if P["hp"] <= 0:
		await _defeat()
		return
	if T["hp"] <= 0:
		await _tiger_down()
		return
	_start_turn()


func _tiger_down() -> void:
	pup["t"].pose("down", 0.3)
	Sfx.play("meow", -2)
	await wait(1.0)
	if phase >= GameData.PHASES.size() - 1:
		await _victory()
		return
	# 진급 연출
	phase += 1
	var f := ColorRect.new()
	f.color = Color(1, 1, 1, 0)
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud["root"].add_child(f)
	var tw := create_tween()
	tw.tween_property(f, "color:a", 0.9, 0.2)
	await tw.finished
	_setup_tiger()
	pup["t"].pose("command", 0.01)
	P["hp"] = mini(P["max_hp"], P["hp"] + 15)
	P["mental"] = P["max_mental"]
	P["broken"] = false
	if phase >= 2:
		P["max_energy"] = 5 if Cfg.mode == "roland" else 4
	_refresh_hud()
	Sfx.play("fanfare")
	var t := _label("%s 진급!" % GameData.PHASES[phase]["rank"], 96, Color("e8913c"), ft, 16)
	t.position = Vector2(0, 250)
	t.size = Vector2(1280, 120)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.pivot_offset = Vector2(640, 60)
	t.scale = Vector2(2, 2)
	hud["root"].add_child(t)
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(f, "color:a", 0.0, 0.5)
	tw2.tween_property(t, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await wait(1.5)
	t.queue_free()
	f.queue_free()
	await _dialogue([GameData.PROMOTE[phase - 1]])
	if phase == 2:
		show_toast("상병 단계부터 기력이 4로 늘어난다!")
	_start_turn()


func _result_screen(title: String, sub: String, col: Color, retry: bool) -> void:
	overlay.visible = true
	for c in overlay.get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	var t := _label(title, 110, col, ft, 18)
	t.position = Vector2(0, 150)
	t.size = Vector2(1280, 140)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(t)
	var s := _label(sub, 30, Color("f3eadb"), fb, 8)
	s.position = Vector2(140, 310)
	s.size = Vector2(1000, 120)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.add_child(s)
	var b := _button("다시 하기" if retry else "처음으로", Vector2(540, 470))
	overlay.add_child(b)
	await b.pressed
	Sfx.play("click")
	overlay.visible = false
	_new_game()
	_start_turn()


func _victory() -> void:
	Sfx.stop_bgm()
	pup["t"].pose("idle", 0.4)
	pup["t"].set_face("happy")
	await _dialogue(GameData.ENDING)
	pup["s"].pose("victory", 0.3)
	Sfx.play("victory")
	await _result_screen("전역까지 화이팅!", "%s\n%s" % [Cfg.player_title(), Cfg.ENDING_MESSAGE], Color("e6bd5c"), false)


func _defeat() -> void:
	Sfx.stop_bgm()
	pup["s"].pose("down", 0.4)
	pup["t"].pose("idle", 0.3)
	pup["t"].set_face("happy")
	Sfx.play("defeat")
	say("t", "신병은 아직 멀었다냥~", 2.0)
	await wait(1.6)
	await _result_screen("포상휴가 취소", "%s 짬타이거에게 당했다...\n짬통은 오늘도 고양이의 것." % GameData.PHASES[phase]["rank"], Color("c9463b"), true)
	Sfx.play_bgm("bgm")


# ---------------------------------------------------------------- 시험용

## test=플랜: 배치 화면 / test=fight: 자동으로 몇 턴 진행
func _run_test() -> void:
	if test_mode.begins_with("roland"):
		_set_mode("roland")
		test_mode = test_mode.substr(6) if test_mode.length() > 6 else "plan"
	_new_game()
	_start_turn()
	if test_mode.begins_with("cards"):
		# 공방 책장을 하나씩 차례로 써 본다(짬타이거는 맞기만 한다). cards_<id>면 그 책장만 두 번
		var ids: Array = GameData.ROLAND_DECK + ["ult"]
		if test_mode.length() > 6:
			ids = [test_mode.substr(6), test_mode.substr(6)]
		for id_ in ids:
			T["hp"] = 999
			T["max_hp"] = 999
			T["mental"] = 999
			T["max_mental"] = 999
			intents = []
			hand = [id_]
			P["energy"] = 9
			_rebuild_planning()
			_on_hand(0)
			await wait(0.2)
			_on_go()
			while busy:
				await wait(0.1)
		return
	if test_mode == "plan":
		for i in 2:
			_on_hand(0)
		return
	if test_mode == "fight" or test_mode == "auto":
		while true:
			await wait(0.3)
			if busy:
				continue
			for k in 3:
				for i in hand.size():
					if cards[hand[i]]["cost"] <= _avail_energy() and slots.find("") >= 0:
						_on_hand(i)
						break
			await wait(0.2)
			_on_go()
			await wait(0.5)


# ---------------------------------------------------------------- 롤랑 모드 공격

func _arc(c: Vector2, r: float, a0: float, a1: float, th: float, col := Color.WHITE, d := 0.12) -> void:
	Fx.crescent(fxl, c, r, a0, a1, th, col, d)


## 잉크 이펙트(art/roland/fx). 회전은 도, sc는 크기
func _ink(name: String, pos: Vector2, rot := 0.0, sc := 1.0, fh := false, fv := false, life := 0.42) -> void:
	var path := "res://art/roland/fx/%s.png" % name
	if not ResourceLoader.exists(path):
		return
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.position = pos
	spr.rotation_degrees = rot
	spr.flip_h = fh
	spr.flip_v = fv
	spr.z_index = 41
	spr.scale = Vector2.ONE * sc * 0.8
	spr.modulate.a = 0.0
	fxl.add_child(spr)
	var tw := spr.create_tween()
	tw.tween_property(spr, "modulate:a", 1.0, 0.03)
	tw.parallel().tween_property(spr, "scale", Vector2.ONE * sc, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(life * 0.45)
	tw.tween_property(spr, "modulate:a", 0.0, life * 0.55)
	tw.tween_callback(spr.queue_free)


## 공방별 동작. 서 있는 롤랑에게 무기를 쥐여 휘두르고, 받은 잉크 이펙트를 쓴다. 맞는 순간에 돌아온다
func _strike_roland(anim: String, side: Dictionary, dd: Dictionary) -> void:
	var p = pup["s"]
	var x0: float = p.position.x
	var tgt := _body("t")
	var k: int = side["i"]
	match anim:
		"r_durandal":
			p.hold("F", "durandal_sword", 120)
			p.hold("B", "")
			if k % 2 == 0:
				# 횡베기
				p.pose("stab_wind", 0.1)
				p.aim("F", -165, 0.12)
				await wait(0.13)
				Sfx.play("swing")
				p.pose("run", 0.06)
				p.aim("F", 35, 0.07, Tween.TRANS_CUBIC)
				_slide("s", x0 + 70, 0.08)
				await wait(0.05)
				_ink("slash_flat", tgt + Vector2(0, -10), 0, 1.35, true)
			else:
				# 올려치기
				p.aim("F", 110, 0.1)
				p.pose("stab_wind", 0.1)
				await wait(0.11)
				Sfx.play("swing")
				p.pose("run", 0.06)
				p.aim("F", -115, 0.08, Tween.TRANS_CUBIC)
				_slide("s", x0 + 50, 0.08)
				await wait(0.05)
				_ink("slash_up", tgt + Vector2(10, -40), 0, 1.0)
		"r_zelkova":
			p.hold("F", "zelkova_axe", 150)
			p.hold("B", "zelkova_mace", 100)
			if dd["t"] == "slash":
				# 도끼로 옆을 후려친다
				p.pose("stab_wind", 0.1)
				p.aim("F", 175, 0.12)
				await wait(0.13)
				Sfx.play("swing")
				p.pose("run", 0.06)
				p.aim("F", 15, 0.08, Tween.TRANS_CUBIC)
				_slide("s", x0 + 60, 0.08)
				await wait(0.05)
				_ink("slash_low_r", tgt + Vector2(0, 30), 0, 1.3)
			else:
				# 메이스로 올려친다
				p.aim("B", 120, 0.1)
				await wait(0.1)
				Sfx.play("swing")
				p.aim("B", -110, 0.08, Tween.TRANS_CUBIC)
				_slide("s", x0 + 40, 0.08)
				await wait(0.05)
				_ink("slash_up", tgt + Vector2(0, -30), 0, 0.95)
		"r_ranga":
			p.hold("F", "ranga_gauntlet", 10)
			p.hold("B", "ranga_dagger", 80)
			p.pose("run", 0.06)
			await wait(0.07)
			Sfx.play("swing", -2)
			if dd["t"] == "pierce":
				# 건틀릿으로 할퀸다
				p.aim("F", -30, 0.04)
				_slide("s", x0 + 90, 0.07)
				await wait(0.04)
				p.aim("F", 15, 0.05)
				_ink("thrust_streak", tgt + Vector2(-40, -10 + k * 18), -8 + k * 10, 0.55, true)
				_ink("hit_spark_side", tgt + Vector2(10, 0), 0, 0.7)
			else:
				# 단검으로 벤다
				p.aim("B", -120, 0.05)
				await wait(0.05)
				p.aim("B", 70, 0.06, Tween.TRANS_CUBIC)
				_slide("s", x0 + 90, 0.07)
				await wait(0.04)
				_ink("slash_curve", tgt, 0, 0.7)
		"r_oldboys":
			p.hold("F", "oldboys_hammer", 100)
			p.hold("B", "")
			p.pose("stab_wind", 0.12)
			p.aim("F", -135, 0.15)
			await wait(0.16)
			Sfx.play("swing")
			p.pose("run", 0.06)
			p.aim("F", 55, 0.08, Tween.TRANS_CUBIC)
			_slide("s", x0 + 60, 0.08)
			await wait(0.06)
			_ink("hit_burst_big", tgt + Vector2(0, 40), 0, 0.9)
			Fx.ring(fxl, tgt + Vector2(0, 90), Color(1, 0.9, 0.7), 20, 170, 0.3, 10)
		"r_allas":
			p.hold("F", "allas_spear", 0)
			p.hold("B", "")
			p.pose("stab_wind", 0.12)
			p.aim("F", -10, 0.12)
			await wait(0.13)
			Sfx.play("swing")
			p.pose("run", 0.05)
			p.aim("F", 2, 0.05)
			_slide("s", x0 + 140, 0.07, Tween.TRANS_CUBIC)
			await wait(0.05)
			_ink("thrust_streak", tgt + Vector2(-30, -10), 0, 1.05, true)
			_ink("hit_spark_side", tgt + Vector2(40, -10), 0, 0.9)
		"r_mook":
			# 칼집에 넣은 채 멈췄다가, 뽑으며 상대를 지나친다
			p.hold("F", "mook_katana", 115)
			p.hold("B", "")
			p.pose("stab_wind", 0.15)
			await wait(0.3)
			Sfx.play("swing")
			p.pose("run", 0.05)
			p.aim("F", -55, 0.07, Tween.TRANS_CUBIC)
			_slide("s", pup["t"].position.x + 60, 0.09, Tween.TRANS_CUBIC)
			await wait(0.05)
			_ink("slash_curve", tgt + Vector2(-10, -20), 0, 1.2, true)
			_ink("slash_low_l", tgt + Vector2(0, 40), 0, 1.1)
		"r_logic":
			p.hold("F", "logic_revolver", 0)
			p.hold("B", "logic_revolver", 6)
			var muzzle: Vector2 = _body("s") + Vector2(150, -18)
			if dd["t"] == "blunt":
				# 샷건
				p.hold("F", "logic_shotgun", 0)
				p.hold("B", "")
				await wait(0.1)
				Sfx.play("boom", -6)
				Sfx.play("gun")
				p.aim("F", -28, 0.04)
				Fx.muzzle(fxl, muzzle + Vector2(20, 0), 1.6)
				for j in 5:
					Fx.thrust(fxl, muzzle, tgt + Vector2(0, -60 + j * 30), Color(1, 0.85, 0.5), 5)
				_slide("s", x0 - 40, 0.1)
				_shake(10, 0.15)
				_ink("hit_burst_big", tgt, 0, 0.8)
			else:
				var h := "F" if k % 2 == 0 else "B"
				await wait(0.08)
				Sfx.play("gun")
				p.aim(h, -24, 0.03)
				Fx.muzzle(fxl, muzzle, 1.0)
				Fx.thrust(fxl, muzzle, tgt + Vector2(0, randf_range(-20, 20)), Color(1, 0.9, 0.6), 6)
				_ink("hit_burst_small", tgt + Vector2(0, randf_range(-20, 20)), randf_range(0, 360), 0.6)
			await wait(0.03)
			p.aim("F", 0, 0.15)
			p.aim("B", 6, 0.15)
		"r_crystal":
			# 쌍검으로 상대를 꿰뚫고 뒤쪽까지 지나가며 베고, 돌아서서 다시 지나가며 벤다
			var tx: float = pup["t"].position.x
			p.hold("F", "crystal_sword", 140)
			p.hold("B", "crystal_sword", -140)
			p.pose("run", 0.06)
			await wait(0.08)
			for pass_ in 2:
				var dir := 1.0 if pass_ == 0 else -1.0
				p.face(dir)
				p.aim("F", 140, 0.01)
				p.aim("B", -140, 0.01)
				Sfx.play("swing")
				_slide("s", tx + (130.0 if dir > 0 else -170.0), 0.1, Tween.TRANS_CUBIC)
				p.aim("F", -20, 0.08)
				p.aim("B", 20, 0.08)
				await wait(0.05)
				_ink("slash_low_r" if dir > 0 else "slash_low_l", tgt + Vector2(0, -30), 0, 1.3)
				_ink("slash_flat", tgt + Vector2(0, 20), 0, 1.2, dir > 0)
				if pass_ == 0:
					_flash("t", Color(1, 1, 1))
					await wait(0.16)
					p.pose("run", 0.05)
					await wait(0.06)
				else:
					_ink("slash_cross", tgt, 0, 0.9)
		"r_wheels":
			p.hold("F", "wheels_greatsword", 120)
			p.hold("B", "")
			p.pose("stab_wind", 0.18)
			p.aim("F", -150, 0.22, Tween.TRANS_SINE)
			await wait(0.24)
			Sfx.play("swing")
			p.pose("run", 0.06)
			p.aim("F", 65, 0.08, Tween.TRANS_CUBIC)
			_slide("s", x0 + 80, 0.09)
			await wait(0.06)
			_ink("slash_curve", tgt + Vector2(-20, -40), 0, 1.4, true)
			_ink("hit_burst_big", Vector2(tgt.x, GROUND - 60), 0, 1.2)
			Fx.explosion(fxl, Vector2(tgt.x, GROUND - 10))
			_shake(18, 0.3)
		"r_ult":
			# Furioso: 아홉 공방의 무기를 차례로 바꿔 쥐며 휘두른다
			Sfx.play("break", -6)
			p.hold("B", "")
			var seq := ["zelkova_axe", "ranga_gauntlet", "oldboys_hammer", "allas_spear", "mook_katana", "logic_revolver", "crystal_sword", "durandal_sword", "wheels_greatsword"]
			var inks := ["slash_low_r", "thrust_streak", "hit_burst_big", "thrust_streak", "slash_curve", "hit_burst_small", "slash_cross", "slash_flat", "slash_up"]
			for j in seq.size():
				p.hold("F", seq[j], -140 if j % 2 == 0 else 120)
				p.aim("F", 40 if j % 2 == 0 else -100, 0.05)
				_slide("s", x0 + 40 + (j % 3) * 30, 0.05)
				Sfx.play("gun" if seq[j] == "logic_revolver" else "swing", -4)
				_ink(inks[j], tgt + Vector2(randf_range(-40, 40), randf_range(-40, 30)), randf_range(-20, 20), 0.9, j % 2 == 1)
				await wait(0.09)
			_ink("slash_cross", tgt, 0, 1.3)
			_ink("hit_burst_big", tgt, 0, 1.3)
			_shake(20, 0.35)
		_:
			await wait(0.08)
