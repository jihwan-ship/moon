class_name Banner
extends Control
## 합 연출 중 화면 위에 뜨는 책장 이름 띠와 주사위 값

var title := ""
var dice: Array = []
var spent := 0
var value := -1
var value_t := ""
var right := false
var color := Color("d0584a")
var pulse := 0.0


func show_card(name_: String, dice_: Array, col: Color) -> void:
	title = name_
	dice = dice_
	spent = 0
	value = -1
	color = col
	visible = true
	modulate.a = 0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	queue_redraw()


func set_value(v: int, t: String) -> void:
	value = v
	value_t = t
	pulse = 1.0
	var tw := create_tween()
	tw.tween_property(self, "pulse", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(_x): queue_redraw(), 0.0, 1.0, 0.25)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var fb: Font = load("res://fonts/Pretendard-Black.ttf")
	# 붓 자국 띠
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5 if right else 3
	pts.append(Vector2(0, 8))
	for i in 21:
		pts.append(Vector2(w * i / 20.0, rng.randf_range(0, 7)))
	pts.append(Vector2(w, 50))
	for i in range(20, -1, -1):
		pts.append(Vector2(w * i / 20.0, 58 - rng.randf_range(0, 7)))
	draw_colored_polygon(pts, Color(0.05, 0.04, 0.035, 0.94))
	draw_line(Vector2(0, 56), Vector2(w, 56), Color(color, 0.8), 3)
	var tx := 20.0 if not right else w - 20.0
	draw_string(fb, Vector2(20, 40), title, HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT, w - 40, 26, Color("f3eadb"))
	# 주사위 줄
	for i in dice.size():
		var c := Vector2(30 + i * 30, 80) if not right else Vector2(w - 30 - i * 30, 80)
		var dd: Dictionary = dice[i]
		CardView.draw_die_icon(self, c, dd["t"], 12.0, i < spent)
	# 값
	if value >= 0:
		var c := Vector2(w + 50, 40) if not right else Vector2(-50, 40)
		var r := 40.0 * (1.0 + pulse * 0.6)
		var col: Color = GameData.DICE[value_t]["color"]
		var hex := PackedVector2Array()
		for k in 6:
			var a := PI / 6 + k * PI / 3
			hex.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(hex, col.darkened(0.35))
		hex.append(hex[0])
		draw_polyline(hex, col.lightened(0.4), 4)
		draw_string(fb, c + Vector2(-40, 15), str(value), HORIZONTAL_ALIGNMENT_CENTER, 80, int(44 * (1.0 + pulse * 0.4)), Color.WHITE)
