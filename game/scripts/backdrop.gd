extends Node2D
## 배경: 해 질 녘 막사 앞 연병장을 원작 무대처럼 깊이 있게 그린다. 코드로 그린다.
## 뒤쪽 막사 벽(WALL)에서 앞으로 바닥이 넓게 펼쳐지고, 캐릭터는 그 바닥 한가운데(GROUND)에 선다.
## 카메라가 멀리서 보므로 좌표는 화면보다 훨씬 넓게 잡는다.

const GROUND := 500.0          # 캐릭터 발 높이 (battle.gd와 같다)
const WALL := 230.0            # 막사 벽과 바닥이 만나는 선
const X0 := -1700.0
const X1 := 3000.0
const BOTTOM := 1400.0
const VP := Vector2(640, -700) # 바닥 줄이 모이는 소실점
var seed_ := 11


func _rand() -> float:
	seed_ = (seed_ * 9301 + 49297) % 233280
	return seed_ / 233280.0


func _ready() -> void:
	# 하늘: 세로 그라디언트 텍스처
	var sky := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 0.82, 1.0])
	g.colors = PackedColorArray([Color("1d1b33"), Color("4b3557"), Color("c76a4f"), Color("f0b067")])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 256
	sky.texture = gt
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.position = Vector2(X0, -1400)
	sky.size = Vector2(X1 - X0, WALL - 200 + 1400)
	sky.show_behind_parent = true
	add_child(sky)
	move_child(sky, 0)


## 깊이(뒤 벽 = 0, 캐릭터 줄 = 1)에 따른 크기
func _depth_scale(y: float) -> float:
	return 0.7 + 0.3 * clampf((y - WALL) / (GROUND - WALL), 0.0, 1.6)


func _draw() -> void:
	seed_ = 11
	_draw_far()
	_draw_barracks()
	_draw_floor()
	# 뒤쪽부터 앞쪽 순서로 소품
	_fence(WALL + 14)
	_lamp(Vector2(-260, WALL + 40))
	_lamp(Vector2(1540, WALL + 40))
	_crates(Vector2(-820, WALL + 90))
	_trash_can(Vector2(1720, WALL + 120))
	_sandbags(Vector2(-1180, WALL + 210))
	_drums(Vector2(2150, WALL + 230))
	_sandbags(Vector2(2500, GROUND + 60))
	_crates(Vector2(-1500, GROUND + 80))


# ---------------------------------------------------------------- 먼 배경

func _draw_far() -> void:
	var top := WALL - 330
	# 노을 해
	draw_circle(Vector2(1100, top - 30), 240, Color(1, 0.75, 0.45, 0.22))
	draw_circle(Vector2(1100, top - 30), 130, Color(1, 0.82, 0.55, 0.85))
	# 먼 산
	var hills := PackedVector2Array([Vector2(X0, top + 40)])
	for i in 50:
		var x := X0 + i * 100.0
		hills.append(Vector2(x, top - 150 - sin(i * 0.6) * 60 - _rand() * 40))
	hills.append(Vector2(X1, top + 40))
	draw_colored_polygon(hills, Color("3a2b45"))


# ---------------------------------------------------------------- 막사(뒤 벽)

