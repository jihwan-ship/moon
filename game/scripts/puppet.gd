class_name Puppet
extends Node2D
## 관절 인형. art/parts.json의 부위 그림을 관절에 붙이고, 각도 사전(포즈)으로 움직인다.
## 각도 단위는 도. 팔다리는 아래로 늘어진 상태가 0이고, 앞(오른쪽)으로 들면 음수다.

const JOINTS := ["lean", "head", "thighF", "shinF", "thighB", "shinB", "upperF", "foreF", "upperB", "foreB", "tail", "prop_rot"]

# 종류별 골격 치수(1배 기준 픽셀)
const RIGS := {
	"s": {"thigh": 54, "shin": 44, "upper": 38, "fore": 32, "hip_y": 110, "hipF": 8, "hipB": -8,
		"neck": Vector2(2, -90), "shF": Vector2(10, -78), "shB": Vector2(-12, -80), "hand": "s_hand", "boot": "s_boot",
		"tail": null},
	"t": {"thigh": 52, "shin": 44, "upper": 40, "fore": 34, "hip_y": 108, "hipF": 12, "hipB": -12,
		"neck": Vector2(0, -98), "shF": Vector2(16, -86), "shB": Vector2(-14, -88), "hand": "t_paw", "boot": "t_boot", "head_scale": 0.74,
		"tail": Vector2(-38, -12)},
}

static var _meta: Dictionary = {}
static var _scale := 2.0

var kind := "s"
var j: Dictionary = {}          # 관절 이름 -> Node2D
var face_spr: Sprite2D
var prop_spr: Sprite2D
var rank_spr: Sprite2D
var bootF: Node2D
var bootB: Node2D
var body_root: Node2D            # 좌우 반전과 들썩임을 담당
var hip: Node2D
var cur := {}                    # 현재 포즈 값
var _tween: Tween
var face_name := ""
var prop_name := ""
var prop_hand := "F"


