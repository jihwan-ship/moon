# 짬타이거

이병 김신병이 전입 첫날 밤, 취사장 뒤 짬통을 지키는 짬타이거와 맞붙는 턴제 카드 전투 게임입니다. Godot 4.3으로 만들었습니다.

## 플레이 방법

- 매 턴 전투 책장 5장을 뽑습니다. 책장을 눌러 위쪽 칸에 놓으면, 같은 줄에 있는 짬타이거의 행동과 주사위 합을 겨룹니다.
- 공격끼리는 높은 쪽이 피해를 줍니다. 막기가 이기면 차이만큼 멘탈 피해를 돌려주고, 회피가 이기면 멘탈을 회복하고 다시 피합니다.
- 멘탈이 0이 되면 다음 턴 동안 움직이지 못하고 받는 피해가 2배가 됩니다.
- 합에서 이기면 투지가 쌓이고, 가득 차면 총력 사격 책장이 손에 들어옵니다.
- 짬타이거는 이병 → 일병 → 상병 → 병장으로 진급합니다.

| 계급 | 기믹 |
|---|---|
| 이병 | 짬밥 섭취: 이 책장에 피해를 주지 못하면 턴 끝에 체력 20% 회복 |
| 일병 | K2 사격: 탄약 3 소모. 탄약이 떨어지면 탄약 보급(주사위 없음)으로 빈틈 |
| 상병 | 군기 잡기. 신병 기력이 4로 늘어남 |
| 병장 | 얼차려: 엎드려뻗쳐(다음 턴 기력 -1), 오리걸음(다음 턴 회피 불가) |

## 친구 이름 바꾸기

`game/scripts/config.gd`의 `PLAYER_NAME`과 `ENDING_MESSAGE` 두 줄만 바꾸면 됩니다.

## 구조

| 경로 | 내용 |
|---|---|
| `game/` | Godot 프로젝트 |
| `game/scripts/battle.gd` | 턴 흐름, 합 판정, 전투 연출 |
| `game/scripts/data.gd` | 책장, 계급, 대사. 수치 조정은 여기서 |
| `game/scripts/puppet.gd`, `poses.gd` | 관절 인형과 포즈 |
| `game/scripts/fx.gd` | 초승달 베기, 불꽃, 폭발 등 연출 |
| `tools/art/` | 인형 부위 SVG를 PNG로 렌더링 (`node tools/art/render.js`) |
| `tools/sfx.py` | 효과음과 배경음 합성 |
| `tools/web_page.py` | 웹 내보내기를 Artifact용으로 다시 묶기 |
| `tools/snap.sh` | Godot 무비 메이커로 장면을 프레임 단위로 찍기 |

## 빌드

```
godot --headless --path game --export-release "Web" ../build/web/index.html
python3 tools/web_page.py
```

## 리소스

캐릭터, 배경, 효과음, 음악은 모두 이 저장소에서 직접 만든 것입니다. 글꼴은 Pretendard와 Black Han Sans(둘 다 OFL 1.1)를 줄여서 넣었습니다(`game/fonts/LICENSE.txt`).
