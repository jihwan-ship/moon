// 짬타이거 인형. 관절 각도로 자세를 만들고 SVG 문자열로 그린다.
// 원작 시트처럼 왼쪽을 보고 서 있다. 좌표계: viewBox 0 0 420 540, 바닥 y = 520.
window.JJAM_TIGER = (() => {
  const INK = '#1c1712';
  const FUR = '#e8913c';
  const FUR_D = '#c4691f';
  const CREAM = '#f8e7ca';
  const STRIPE = '#2a1c13';
  const BOOT = '#16130f';
  const W = 420, H = 540, GROUND = 520;

  const rad = (d) => (d * Math.PI) / 180;
  const seg = (p, len, deg) => [p[0] + len * Math.cos(rad(deg)), p[1] + len * Math.sin(rad(deg))];
  const r1 = (n) => Math.round(n * 10) / 10;
  const P = (p) => `${r1(p[0])} ${r1(p[1])}`;

  // 디지털 무늬 전투복
  const CAMO = `<pattern id="camo" patternUnits="userSpaceOnUse" width="48" height="48">
    <rect width="48" height="48" fill="#6c7249"/>
    <path d="M0 0h10v6h6v8H4v-6H0z M22 4h12v6h-6v6h-8z M36 18h12v10h-8v-4h-4z M6 24h10v6h4v8H8v-6H6z M26 30h10v8h6v10H28v-8h-2z" fill="#4b4f30"/>
    <path d="M14 10h8v6h-8z M30 12h6v6h-6z M2 38h6v6H2z M40 2h6v8h-6z M18 40h6v6h-6z" fill="#8d7c55"/>
    <path d="M10 16h4v4h-4z M34 24h4v4h-4z M20 32h4v4h-4z M42 40h4v4h-4z" fill="#2f3121"/>
  </pattern>`;

  const limb = (a, b, w, paint) =>
    `<path d="M${P(a)} L${P(b)}" stroke="${INK}" stroke-width="${w + 9}" stroke-linecap="round"/>` +
    `<path d="M${P(a)} L${P(b)}" stroke="${paint}" stroke-width="${w}" stroke-linecap="round"/>`;

  const paw = (p, r = 15) =>
    `<circle cx="${r1(p[0])}" cy="${r1(p[1])}" r="${r}" fill="${FUR}" stroke="${INK}" stroke-width="4.5"/>` +
    `<path d="M${r1(p[0] - 6)} ${r1(p[1] - 4)} v6 M${r1(p[0] + 1)} ${r1(p[1] - 6)} v6" stroke="${FUR_D}" stroke-width="2.5" stroke-linecap="round"/>`;

  const boot = (p, deg) =>
    `<g transform="translate(${P(p)}) rotate(${r1(deg)})"><path d="M-30 -10 Q-34 8 -18 12 H14 Q18 0 12 -14 Z" fill="${BOOT}" stroke="${INK}" stroke-width="4"/><path d="M-30 6 H14" stroke="#3a332a" stroke-width="3"/></g>`;

  // 소품. 원점이 손, 왼쪽(-x)이 앞
  const PROPS = {
    claw: `<g stroke="${INK}" stroke-width="3" fill="#f4f1ea"><path d="M-10 -12 Q-34 -22 -44 -8 Q-30 -14 -12 -4 Z"/><path d="M-12 -2 Q-38 -2 -48 12 Q-32 4 -12 6 Z"/><path d="M-10 8 Q-32 16 -38 32 Q-26 20 -8 14 Z"/></g>`,
    rifle: `<g stroke="${INK}" stroke-width="3.5" stroke-linejoin="round">
      <path d="M-170 -12 H-60 V-4 H-170 Z" fill="#2b2b2b"/>
      <path d="M-62 -20 H30 V6 H-6 L-12 18 H-40 L-36 6 H-62 Z" fill="#3a3a38"/>
      <path d="M-30 6 H-14 L-10 40 H-26 Z" fill="#2b2b2b"/>
      <path d="M30 -16 H70 L76 14 H54 L46 2 H30 Z" fill="#3a3a38"/>
      <path d="M-40 -28 H-8 V-20 H-40 Z" fill="#2b2b2b"/>
      <path d="M-176 -16 H-166 V0 H-176 Z" fill="#1a1a1a"/></g>`,
    tray: `<g stroke="${INK}" stroke-width="3.5" stroke-linejoin="round">
      <path d="M-118 -18 H34 L26 18 H-110 Z" fill="#c9ccd0"/>
      <path d="M-104 -10 H-62 V10 H-104 Z" fill="#fbfbf6"/>
      <path d="M-54 -10 H-20 V10 H-54 Z" fill="#c8402e"/>
      <path d="M-12 -10 H20 V10 H-12 Z" fill="#d9a352"/>
      <path d="M-98 -2 h8 M-84 2 h10 M-46 -2 h16 M-4 0 h14" stroke="#fff" stroke-width="2" opacity=".7"/></g>`,
    baton: `<g stroke="${INK}" stroke-width="3.5"><path d="M-6 6 L-120 -60" stroke-width="16" stroke-linecap="round"/><path d="M-6 6 L-120 -60" stroke="#5a3a22" stroke-width="10" stroke-linecap="round"/><path d="M0 10 L-22 -2" stroke="#222" stroke-width="12" stroke-linecap="round"/></g>`,
    crate: `<g stroke="${INK}" stroke-width="4" stroke-linejoin="round">
      <path d="M-90 -50 H40 V40 H-90 Z" fill="#5d6236"/>
      <path d="M-90 -50 H40 V-34 H-90 Z" fill="#474b28"/>
      <path d="M-70 -10 H20" stroke="#e9e3c8" stroke-width="3"/>
      <text x="-25" y="22" font-size="26" font-weight="800" text-anchor="middle" fill="#e9e3c8" stroke="none" font-family="sans-serif">탄약</text></g>`,
    whistle: '',
  };

  // 표정. 원점이 머리 가운데, 왼쪽을 본다
  const EYES = {
    normal: `<g stroke="${INK}" stroke-width="4" stroke-linecap="round">
      <path d="M-58 -2 Q-44 -12 -28 -4" fill="none"/><path d="M-6 -4 Q10 -12 26 -2" fill="none"/></g>
      <ellipse cx="-42" cy="4" rx="8" ry="7" fill="${INK}"/><ellipse cx="10" cy="4" rx="8" ry="7" fill="${INK}"/>
      <path d="M-56 -4 H-26 M-6 -4 H24" stroke="${INK}" stroke-width="5" stroke-linecap="round"/>`,
    angry: `<g stroke="${INK}" stroke-linecap="round">
      <path d="M-62 -18 L-28 -8 M-4 -8 L28 -18" stroke-width="6"/></g>
      <ellipse cx="-42" cy="4" rx="9" ry="9" fill="${INK}"/><ellipse cx="10" cy="4" rx="9" ry="9" fill="${INK}"/>
      <circle cx="-45" cy="1" r="2.5" fill="#fff"/><circle cx="7" cy="1" r="2.5" fill="#fff"/>`,
    hurt: `<g stroke="${INK}" stroke-width="5" stroke-linecap="round" fill="none">
      <path d="M-56 -8 L-34 2 L-56 12"/><path d="M24 -8 L2 2 L24 12"/></g>
      <path d="M40 -26 q8 10 0 16 q-8 -6 0 -16z" fill="#9fd4ff" stroke="${INK}" stroke-width="2.5"/>`,
    happy: `<g stroke="${INK}" stroke-width="5" stroke-linecap="round" fill="none">
      <path d="M-56 6 Q-42 -10 -28 6"/><path d="M-4 6 Q10 -10 24 6"/></g>`,
    shout: `<g stroke="${INK}" stroke-linecap="round"><path d="M-62 -20 L-28 -12 M-4 -12 L28 -20" stroke-width="6"/></g>
      <circle cx="-42" cy="2" r="10" fill="#fff" stroke="${INK}" stroke-width="4"/><circle cx="10" cy="2" r="10" fill="#fff" stroke="${INK}" stroke-width="4"/>
      <circle cx="-45" cy="3" r="4" fill="${INK}"/><circle cx="7" cy="3" r="4" fill="${INK}"/>`,
  };
  const MOUTH = {
    closed: `<path d="M-22 34 q-8 8 -16 2 M-22 34 q6 8 14 2" stroke="${INK}" stroke-width="3.5" fill="none" stroke-linecap="round"/>`,
    open: `<path d="M-38 34 Q-22 62 -6 34 Z" fill="#8e2f2a" stroke="${INK}" stroke-width="3.5" stroke-linejoin="round"/><path d="M-30 46 q8 6 16 0" stroke="#e46a6a" stroke-width="4" fill="none"/>`,
    eat: `<path d="M-36 34 Q-22 52 -8 34" fill="#8e2f2a" stroke="${INK}" stroke-width="3.5"/><circle cx="-14" cy="44" r="4" fill="#fbfbf6" stroke="${INK}" stroke-width="2"/>`,
    whistle: `<path d="M-22 34 q-8 8 -16 2" stroke="${INK}" stroke-width="3.5" fill="none" stroke-linecap="round"/>
      <g stroke="${INK}" stroke-width="3.5"><path d="M-36 30 H-70 V44 H-40 Z" fill="#c9a33a"/><circle cx="-74" cy="42" r="12" fill="#e2bd4a"/></g>`,
  };

  // 계급장: 작대기 수
  const RANK_BARS = { 이병: 1, 일병: 2, 상병: 3, 병장: 4 };

  function head(face, mouth, rank) {
    const bars = RANK_BARS[rank] || 1;
    let rankSvg = `<rect x="-36" y="-118" width="34" height="30" rx="3" fill="#1d1d1a" stroke="${INK}" stroke-width="3"/>`;
    const top = -103 - (bars * 6 - 2) / 2;
    for (let i = 0; i < bars; i++) {
      rankSvg += `<rect x="-31" y="${r1(top + i * 6)}" width="24" height="4" fill="#e7e2d0"/>`;
    }
    return `
      <path d="M-70 -66 L-92 -132 L-30 -92 Z" fill="${FUR}" stroke="${INK}" stroke-width="5" stroke-linejoin="round"/>
      <path d="M-74 -78 L-84 -116 L-50 -92 Z" fill="#f5b6a4"/>
      <path d="M48 -74 L70 -136 L94 -66 Z" fill="${FUR_D}" stroke="${INK}" stroke-width="5" stroke-linejoin="round"/>
      <path d="M-104 6 Q-112 -40 -88 -70 Q-40 -108 30 -96 Q96 -84 104 -20 Q110 28 84 56 Q40 92 -24 88 Q-82 84 -100 44 Q-120 40 -104 6 Z"
        fill="${FUR}" stroke="${INK}" stroke-width="5.5" stroke-linejoin="round"/>
      <path d="M70 -40 l26 -6 M74 -18 l28 0 M70 6 l26 6" stroke="${STRIPE}" stroke-width="7" stroke-linecap="round"/>
      <path d="M-100 0 l22 4 M-98 22 l20 -2" stroke="${STRIPE}" stroke-width="6" stroke-linecap="round"/>
      <path d="M-78 30 Q-84 70 -40 76 Q4 80 8 44 Q6 20 -30 18 Q-70 16 -78 30 Z" fill="${CREAM}"/>
      ${EYES[face] || EYES.normal}
      <path d="M-30 22 h16 l-8 9 Z" fill="#d36b7a" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>
      ${MOUTH[mouth] || MOUTH.closed}
      <path d="M-80 34 l-40 -6 M-80 42 l-42 6 M6 32 l34 -8 M6 40 l36 4" stroke="#fff6e6" stroke-width="2.4" stroke-linecap="round"/>
      <path d="M-96 -58 Q-90 -120 0 -124 Q86 -122 92 -60 L98 -54 Q0 -70 -96 -50 Z" fill="url(#camo)" stroke="${INK}" stroke-width="5" stroke-linejoin="round"/>
      <path d="M-96 -52 Q-120 -46 -132 -34 Q-104 -36 -84 -44 Z" fill="#4b4f30" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
      <path d="M-58 -112 L-74 -132 L-40 -116 Z M40 -118 L58 -134 L68 -108 Z" fill="${FUR}" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
      ${rankSvg}`;
  }

  // 자세 정의. 각도는 화면 기준(0 = 오른쪽, 90 = 아래), 왼쪽이 앞.
  const POSES = {
    idle: { hip: [210, 404], lean: 0, legF: [100, 95], legB: [80, 90], armF: [120, 70], armB: [60, 110], face: 'normal', mouth: 'closed', tail: -40 },
    claw: { hip: [220, 410], lean: -22, legF: [125, 100], legB: [55, 95], armF: [200, 185], armB: [40, 80], face: 'angry', mouth: 'open', tail: -10, prop: ['claw', 'F', 0] },
    punch: { hip: [215, 408], lean: -14, legF: [115, 95], legB: [65, 90], armF: [185, 180], armB: [70, 120], face: 'angry', mouth: 'closed', tail: -30 },
    shoot: { hip: [220, 412], lean: -6, legF: [118, 92], legB: [62, 98], armF: [175, 185], armB: [150, 180], face: 'angry', mouth: 'closed', tail: -20, prop: ['rifle', 'B', 0] },
    eat: { hip: [210, 408], lean: 6, legF: [100, 95], legB: [80, 90], armF: [130, 190], armB: [150, 200], face: 'happy', mouth: 'eat', tail: -60, prop: ['tray', 'F', 0] },
    guard: { hip: [214, 408], lean: 4, legF: [112, 96], legB: [70, 90], armF: [200, 290], armB: [200, 280], face: 'angry', mouth: 'closed', tail: -30 },
    hurt: { hip: [226, 406], lean: 22, legF: [100, 80], legB: [60, 100], armF: [250, 210], armB: [-30, 10], face: 'hurt', mouth: 'open', tail: 10 },
    command: { hip: [210, 404], lean: -4, legF: [96, 92], legB: [84, 88], armF: [190, 180], armB: [60, 120], face: 'shout', mouth: 'whistle', tail: -50 },
    baton: { hip: [216, 410], lean: -16, legF: [122, 96], legB: [60, 92], armF: [220, 200], armB: [60, 100], face: 'angry', mouth: 'open', tail: -20, prop: ['baton', 'F', 0] },
    supply: { hip: [210, 406], lean: 8, legF: [104, 92], legB: [78, 90], armF: [140, 200], armB: [150, 210], face: 'happy', mouth: 'closed', tail: -50, prop: ['crate', 'F', 0] },
    move: { hip: [214, 400], lean: -16, legF: [140, 80], legB: [40, 120], armF: [60, 110], armB: [150, 200], face: 'angry', mouth: 'closed', tail: 0 },
  };

  const THIGH = 56, SHIN = 52, UPPER = 46, FORE = 42;

  function build(name, rank = '이병') {
    const p = POSES[name] || POSES.idle;
    const hip = p.hip;
    const torsoDeg = -90 + p.lean;
    const neck = seg(hip, 92, torsoDeg);
    const shF = seg(neck, 16, torsoDeg + 90 + 180); // 앞쪽(왼쪽) 어깨
    const shB = seg(neck, 16, torsoDeg + 90);
    const hipF = [hip[0] - 18, hip[1]];
    const hipB = [hip[0] + 18, hip[1]];
    const kneeF = seg(hipF, THIGH, p.legF[0]);
    const footF = seg(kneeF, SHIN, p.legF[1]);
    const kneeB = seg(hipB, THIGH, p.legB[0]);
    const footB = seg(kneeB, SHIN, p.legB[1]);
    const elbF = seg([shF[0], shF[1] + 10], UPPER, p.armF[0]);
    const handF = seg(elbF, FORE, p.armF[1]);
    const elbB = seg([shB[0], shB[1] + 10], UPPER, p.armB[0]);
    const handB = seg(elbB, FORE, p.armB[1]);
    // 다리가 땅에 닿도록 전체를 위아래로 맞춘다
    const lift = GROUND - 12 - Math.max(footF[1], footB[1]);
    const tailBase = [hip[0] + 30, hip[1] - 6];
    const tailMid = seg(tailBase, 60, p.tail + 20);
    const tailEnd = seg(tailMid, 56, p.tail - 50);
    const tail = `<path d="M${P(tailBase)} Q${P(tailMid)} ${P(tailEnd)}" stroke="${INK}" stroke-width="27" fill="none" stroke-linecap="round"/>
      <path d="M${P(tailBase)} Q${P(tailMid)} ${P(tailEnd)}" stroke="${FUR}" stroke-width="18" fill="none" stroke-linecap="round"/>
      <circle cx="${r1(tailEnd[0])}" cy="${r1(tailEnd[1])}" r="9" fill="${STRIPE}"/>`;
    const headDeg = p.lean * 0.5;
    const headAt = seg(neck, 78, torsoDeg);
    const prop = p.prop
      ? `<g transform="translate(${P(p.prop[1] === 'F' ? handF : handB)}) rotate(${p.prop[2] || 0})">${PROPS[p.prop[0]]}</g>`
      : '';
    const propBehind = p.prop && p.prop[1] === 'B' ? prop : '';
    const propFront = p.prop && p.prop[1] === 'F' ? prop : '';
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
      <defs>${CAMO}<filter id="ink" x="-5%" y="-5%" width="110%" height="110%"><feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="7"/><feDisplacementMap in="SourceGraphic" scale="3.5"/></filter></defs>
      <g transform="translate(0 ${r1(lift)})" stroke-linejoin="round" filter="url(#ink)">
        ${tail}
        ${limb([shB[0], shB[1] + 10], elbB, 32, 'url(#camo)')}${limb(elbB, handB, 29, 'url(#camo)')}${paw(handB, 16)}
        ${limb(hipB, kneeB, 42, 'url(#camo)')}${limb(kneeB, footB, 37, 'url(#camo)')}${boot(footB, 0)}
        ${propBehind}
        ${limb(hip, neck, 96, 'url(#camo)')}
        <path d="M${P(seg(hip, 6, torsoDeg - 90))} L${P(seg(hip, 6, torsoDeg + 90))}" stroke="${INK}" stroke-width="14"/>
        <path d="M${P(neck)} l-10 18 l10 -6 l10 6 Z" fill="${CREAM}" stroke="${INK}" stroke-width="3"/>
        ${limb(hipF, kneeF, 42, 'url(#camo)')}${limb(kneeF, footF, 37, 'url(#camo)')}${boot(footF, 0)}
        <g transform="translate(${P(headAt)}) rotate(${r1(headDeg)})">${head(p.face, p.mouth, rank)}</g>
        ${limb([shF[0], shF[1] + 10], elbF, 32, 'url(#camo)')}${limb(elbF, handF, 29, 'url(#camo)')}${paw(handF, 17)}
        ${propFront}
      </g>
    </svg>`;
    const headY = headAt[1] + lift;
    return { svg, w: W, h: H, foot: [hip[0], GROUND], head: [headAt[0], headY] };
  }

  return { build, POSES: Object.keys(POSES), W, H };
})();
