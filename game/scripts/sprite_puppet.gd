class_name SpritePuppet
extends Node2D
## 통짜 자세 그림으로 움직이는 캐릭터. Puppet과 같은 이름의 함수를 제공해서 battle.gd가 그대로 쓸 수 있다.
## 롤랑 모드: art/roland/의 자세 그림(원작에서 조립한 것, 저장소에는 없음)을 쓴다.

const DIR := "res://art/roland/"
# 이병 포즈 이름 -> 롤랑 자세 그림
const MAP := {
	"idle": "idle", "run": "move", "stab_wind": "move", "stab": "thrust", "butt_wind": "slash_ready", "butt": "slash",
	"aim": "logic_pistols", "recoil": "logic_pistols", "block": "guard", "evade": "evade", "hurt": "hurt",
	"throw_wind": "slash_ready", "throw": "wheels_smash", "eat": "idle", "cheer": "idle", "down": "hurt", "victory": "idle",
}

var kind := "r"
var body_root: Node2D
var spr: Sprite2D
var meta: Dictionary = {}
var cur_pose := ""


static func available() -> bool:
	return ResourceLoader.exists(DIR + "idle.png") and FileAccess.file_exists(DIR + "poses.json")


func setup(_kind: String) -> void:
	var f := FileAccess.open(DIR + "poses.json", FileAccess.READ)
	meta = JSON.parse_string(f.get_as_text())
	body_root = Node2D.new()
	add_child(body_root)
	spr = Sprite2D.new()
	spr.centered = false
	# 원작 그림은 왼쪽을 본다. 뒤집어서 오른쪽을 보게 한다
	spr.flip_h = true
	spr.scale = Vector2.ONE * 0.62
	body_root.add_child(spr)
	_show("idle")


func _show(img: String) -> void:
	if img == cur_pose:
		return
	cur_pose = img
	spr.texture = load(DIR + img + ".png")
	var m: Dictionary = meta[img]
	var foot: Array = m["foot"]
	# 뒤집었으므로 발 기준점의 x도 반대편에서 잰다
	spr.offset = Vector2(-(float(m["w"]) - float(foot[0])), -float(foot[1]))


func pose(name_: String, dur := 0.18, _trans := Tween.TRANS_QUAD, _ease := Tween.EASE_OUT) -> Tween:
	var img: String = MAP.get(name_, "idle")
	var changed := img != cur_pose
	_show(img)
	var tw := create_tween()
	if changed:
		# 자세가 바뀔 때 살짝 눌렸다 펴지는 느낌
		body_root.scale = Vector2(1.06, 0.94)
		tw.tween_property(body_root, "scale", Vector2.ONE, maxf(dur, 0.08)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_interval(0.01)
	return tw


func set_pose(p: Dictionary) -> void:
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
