class_name SpritePuppet
extends Node2D
## 롤랑 모드 캐릭터. Puppet과 같은 이름의 함수를 제공해서 battle.gd가 그대로 쓸 수 있다.
## 평소에는 서 있는 그림 한 장을 기울이고 웅크리는 식으로 움직이고,
## 공격 순간에만 무기 자세 그림으로 바뀐다. 얼굴이 섞이거나 찌그러지지 않게 겹치기와 늘이기는 하지 않는다.
## 그림은 art/roland/(원작에서 뽑은 것, 저장소에는 없음)에 있다.

const DIR := "res://art/roland/"
const SCALE := 0.62

# 서 있는 그림으로 표현하는 자세: [기울기(도), 가로 크기, 세로 크기, 앞뒤 이동, 위아래 이동]
# 크기는 늘 1이다(얼굴이 찌그러지지 않게)
const BODY := {
	"idle": [0, 1.0, 1.0, 0, 0],
	"run": [12, 1.0, 1.0, 10, 4],
	"stab_wind": [-6, 1.0, 1.0, -6, 4],
	"butt_wind": [-6, 1.0, 1.0, -6, 4],
	"throw_wind": [-8, 1.0, 1.0, -8, 0],
	"block": [-5, 1.0, 1.0, -10, 8],
	"evade": [-16, 1.0, 1.0, -24, 6],
	"hurt": [-12, 1.0, 1.0, -16, 0],
	"eat": [0, 1.0, 1.0, 0, 0],
	"cheer": [-4, 1.0, 1.0, 0, -6],
	"victory": [-4, 1.0, 1.0, 0, -6],
	"down": [-82, 1.0, 1.0, -30, 10],
}

var kind := "r"
var body_root: Node2D   # 숨쉬기(battle.gd가 scale:y를 움직인다)
var lean: Node2D        # 기울기와 웅크림
var spr: Sprite2D
var meta: Dictionary = {}
var cur_pose := ""
var facing := 1.0
# 무기: 휘두르는 기준점(오른쪽을 볼 때, 발 기준). 손이 아래로 늘어진 그림이라 어깨 높이에 두어
# 무기가 몸 위로 크게 보이게 한다. WSCALE은 무기 그림 전체에 곱하는 크기
const HAND := {"F": Vector2(30, -168), "B": Vector2(-24, -172)}
const WSCALE := 1.5
var hands: Node2D        # 바라보는 방향에 따라 좌우가 뒤집힌다
var hand := {}           # "F"/"B" -> 회전하는 손 노드
var held := {}           # "F"/"B" -> 들고 있는 무기 이름
var wmeta: Dictionary = {}
var _aim_tw := {}
var _tw: Tween


static func available() -> bool:
	return ResourceLoader.exists(DIR + "stand.png") and FileAccess.file_exists(DIR + "poses.json")


func setup(_kind: String) -> void:
	var f := FileAccess.open(DIR + "poses.json", FileAccess.READ)
	meta = JSON.parse_string(f.get_as_text())
	body_root = Node2D.new()
	add_child(body_root)
	lean = Node2D.new()
	body_root.add_child(lean)
	spr = _new_sprite()
	if FileAccess.file_exists(DIR + "weapons.json"):
		wmeta = JSON.parse_string(FileAccess.open(DIR + "weapons.json", FileAccess.READ).get_as_text())
	hands = Node2D.new()
	lean.add_child(hands)
	for h in ["F", "B"]:
		var n := Node2D.new()
		n.position = HAND[h]
		n.z_index = 2 if h == "F" else -2
		var w := Sprite2D.new()
		w.centered = false
		n.add_child(w)
		hands.add_child(n)
		hand[h] = n
	_show("stand")


func _new_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.scale = Vector2.ONE * SCALE
	lean.add_child(s)
	return s


func _place(s: Sprite2D, img: String) -> void:
	s.texture = load(DIR + img + ".png")
	var m: Dictionary = meta[img]
	var foot: Array = m["foot"]
	# 원작 그림은 왼쪽을 본다. facing이 1이면 뒤집어서 오른쪽을 보게 한다
	s.flip_h = facing > 0
	if s.flip_h:
		s.offset = Vector2(-(float(m["w"]) - float(foot[0])), -float(foot[1]))
	else:
		s.offset = Vector2(-float(foot[0]), -float(foot[1]))


## 그림을 바꾼다
func _show(img: String) -> void:
	if img == cur_pose:
		return
	cur_pose = img
	_place(spr, img)


## 바라보는 방향(1 = 오른쪽, -1 = 왼쪽)
func face(dir: float) -> void:
	if dir == facing:
		return
	facing = dir
	_place(spr, cur_pose)
	hands.scale.x = dir


func _body_to(v: Array, dur: float) -> Tween:
	if _tw:
		_tw.kill()
	_tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var d := maxf(dur, 0.06)
	_tw.tween_property(lean, "rotation_degrees", float(v[0]) * facing, d)
	_tw.tween_property(lean, "scale", Vector2(v[1], v[2]), d)
	_tw.tween_property(lean, "position", Vector2(float(v[3]) * facing, v[4]), d)
	return _tw


## 무기 자세 그림(공방별 공격 동작용). 기울기는 바로 펴진다
func show_img(img: String, _squash := true) -> void:
	_show(img)
	_body_to([0, 1.0, 1.0, 0, 0], 0.05)


func pose(name_: String, dur := 0.18, _trans := Tween.TRANS_QUAD, _ease := Tween.EASE_OUT) -> Tween:
	if name_ in ["idle", "eat", "cheer", "victory"]:
		face(1.0)
		clear_weapons()
	_show("stand")
	return _body_to(BODY.get(name_, BODY["idle"]), dur)


func set_pose(_p: Dictionary) -> void:
	pass


func tween_pose(_p: Dictionary, dur := 0.18, _trans := Tween.TRANS_QUAD, _ease := Tween.EASE_OUT) -> Tween:
	var tw := create_tween()
	tw.tween_interval(dur)
	return tw


func set_face(_f: String) -> void:
	pass


func set_prop(_p: String, _hand := "F") -> void:
	pass


func set_rank(_n: int) -> void:
	pass


# ---------------------------------------------------------------- 무기

## 손에 무기를 쥐인다. 각도(도)는 0이면 앞(상대 쪽), -90이면 위, 90이면 아래를 가리킨다
func hold(h: String, weapon: String, angle := 60.0) -> void:
	var n: Node2D = hand[h]
	var w: Sprite2D = n.get_child(0)
	held[h] = weapon
	if weapon == "" or not wmeta.has(weapon):
		w.texture = null
		return
	var m: Dictionary = wmeta[weapon]
	w.texture = load(DIR + "weapons/%s.png" % weapon)
	w.offset = -Vector2(m["grip"][0], m["grip"][1])
	# 그림은 칼날이 왼쪽을 향하므로 180도 돌려서 앞을 향하게 한다
	w.rotation_degrees = 180
	w.scale = Vector2.ONE * float(m["scale"]) * WSCALE
	n.rotation_degrees = angle


## 손을 angle까지 휘두른다
func aim(h: String, angle: float, dur := 0.1, trans := Tween.TRANS_QUAD) -> Tween:
	if _aim_tw.has(h) and _aim_tw[h]:
		_aim_tw[h].kill()
	var tw := create_tween().set_trans(trans).set_ease(Tween.EASE_OUT)
	tw.tween_property(hand[h], "rotation_degrees", angle, maxf(dur, 0.01))
	_aim_tw[h] = tw
	return tw


func clear_weapons() -> void:
	hold("F", "")
	hold("B", "")
