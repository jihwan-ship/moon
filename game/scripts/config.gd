extends Node
## 친구에게 맞춰 바꾸는 설정. 이름과 마지막 응원 문구만 바꾸면 된다.

const PLAYER_NAME := "김신병"
const ENDING_MESSAGE := "군 생활 건강하게!\n짬타이거가 지켜보고 있다냥."


# "soldier" = 이병 김신병, "roland" = 롤랑 모드
var mode := "soldier"


func player_name() -> String:
	return "롤랑" if mode == "roland" else PLAYER_NAME


func player_title() -> String:
	return "검은 침묵 롤랑" if mode == "roland" else "이병 " + PLAYER_NAME


func fmt(s: String) -> String:
	return s.replace("{name}", player_name())
