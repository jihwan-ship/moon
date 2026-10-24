// 인형 부위 SVG. 모든 부위는 관절(피벗)이 (0, 0)에 오도록 그린다.
// 팔다리는 피벗에서 아래(+y)로 뻗고, 캐릭터는 오른쪽(+x)을 본다.
// 결과: { 이름: { vb: [minx, miny, w, h], body: 'svg 내용' } }

const INK = '#1c1712';
const SKIN = '#f6d9bb';
const SKIN_D = '#e2b48f';
const FUR = '#e8913c';
const FUR_D = '#c4691f';
const CREAM = '#f8e7ca';
const STRIPE = '#2a1c13';
const BOOT = '#191612';
const OW = 4.5; // 외곽선 두께

const DEFS = `
<pattern id="camo" patternUnits="userSpaceOnUse" width="48" height="48">
  <rect width="48" height="48" fill="#6c7249"/>
  <path d="M0 0h10v6h6v8H4v-6H0z M22 4h12v6h-6v6h-8z M36 18h12v10h-8v-4h-4z M6 24h10v6h4v8H8v-6H6z M26 30h10v8h6v10H28v-8h-2z" fill="#4b4f30"/>
  <path d="M14 10h8v6h-8z M30 12h6v6h-6z M2 38h6v6H2z M40 2h6v8h-6z M18 40h6v6h-6z" fill="#8d7c55"/>
  <path d="M10 16h4v4h-4z M34 24h4v4h-4z M20 32h4v4h-4z M42 40h4v4h-4z" fill="#2f3121"/>
</pattern>
<filter id="ink" x="-10%" y="-10%" width="120%" height="120%">
  <feTurbulence type="fractalNoise" baseFrequency="0.04" numOctaves="2" seed="3"/>
  <feDisplacementMap in="SourceGraphic" scale="2.6"/>
</filter>
<linearGradient id="shade" x1="0" y1="0" x2="1" y2="0">
  <stop offset="0" stop-color="#000" stop-opacity="0"/>
  <stop offset="1" stop-color="#000" stop-opacity="0.28"/>
</linearGradient>`;

const pad = 10;
const box = (x0, y0, x1, y1) => [x0 - pad, y0 - pad, x1 - x0 + pad * 2, y1 - y0 + pad * 2];

// 피벗에서 아래로 뻗는 캡슐
function capsule(len, w, fill, extra = '') {
  return {
    vb: box(-w / 2 - OW, -w / 2 - OW, w / 2 + OW, len + w / 2 + OW),
    body: `<rect x="${-w / 2}" y="${-w / 2}" width="${w}" height="${len + w}" rx="${w / 2}" fill="${fill}" stroke="${INK}" stroke-width="${OW}"/>
      <rect x="${-w / 2}" y="${-w / 2}" width="${w}" height="${len + w}" rx="${w / 2}" fill="url(#shade)"/>${extra}`,
  };
}

const P = {};

