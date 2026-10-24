// 임시 그래픽. 원작 리소스 없이 SVG로 직접 그린 실루엣들.
window.JJAM_ART = (() => {
  // 무기와 소품 실루엣. viewBox 0 0 48 48, 손잡이가 왼쪽 아래, 끝이 오른쪽 위.
  const GLYPH = {
    sword: '<path d="M38 5 L43 10 L19 34 L14 29 Z"/><path d="M9 27 L21 39 L18 42 L6 30 Z"/><path d="M10 36 L12 38 L6 44 L4 42 Z"/>',
    greatsword: '<path d="M35 3 L45 13 L21 37 L11 27 Z"/><path d="M6 25 L23 42 L20 45 L3 28 Z"/><path d="M9 37 L11 39 L5 45 L3 43 Z"/>',
    katana: '<path d="M42 4 Q38 20 15 34 L13 32 Q34 18 42 4 Z"/><circle cx="13.5" cy="34.5" r="3.2"/><path d="M11 36 L13 38 L6 45 L4 43 Z"/>',
    dagger: '<path d="M31 12 L36 17 L22 31 L17 26 Z"/><path d="M13 24 L24 35 L21 38 L10 27 Z"/><path d="M14 32 L16 34 L10 40 L8 38 Z"/><path d="M41 22 L44 25 L36 33 L33 30 Z" opacity=".75"/>',
    dual: '<path d="M7 6 L10 5 L31 29 L28 32 Z"/><path d="M41 6 L38 5 L17 29 L20 32 Z"/><path d="M24 30 L32 38 L29 41 L21 33 Z"/><path d="M24 30 L16 38 L19 41 L27 33 Z"/>',
    mace: '<path d="M8 41 L11 44 L29 26 L26 23 Z"/><circle cx="32" cy="18" r="8"/><path d="M32 5 L35 11 L29 11 Z M45 18 L39 21 L39 15 Z M32 31 L29 25 L35 25 Z M19 18 L25 15 L25 21 Z M41 9 L38 15 L35 12 Z M41 27 L35 24 L38 21 Z"/>',
    hammer: '<path d="M7 42 L10 45 L30 24 L27 21 Z"/><path d="M21 12 L33 3 L45 18 L33 27 Z"/>',
    spear: '<path d="M5 44 L8 47 L35 17 L32 14 Z"/><path d="M31 13 Q38 4 46 2 Q44 10 35 17 Z"/>',
    gun: '<path d="M6 15 H42 V22 H22 L19 33 H12 L15 22 H6 Z"/><path d="M19 22 Q21 28 26 26" fill="none" stroke-width="2"/><rect x="38" y="12" width="3" height="3"/>',
    rifle: '<path d="M2 19 H45 V23 H31 L29 29 H25 L26 23 H17 L12 30 H4 L8 23 H2 Z"/><path d="M22 23 H27 L28 33 H23 Z"/><rect x="30" y="15" width="7" height="4"/>',
    claw: '<g fill="none" stroke-width="4" stroke-linecap="round"><path d="M14 6 Q26 20 16 42"/><path d="M24 4 Q36 20 26 44"/><path d="M34 6 Q44 20 36 40"/></g>',
    tray: '<path d="M4 20 H44 L40 34 H8 Z"/><path d="M15 21 V33 M25 21 V33" stroke-width="1.5" stroke="#000" opacity=".35"/><ellipse cx="34" cy="12" rx="3" ry="4"/><path d="M33 15 L31 22 H33 L35 15 Z"/>',
    crate: '<path d="M7 15 H41 V41 H7 Z"/><path d="M7 15 L41 41 M41 15 L7 41" stroke="#000" stroke-width="2" opacity=".35"/><path d="M5 12 H43 V16 H5 Z"/>',
    baton: '<path d="M8 42 L11 45 L38 15 L35 12 Z"/><circle cx="38" cy="12" r="5"/>',
    whistle: '<circle cx="20" cy="28" r="12"/><path d="M26 19 H44 V27 H30 Z"/><circle cx="20" cy="28" r="4" fill="#000" opacity=".35"/><path d="M10 18 Q6 8 14 4" fill="none" stroke-width="2"/>',
  };

  const glyph = (id, cls = '') =>
    `<svg class="glyph ${cls}" viewBox="0 0 48 48" aria-hidden="true"><g fill="currentColor" stroke="currentColor" stroke-width="0">${GLYPH[id] || ''}</g></svg>`;

  // 주사위 아이콘. viewBox 0 0 16 16
  const ICON = {
    slash: 'M3 13.5 Q4 4 13.5 2.5 Q7.5 6 5.5 13.5 Z',
    pierce: 'M2 13 L10 5 L8 3 L14 2 L13 8 L11 6 L3 14 Z',
    blunt: 'M8 1 L10 6 L15 6 L11 9.5 L12.5 15 L8 11.5 L3.5 15 L5 9.5 L1 6 L6 6 Z',
    block: 'M8 1 L14 3 V8 Q14 13 8 15 Q2 13 2 8 V3 Z',
    evade: 'M8 2 A6 6 0 1 0 14 8 H11.5 A3.5 3.5 0 1 1 8 4.5 V7 L12 3.2 L8 -0.5 Z',
  };
  const dieIcon = (die) => {
    const cls = die.counter ? 'counter' : (die.t === 'block' || die.t === 'evade') ? 'def' : 'atk';
    return `<i class="di ${cls}"><svg viewBox="0 0 16 16" aria-hidden="true"><path d="${ICON[die.t]}"/></svg></i>`;
  };

  const HEAD_ROLAND =
    '<circle cx="40" cy="34" r="16" fill="#e2c4a4"/>' +
    '<path d="M23 35 Q21 14 41 15 Q59 15 57 35 Q55 25 47 22 Q41 29 29 27 Z" fill="#17120f"/>' +
    '<path d="M43 37 h4.5 M33 37 h4.5" stroke="#2a1d14" stroke-width="2.2" stroke-linecap="round"/>' +
    '<path d="M37 43 q3 1.2 6 0" stroke="#7a4a35" stroke-width="1.5" fill="none" stroke-linecap="round"/>';

  const HEAD_TIGER =
    '<path d="M21 36 L17 15 L35 26 Z" fill="#e0892f"/><path d="M59 36 L63 15 L45 26 Z" fill="#e0892f"/>' +
    '<circle cx="40" cy="45" r="20" fill="#e0892f"/>' +
    '<path d="M25 41 h6 M24 47 h6 M55 41 h-6 M56 47 h-6 M40 34 v4" stroke="#2a1a0c" stroke-width="2.4" stroke-linecap="round"/>' +
    '<path d="M21 30 Q40 10 59 30 Z" fill="#5f6b35"/><rect x="18" y="29" width="44" height="4.5" rx="2.2" fill="#4a5429"/>' +
    '<ellipse cx="33" cy="44" rx="2.6" ry="3.3" fill="#1a120a"/><ellipse cx="47" cy="44" rx="2.6" ry="3.3" fill="#1a120a"/>' +
    '<path d="M37.5 50 h5 l-2.5 2.6 Z" fill="#7a3a2a"/>' +
    '<path d="M40 52.6 q-3 3 -6 1 M40 52.6 q3 3 6 1" stroke="#2a1a0c" stroke-width="1.6" fill="none" stroke-linecap="round"/>' +
    '<path d="M22 52 l-8 -1 M22 55 l-8 2 M58 52 l8 -1 M58 55 l8 2" stroke="#f3d9b5" stroke-width="1.1" stroke-linecap="round"/>';

  // 롤랑 전신. 오른쪽을 본다. 무기는 오른손(화면 오른쪽)에 든다.
  const roland = (weapon) =>
    `<svg viewBox="0 0 80 120" aria-hidden="true">
      <path d="M30 86 L28 114 H35 L39 92 L42 114 H49 L48 86 Z" fill="#0d0c0b"/>
      <path d="M26 113 h10 v4 h-12 Z M41 113 h10 l2 4 h-12 Z" fill="#050505"/>
      <path d="M23 52 Q40 44 57 52 L59 92 H21 Z" fill="#161412"/>
      <path d="M34 49 L40 64 L46 49 Z" fill="#ece4d3"/><path d="M39 52 L40 66 L41 52 Z" fill="#111"/>
      <path d="M24 54 L17 80 L22 82 L30 60 Z" fill="#161412"/><circle cx="19" cy="82" r="3.2" fill="#e2c4a4"/>
      ${HEAD_ROLAND}
      <path d="M53 54 L61 76 L56 79 L48 60 Z" fill="#161412"/>
      <g class="weapon" transform="translate(51 37) scale(0.95)" color="#d3d7da">${weapon ? `<g fill="currentColor">${GLYPH[weapon]}</g>` : ''}</g>
      <circle cx="58" cy="78" r="3.2" fill="#e2c4a4"/>
    </svg>`;

  // 짬타이거 전신. 왼쪽을 본다. 소품은 왼손(화면 왼쪽)에 든다.
  const tiger = (prop) =>
    `<svg viewBox="0 0 80 120" aria-hidden="true">
      <path d="M58 100 Q78 94 72 70" stroke="#e0892f" stroke-width="6" fill="none" stroke-linecap="round"/>
      <path d="M70 80 l5 -2 M73 73 l5 0" stroke="#2a1a0c" stroke-width="2" stroke-linecap="round"/>
      <ellipse cx="31" cy="112" rx="8" ry="6" fill="#e0892f"/><ellipse cx="50" cy="112" rx="8" ry="6" fill="#e0892f"/>
      <ellipse cx="40" cy="90" rx="20" ry="23" fill="#e0892f"/>
      <ellipse cx="40" cy="94" rx="12" ry="15" fill="#f6dcb5"/>
      <path d="M22 84 h6 M21 92 h6 M58 84 h-6 M59 92 h-6" stroke="#2a1a0c" stroke-width="2.4" stroke-linecap="round"/>
      <path d="M26 72 L50 72 L48 78 L28 78 Z" fill="#5f6b35" opacity=".9"/>
      ${HEAD_TIGER}
      <g class="prop" transform="translate(-2 62) scale(0.62) translate(48 0) scale(-1 1)" color="#c9ccc4">${prop ? `<g fill="currentColor" stroke="currentColor">${GLYPH[prop]}</g>` : ''}</g>
      <ellipse cx="21" cy="88" rx="5" ry="4.5" fill="#e0892f"/><ellipse cx="59" cy="88" rx="5" ry="4.5" fill="#e0892f"/>
    </svg>`;

  const faceRoland = `<svg viewBox="18 12 44 44" aria-hidden="true">${HEAD_ROLAND}</svg>`;
  const faceTiger = `<svg viewBox="14 12 52 52" aria-hidden="true">${HEAD_TIGER}</svg>`;

  return { glyph, dieIcon, roland, tiger, faceRoland, faceTiger };
})();
