class_name CardView
extends Control
## 전투 책장 한 장. 손패(big), 배치 칸과 적 의도(mini)에 같이 쓴다.

signal pressed

const ICONS := {"bayonet": "s_k2", "butt": "s_k2", "burst": "s_k2", "helmet": "s_head", "crawl": "s_boot",
	"grenade": "s_grenade", "ration": "s_ration", "song": "s_face_shout", "ult": "s_k2",
	"punch": "t_paw", "claw": "t_claw", "eat": "t_tray", "k2": "t_rifle", "supply": "t_crate", "baton": "t_baton",
	"pushup": "t_face_shout", "duck": "t_face_shout"}

var id := ""
var def: Dictionary = {}
var enemy := false
var mini := false
var disabled := false:
	set(v):
		disabled = v
		modulate = Color(1, 1, 1, 0.45) if v else Color.WHITE
var no_evade := false
var bonus := 0
var hovered := false
var icon: Texture2D
const FONT_R := preload("res://fonts/Pretendard-SemiBold.ttf")
const FONT_B := preload("res://fonts/Pretendard-Black.ttf")


static func type_color(d: Dictionary, is_enemy: bool) -> Color:
	if is_enemy:
		return Color("8e9b54")
	if d.get("ult", false):
		return Color("e6bd5c")
	var dice: Array = d["dice"]
	if dice.is_empty():
		return Color("5fbf4a")
	if GameData.DICE[dice[0]["t"]]["atk"]:
		return Color("d0584a")
	return Color("4a8fe0")


func setup(id_: String, def_: Dictionary, is_enemy := false, is_mini := false) -> void:
	id = id_
	def = def_
	enemy = is_enemy
	mini = is_mini
	custom_minimum_size = Vector2(118, 112) if mini else Vector2(150, 206)
	size = custom_minimum_size
	pivot_offset = size / 2
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 그리기 도중에 처음 불러온 텍스처는 하얗게 나올 수 있어서 미리 불러 둔다
	var p: String = ICONS.get(id, "")
	icon = load("res://art/parts/%s.png" % p) if p != "" else null
	queue_redraw()


func _ready() -> void:
	# 글꼴과 그림이 처음 쓰일 때 캐시 텍스처가 바뀌면 이전 그리기 명령이 하얗게 남는다. 몇 프레임 뒤 다시 그린다.
	for k in 3:
		await get_tree().process_frame
		queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		hovered = true
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		hovered = false
		queue_redraw()


func _font(bold := false) -> Font:
	return FONT_B if bold else FONT_R


func _icon_tex() -> Texture2D:
	return icon


static func draw_die_icon(ci: CanvasItem, c: Vector2, t: String, r: float, off := false) -> void:
	var col: Color = GameData.DICE[t]["color"]
	if off:
		col = col.darkened(0.6)
	var hex := PackedVector2Array()
	for k in 6:
		var a := PI / 6 + k * PI / 3
		hex.append(c + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(hex, col.darkened(0.55))
	hex.append(hex[0])
	ci.draw_polyline(hex, col, 2.0)
	var w := Color(1, 1, 1, 0.9)
	match t:
		"slash":
			ci.draw_arc(c + Vector2(-r * 0.5, r * 0.5), r * 0.9, -PI / 2, 0, 8, w, 2.5)
		"pierce":
			ci.draw_line(c + Vector2(-r * 0.5, r * 0.5), c + Vector2(r * 0.5, -r * 0.5), w, 2.5)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.55, -r * 0.55), c + Vector2(r * 0.05, -r * 0.45), c + Vector2(r * 0.45, -r * 0.05)]), w)
		"blunt":
			ci.draw_circle(c, r * 0.38, w)
		"block":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * .45, -r * .45), c + Vector2(r * .45, -r * .45), c + Vector2(r * .45, 0), c + Vector2(0, r * .55), c + Vector2(-r * .45, 0)]), w)
		"evade":
			ci.draw_arc(c, r * 0.42, 0.3, TAU - 0.6, 10, w, 2.5)


