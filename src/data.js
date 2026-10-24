// 게임 데이터. 로직(game.js)과 분리해 두면 나중에 라오루 모드(XML)로 옮기기 쉽다.
// 카드 이름과 비용은 원작 검은침묵의 책장 기준, 주사위 수치는 임시값.
window.JJAM_DATA = (() => {
  const d = (t, min, max, extra) => Object.assign({ t, min, max }, extra);

  // 주사위 종류. atk = 공격, def = 수비
  const DICE = {
    slash: { label: '참격', kind: 'atk' },
    pierce: { label: '관통', kind: 'atk' },
    blunt: { label: '타격', kind: 'atk' },
    block: { label: '방어', kind: 'def' },
    evade: { label: '회피', kind: 'def' },
  };

  // 내성. 피해량 배율
  const RESIST = {
    fatal: { label: '취약', mult: 2 },
    weak: { label: '약점', mult: 1.5 },
    normal: { label: '보통', mult: 1 },
    endure: { label: '견딤', mult: 0.5 },
    ineff: { label: '내성', mult: 0.25 },
  };

  const ROLAND = {
    hp: 106,
    stagger: 56,
    speed: [2, 7],
    speedDice: 3, // 지속능력 '속도 3'. 상병 단계(감정 단계 3 대용)부터 +1
    resist: { slash: 'normal', pierce: 'normal', blunt: 'endure' },
    baseLight: 4, // 짬타이거가 진급할 때마다 최대 빛 +1, 빛 전부 회복
    lightRegen: 3,
    startHand: 4,
    blackSilenceDraw: 2, // 지속능력 '검은침묵': 무대 시작 시 2장 더 뽑기
    drawPerScene: 2,
    phaseHeal: 10,
  };

  // rarity: paperback(초록) hardcover(파랑) limited(보라) art(금색)
  const ROLAND_CARDS = {
    zelkova: { name: '느티나무 공방', rarity: 'paperback', cost: 0, weapon: 'mace', pose: { slash: 'zelkova_axe', blunt: 'zelkova_crouch' }, dice: [d('slash', 3, 6), d('blunt', 3, 7)] },
    ranga: { name: '랑아 공방', rarity: 'paperback', cost: 0, weapon: 'dagger', pose: { pierce: 'ranga_claw', slash: 'ranga_claw' }, dice: [d('pierce', 2, 4), d('pierce', 2, 4), d('slash', 2, 5)] },
    oldboys: {
      name: '늙은소년 공방', rarity: 'paperback', cost: 1, weapon: 'hammer', pose: { blunt: 'slash' },
      dice: [d('block', 4, 8, { onWin: 'light' }), d('blunt', 4, 8)],
      text: '방어 주사위가 합에서 이기면 빛 1 회복',
    },
    allas: { name: '알라스 공방', rarity: 'hardcover', cost: 2, weapon: 'spear', pose: { pierce: 'thrust' }, dice: [d('pierce', 4, 8), d('pierce', 5, 9)] },
    mook: { name: '묵 공방', rarity: 'hardcover', cost: 2, weapon: 'katana', pose: { slash: 'mook_slash' }, dice: [d('slash', 6, 12)] },
    logic: { name: '로직 아틀리에', rarity: 'hardcover', cost: 2, weapon: 'gun', pose: { pierce: 'logic_pistols', blunt: 'logic_pistols' }, dice: [d('pierce', 4, 8), d('pierce', 5, 8), d('blunt', 7, 12)] },
    durandal: { name: '듀랑달', rarity: 'limited', cost: 2, weapon: 'sword', pose: { slash: 'slash', pierce: 'thrust' }, dice: [d('slash', 5, 9), d('slash', 5, 9)] },
    crystal: {
      name: '크리스탈 아틀리에', rarity: 'hardcover', cost: 3, weapon: 'dual', pose: { slash: 'crystal' },
      dice: [d('evade', 4, 8), d('slash', 5, 9), d('slash', 5, 9), d('slash', 4, 8, { counter: true })],
      text: '노란 주사위는 반격. 이번 장면에 일방 공격을 받으면 대신 합을 한다',
    },
    wheels: { name: '휠즈 인더스트리', rarity: 'limited', cost: 4, weapon: 'greatsword', pose: { blunt: 'wheels_smash' }, dice: [d('blunt', 10, 18), d('block', 5, 9)] },
    furioso: {
      name: 'Furioso', rarity: 'art', cost: 0, special: 'furioso', weapon: 'sword', pose: {},
      dice: [
        d('blunt', 4, 8, { w: 'mace' }), d('pierce', 3, 6, { w: 'dagger' }), d('blunt', 4, 8, { w: 'hammer' }),
        d('pierce', 5, 9, { w: 'spear' }), d('slash', 5, 9, { w: 'katana' }), d('pierce', 4, 8, { w: 'gun' }),
        d('slash', 5, 9, { w: 'dual' }), d('blunt', 7, 12, { w: 'greatsword' }), d('slash', 6, 10, { w: 'sword' }),
      ],
      text: '아홉 공방 책장을 모두 쓰면 손에 들어온다. 쓰고 나면 기록이 초기화된다',
    },
  };

  // Furioso 주사위의 무기 -> 롤랑 자세
  const WEAPON_POSE = {
    mace: 'zelkova_crouch', dagger: 'ranga_claw', hammer: 'wheels_swing', spear: 'thrust', katana: 'mook_slash',
    gun: 'logic_pistols', dual: 'crystal', greatsword: 'wheels_smash', sword: 'slash',
  };
  for (const [id, def] of Object.entries(ROLAND_CARDS)) def.id = id;

  const ROLAND_DECK = ['zelkova', 'ranga', 'oldboys', 'allas', 'mook', 'logic', 'durandal', 'crystal', 'wheels'];

  const TIGER_RESIST = { slash: 'normal', pierce: 'weak', blunt: 'endure' };

  const TIGER_CARDS = {
    punch: { name: '냥냥펀치', prop: 'claw', tpose: 'punch', dice: [d('blunt', 4, 7), d('slash', 3, 6)] },
    scratch: { name: '할퀴기', prop: 'claw', tpose: 'claw', dice: [d('slash', 5, 9)] },
    eat: {
      name: '짬밥 섭취', prop: 'tray', tpose: 'eat', gimmick: 'heal', heal: 0.2, dice: [d('block', 5, 9)],
      text: '이 책장에 피해를 주지 못하면 장면 끝에 체력 20% 회복',
    },
    k2: {
      name: 'K2 점사', prop: 'rifle', tpose: 'shoot', ammo: 3, weight: 1.5, dice: [d('pierce', 4, 8), d('pierce', 4, 8), d('pierce', 4, 8)],
      text: '탄약 3 소모',
    },
    supply: { name: '탄약 보급', prop: 'crate', tpose: 'supply', gimmick: 'supply', dice: [], text: '주사위 없음. 탄약을 채운다. 반격 기회!' },
    discipline: { name: '군기 잡기', prop: 'baton', tpose: 'baton', dice: [d('blunt', 5, 9), d('slash', 5, 9)] },
    pushup: {
      name: '얼차려: 엎드려뻗쳐', prop: 'whistle', tpose: 'command', onHit: 'pushup', weight: 1.3, dice: [d('blunt', 6, 10)],
      text: '적중 시 다음 장면 롤랑 속도 주사위 -1',
    },
    duckwalk: {
      name: '얼차려: 오리걸음', prop: 'whistle', tpose: 'command', onHit: 'duckwalk', weight: 1.3, dice: [d('slash', 4, 7), d('blunt', 4, 7)],
      text: '적중 시 다음 장면 롤랑 회피 주사위 사용 불가',
    },
  };

  const STATUS = {
    pushup: { name: '엎드려뻗쳐', desc: '속도 주사위 -1' },
    duckwalk: { name: '오리걸음', desc: '회피 주사위 사용 불가' },
  };

  // 짬타이거 계급(막). 쓰러뜨리면 다음 계급으로 진급한다.
  const PHASES = [
    { rank: '이병', hp: 60, stagger: 34, dice: 2, speed: [1, 4], maxAmmo: 0, pool: ['punch', 'scratch', 'eat'],
      intro: '이병! 짬! 타이거! 냥!' },
    { rank: '일병', hp: 95, stagger: 44, dice: 2, speed: [2, 5], maxAmmo: 6, pool: ['punch', 'scratch', 'eat', 'k2'],
      intro: '이제 총도 쏠 줄 안다냥.' },
    { rank: '상병', hp: 125, stagger: 54, dice: 3, speed: [2, 6], maxAmmo: 6, pool: ['punch', 'scratch', 'eat', 'k2', 'discipline'],
      intro: '상병 꺾였다냥. 짬통은 내 거다냥.' },
    { rank: '병장', hp: 165, stagger: 64, dice: 3, speed: [3, 7], maxAmmo: 6, pool: ['scratch', 'eat', 'k2', 'discipline', 'pushup', 'duckwalk'],
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

  for (const [id, def] of Object.entries(TIGER_CARDS)) def.id = id;

  return { DICE, RESIST, ROLAND, ROLAND_CARDS, WEAPON_POSE, ROLAND_DECK, TIGER_RESIST, TIGER_CARDS, STATUS, PHASES, LINES };
})();
