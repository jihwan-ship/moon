class_name GameData
## 게임 데이터. 수치 조정은 여기서 한다.

# 주사위 종류
const DICE := {
	"slash": {"label": "베기", "atk": true, "color": Color("e0503f")},
	"pierce": {"label": "찌르기", "atk": true, "color": Color("e0503f")},
	"blunt": {"label": "타격", "atk": true, "color": Color("e0503f")},
	"block": {"label": "막기", "atk": false, "color": Color("4f8fd6")},
	"evade": {"label": "회피", "atk": false, "color": Color("57b07a")},
}

const PLAYER := {"hp": 80, "mental": 40, "energy": 3, "hand": 5, "slots": 3, "focus_max": 10}

static func d(t: String, lo: int, hi: int) -> Dictionary:
	return {"t": t, "min": lo, "max": hi}

# 신병 전투 책장
# anim: 공격 동작 이름(battle.gd의 ATTACKS), heal/mental/buff: 사용 효과
static func player_cards() -> Dictionary:
	return {
		"bayonet": {"name": "총검 찌르기", "cost": 1, "dice": [d("pierce", 4, 8), d("pierce", 2, 6)], "anim": "stab",
			"desc": "총검으로 두 번 찌른다."},
		"butt": {"name": "개머리판 치기", "cost": 1, "dice": [d("blunt", 3, 7), d("blunt", 3, 6)], "anim": "butt",
			"desc": "개머리판으로 후려친다. 멘탈 피해가 크다.", "mental_bonus": 3},
		"burst": {"name": "K2 점사", "cost": 2, "dice": [d("pierce", 3, 6), d("pierce", 3, 6), d("pierce", 3, 6)], "anim": "fire",
			"desc": "세 발 점사. 막기 쉽지 않다."},
		"helmet": {"name": "방탄모 막기", "cost": 0, "dice": [d("block", 4, 8)], "anim": "",
			"desc": "막기에 성공하면 기력 1을 돌려받는다.", "block_energy": 1},
		"crawl": {"name": "포복 회피", "cost": 0, "dice": [d("evade", 3, 7)], "anim": "",
			"desc": "회피에 성공하면 멘탈을 회복하고 다시 피한다."},
		"grenade": {"name": "수류탄 투척", "cost": 2, "dice": [d("blunt", 8, 14)], "anim": "throw",
			"desc": "한 방에 크게. 짬통도 날려 버린다."},
		"ration": {"name": "전투식량", "cost": 1, "dice": [], "anim": "", "heal": 12, "mental": 6,
			"desc": "체력 12, 멘탈 6 회복. 주사위 없음."},
		"song": {"name": "군가 제창", "cost": 1, "dice": [d("block", 3, 6)], "anim": "", "buff": 2,
			"desc": "다음 턴 모든 주사위 +2."},
		"ult": {"name": "총력 사격", "cost": 0, "dice": [d("pierce", 5, 9), d("pierce", 5, 9), d("pierce", 5, 9), d("pierce", 6, 10)],
			"anim": "fire", "ult": true, "desc": "투지를 모두 쏟아붓는다. 이기면 상대 주사위를 모두 부순다."},
	}

# 정시우 모드 책장: 원작 검은 침묵의 아홉 공방. art는 art/sium/cards의 낙서 그림
static func sium_cards() -> Dictionary:
	var c := {
		"zelkova": {"name": "느티나무 공방", "cost": 0, "dice": [d("slash", 3, 6), d("blunt", 3, 7)], "desc": "도끼로 옆을 후려치고 메이스로 올려친다."},
		"ranga": {"name": "랑아 공방", "cost": 0, "dice": [d("pierce", 2, 4), d("pierce", 2, 4), d("slash", 2, 5)], "desc": "건틀릿으로 두 번 할퀴고 단검으로 벤다."},
		"oldboys": {"name": "늙은소년 공방", "cost": 1, "dice": [d("block", 5, 9), d("blunt", 4, 8)], "block_energy": 1, "desc": "막아 내고 망치로 내리친다. 막으면 기력 1."},
		"allas": {"name": "알라스 공방", "cost": 2, "dice": [d("pierce", 4, 8), d("pierce", 5, 9)], "desc": "창을 내지르며 꿰뚫는다."},
		"mook": {"name": "묵 공방", "cost": 2, "dice": [d("slash", 6, 12)], "desc": "칼을 뽑으며 단번에 벤다."},
		"logic": {"name": "로직 아틀리에", "cost": 2, "dice": [d("pierce", 4, 8), d("pierce", 5, 8), d("blunt", 7, 12)], "desc": "리볼버 두 발, 마지막은 샷건."},
		"durandal": {"name": "뒤랑달", "cost": 2, "dice": [d("slash", 5, 9), d("slash", 5, 9)], "desc": "횡베기 후 올려친다."},
		"crystal": {"name": "크리스탈 아틀리에", "cost": 3, "dice": [d("evade", 4, 8), d("slash", 5, 9), d("slash", 5, 9)], "desc": "물러서며 베고, 파고들며 벤다."},
		"wheels": {"name": "휠즈 인더스트리", "cost": 3, "dice": [d("blunt", 10, 18)], "mental_bonus": 4, "desc": "대검을 크게 내리친다."},
		"ult": {"name": "Furioso", "cost": 0, "dice": [d("slash", 20, 39)], "ult": true, "desc": "아홉 공방의 무기를 모두 휘두른다. 이기면 상대 주사위를 모두 부순다."},
	}
	for k in c:
		c[k]["anim"] = "r_" + k
		c[k]["art"] = "res://art/sium/cards/%s.png" % ("furioso" if k == "ult" else k)
	return c

