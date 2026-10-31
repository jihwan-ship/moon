class_name Poses
## 포즈 사전. 빠진 관절은 BASE 값을 쓴다.
## 각도: 팔다리가 아래로 늘어지면 0, 앞(오른쪽)으로 들수록 음수. 정강이는 무릎을 뒤로 굽히면 양수.

const BASE := {"lean": 0, "head": 0, "thighF": -8, "shinF": 6, "thighB": 8, "shinB": 4,
	"upperF": 0, "foreF": 0, "upperB": 0, "foreB": 0, "tail": 0, "prop_rot": 0, "hip_dx": 0, "hip_dy": 0}

const S := {
	"idle": {"lean": -2, "head": 3, "thighF": -14, "shinF": 14, "thighB": 14, "shinB": 6,
		"upperF": -30, "foreF": -60, "upperB": 10, "foreB": -70, "prop": "s_k2", "prop_rot": 64, "face": "normal"},
	"run": {"lean": 14, "head": -6, "thighF": -50, "shinF": 70, "thighB": 40, "shinB": 50, "hip_dy": 6,
		"upperF": -20, "foreF": -70, "upperB": 20, "foreB": -80, "prop": "s_k2", "prop_rot": 80, "face": "focus"},
	"stab_wind": {"lean": -10, "head": 6, "thighF": -30, "shinF": 30, "thighB": 24, "shinB": 10, "hip_dy": 8,
		"upperF": 10, "foreF": -80, "upperB": 30, "foreB": -60, "prop": "s_k2", "prop_rot": 70, "face": "focus"},
	"stab": {"lean": 22, "head": -12, "thighF": -60, "shinF": 40, "thighB": 44, "shinB": 4, "hip_dy": 14, "hip_dx": 16,
		"upperF": -90, "foreF": -6, "upperB": -50, "foreB": -40, "prop": "s_k2", "prop_rot": 96, "face": "shout"},
	"butt_wind": {"lean": -16, "head": 8, "thighF": -24, "shinF": 26, "thighB": 20, "shinB": 10,
		"upperF": -170, "foreF": -20, "upperB": -150, "foreB": -30, "prop": "s_k2", "prop_rot": 250, "face": "focus"},
	"butt": {"lean": 26, "head": -10, "thighF": -54, "shinF": 36, "thighB": 40, "shinB": 6, "hip_dy": 14, "hip_dx": 14,
		"upperF": -60, "foreF": -20, "upperB": -40, "foreB": -30, "prop": "s_k2", "prop_rot": 200, "face": "shout"},
	"aim": {"lean": -4, "head": 4, "thighF": -26, "shinF": 20, "thighB": 22, "shinB": 8, "hip_dy": 6,
		"upperF": -84, "foreF": -6, "upperB": -60, "foreB": -60, "prop": "s_k2", "prop_rot": 90, "face": "focus"},
	"recoil": {"lean": -12, "head": 10, "thighF": -24, "shinF": 20, "thighB": 24, "shinB": 8, "hip_dy": 6, "hip_dx": -8,
		"upperF": -100, "foreF": -10, "upperB": -74, "foreB": -60, "prop": "s_k2", "prop_rot": 80, "face": "shout"},
	"block": {"lean": -8, "head": 14, "thighF": -30, "shinF": 34, "thighB": 26, "shinB": 20, "hip_dy": 16,
		"upperF": -120, "foreF": -80, "upperB": -110, "foreB": -90, "prop": "s_k2", "prop_rot": 0, "face": "focus"},
	"evade": {"lean": -26, "head": 18, "thighF": -10, "shinF": 70, "thighB": 50, "shinB": 30, "hip_dy": 24, "hip_dx": -20,
		"upperF": 20, "foreF": -60, "upperB": 40, "foreB": -40, "prop": "s_k2", "prop_rot": 60, "face": "focus"},
	"hurt": {"lean": -24, "head": 22, "thighF": -4, "shinF": 20, "thighB": 30, "shinB": 10, "hip_dx": -10,
		"upperF": 40, "foreF": -20, "upperB": 60, "foreB": -10, "prop": "s_k2", "prop_rot": 40, "face": "hurt"},
	"throw_wind": {"lean": -18, "head": 6, "thighF": -30, "shinF": 30, "thighB": 24, "shinB": 10, "hip_dy": 8,
		"upperF": -20, "foreF": -60, "upperB": 150, "foreB": 40, "prop": "s_grenade", "prop_hand": "B", "face": "focus"},
	"throw": {"lean": 22, "head": -8, "thighF": -50, "shinF": 30, "thighB": 40, "shinB": 4, "hip_dy": 10, "hip_dx": 10,
		"upperF": 20, "foreF": -40, "upperB": -150, "foreB": -10, "prop": "", "face": "shout"},
	"eat": {"lean": 4, "head": -10, "thighF": -10, "shinF": 10, "thighB": 10, "shinB": 4,
		"upperF": -70, "foreF": -90, "upperB": 10, "foreB": -40, "prop": "s_ration", "prop_rot": 0, "face": "happy"},
	"cheer": {"lean": -8, "head": 10, "thighF": -16, "shinF": 10, "thighB": 14, "shinB": 4,
		"upperF": -170, "foreF": 0, "upperB": 20, "foreB": -30, "prop": "", "face": "shout"},
	"down": {"lean": -70, "head": 20, "thighF": -60, "shinF": 30, "thighB": -40, "shinB": 30, "hip_dy": 70, "hip_dx": -20,
		"upperF": 60, "foreF": 0, "upperB": 80, "foreB": 0, "prop": "", "face": "tired"},
	"victory": {"lean": -6, "head": 8, "thighF": -20, "shinF": 10, "thighB": 18, "shinB": 4,
		"upperF": -160, "foreF": -10, "upperB": 30, "foreB": -60, "prop": "s_k2", "prop_rot": 0, "prop_hand": "B", "face": "happy"},
}