// ---------------- 신병 ----------------
P.s_thigh = capsule(54, 36, 'url(#camo)');
P.s_shin = capsule(44, 32, 'url(#camo)', `<path d="M-16 40 Q0 46 16 40" stroke="${INK}" stroke-width="3" fill="none"/>`);
P.s_boot = {
  vb: box(-24, -14, 38, 22),
  body: `<path d="M-20 -12 Q-24 8 -14 16 H32 Q38 12 34 2 Q26 -4 14 -6 L12 -12 Z" fill="${BOOT}" stroke="${INK}" stroke-width="${OW}" stroke-linejoin="round"/>
    <path d="M-16 10 H34" stroke="#3b342b" stroke-width="4"/><path d="M-6 -8 l10 6 M-4 -2 l10 6" stroke="#4a4237" stroke-width="2.5"/>`,
};
P.s_torso = {
  vb: box(-46, -96, 46, 16),
  body: `<path d="M-34 8 Q-40 -40 -40 -70 Q-38 -92 -12 -94 H14 Q40 -92 40 -70 Q40 -40 34 8 Z" fill="url(#camo)" stroke="${INK}" stroke-width="${OW}" stroke-linejoin="round"/>
    <path d="M-34 8 Q-40 -40 -40 -70 Q-38 -92 -12 -94 H14 Q40 -92 40 -70 Q40 -40 34 8 Z" fill="url(#shade)"/>
    <path d="M-12 -94 L0 -76 L12 -94" fill="#5a5f3b" stroke="${INK}" stroke-width="3.5" stroke-linejoin="round"/>
    <path d="M0 -76 V2" stroke="${INK}" stroke-width="2.5"/>
    <rect x="-36" y="-6" width="72" height="14" rx="3" fill="#2a2a24" stroke="${INK}" stroke-width="3"/>
    <rect x="-8" y="-8" width="16" height="18" rx="3" fill="#c7c2a8" stroke="${INK}" stroke-width="3"/>
    <rect x="6" y="-62" width="28" height="11" rx="2" fill="#f4f0dc" stroke="${INK}" stroke-width="2.5"/>
    <text x="20" y="-53.5" font-size="9" font-weight="800" text-anchor="middle" fill="#1d1d1a" font-family="'Noto Sans CJK KR','Noto Sans KR',sans-serif">김신병</text>
    <rect x="-24" y="-64" width="16" height="16" rx="2" fill="#1d1d1a" stroke="${INK}" stroke-width="2.5"/>
    <rect x="-20" y="-57.5" width="8" height="3" fill="#e7e2d0"/>
    <path d="M-34 -30 h22 M14 -30 h20" stroke="#3f4228" stroke-width="3"/>`,
};
P.s_upper = capsule(38, 28, 'url(#camo)');
P.s_fore = capsule(32, 26, 'url(#camo)', `<path d="M-13 30 H13" stroke="${INK}" stroke-width="3"/>`);
P.s_hand = {
  vb: box(-15, -6, 15, 26),
  body: `<circle cx="0" cy="10" r="14" fill="${SKIN}" stroke="${INK}" stroke-width="${OW}"/>
    <path d="M-7 4 v8 M0 2 v9 M7 4 v8" stroke="${SKIN_D}" stroke-width="2.5" stroke-linecap="round"/>`,
};

// 머리: 피벗은 목. 얼굴 가운데는 (8, -66)
const HEAD_C = [8, -66];
P.s_head = {
  vb: box(-70, -150, 84, 6),
  body: `<path d="M-6 0 L-8 -14 H16 L14 0 Z" fill="${SKIN_D}" stroke="${INK}" stroke-width="3.5"/>
    <ellipse cx="8" cy="-64" rx="62" ry="58" fill="${SKIN}" stroke="${INK}" stroke-width="${OW + 1}"/>
    <ellipse cx="-38" cy="-62" rx="12" ry="15" fill="${SKIN}" stroke="${INK}" stroke-width="4"/>
    <path d="M-40 -66 q4 -4 6 4" stroke="${SKIN_D}" stroke-width="3" fill="none"/>
    <path d="M-52 -78 Q-50 -102 -26 -110 L-20 -86 Q-36 -82 -40 -70 Z" fill="#2b231d" stroke="${INK}" stroke-width="3"/>
    <path d="M-60 -72 Q-66 -136 6 -144 Q78 -142 76 -78 Q60 -88 8 -90 Q-34 -90 -60 -72 Z" fill="url(#camo)" stroke="${INK}" stroke-width="${OW + 1}" stroke-linejoin="round"/>
    <path d="M-60 -72 Q-66 -136 6 -144 Q78 -142 76 -78 Q60 -88 8 -90 Q-34 -90 -60 -72 Z" fill="url(#shade)"/>
    <path d="M-62 -72 Q8 -96 80 -76 L82 -66 Q8 -86 -64 -62 Z" fill="#4b4f30" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
    <path d="M-36 -64 Q-30 -20 4 -12" stroke="#3a3326" stroke-width="3.5" fill="none"/>
    <rect x="-2" y="-128" width="20" height="18" rx="2" fill="#1d1d1a" stroke="${INK}" stroke-width="3"/>
    <rect x="2" y="-120.5" width="12" height="3.5" fill="#e7e2d0"/>`,
};
// 표정: 머리와 같은 좌표계(피벗 = 목)
const face = (eyes, mouth, extra = '') => ({ vb: box(-20, -110, 72, -10), body: eyes + mouth + extra });
const EYE = (x, y) => `<ellipse cx="${x}" cy="${y}" rx="6" ry="8" fill="${INK}"/><circle cx="${x + 2}" cy="${y - 3}" r="2" fill="#fff"/>`;
P.s_face_normal = face(EYE(16, -64) + EYE(46, -64) + `<path d="M8 -80 l14 -2 M38 -82 l14 2" stroke="${INK}" stroke-width="4" stroke-linecap="round"/>`,
  `<path d="M28 -40 q6 4 12 0" stroke="${INK}" stroke-width="3.5" fill="none" stroke-linecap="round"/>`,
  `<ellipse cx="6" cy="-46" rx="8" ry="4" fill="#f2a59a" opacity=".6"/><ellipse cx="54" cy="-46" rx="7" ry="4" fill="#f2a59a" opacity=".6"/>`);
