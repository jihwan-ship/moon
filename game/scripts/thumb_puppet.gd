class_name ThumbPuppet
extends Node2D
## 정시우 모드의 짬타이거: 엄지척 아재 그림 한 장. Puppet과 같은 이름의 함수를 제공한다.
## 그림을 통째로 기울이고 들썩이고 앞으로 들이받는 식으로만 움직인다(얼굴은 늘이지 않는다).
## 왼쪽(플레이어 쪽)을 보고 서 있다고 보고 값을 정한다.

const IMG := "res://art/sium/thumb.png"
const SCALE := 0.42

# 자세: [기울기(도, +면 뒤로 젖힘), 앞뒤(+면 뒤로), 위아래(+면 아래로)]
const BODY := {
	"idle": [0, 0, 0],
	"run": [-10, -10, 4],
	"claw_wind": [10, 14, 6], "claw": [-16, -36, 0],
	"punch_wind": [10, 14, 6], "punch": [-18, -40, 0],
	"baton_wind": [12, 16, 6], "baton": [-20, -36, 0],
	"aim": [4, 6, 0], "recoil": [12, 18, 0],
	"eat": [-4, 0, 8], "supply": [0, 0, -14],
	"guard": [8, 12, 10], "hurt": [16, 24, 0], "dizzy": [10, 6, 6],
	"command": [-6, -6, -10], "cheer": [-4, 0, -12], "victory": [-4, 0, -12],
	"down": [84, 60, 10],
}

var kind := "t"
var body_root: Node2D   # 숨쉬기(battle.gd가 scale:y를 움직인다)
var lean: Node2D
var spr: Sprite2D
var _tw: Tween
var _hop: Tween


func setup(_kind: String) -> void:
	body_root = Node2D.new()
	add_child(body_root)
	lean = Node2D.new()
	body_root.add_child(lean)
	spr = Sprite2D.new()
	spr.texture = load(IMG)
	spr.centered = false
	var sz := spr.texture.get_size()
	# 발 가운데가 원점
	spr.offset = Vector2(-sz.x / 2, -sz.y + 6)
	spr.scale = Vector2.ONE * SCALE
	lean.add_child(spr)


func pose(name_: String, dur := 0.18, trans := Tween.TRANS_QUAD, ease := Tween.EASE_OUT) -> Tween:
	var v: Array = BODY.get(name_, BODY["idle"])
	if _tw:
		_tw.kill()
	_tw = create_tween().set_parallel(true).set_trans(trans).set_ease(ease)
	var d := maxf(dur, 0.05)
	_tw.tween_property(lean, "rotation_degrees", float(v[0]), d)
	_tw.tween_property(lean, "position", Vector2(v[1], v[2]), d)
	# 공격하거나 신날 때는 한 번 콩 뛴다
	if name_ in ["claw", "punch", "baton", "cheer", "victory", "command", "supply"]:
		_jump(22.0 if name_ in ["cheer", "victory"] else 12.0, d)
	# 맞으면 잠깐 붉게
	if name_ in ["hurt", "dizzy"]:
		var f := create_tween()
		spr.modulate = Color(1, 0.55, 0.55)
		f.tween_property(spr, "modulate", Color.WHITE, 0.3)
	return _tw


func _jump(h: float, d: float) -> void:
	if _hop:
		_hop.kill()
	_hop = create_tween()
	_hop.tween_property(spr, "position:y", -h, d * 0.8 + 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop.tween_property(spr, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


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


func prop_tip(_which := "F") -> Vector2:
	return global_position + Vector2(-120, -150)