const T := {
	"idle": {"lean": 2, "head": -2, "thighF": -10, "shinF": 10, "thighB": 12, "shinB": 6,
		"upperF": -20, "foreF": -50, "upperB": 14, "foreB": -40, "tail": 0, "prop": "", "face": "normal"},
	"run": {"lean": 16, "head": -8, "thighF": -50, "shinF": 70, "thighB": 40, "shinB": 50, "hip_dy": 6,
		"upperF": 30, "foreF": -60, "upperB": -30, "foreB": -60, "tail": 20, "prop": "", "face": "angry"},
	"claw_wind": {"lean": -12, "head": 6, "thighF": -24, "shinF": 26, "thighB": 22, "shinB": 10, "hip_dy": 8,
		"upperF": -160, "foreF": -30, "upperB": 20, "foreB": -40, "tail": -20, "prop": "t_claw", "prop_rot": -90, "face": "angry"},
	"claw": {"lean": 24, "head": -10, "thighF": -56, "shinF": 36, "thighB": 40, "shinB": 4, "hip_dy": 14, "hip_dx": 14,
		"upperF": -40, "foreF": -30, "upperB": 30, "foreB": -30, "tail": 30, "prop": "t_claw", "prop_rot": -60, "face": "angry"},
	"punch_wind": {"lean": -10, "head": 4, "thighF": -24, "shinF": 26, "thighB": 22, "shinB": 10, "hip_dy": 8,
		"upperF": 30, "foreF": -110, "upperB": -20, "foreB": -60, "tail": -10, "prop": "", "face": "angry"},
	"punch": {"lean": 20, "head": -8, "thighF": -54, "shinF": 34, "thighB": 40, "shinB": 4, "hip_dy": 12, "hip_dx": 14,
		"upperF": -90, "foreF": 0, "upperB": 30, "foreB": -60, "tail": 30, "prop": "", "face": "angry"},
	"aim": {"lean": -2, "head": 2, "thighF": -26, "shinF": 20, "thighB": 22, "shinB": 8, "hip_dy": 6,
		"upperF": -84, "foreF": -6, "upperB": -60, "foreB": -60, "tail": -20, "prop": "t_rifle", "prop_rot": 90, "face": "angry"},
	"recoil": {"lean": -12, "head": 8, "thighF": -24, "shinF": 20, "thighB": 24, "shinB": 8, "hip_dy": 6, "hip_dx": -8,
		"upperF": -100, "foreF": -10, "upperB": -74, "foreB": -60, "tail": 10, "prop": "t_rifle", "prop_rot": 80, "face": "shout"},
	"eat": {"lean": 6, "head": -14, "thighF": -10, "shinF": 10, "thighB": 10, "shinB": 4,
		"upperF": -70, "foreF": -40, "upperB": -60, "foreB": -50, "tail": -40, "prop": "t_tray", "prop_rot": -90, "face": "happy"},
	"guard": {"lean": -6, "head": 10, "thighF": -30, "shinF": 34, "thighB": 26, "shinB": 20, "hip_dy": 14,
		"upperF": -130, "foreF": -70, "upperB": -120, "foreB": -80, "tail": -30, "prop": "", "face": "angry"},
	"hurt": {"lean": -24, "head": 22, "thighF": -4, "shinF": 20, "thighB": 30, "shinB": 10, "hip_dx": -10,
		"upperF": 40, "foreF": -20, "upperB": 60, "foreB": -10, "tail": 40, "prop": "", "face": "hurt"},
	"command": {"lean": -6, "head": 6, "thighF": -12, "shinF": 8, "thighB": 12, "shinB": 4,
		"upperF": -150, "foreF": -20, "upperB": 30, "foreB": -60, "tail": -50, "prop": "", "face": "shout"},
	"baton_wind": {"lean": -14, "head": 6, "thighF": -24, "shinF": 26, "thighB": 22, "shinB": 10, "hip_dy": 8,
		"upperF": -170, "foreF": -20, "upperB": 20, "foreB": -40, "tail": -20, "prop": "t_baton", "prop_rot": -100, "face": "angry"},
	"baton": {"lean": 24, "head": -8, "thighF": -56, "shinF": 36, "thighB": 40, "shinB": 4, "hip_dy": 14, "hip_dx": 14,
		"upperF": -50, "foreF": -10, "upperB": 30, "foreB": -30, "tail": 30, "prop": "t_baton", "prop_rot": -20, "face": "shout"},
	"supply": {"lean": 8, "head": -6, "thighF": -10, "shinF": 10, "thighB": 10, "shinB": 4,
		"upperF": -60, "foreF": -50, "upperB": -50, "foreB": -60, "tail": -40, "prop": "t_crate", "prop_rot": -90, "face": "happy"},
	"dizzy": {"lean": -10, "head": 18, "thighF": -4, "shinF": 30, "thighB": 24, "shinB": 30, "hip_dy": 18,
		"upperF": 30, "foreF": -10, "upperB": 40, "foreB": -10, "tail": 50, "prop": "", "face": "dizzy"},
	"down": {"lean": -76, "head": 24, "thighF": -60, "shinF": 30, "thighB": -40, "shinB": 30, "hip_dy": 66, "hip_dx": -20,
		"upperF": 60, "foreF": 0, "upperB": 80, "foreB": 0, "tail": 60, "prop": "", "face": "dizzy"},
}