P.s_face_focus = face(EYE(16, -62) + EYE(46, -62) + `<path d="M6 -78 L24 -72 M36 -72 L54 -78" stroke="${INK}" stroke-width="5" stroke-linecap="round"/>`,
  `<path d="M26 -40 h14" stroke="${INK}" stroke-width="4" stroke-linecap="round"/>`);
P.s_face_shout = face(`<path d="M4 -80 L24 -70 M36 -70 L56 -80" stroke="${INK}" stroke-width="5.5" stroke-linecap="round"/>` + EYE(16, -60) + EYE(46, -60),
  `<path d="M22 -46 Q34 -18 46 -46 Z" fill="#8e2f2a" stroke="${INK}" stroke-width="3.5" stroke-linejoin="round"/><path d="M28 -32 q6 4 12 0" stroke="#e46a6a" stroke-width="4" fill="none"/>`);
P.s_face_hurt = face(`<path d="M8 -72 L22 -64 L8 -56 M54 -72 L40 -64 L54 -56" stroke="${INK}" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`,
  `<path d="M24 -38 Q32 -48 42 -38" stroke="${INK}" stroke-width="4" fill="none" stroke-linecap="round"/>`,
  `<path d="M62 -92 q9 11 0 18 q-9 -7 0 -18z" fill="#9fd4ff" stroke="${INK}" stroke-width="2.5"/>`);
P.s_face_happy = face(`<path d="M8 -62 Q16 -74 24 -62 M38 -62 Q46 -74 54 -62" stroke="${INK}" stroke-width="5" fill="none" stroke-linecap="round"/>`,
  `<path d="M24 -44 Q32 -30 42 -44 Z" fill="#8e2f2a" stroke="${INK}" stroke-width="3.5"/>`,
  `<ellipse cx="6" cy="-48" rx="9" ry="5" fill="#f2a59a" opacity=".8"/><ellipse cx="56" cy="-48" rx="8" ry="5" fill="#f2a59a" opacity=".8"/>`);
P.s_face_tired = face(`<path d="M8 -64 h16 M38 -64 h16" stroke="${INK}" stroke-width="5" stroke-linecap="round"/><path d="M8 -58 q8 5 16 0 M38 -58 q8 5 16 0" stroke="#8a7a9a" stroke-width="2.5" fill="none"/>`,
  `<path d="M26 -40 q6 -3 12 0" stroke="${INK}" stroke-width="3.5" fill="none" stroke-linecap="round"/>`);

// 소품: 피벗은 손. 앞(+x)을 향한다
P.s_k2 = {
  vb: box(-70, -26, 176, 46),
  body: `<g stroke="${INK}" stroke-width="3.5" stroke-linejoin="round">
    <path d="M136 -8 L172 -4 L136 0 Z" fill="#d9dde0"/>
    <path d="M60 -10 H138 V-2 H60 Z" fill="#2b2b2b"/>
    <path d="M-20 -18 H64 V6 H30 L24 18 H0 L4 6 H-20 Z" fill="#3a3a38"/>
    <path d="M8 6 H24 L28 40 H12 Z" fill="#2b2b2b"/>
    <path d="M-20 -14 H-62 L-66 12 H-44 L-36 2 H-20 Z" fill="#3a3a38"/>
    <path d="M10 -26 H42 V-18 H10 Z" fill="#2b2b2b"/>
    <path d="M118 -16 h6 v6 h-6 z" fill="#1a1a1a"/></g>`,
};
P.s_grenade = {
  vb: box(-16, -30, 16, 16),
  body: `<g stroke="${INK}" stroke-width="3.5"><ellipse cx="0" cy="0" rx="14" ry="16" fill="#4b5a30"/><path d="M-6 -14 H6 V-22 H-6 Z" fill="#8b8b80"/>
    <path d="M6 -20 Q20 -26 14 -10" fill="none"/><circle cx="-6" cy="-26" r="4" fill="none"/></g>
    <path d="M-14 0 H14 M0 -16 V16" stroke="#3a4724" stroke-width="2"/>`,
};
P.s_ration = {
  vb: box(-26, -34, 26, 10),
  body: `<g stroke="${INK}" stroke-width="3.5" stroke-linejoin="round"><path d="M-22 -32 H22 L20 8 H-20 Z" fill="#8d7c55"/>
    <path d="M-22 -32 H22 V-24 H-22 Z" fill="#6c5f40"/></g>
    <text x="0" y="-6" font-size="11" font-weight="900" text-anchor="middle" fill="#2a2416" font-family="'Noto Sans CJK KR',sans-serif">전투식량</text>`,
};