static func load_meta() -> void:
	if not _meta.is_empty():
		return
	var f := FileAccess.open("res://art/parts.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	_scale = float(data["scale"])
	_meta = data["parts"]


func _sprite(part: String, z := 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load("res://art/parts/%s.png" % part)
	s.centered = false
	var m: Dictionary = _meta[part]
	s.offset = Vector2(m["ox"], m["oy"]) * _scale
	s.scale = Vector2.ONE / _scale
	s.z_index = z
	return s


func _joint(parent: Node2D, name_: String, pos: Vector2, part: String, z: int) -> Node2D:
	var n := Node2D.new()
	n.name = name_
	n.position = pos
	n.z_index = z
	parent.add_child(n)
	if part != "":
		n.add_child(_sprite(part))
	j[name_] = n
	return n


func setup(kind_: String) -> void:
	kind = kind_
	load_meta()
	var r: Dictionary = RIGS[kind]
	var p := kind + "_"
	body_root = Node2D.new()
	add_child(body_root)
	hip = Node2D.new()
	hip.position = Vector2(0, -r["hip_y"])
	body_root.add_child(hip)
	# 뒷다리
	var tb := _joint(hip, "thighB", Vector2(r["hipB"], 0), p + "thigh", -3)
	var sb := _joint(tb, "shinB", Vector2(0, r["thigh"]), p + "shin", 0)
	bootB = _joint(sb, "bootB", Vector2(0, r["shin"]), r["boot"], 1)
	# 몸통
	var torso := _joint(hip, "lean", Vector2.ZERO, p + "torso", 0)
	if r["tail"] != null:
		_joint(torso, "tail", r["tail"], "t_tail", -8)
	var ub := _joint(torso, "upperB", r["shB"], p + "upper", -6)
	var fb := _joint(ub, "foreB", Vector2(0, r["upper"]), p + "fore", 0)
	var hb := _joint(fb, "handB", Vector2(0, r["fore"]), r["hand"], 1)
	# 앞다리
	var tf := _joint(hip, "thighF", Vector2(r["hipF"], 0), p + "thigh", 1)
	var sf := _joint(tf, "shinF", Vector2(0, r["thigh"]), p + "shin", 0)
	bootF = _joint(sf, "bootF", Vector2(0, r["shin"]), r["boot"], 1)
	# 머리와 앞팔
	var head := _joint(torso, "head", r["neck"], p + "head", 3)
	head.scale = Vector2.ONE * r.get("head_scale", 1.0)
	face_spr = Sprite2D.new()
	face_spr.centered = false
	face_spr.z_index = 1
	head.add_child(face_spr)
	if kind == "t":
		rank_spr = _sprite("t_rank1", 2)
		head.add_child(rank_spr)
	var uf := _joint(torso, "upperF", r["shF"], p + "upper", 5)
	var ff := _joint(uf, "foreF", Vector2(0, r["upper"]), p + "fore", 0)
	var hf := _joint(ff, "handF", Vector2(0, r["fore"]), r["hand"], 2)
	prop_spr = Sprite2D.new()
	prop_spr.centered = false
	prop_spr.z_index = -1
	hf.add_child(prop_spr)
	set_face("normal")
	set_pose(Poses.get_pose(kind, "idle"))


func set_face(f: String) -> void:
	if f == "" or f == face_name:
		return
	var part := "%s_face_%s" % [kind, f]
	if not _meta.has(part):
		return
	face_name = f
	face_spr.texture = load("res://art/parts/%s.png" % part)
	var m: Dictionary = _meta[part]
	face_spr.offset = Vector2(m["ox"], m["oy"]) * _scale
	face_spr.scale = Vector2.ONE / _scale


func set_rank(n: int) -> void:
	if rank_spr:
		rank_spr.texture = load("res://art/parts/t_rank%d.png" % clampi(n, 1, 4))


func set_prop(p: String, hand := "F") -> void:
	if p == prop_name and hand == prop_hand:
		return
	prop_name = p
	prop_hand = hand
	if prop_spr.get_parent():
		prop_spr.get_parent().remove_child(prop_spr)
	j["hand" + hand].add_child(prop_spr)
	if p == "":
		prop_spr.texture = null
		return
	prop_spr.texture = load("res://art/parts/%s.png" % p)
	var m: Dictionary = _meta[p]
	prop_spr.offset = Vector2(m["ox"], m["oy"]) * _scale
	prop_spr.scale = Vector2.ONE / _scale
	prop_spr.position = Vector2(0, 10)
	prop_spr.z_index = 3 if hand == "F" else -2


## 포즈 값 하나를 노드에 반영한다
func _apply(k: String, v) -> void:
	cur[k] = v
	match k:
		"hip_dx":
			hip.position.x = v
		"hip_dy":
			hip.position.y = -RIGS[kind]["hip_y"] + v
		"prop_rot":
			prop_spr.rotation_degrees = v
		_:
			if j.has(k):
				j[k].rotation_degrees = v


func _process(_d: float) -> void:
	# 발은 늘 바닥과 평행하게
	if bootF:
		bootF.global_rotation = body_root.global_rotation
		bootB.global_rotation = body_root.global_rotation


func set_pose(p: Dictionary) -> void:
	if _tween:
		_tween.kill()
	for k in p:
		if k == "face":
			set_face(p[k])
		elif k == "prop":
			set_prop(p[k], p.get("prop_hand", "F"))
		elif k == "prop_hand":
			pass
		else:
			_apply(k, float(p[k]))


## 포즈로 부드럽게 옮겨 간다. 표정과 소품은 바로 바뀐다.
func tween_pose(p: Dictionary, dur := 0.18, trans := Tween.TRANS_QUAD, ease := Tween.EASE_OUT) -> Tween:
	if _tween:
		_tween.kill()
	if p.has("face"):
		set_face(p["face"])
	if p.has("prop"):
		set_prop(p["prop"], p.get("prop_hand", "F"))
	_tween = create_tween().set_parallel(true).set_trans(trans).set_ease(ease)
	for k in p:
		if k in ["face", "prop", "prop_hand"]:
			continue
		var from: float = cur.get(k, 0.0)
		var to := float(p[k])
		_tween.tween_method(func(v): _apply(k, v), from, to, dur)
	return _tween


func pose(name_: String, dur := 0.18, trans := Tween.TRANS_QUAD, ease := Tween.EASE_OUT) -> Tween:
	return tween_pose(Poses.get_pose(kind, name_), dur, trans, ease)