const SIUM_DECK := ["zelkova", "ranga", "oldboys", "allas", "mook", "logic", "durandal", "crystal", "wheels"]

const DECK := ["bayonet", "bayonet", "butt", "butt", "burst", "helmet", "helmet", "crawl", "crawl", "grenade", "ration", "song"]

# 짬타이거 책장. pose: 공격 동작
static func tiger_cards() -> Dictionary:
	return {
		"punch": {"name": "따봉펀치" if Cfg.mode == "sium" else "냥냥펀치", "dice": [d("blunt", 3, 6), d("blunt", 2, 5)], "anim": "punch"},
		"claw": {"name": "할퀴기", "dice": [d("slash", 4, 8)], "anim": "claw"},
		"eat": {"name": "짬밥 섭취", "dice": [d("block", 4, 8)], "anim": "", "gimmick": "heal",
			"desc": "이 책장에 피해를 주지 못하면 턴 끝에 체력 20% 회복"},
		"k2": {"name": "K2 사격", "dice": [d("pierce", 3, 7), d("pierce", 3, 7), d("pierce", 3, 7)], "anim": "shoot", "ammo": 3,
			"desc": "탄약 3 소모"},
		"supply": {"name": "탄약 보급", "dice": [], "anim": "", "gimmick": "supply", "desc": "주사위 없음. 탄약을 채운다. 반격 기회!"},
		"baton": {"name": "군기 잡기", "dice": [d("blunt", 4, 8), d("slash", 4, 8)], "anim": "baton"},
		"pushup": {"name": "얼차려: 엎드려뻗쳐", "dice": [d("blunt", 5, 9)], "anim": "command", "on_hit": "pushup",
			"desc": "적중 시 다음 턴 기력 -1"},
		"duck": {"name": "얼차려: 오리걸음", "dice": [d("slash", 3, 6), d("blunt", 3, 6)], "anim": "command", "on_hit": "duck",
			"desc": "적중 시 다음 턴 회피 주사위 사용 불가"},
	}

const STATUS := {
	"pushup": {"name": "엎드려뻗쳐", "desc": "기력 -1"},
	"duck": {"name": "오리걸음", "desc": "회피 불가"},
	"song": {"name": "사기충천", "desc": "주사위 +2"},
}

# 짬타이거 계급. 쓰러뜨리면 진급한다
const PHASES := [
	{"rank": "이병", "n": 1, "hp": 45, "mental": 24, "intents": 1, "ammo": 0, "pool": ["punch", "claw", "eat"]},
	{"rank": "일병", "n": 2, "hp": 60, "mental": 30, "intents": 2, "ammo": 6, "pool": ["punch", "claw", "eat", "k2"]},
	{"rank": "상병", "n": 3, "hp": 75, "mental": 34, "intents": 2, "ammo": 6, "pool": ["punch", "claw", "eat", "k2", "baton"]},
	{"rank": "병장", "n": 4, "hp": 95, "mental": 40, "intents": 3, "ammo": 6, "pool": ["claw", "eat", "k2", "baton", "pushup", "duck"]},
]