// ---------------- 짬타이거 ----------------
P.t_thigh = capsule(52, 40, 'url(#camo)');
P.t_shin = capsule(44, 36, 'url(#camo)');
P.t_boot = {
  vb: box(-26, -14, 36, 22),
  body: `<path d="M-22 -12 Q-26 8 -16 16 H30 Q36 10 30 0 Q22 -6 12 -8 L10 -12 Z" fill="${BOOT}" stroke="${INK}" stroke-width="${OW}" stroke-linejoin="round"/>
    <path d="M-18 10 H32" stroke="#3b342b" stroke-width="4"/>`,
};
P.t_torso = {
  vb: box(-56, -104, 56, 16),
  body: `<path d="M-46 8 Q-56 -40 -46 -76 Q-34 -102 0 -102 Q34 -102 46 -76 Q56 -40 46 8 Z" fill="url(#camo)" stroke="${INK}" stroke-width="${OW}" stroke-linejoin="round"/>
    <path d="M-46 8 Q-56 -40 -46 -76 Q-34 -102 0 -102 Q34 -102 46 -76 Q56 -40 46 8 Z" fill="url(#shade)"/>
    <path d="M-10 -100 L4 -80 L18 -100" fill="${CREAM}" stroke="${INK}" stroke-width="3.5" stroke-linejoin="round"/>
    <rect x="-46" y="-6" width="92" height="14" rx="3" fill="#2a2a24" stroke="${INK}" stroke-width="3"/>
    <rect x="-8" y="-8" width="16" height="18" rx="3" fill="#c7c2a8" stroke="${INK}" stroke-width="3"/>
    <rect x="10" y="-70" width="30" height="11" rx="2" fill="#f4f0dc" stroke="${INK}" stroke-width="2.5"/>
    <text x="25" y="-61.5" font-size="9" font-weight="800" text-anchor="middle" fill="#1d1d1a" font-family="'Noto Sans CJK KR',sans-serif">짬타이거</text>`,
};
P.t_upper = capsule(40, 32, 'url(#camo)');
P.t_fore = capsule(34, 30, 'url(#camo)');
P.t_paw = {
  vb: box(-18, -6, 18, 30),
  body: `<circle cx="0" cy="12" r="16" fill="${FUR}" stroke="${INK}" stroke-width="${OW}"/>
    <path d="M-7 6 v8 M1 4 v8 M9 6 v8" stroke="${FUR_D}" stroke-width="3" stroke-linecap="round"/>`,
};
P.t_tail = {
  vb: box(-14, -14, 104, 70),
  body: `<path d="M0 0 Q40 70 96 30" stroke="${INK}" stroke-width="28" fill="none" stroke-linecap="round"/>
    <path d="M0 0 Q40 70 96 30" stroke="${FUR}" stroke-width="19" fill="none" stroke-linecap="round"/>
    <path d="M30 34 l10 -8 M52 44 l6 -10 M74 42 l2 -12" stroke="${STRIPE}" stroke-width="6" stroke-linecap="round"/>
    <circle cx="96" cy="30" r="10" fill="${STRIPE}"/>`,
};
// 머리: 피벗은 목, 얼굴 가운데는 (10, -78). 원래 왼쪽을 보던 그림을 뒤집어 오른쪽을 보게 한다
const T_HEAD = `
  <path d="M70 -66 L92 -132 L30 -92 Z" fill="${FUR}" stroke="${INK}" stroke-width="5" stroke-linejoin="round"/>
  <path d="M74 -78 L84 -116 L50 -92 Z" fill="#f5b6a4"/>
  <path d="M-48 -74 L-70 -136 L-94 -66 Z" fill="${FUR_D}" stroke="${INK}" stroke-width="5" stroke-linejoin="round"/>
  <path d="M104 6 Q112 -40 88 -70 Q40 -108 -30 -96 Q-96 -84 -104 -20 Q-110 28 -84 56 Q-40 92 24 88 Q82 84 100 44 Q120 40 104 6 Z"
    fill="${FUR}" stroke="${INK}" stroke-width="5.5" stroke-linejoin="round"/>
  <path d="M-70 -40 l-26 -6 M-74 -18 l-28 0 M-70 6 l-26 6" stroke="${STRIPE}" stroke-width="7" stroke-linecap="round"/>
  <path d="M100 0 l-22 4 M98 22 l-20 -2" stroke="${STRIPE}" stroke-width="6" stroke-linecap="round"/>
  <path d="M78 30 Q84 70 40 76 Q-4 80 -8 44 Q-6 20 30 18 Q70 16 78 30 Z" fill="${CREAM}"/>
  <path d="M96 -58 Q90 -120 0 -124 Q-86 -122 -92 -60 L-98 -54 Q0 -70 96 -50 Z" fill="url(#camo)" stroke="${INK}" stroke-width="5" stroke-linejoin="round"/>
  <path d="M96 -52 Q120 -46 132 -34 Q104 -36 84 -44 Z" fill="#4b4f30" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
  <path d="M58 -112 L74 -132 L40 -116 Z M-40 -118 L-58 -134 L-68 -108 Z" fill="${FUR}" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
  <rect x="2" y="-118" width="34" height="30" rx="3" fill="#1d1d1a" stroke="${INK}" stroke-width="3"/>`;