func _draw() -> void:
	var col := type_color(def, enemy)
	var rect := Rect2(Vector2.ZERO, size)
	var lift := -10.0 if hovered and not mini and not disabled else 0.0
	rect.position.y += lift
	# 판
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("16120f")
	sb.border_color = col
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(col.r, col.g, col.b, 0.45 if hovered else 0.25)
	sb.shadow_size = 10 if hovered else 5
	draw_style_box(sb, rect)
	var f := _font()
	var fb := _font(true)
	var name_: String = def["name"]
	if mini:
		# 작은 칸: 이름 띠 + 그림 + 주사위
		draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(size.x - 6, 24)), col.darkened(0.35))
		draw_string(fb, rect.position + Vector2(8, 21), name_, HORIZONTAL_ALIGNMENT_LEFT, size.x - 14, 14 if name_.length() < 8 else 11, Color.WHITE)
		var tex := _icon_tex()
		if tex:
			var s := minf(64.0 / tex.get_width(), 46.0 / tex.get_height())
			var tsz := tex.get_size() * s
			draw_texture_rect(tex, Rect2(rect.position + Vector2((size.x - tsz.x) / 2, 30 + (46 - tsz.y) / 2), tsz), false, Color(1, 1, 1, 0.85))
		_draw_dice(rect.position + Vector2(8, 82), 13.0, f, 16)
		return
	# 큰 책장
	draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(size.x - 6, 30)), col.darkened(0.25))
	draw_circle(rect.position + Vector2(16, 18), 14, Color("e6bd5c"))
	draw_arc(rect.position + Vector2(16, 18), 14, 0, TAU, 24, Color("1a1206"), 2.5)
	draw_string(fb, rect.position + Vector2(9, 25), str(def.get("cost", 0)), HORIZONTAL_ALIGNMENT_CENTER, 14, 20, Color("1a1206"))
	draw_string(fb, rect.position + Vector2(34, 25), name_, HORIZONTAL_ALIGNMENT_LEFT, size.x - 40, 15 if name_.length() < 7 else 13, Color.WHITE)
	# 그림 칸
	var art := Rect2(rect.position + Vector2(8, 38), Vector2(size.x - 16, 74))
	draw_rect(art, col.darkened(0.7))
	var tex := _icon_tex()
	if tex:
		var s := minf((art.size.x - 10) / tex.get_width(), (art.size.y - 8) / tex.get_height())
		var tsz := tex.get_size() * s
		draw_texture_rect(tex, Rect2(art.position + (art.size - tsz) / 2, tsz), false)
	draw_rect(art, col.darkened(0.2), false, 2)
	_draw_dice(rect.position + Vector2(10, 128), 12.0, f, 15)
	var desc: String = def.get("desc", "")
	draw_multiline_string(f, rect.position + Vector2(8, size.y - 36), desc, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 11, 2, Color("b9ad9a"))


func _draw_dice(origin: Vector2, r: float, f: Font, fs: int) -> void:
	var dice: Array = def["dice"]
	var x := origin.x
	var y := origin.y
	var step := 52.0 if not mini else 0.0
	for i in dice.size():
		var dd: Dictionary = dice[i]
		var off: bool = no_evade and dd["t"] == "evade"
		var c := Vector2(x + r, y)
		if mini:
			c = Vector2(origin.x + r + (i % 4) * 26, y + (i / 4) * 24)
		draw_die_icon(self, c, dd["t"], r, off)
		if not mini:
			var lo: int = dd["min"] + bonus
			var hi: int = dd["max"] + bonus
			draw_string(f, Vector2(c.x + r + 4, y + 6), "%d-%d" % [lo, hi], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("f0e6d2") if not off else Color(0.5, 0.5, 0.5))
			if i % 2 == 1:
				x = origin.x
				y += 26
			else:
				x += 66
	if mini and not dice.is_empty():
		var lo := 999
		var hi := 0
		for dd in dice:
			lo = mini(lo, dd["min"])
			hi = maxi(hi, dd["max"])
	if dice.is_empty():
		draw_string(f, Vector2(origin.x, origin.y + 6), "주사위 없음", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("b9ad9a"))
