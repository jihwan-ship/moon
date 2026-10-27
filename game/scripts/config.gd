extends Node
## 친구에게 맞춰 바꾸는 설정. 이름과 마지막 응원 문구만 바꾸면 된다.

const PLAYER_NAME := "김신병"
const ENDING_MESSAGE := "군 생활 건강하게!\n짬타이거가 지켜보고 있다냥."


# "soldier" = 이병 김신병, "sium" = 쫄라맨 정시우가 롤랑 책장을 쓰는 모드
var mode := "soldier"


func player_name() -> String:
	return {"sium": "정시우"}.get(mode, PLAYER_NAME)


func player_title() -> String:
	return {"sium": "검은 침묵 정시우"}.get(mode, "이병 " + PLAYER_NAME)


func ending_message() -> String:
	return "군 생활 건강하게!\n따봉 아재가 지켜보고 있다." if mode == "sium" else ENDING_MESSAGE


func fmt(s: String) -> String:
	return s.replace("{name}", player_name())