const T_NECK = 86; // 머리 아래쪽에서 목까지
P.t_head = { vb: box(-112, -140 - T_NECK, 136, 92 - T_NECK), body: `<g transform="translate(0 ${-T_NECK})">${T_HEAD}</g>` };
const tf = (inner) => ({ vb: box(-70, -60 - T_NECK, 80, 70 - T_NECK), body: `<g transform="translate(0 ${-T_NECK})">${inner}</g>` });
const TE = (x, y, r = 8) => `<ellipse cx="${x}" cy="${y}" rx="${r}" ry="${r - 1}" fill="${INK}"/><circle cx="${x + 3}" cy="${y - 3}" r="2.5" fill="#fff"/>`;
const T_NOSE = `<path d="M30 22 h-16 l8 9 Z" fill="#d36b7a" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>
  <path d="M80 34 l40 -6 M80 42 l42 6 M-6 32 l-34 -8 M-6 40 l-36 4" stroke="#fff6e6" stroke-width="2.4" stroke-linecap="round"/>`;
const M_CLOSED = `<path d="M22 34 q8 8 16 2 M22 34 q-6 8 -14 2" stroke="${INK}" stroke-width="3.5" fill="none" stroke-linecap="round"/>`;
const M_OPEN = `<path d="M38 34 Q22 62 6 34 Z" fill="#8e2f2a" stroke="${INK}" stroke-width="3.5" stroke-linejoin="round"/><path d="M30 46 q-8 6 -16 0" stroke="#e46a6a" stroke-width="4" fill="none"/>`;
P.t_face_normal = tf(`<path d="M58 -2 Q44 -12 28 -4 M6 -4 Q-10 -12 -26 -2" stroke="${INK}" stroke-width="4" fill="none" stroke-linecap="round"/>` + TE(42, 4) + TE(-10, 4) + T_NOSE + M_CLOSED);
P.t_face_angry = tf(`<path d="M62 -18 L28 -8 M4 -8 L-28 -18" stroke="${INK}" stroke-width="6" stroke-linecap="round"/>` + TE(42, 4, 9) + TE(-10, 4, 9) + T_NOSE + M_OPEN);
P.t_face_hurt = tf(`<path d="M56 -8 L34 2 L56 12 M-24 -8 L-2 2 L-24 12" stroke="${INK}" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M-40 -26 q-8 10 0 16 q8 -6 0 -16z" fill="#9fd4ff" stroke="${INK}" stroke-width="2.5"/>` + T_NOSE + M_OPEN);
P.t_face_happy = tf(`<path d="M56 6 Q42 -10 28 6 M4 6 Q-10 -10 -24 6" stroke="${INK}" stroke-width="5" fill="none" stroke-linecap="round"/>` + T_NOSE +
  `<path d="M36 34 Q22 52 8 34" fill="#8e2f2a" stroke="${INK}" stroke-width="3.5"/><circle cx="14" cy="44" r="4" fill="#fbfbf6" stroke="${INK}" stroke-width="2"/>`);
