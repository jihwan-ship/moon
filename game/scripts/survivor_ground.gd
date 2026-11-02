extends Node2D
## 뱀서 테스트판 바닥: 해 질 녘 연병장 흙바닥과 자갈, 경기장 가장자리 철조망. 코드로 그린다.

const A := 2000.0


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	draw_rect(Rect2(-A - 400, -A - 400, (A + 400) * 2, (A + 400) * 2), Color("2a2128"))
	draw_rect(Rect2(-A, -A, A * 2, A * 2), Color("6b5a4a"))
	# 바닥 줄눈
	for i in range(-20, 21):
		var x := i * 100.0
		draw_line(Vector2(x, -A), Vector2(x, A), Color(0, 0, 0, 0.06), 2)
		draw_line(Vector2(-A, x), Vector2(A, x), Color(0, 0, 0, 0.06), 2)
	# 자갈과 흙 얼룩
	for i in 900:
		var p := Vector2(rng.randf_range(-A, A), rng.randf_range(-A, A))
		draw_circle(p, rng.randf_range(2, 6), Color(0.25, 0.2, 0.17, 0.5))
	for i in 40:
		var p := Vector2(rng.randf_range(-A, A), rng.randf_range(-A, A))
		draw_circle(p, rng.randf_range(40, 90), Color(0, 0, 0, 0.06))
	# 가장자리 철조망
	for i in range(-40, 41):
		var k := i * 50.0
		for p in [Vector2(k, -A), Vector2(k, A), Vector2(-A, k), Vector2(A, k)]:
			draw_line(p, p + Vector2(0, -60), Color("231c22"), 6)
	for side in [[Vector2(-A, -A), Vector2(A, -A)], [Vector2(-A, A), Vector2(A, A)]]:
		for h in [-50, -30, -10]:
			draw_line(side[0] + Vector2(0, h), side[1] + Vector2(0, h), Color("231c22"), 3)
	for side in [[Vector2(-A, -A), Vector2(-A, A)], [Vector2(A, -A), Vector2(A, A)]]:
		draw_line(side[0], side[1], Color("231c22"), 6)
