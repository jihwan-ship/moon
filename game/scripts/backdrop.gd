extends Node2D
## 배경: 해 질 녘 연병장과 막사, 오른쪽에 짬통. 코드로 그린다.

const W := 1280.0
const GROUND := 500.0
var seed_ := 11


func _rand() -> float:
	seed_ = (seed_ * 9301 + 49297) % 233280
	return seed_ / 233280.0


func _ready() -> void:
	# 하늘: 세로 그라디언트 텍스처
	var sky := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 0.8, 1.0])
	g.colors = PackedColorArray([Color("1d1b33"), Color("4b3557"), Color("c76a4f"), Color("f0b067")])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 256
	sky.texture = gt
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.position = Vector2(-600, -400)
	sky.size = Vector2(W + 1200, GROUND + 400)
	sky.z_index = -100
	sky.show_behind_parent = true
	add_child(sky)
	move_child(sky, 0)


func _draw() -> void:
	seed_ = 11
	# 노을 해
	draw_circle(Vector2(820, GROUND - 40), 120, Color(1, 0.75, 0.45, 0.25))
	draw_circle(Vector2(820, GROUND - 40), 70, Color(1, 0.82, 0.55, 0.85))
	# 먼 산
	var hills := PackedVector2Array([Vector2(-600, GROUND - 60)])
	for i in 40:
		var x := -600 + i * 70.0
		hills.append(Vector2(x, GROUND - 120 - sin(i * 0.7) * 40 - _rand() * 30))
	hills.append(Vector2(W + 600, GROUND - 60))
	hills.append(Vector2(W + 600, GROUND))
	hills.append(Vector2(-600, GROUND))
	draw_colored_polygon(hills, Color("3a2b45"))
	# 막사 두 동
	for b in [[-180.0, 560.0], [760.0, 520.0]]:
		var bx: float = b[0]
		var bw: float = b[1]
		var top := GROUND - 210
		draw_rect(Rect2(bx, top, bw, 210), Color("2c2531"))
		var roof := PackedVector2Array([Vector2(bx - 24, top), Vector2(bx + bw * 0.5, top - 60), Vector2(bx + bw + 24, top)])
		draw_colored_polygon(roof, Color("3d2f3a"))
		draw_line(Vector2(bx - 24, top), Vector2(bx + bw + 24, top), Color("1a1520"), 6)
		var cols := int(bw / 70)
		for c in cols:
			for r in 2:
				var wx := bx + 30 + c * 70
				var wy := top + 40 + r * 80
				var lit := _rand() > 0.35
				draw_rect(Rect2(wx, wy, 40, 48), Color("ffd27a") if lit else Color("1a1520"))
				if lit:
					draw_rect(Rect2(wx - 10, wy - 10, 60, 68), Color(1, 0.8, 0.4, 0.12))
				draw_rect(Rect2(wx, wy, 40, 48), Color("1a1520"), false, 3)
				draw_line(Vector2(wx + 20, wy), Vector2(wx + 20, wy + 48), Color("1a1520"), 2)
	# 막사 간판
	draw_rect(Rect2(-40, GROUND - 268, 240, 34), Color("e9e2c8"))
	draw_rect(Rect2(-40, GROUND - 268, 240, 34), Color("1a1520"), false, 3)
	draw_string(load("res://fonts/BlackHanSans.ttf"), Vector2(-40, GROUND - 242), "제 1 생활관", HORIZONTAL_ALIGNMENT_CENTER, 240, 24, Color("2c2531"))
	# 철조망 울타리
	for i in 40:
		var x := -600 + i * 60.0
		draw_line(Vector2(x, GROUND - 4), Vector2(x, GROUND - 70), Color("231c22"), 5)
	for h in [GROUND - 60, GROUND - 40, GROUND - 20]:
		draw_line(Vector2(-600, h), Vector2(W + 600, h + 2), Color("231c22"), 2)
	# 연병장 바닥
	var ground := PackedVector2Array([Vector2(-600, GROUND), Vector2(W + 600, GROUND), Vector2(W + 600, 1000), Vector2(-600, 1000)])
	draw_colored_polygon(ground, Color("6b5a4a"))
	for i in 18:
		var y := GROUND + 6 + pow(i, 1.6) * 3.0
		draw_line(Vector2(-600, y), Vector2(W + 600, y), Color(0, 0, 0, 0.08 + i * 0.006), 2)
	for i in 120:
		var x := -600 + _rand() * (W + 1200)
		var y := GROUND + 10 + _rand() * 230
		draw_circle(Vector2(x, y), 1.5 + _rand() * 2.5, Color(0.25, 0.2, 0.17, 0.5))
	# 짬통(오른쪽)
	var cx := 1130.0
	draw_rect(Rect2(cx - 50, GROUND - 92, 100, 92), Color("3f6a4a"))
	draw_rect(Rect2(cx - 56, GROUND - 104, 112, 16), Color("2f523a"))
	draw_rect(Rect2(cx - 50, GROUND - 92, 100, 92), Color("1a1520"), false, 4)
	draw_rect(Rect2(cx - 56, GROUND - 104, 112, 16), Color("1a1520"), false, 4)
	draw_string(load("res://fonts/Pretendard-Black.ttf"), Vector2(cx - 26, GROUND - 40), "잔반", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("e9e2c8"))
	# 바닥 그늘
	draw_rect(Rect2(-600, GROUND - 2, W + 1200, 6), Color(0, 0, 0, 0.25))
