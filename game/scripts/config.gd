extends Node
## 친구에게 맞춰 바꾸는 설정. 이름과 마지막 응원 문구만 바꾸면 된다.

const PLAYER_NAME := "김신병"
const ENDING_MESSAGE := "군 생활 건강하게!\n짬타이거가 지켜보고 있다냥."


func fmt(s: String) -> String:
	return s.replace("{name}", PLAYER_NAME)