func _draw_barracks() -> void:
	var top := WALL - 330
	draw_rect(Rect2(X0, top, X1 - X0, WALL - top), Color("2c2531"))
	# 처마와 지붕
	var roof := PackedVector2Array([Vector2(X0, top), Vector2(X0, top - 60), Vector2(X1, top - 60), Vector2(X1, top)])
	draw_colored_polygon(roof, Color("3d2f3a"))
	draw_line(Vector2(X0, top), Vector2(X1, top), Color("1a1520"), 10)
	# 기둥으로 칸을 나눈다
	for i in 24:
		var x := X0 + i * 200.0
		draw_rect(Rect2(x - 10, top, 20, WALL - top), Color("241e29"))
	# 창문 두 층
	for i in 23:
		var bx := X0 + 30 + i * 200.0
		if absf(bx + 70 - 640) < 260:
			continue
		for r in 2:
			var wx := bx + 20
			var wy := top + 50 + r * 130
			var lit := _rand() > 0.4
			if lit:
				draw_rect(Rect2(wx - 16, wy - 16, 132, 122), Color(1, 0.8, 0.4, 0.1))
			draw_rect(Rect2(wx, wy, 100, 90), Color("ffd27a") if lit else Color("1a1520"))
			draw_rect(Rect2(wx, wy, 100, 90), Color("1a1520"), false, 5)
			draw_line(Vector2(wx + 50, wy), Vector2(wx + 50, wy + 90), Color("1a1520"), 4)
	# 가운데 현관: 안에서 불빛이 새어 나온다
	var dx := 640.0
	draw_rect(Rect2(dx - 230, top + 20, 460, WALL - top - 20), Color("1d1820"))
	draw_rect(Rect2(dx - 170, top + 70, 340, WALL - top - 70), Color("f5a35a"))
	draw_rect(Rect2(dx - 120, top + 110, 240, WALL - top - 110), Color("ffd99a"))
	draw_rect(Rect2(dx - 170, top + 70, 340, WALL - top - 70), Color("1a1520"), false, 6)
	draw_line(Vector2(dx, top + 70), Vector2(dx, WALL), Color("1a1520"), 5)
	# 현관 불빛이 바닥으로 번진다
	var glow := PackedVector2Array([Vector2(dx - 170, WALL), Vector2(dx + 170, WALL), Vector2(dx + 420, GROUND - 40), Vector2(dx - 420, GROUND - 40)])
	draw_colored_polygon(glow, Color(1, 0.78, 0.45, 0.13))
	# 간판
	var font := load("res://fonts/BlackHanSans.ttf")
	draw_rect(Rect2(dx - 180, top - 30, 360, 64), Color("e9e2c8"))
	draw_rect(Rect2(dx - 180, top - 30, 360, 64), Color("1a1520"), false, 5)
	draw_string(font, Vector2(dx - 180, top + 18), "제 1 생활관", HORIZONTAL_ALIGNMENT_CENTER, 360, 44, Color("2c2531"))
	# 벽 아래 그늘
	draw_rect(Rect2(X0, WALL - 12, X1 - X0, 12), Color(0, 0, 0, 0.35))


# ---------------------------------------------------------------- 바닥

func _draw_floor() -> void:
	var floor_ := PackedVector2Array([Vector2(X0, WALL), Vector2(X1, WALL), Vector2(X1, BOTTOM), Vector2(X0, BOTTOM)])
	draw_colored_polygon(floor_, Color("6b5a4a"))
	# 뒤로 갈수록 어둡게
	for i in 10:
		var y0 := WALL + i * 24.0
		draw_rect(Rect2(X0, y0, X1 - X0, 24), Color(0, 0, 0, 0.3 - i * 0.03))
	# 앞뒤로 뻗는 줄(소실점으로 모인다)
	for i in range(-30, 31):
		var bx := 640.0 + i * 110.0
		var a := Vector2(bx, WALL)
		var dir := (a - VP).normalized()
		var b := a + dir * ((BOTTOM - WALL) / dir.y)
		draw_line(a, b, Color(0, 0, 0, 0.1), 3)
	# 가로 줄: 앞으로 올수록 간격이 넓어진다
	for i in range(1, 16):
		var y := WALL + pow(i / 15.0, 1.7) * (BOTTOM - WALL)
		draw_line(Vector2(X0, y), Vector2(X1, y), Color(0, 0, 0, 0.12), 3)
	# 자갈
	for i in 260:
		var y := WALL + 10 + pow(_rand(), 0.8) * (BOTTOM - WALL)
		var x := X0 + _rand() * (X1 - X0)
		draw_circle(Vector2(x, y), (2.0 + _rand() * 4.0) * _depth_scale(y), Color(0.25, 0.2, 0.17, 0.5))
	# 캐릭터가 서는 곳을 은은하게 비춘다
	var pool := PackedVector2Array()
	for k in 40:
		var t := TAU * k / 40.0
		pool.append(Vector2(640 + cos(t) * 1100, GROUND + sin(t) * 200))
	draw_colored_polygon(pool, Color(1, 0.85, 0.6, 0.07))


# ---------------------------------------------------------------- 소품 (p는 바닥에 닿는 점)

func _fence(y: float) -> void:
	for i in 80:
		var x := X0 + i * 60.0
		if absf(x - 640) < 200:
			continue
		draw_line(Vector2(x, y), Vector2(x, y - 90), Color("231c22"), 6)
	for h in [y - 75, y - 50, y - 25]:
		draw_line(Vector2(X0, h), Vector2(440, h), Color("231c22"), 3)
		draw_line(Vector2(840, h), Vector2(X1, h), Color("231c22"), 3)


