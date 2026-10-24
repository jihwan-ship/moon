// 게임 데이터. 로직(game.js)과 분리해 두면 나중에 라오루 모드(XML)로 옮기기 쉽다.
window.JJAM_DATA = (() => {
  const d = (t, min, max, extra) => Object.assign({ t, min, max }, extra);

  // 주사위 종류. atk = 공격, def = 수비
  const DICE = {
    slash: { label: '참격', short: '참', kind: 'atk' },
    pierce: { label: '관통', short: '관', kind: 'atk' },
    blunt: { label: '타격', short: '타', kind: 'atk' },
    block: { label: '방어', short: '방', kind: 'def' },
    evade: { label: '회피', short: '회', kind: 'def' },
  };

  const ROLAND = {
    hp: 140,
    stagger: 70,
    speedDice: 3,
    startLight: 4,
    maxLight: 5,
    lightRegen: 3,
    startHand: 5,
    drawPerScene: 3,
    phaseHeal: 20, // 짬타이거가 진급할 때 롤랑이 회복하는 체력
  };

  const ROLAND_CARDS = {
    durandal: { name: '듀랜달', workshop: true, cost: 1, dice: [d('slash', 4, 8), d('slash', 3, 6)] },
    zelkova: { name: '젤코바 공방', workshop: true, cost: 2, dice: [d('slash', 4, 8), d('blunt', 4, 8)] },
    oldboys: {
      name: '올드 보이즈 공방', workshop: true, cost: 1,
      dice: [d('block', 4, 8, { onWin: 'light' }), d('blunt', 3, 7)],
      text: '방어 주사위가 이기면 빛 1 회복',
    },
    allas: { name: '알라스 공방', workshop: true, cost: 2, dice: [d('pierce', 6, 11)] },
    mook: { name: '묵 공방', workshop: true, cost: 2, dice: [d('evade', 4, 8), d('slash', 5, 9)] },
    logic: { name: '로그 아뜰리에', workshop: true, cost: 1, dice: [d('pierce', 3, 6), d('pierce', 3, 6)] },
    wheels: { name: '휠 인더스트리', workshop: true, cost: 3, dice: [d('blunt', 8, 15)] },
    crystal: { name: '크리스탈 아뜰리에', workshop: true, cost: 2, dice: [d('slash', 3, 6), d('slash', 3, 6), d('slash', 3, 6)] },
    ranga: { name: '랑가 공방', workshop: true, cost: 1, dice: [d('pierce', 2, 4), d('pierce', 2, 4), d('pierce', 2, 4)] },
    step: { name: '검은 침묵의 발걸음', cost: 0, dice: [d('evade', 4, 8)] },
    guard: { name: '막아서기', cost: 0, dice: [d('block', 3, 7)] },
    furioso: {
      name: 'Furioso', cost: 0, special: 'furioso',
      dice: [d('slash', 5, 9), d('pierce', 5, 9), d('blunt', 5, 9), d('slash', 6, 10), d('pierce', 6, 10), d('blunt', 7, 12)],
      text: '아홉 공방 카드를 모두 쓰면 손에 들어온다',
    },
  };

  const ROLAND_DECK = ['durandal', 'zelkova', 'oldboys', 'allas', 'mook', 'logic', 'wheels', 'crystal', 'ranga', 'step', 'guard'];
  const WORKSHOPS = ROLAND_DECK.filter((id) => ROLAND_CARDS[id].workshop);

  const TIGER_CARDS = {
    punch: { name: '냥냥펀치', dice: [d('blunt', 3, 6), d('slash', 2, 5)] },
    scratch: { name: '할퀴기', dice: [d('slash', 4, 8)] },
    eat: {
      name: '짬밥 섭취', gimmick: 'heal', heal: 0.2, dice: [d('block', 4, 8)],
      text: '이 카드에 피해를 주지 못하면 장면 끝에 체력 20% 회복',
    },
    k2: {
      name: 'K2 점사', ammo: 3, weight: 1.5, dice: [d('pierce', 3, 7), d('pierce', 3, 7), d('pierce', 3, 7)],
      text: '탄약 3 소모',
    },
    supply: { name: '탄약 보급', gimmick: 'supply', dice: [], text: '주사위 없음. 탄약을 채운다. 반격 기회!' },
    discipline: { name: '군기 잡기', dice: [d('blunt', 4, 8), d('slash', 4, 8)] },
    pushup: {
      name: '얼차려: 엎드려뻗쳐', onHit: 'pushup', weight: 1.3, dice: [d('blunt', 5, 9)],
      text: '적중 시 다음 장면 롤랑 속도 주사위 -1',
    },
    duckwalk: {
      name: '얼차려: 오리걸음', onHit: 'duckwalk', weight: 1.3, dice: [d('slash', 3, 6), d('blunt', 3, 6)],
      text: '적중 시 다음 장면 롤랑 회피 주사위 사용 불가',
    },
  };

  const STATUS = {
    pushup: { name: '엎드려뻗쳐', desc: '속도 주사위 -1' },
    duckwalk: { name: '오리걸음', desc: '회피 주사위 사용 불가' },
  };

  // 짬타이거 계급(페이즈). 쓰러뜨리면 다음 계급으로 진급한다.
  const PHASES = [
    { rank: '이병', hp: 50, stagger: 30, dice: 2, maxAmmo: 0, pool: ['punch', 'scratch', 'eat'],
      intro: '이병! 짬! 타이거! 냥!' },
    { rank: '일병', hp: 70, stagger: 40, dice: 2, maxAmmo: 6, pool: ['punch', 'scratch', 'eat', 'k2'],
      intro: '이제 총도 쏠 줄 안다냥.' },
    { rank: '상병', hp: 90, stagger: 50, dice: 3, maxAmmo: 6, pool: ['punch', 'scratch', 'eat', 'k2', 'discipline'],
      intro: '상병 꺾였다냥. 짬통은 내 거다냥.' },
    { rank: '병장', hp: 120, stagger: 60, dice: 3, maxAmmo: 6, pool: ['scratch', 'eat', 'k2', 'discipline', 'pushup', 'duckwalk'],
      intro: '말년 병장 건드리면 어떻게 되는지 알려주겠다냥.' },
  ];

  const LINES = {
    roland: {
      start: ['좋아, 가자.'],
      attack: ['금방 끝내자.', '고양이 상대로 이게 뭐 하는 짓인지.', '야근 수당은 나오는 거지?'],
      eatBlocked: ['밥 먹을 시간은 못 주겠는데.', '짬통은 내가 엎었다.'],
      tigerStagger: ['고양이 상대로 이렇게까지 해야 하나.', '지금이다.'],
      stagger: ['...방심했군.', '귀찮게 됐네.'],
      pushup: ['...내가 왜 이걸 하고 있지.'],
      duckwalk: ['무릎 나가겠네, 이거.'],
      furiosoReady: ['슬슬 마무리할까.'],
      furioso: ['Furioso.'],
      win: ['...전역 축하한다.'],
      lose: ['고양이한테 지다니, 안젤라가 비웃겠군.'],
    },
    tiger: {
      eat: ['냠냠... 오늘 메뉴는 제육이다냥.', '짬밥은 못 참지냥.'],
      ate: ['배부르다냥! 다시 싸울 수 있다냥.'],
      k2: ['사격 개시냥!', '조준... 발사냥!'],
      supply: ['탄약 보급 받으러 간다냥!'],
      pushup: ['엎드려뻗쳐!'],
      duckwalk: ['오리걸음 실시!'],
      stagger: ['냐아앙...? 어지럽다냥...'],
      phaseDown: ['다음 계급장 달고 오겠다냥...'],
      final: ['전역... 하겠습니다냥...'],
    },
  };

  return { DICE, ROLAND, ROLAND_CARDS, ROLAND_DECK, WORKSHOPS, TIGER_CARDS, STATUS, PHASES, LINES };
})();