P.t_face_shout = tf(`<path d="M62 -20 L28 -12 M4 -12 L-28 -20" stroke="${INK}" stroke-width="6" stroke-linecap="round"/>
  <circle cx="42" cy="2" r="10" fill="#fff" stroke="${INK}" stroke-width="4"/><circle cx="-10" cy="2" r="10" fill="#fff" stroke="${INK}" stroke-width="4"/>
  <circle cx="45" cy="3" r="4" fill="${INK}"/><circle cx="-7" cy="3" r="4" fill="${INK}"/>` + T_NOSE +
  `<g stroke="${INK}" stroke-width="3.5"><path d="M36 30 H70 V44 H40 Z" fill="#c9a33a"/><circle cx="74" cy="42" r="12" fill="#e2bd4a"/></g>`);
P.t_face_dizzy = tf(`<g stroke="${INK}" stroke-width="4" fill="none"><path d="M34 4 a8 8 0 1 1 8 8 a4 4 0 1 1 -4 -4"/><path d="M-18 4 a8 8 0 1 1 8 8 a4 4 0 1 1 -4 -4"/></g>` + T_NOSE + M_OPEN);
for (let n = 1; n <= 4; n++) {
  const gap = 6;
  const top = -103 - (n * gap - 2) / 2;
  let bars = '';
  for (let i = 0; i < n; i++) bars += `<rect x="7" y="${top + i * gap}" width="24" height="4" fill="#e7e2d0"/>`;
  P['t_rank' + n] = { vb: box(0, -120 - T_NECK, 40, -86 - T_NECK), body: `<g transform="translate(0 ${-T_NECK})">${bars}</g>` };
}
P.t_claw = {
  vb: box(-4, -30, 56, 40),
  body: `<g stroke="${INK}" stroke-width="3" fill="#f4f1ea"><path d="M10 -12 Q34 -22 44 -8 Q30 -14 12 -4 Z"/><path d="M12 -2 Q38 -2 48 12 Q32 4 12 6 Z"/><path d="M10 8 Q32 16 38 32 Q26 20 8 14 Z"/></g>`,
};
P.t_rifle = P.s_k2;
P.t_tray = {
  vb: box(-34, -20, 118, 20),
  body: `<g stroke="${INK}" stroke-width="3.5" stroke-linejoin="round"><path d="M-34 -18 H118 L110 18 H-26 Z" fill="#c9ccd0"/>
    <path d="M-20 -10 H22 V10 H-20 Z" fill="#fbfbf6"/><path d="M30 -10 H64 V10 H30 Z" fill="#c8402e"/><path d="M72 -10 H104 V10 H72 Z" fill="#d9a352"/></g>`,
};
P.t_baton = {
  vb: box(-10, -80, 130, 16),
  body: `<path d="M6 6 L120 -60" stroke="${INK}" stroke-width="17" stroke-linecap="round"/><path d="M6 6 L120 -60" stroke="#5a3a22" stroke-width="10" stroke-linecap="round"/>
    <path d="M0 10 L22 -2" stroke="#222" stroke-width="13" stroke-linecap="round"/>`,
};
P.t_crate = {
  vb: box(-40, -50, 90, 40),
  body: `<g stroke="${INK}" stroke-width="4" stroke-linejoin="round"><path d="M-40 -50 H90 V40 H-40 Z" fill="#5d6236"/><path d="M-40 -50 H90 V-34 H-40 Z" fill="#474b28"/></g>
    <text x="25" y="22" font-size="28" font-weight="900" text-anchor="middle" fill="#e9e3c8" font-family="'Noto Sans CJK KR',sans-serif">탄약</text>`,
};

module.exports = { P, DEFS, HEAD_C };