const INTRO := [
	["", "{name}의 전입 첫날 밤."],
	["", "취사장 뒤 짬통에서 수상한 소리가 들린다..."],
	["s", "누, 누구십니까!"],
	["t", "이병! 짬! 타이거! 냥!"],
	["t", "이 짬통은 내 구역이다냥. 신병이 감히 넘보냐옹?"],
	["s", "이병 {name}! 짬통을 지키라는 명령을 받았습니다!"],
	["t", "그럼 실력으로 증명해 봐라냥!"],
]

# 정시우 모드: 짬타이거는 엄지척 아재라 냥냥거리지 않고, 정시우는 늘 같은 말만 한다
const SIUM_LINE := "그건 그거고 이건 이거니까"

const INTRO_SIUM := [
	["", "{name}의 전입 첫날 밤."],
	["", "취사장 뒤 짬통에서 수상한 소리가 들린다..."],
	["s", SIUM_LINE],
	["t", "이병! 짬! 타이거! 따봉!"],
	["t", "이 짬통은 내 구역이다. 신병이 감히 넘보나?"],
	["s", SIUM_LINE],
	["t", "...뭐라는 거야. 실력으로 증명해 봐라!"],
]

# 짬타이거 대사를 정시우 모드용으로 바꾼 것
const SIUM_TIGER := {
	"크윽... 이병 시절은 끝났다냥. 이제 일병이다냥!": "크윽... 이병 시절은 끝났다. 이제 일병이다!",
	"상병 꺾였다냥. 이제부터 진짜다냥!": "상병 꺾였다. 이제부터 진짜다!",
	"말년 병장 건드리면 어떻게 되는지 알려주겠다냥!": "말년 병장 건드리면 어떻게 되는지 알려주마!",
	"냠냠... 오늘은 제육이다냥.": "냠냠... 오늘은 제육이다. 따봉!",
	"짬밥은 못 참지냥.": "짬밥은 못 참지!",
	"배부르다냥! 다시 간다냥!": "배부르다! 다시 간다!",
	"사격 개시냥!": "사격 개시!",
	"조준... 발사냥!": "조준... 발사!",
	"탄약 보급 받으러 간다냥!": "탄약 보급 받으러 간다!",
	"냐앙!": "윽!",
	"아프다냥!": "아프다!",
	"냐아앙...? 어지럽다냥...": "어어...? 어지럽다...",
	"졌다냥... 신병 주제에 제법이다냥.": "졌다... 신병 주제에 제법이구만. 따봉!",
	"전역할 때까지 이 짬통... 아니 이 부대를 잘 부탁한다냥.": "전역할 때까지 이 짬통... 아니 이 부대를 잘 부탁한다.",
	"신병은 아직 멀었다냥~": "신병은 아직 멀었구만~",
}


## 모드에 맞게 대사를 바꾼다
static func speak(who: String, text: String) -> String:
	if Cfg.mode != "sium":
		return text
	if who == "s":
		return SIUM_LINE
	if who == "t":
		return SIUM_TIGER.get(text, text.replace("다냥", "다").replace("냐옹", "냐").replace("냥", ""))
	return text


const PROMOTE := [
	["t", "크윽... 이병 시절은 끝났다냥. 이제 일병이다냥!"],
	["t", "상병 꺾였다냥. 이제부터 진짜다냥!"],
	["t", "말년 병장 건드리면 어떻게 되는지 알려주겠다냥!"],
]

const LINES := {
	"s_attack": ["받아라!", "이병 {name}, 돌격!", "이게 훈련소 짬이다!"],
	"s_hurt": ["으악!", "아파요...", "엄마..."],
	"s_win_clash": ["좋았어!", "됐다!"],
	"s_eat_block": ["짬통은 못 줍니다!", "밥은 나중에!"],
	"s_pushup": ["...왜 제가 엎드려뻗쳐를...", "전입 첫날인데..."],
	"t_eat": ["냠냠... 오늘은 제육이다냥.", "짬밥은 못 참지냥."],
	"t_ate": ["배부르다냥! 다시 간다냥!"],
	"t_k2": ["사격 개시냥!", "조준... 발사냥!"],
	"t_supply": ["탄약 보급 받으러 간다냥!"],
	"t_command": ["엎드려뻗쳐!", "오리걸음 실시!"],
	"t_hurt": ["냐앙!", "아프다냥!"],
	"t_break": ["냐아앙...? 어지럽다냥..."],
}

const ENDING := [
	["t", "졌다냥... 신병 주제에 제법이다냥."],
	["t", "전역할 때까지 이 짬통... 아니 이 부대를 잘 부탁한다냥."],
	["s", "충성! 이병 {name}, 끝까지 버티겠습니다!"],
]
