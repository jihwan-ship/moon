class_name SpritePuppet
extends Node2D
## 롤랑 모드 캐릭터. Puppet과 같은 이름의 함수를 제공해서 battle.gd가 그대로 쓸 수 있다.
## 평소에는 서 있는 그림 한 장을 기울이고 웅크리는 식으로 움직이고,
## 공격 순간에만 무기 자세 그림으로 부드럽게 겹쳐 넘어간다.
## 그림은 art/roland/(원작에서 뽑은 것, 저장소에는 없음)에 있다.

const DIR := "res://art/roland/"
const SCALE := 0.62

# 서 있는 그림으로 표현하는 자세: [기울기(도), 가로 크기, 세로 크기, 앞뒤 이동, 위아래 이동]
const BODY := {
	"idle": [0, 1.0, 1.0, 0, 0],
	"run": [12, 1.0, 0.97, 10, 4],
	"stab_wind": [-6, 1.03, 0.96, -6, 4],
	"butt_wind": [-6, 1.03, 0.96, -6, 4],
	"throw_wind": [-8, 1.0, 1.0, -8, 0],
	"block": [-5, 1.05, 0.93, -10, 8],
	"evade": [-16, 1.0, 1.0, -24, 6],
	"hurt": [-12, 1.0, 0.98, -16, 0],
	"eat": [0, 1.0, 1.0, 0, 0],
	"cheer": [-4, 1.0, 1.03, 0, -6],
	"victory": [-4, 1.0, 1.03, 0, -6],
	"down": [-82, 1.0, 1.0, -30, 10],
}

var kind := "r"
var body_root: Node2D   # 숨쉬기(battle.gd가 scale:y를 움직인다)
var lean: Node2D        # 기울기와 웅크림
var spr: Sprite2D
var spr_old: Sprite2D   # 바뀌기 전 그림(겹쳐서 사라진다)
var meta: Dictionary = {}
var cur_pose := ""
var facing := 1.0
var _tw: Tween
var _fade: Tween


static func available() -> bool:
	return ResourceLoader.exists(DIR + "stand.png") and FileAccess.file_exists(DIR + "poses.json")


func setup(_kind: String) -> void:
	var f := FileAccess.open(DIR + "poses.json", FileAccess.READ)
	meta = JSON.parse_string(f.get_as_text())
	body_root = Node2D.new()
	add_child(body_root)
	lean = Node2D.new()
	body_root.add_child(lean)
	spr_old = _new_sprite()
	spr = _new_sprite()
	spr_old.visible = false
	_show("stand", false)


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


## 그림을 바꾼다. fade면 이전 그림이 잠깐 겹쳐 남았다가 사라진다
func _show(img: String, fade := true) -> void:
	if img == cur_pose:
		return
	if fade and cur_pose != "":
		spr_old.texture = spr.texture
		spr_old.offset = spr.offset
		spr_old.flip_h = spr.flip_h
		spr_old.visible = true
		spr_old.modulate.a = 1.0
		spr.modulate.a = 0.0
		if _fade:
			_fade.kill()
		_fade = create_tween().set_parallel(true)
		_fade.tween_property(spr, "modulate:a", 1.0, 0.05)
		_fade.tween_property(spr_old, "modulate:a", 0.0, 0.12)
		_fade.chain().tween_callback(func(): spr_old.visible = false)
	cur_pose = img
	_place(spr, img)


## 바라보는 방향(1 = 오른쪽, -1 = 왼쪽)
func face(dir: float) -> void:
	if dir == facing:
		return
	facing = dir
	_place(spr, cur_pose)
	spr_old.visible = false


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
	_show(img, true)
	_body_to([0, 1.0, 1.0, 0, 0], 0.05)


func pose(name_: String, dur := 0.18, _trans := Tween.TRANS_QUAD, _ease := Tween.EASE_OUT) -> Tween:
	if name_ in ["idle", "eat", "cheer", "victory"]:
		face(1.0)
	_show("stand", true)
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