func _shadow(p: Vector2, w: float) -> void:
	var pts := PackedVector2Array()
	for k in 20:
		var t := TAU * k / 20.0
		pts.append(p + Vector2(cos(t) * w, sin(t) * w * 0.18))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.3))


func _lamp(p: Vector2) -> void:
	var s := _depth_scale(p.y)
	_shadow(p, 40 * s)
	draw_line(p, p + Vector2(0, -360) * s, Color("1a1520"), 12 * s)
	draw_line(p + Vector2(0, -360) * s, p + Vector2(60, -360) * s, Color("1a1520"), 10 * s)
	var bulb := p + Vector2(60, -340) * s
	draw_circle(bulb, 90 * s, Color(1, 0.8, 0.45, 0.12))
	draw_circle(bulb, 18 * s, Color("ffe1a0"))


func _box(p: Vector2, w: float, h: float, col: Color, s: float) -> void:
	var r := Rect2(p.x - w * s / 2, p.y - h * s, w * s, h * s)
	draw_rect(r, col)
	# 윗면을 살짝 보여 줘서 입체감
	var top := PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.position + Vector2(r.size.x - 14 * s, -16 * s), r.position + Vector2(14 * s, -16 * s)])
	draw_colored_polygon(top, col.lightened(0.18))
	draw_rect(r, Color("1a1520"), false, 5 * s)
	draw_polyline(top + PackedVector2Array([top[0]]), Color("1a1520"), 4 * s)


func _crates(p: Vector2) -> void:
	var s := _depth_scale(p.y)
	_shadow(p + Vector2(20, 0) * s, 160 * s)
	_box(p, 130, 110, Color("7a5a3a"), s)
	_box(p + Vector2(130, 6) * s, 110, 90, Color("6e5034"), s)
	_box(p + Vector2(40, -110) * s, 100, 90, Color("806040"), s)


func _trash_can(p: Vector2) -> void:
	var s := _depth_scale(p.y)
	_shadow(p, 110 * s)
	_box(p, 190, 170, Color("3f6a4a"), s)
	draw_rect(Rect2(p.x - 105 * s, p.y - 196 * s, 210 * s, 30 * s), Color("2f523a"))
	draw_rect(Rect2(p.x - 105 * s, p.y - 196 * s, 210 * s, 30 * s), Color("1a1520"), false, 5 * s)
	draw_string(load("res://fonts/Pretendard-Black.ttf"), Vector2(p.x - 52 * s, p.y - 70 * s), "잔반", HORIZONTAL_ALIGNMENT_LEFT, -1, int(50 * s), Color("e9e2c8"))


func _sandbags(p: Vector2) -> void:
	var s := _depth_scale(p.y)
	_shadow(p, 200 * s)
	for row in 3:
		for k in 4 - row:
			var c := p + Vector2((k - (3 - row) / 2.0) * 90, -30 - row * 50) * s
			var pts := PackedVector2Array()
			for m in 16:
				var t := TAU * m / 16.0
				pts.append(c + Vector2(cos(t) * 50, sin(t) * 28) * s)
			draw_colored_polygon(pts, Color("a08a62").darkened(row * 0.08))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color("1a1520"), 4 * s)


func _drums(p: Vector2) -> void:
	var s := _depth_scale(p.y)
	_shadow(p, 150 * s)
	for k in 2:
		var c := p + Vector2(k * 120 - 60, k * 10) * s
		draw_rect(Rect2(c.x - 50 * s, c.y - 150 * s, 100 * s, 150 * s), Color("4c5a3a"))
		for h in [40, 100]:
			draw_line(c + Vector2(-50, -h) * s, c + Vector2(50, -h) * s, Color("1a1520"), 4 * s)
		draw_rect(Rect2(c.x - 50 * s, c.y - 150 * s, 100 * s, 150 * s), Color("1a1520"), false, 5 * s)
		var lid := PackedVector2Array()
		for m in 16:
			var t := TAU * m / 16.0
			lid.append(c + Vector2(cos(t) * 50, -150 + sin(t) * 14) * s)
		draw_colored_polygon(lid, Color("5d6c48"))
		draw_polyline(lid + PackedVector2Array([lid[0]]), Color("1a1520"), 4 * s)