# 쫄라맨 정시우. 없는 자세는 신병(S) 자세를 빌리고, 신병 소품은 뺀다
const K := {
	"idle": {"lean": 0, "head": 0, "thighF": -18, "shinF": 0, "thighB": 18, "shinB": 0,
		"upperF": -38, "foreF": 0, "upperB": 38, "foreB": 0, "prop": "", "prop2": "", "zB": -6},
	# 로직 아틀리에 첫 발: 몸을 옆으로 돌려 앞손 권총 한 자루만 쭉 뻗는다(뒷손 권총은 몸 뒤에 숨어 안 보인다)
	"pistol_ready": {"lean": -2, "head": 2, "thighF": -22, "shinF": 6, "thighB": 18, "shinB": 4,
		"upperF": -90, "foreF": 0, "upperB": 8, "foreB": 0, "prop": "k_pistol", "prop_rot": 90, "prop2": ""},
	"pistol_fire1": {"lean": -8, "head": 6, "thighF": -22, "shinF": 6, "thighB": 18, "shinB": 4, "hip_dx": -6,
		"upperF": -104, "foreF": -4, "upperB": 12, "foreB": 0, "prop": "k_pistol", "prop_rot": 92, "prop2": ""},
	# 두 번째 발: 몸을 앞으로 돌려 두 자루가 다 보인다. 앞손으로 쏘고 뒷손 권총은 아래로 비스듬히
	"pistol_ready2": {"lean": 0, "head": 0, "thighF": -16, "shinF": 4, "thighB": 16, "shinB": 4,
		"upperF": -90, "foreF": 0, "upperB": 22, "foreB": -40, "prop": "k_pistol", "prop_rot": 90, "prop2": "k_pistol", "prop2_rot": 55},
	"pistol_fire2": {"lean": -8, "head": 6, "thighF": -16, "shinF": 4, "thighB": 16, "shinB": 4, "hip_dx": -6,
		"upperF": -104, "foreF": -4, "upperB": 26, "foreB": -40, "prop": "k_pistol", "prop_rot": 92, "prop2": "k_pistol", "prop2_rot": 55},
	# 샷건: 앞으로 숙이고 다리를 벌려 버티며 양손으로 쏜다
	"shotgun_ready": {"lean": 16, "head": -10, "thighF": -52, "shinF": 42, "thighB": 46, "shinB": 6, "hip_dy": 12,
		"upperF": -78, "foreF": -10, "upperB": -64, "foreB": -24, "prop": "k_shotgun", "prop_rot": 88, "prop2": ""},
	"shotgun_fire": {"lean": 2, "head": 4, "thighF": -48, "shinF": 36, "thighB": 50, "shinB": 4, "hip_dy": 10, "hip_dx": -18,
		"upperF": -96, "foreF": -10, "upperB": -82, "foreB": -24, "prop": "k_shotgun", "prop_rot": 94, "prop2": ""},
	# 휠즈 인더스트리: 대검을 뒤로 끌듯 낮게 잡고(ready), 뒤에서 머리 위로 천천히 들어 올렸다가(lift),
	# 머리 위를 넘겨 낮게 파고들며 땅에 내리찍는다(slam). 칼이 위로 원을 그리도록 각도를 360도 넘겨 잡는다.
	# slam_n은 slam과 똑같은 모습을 -180~180 범위 각도로 적은 것(찍은 뒤 이걸로 바꿔 놓고 풀어야 팔이 빙글 돌지 않는다)
	"wheels_ready": {"lean": -10, "head": 6, "thighF": -20, "shinF": 30, "thighB": 30, "shinB": 20, "hip_dy": 12,
		"upperF": 40, "foreF": -10, "upperB": 30, "foreB": -10, "prop": "k_greatsword", "prop_rot": 140, "prop2": ""},
	"wheels_lift": {"lean": -20, "head": 10, "thighF": -30, "shinF": 6, "thighB": 18, "shinB": 4, "hip_dy": -6,
		"upperF": 150, "foreF": 30, "upperB": 140, "foreB": 30, "prop": "k_greatsword", "prop_rot": 63, "prop2": ""},
	"wheels_slam": {"lean": 28, "head": -12, "thighF": -72, "shinF": 74, "thighB": 62, "shinB": 0, "hip_dy": 26, "hip_dx": 20,
		"upperF": 298, "foreF": -10, "upperB": 306, "foreB": -16, "prop": "k_greatsword", "prop_rot": 54, "prop2": ""},
	"wheels_slam_n": {"lean": 28, "head": -12, "thighF": -72, "shinF": 74, "thighB": 62, "shinB": 0, "hip_dy": 26, "hip_dx": 20,
		"upperF": -62, "foreF": -10, "upperB": -54, "foreB": -16, "prop": "k_greatsword", "prop_rot": 54, "prop2": ""},
	# 합에서 지고 맞을 때: 웅크리고 두 팔을 얼굴 앞에 엇갈려 막는다
	"hurt": {"lean": 6, "head": 6, "thighF": -30, "shinF": 30, "thighB": 26, "shinB": 14, "hip_dy": 10, "hip_dx": -10,
		"upperF": -100, "foreF": -84, "upperB": -165, "foreB": 70, "prop": "", "prop2": "", "zB": 6},
}


static func get_pose(kind: String, name: String) -> Dictionary:
	var p := BASE.duplicate()
	if kind == "k":
		p.merge(K["idle"], true)
		if S.has(name):
			var sp: Dictionary = S[name].duplicate()
			sp["prop"] = ""
			sp.erase("face")
			p.merge(sp, true)
		if K.has(name):
			p.merge(K[name], true)
		return p
	var src: Dictionary = S if kind == "s" else T
	p.merge(src.get(name, src["idle"]), true)
	return p


static func names(kind: String) -> Array:
	if kind == "k":
		return K.keys() + ["run", "stab", "butt", "block", "evade", "hurt"]
	return (S if kind == "s" else T).keys()
