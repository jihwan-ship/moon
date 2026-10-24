'use strict';
// Phaser 무대: 배경, 캐릭터, 속도 주사위, 화살표, 합 연출. 게임 로직은 game.js에 있다.
window.JJAM_STAGE = (() => {
  const TG = window.JJAM_TIGER;
  const W = 1280, H = 720, GROUND = 610;
  const SCALE = 0.6;
  const ASSET = 'assets/ruina/';

  const POS = {
    idle: { roland: 330, tiger: 950 },
    clash: { roland: 545, tiger: 735 },
    rAttack: { roland: 720, tiger: 930 },
    tAttack: { roland: 350, tiger: 560 },
  };

  const ROLAND_POSES = ['slash_ready', 'idle', 'hurt', 'move', 'evade', 'guard', 'slash', 'thrust', 'crystal', 'mook_slash', 'mook_thrust',
    'wheels_swing', 'wheels_smash', 'ranga_claw', 'logic_pistols', 'zelkova_axe', 'zelkova_crouch'];
  const FX = ['ink_arc', 'ink_arc_big', 'ink_arc_wide', 'ink_swipe', 'ink_rise', 'claw_arc', 'dash_trail', 'smoke_trail', 'debris', 'muzzle', 'muzzle_big'];
  const CARDS = ['zelkova', 'ranga', 'oldboys', 'allas', 'mook', 'logic', 'durandal', 'crystal', 'wheels', 'furioso'];

  // 롤랑 자세가 내는 이펙트
  const POSE_FX = {
    slash: 'ink_arc_big', thrust: 'dash_trail', crystal: 'ink_arc', mook_slash: 'ink_arc_big', mook_thrust: 'ink_arc_wide',
    wheels_smash: 'debris', wheels_swing: 'smoke_trail', ranga_claw: 'claw_arc', logic_pistols: 'muzzle',
    zelkova_axe: 'ink_swipe', zelkova_crouch: 'ink_rise',
  };
  // 짬타이거 자세가 내는 이펙트
  const TIGER_FX = { claw: 'claw_arc', punch: 'ink_arc', shoot: 'muzzle', baton: 'ink_swipe', command: 'ink_arc_wide' };

  let scene = null;
  let meta = {};
  let fast = false;
  let rank = '이병';
  const st = { roland: null, tiger: null };
  let readyResolve;
  const ready = new Promise((r) => { readyResolve = r; });
  let pending = { dice: null };
  let diceObjs = [];
  let hasRuina = false;

  const dur = (ms) => (fast ? ms * 0.35 : ms);

  // ---------- 짬타이거 텍스처 ----------
  const tigerTex = (pose) => `t_${rank}_${pose}`;
  function buildTigerTextures(r) {
    const jobs = TG.POSES.map((pose) => new Promise((res) => {
      const key = `t_${r}_${pose}`;
      if (scene.textures.exists(key)) return res();
      const { svg } = TG.build(pose, r);
      const img = new Image();
      img.onload = () => { if (!scene.textures.exists(key)) scene.textures.addImage(key, img); res(); };
      img.onerror = () => res();
      img.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
    }));
    return Promise.all(jobs);
  }

  // ---------- 배경 ----------
  function makeBackground() {
    const tex = scene.textures.createCanvas('bg', W, H);
    const c = tex.getContext();
    const wall = c.createLinearGradient(0, 0, 0, 560);
    wall.addColorStop(0, '#2c2928');
    wall.addColorStop(0.55, '#5a5652');
    wall.addColorStop(1, '#77716b');
    c.fillStyle = wall;
    c.fillRect(0, 0, W, 560);
    // 도서관 서가 아치
    let seed = 7;
    const rnd = () => ((seed = (seed * 9301 + 49297) % 233280) / 233280);
    for (let i = 0; i < 6; i++) {
      const x = 40 + i * 210, w = 170, top = 70;
      c.fillStyle = 'rgba(20,18,17,0.55)';
      c.beginPath();
      c.moveTo(x, 560);
      c.lineTo(x, top + 80);
      c.quadraticCurveTo(x + w / 2, top - 30, x + w, top + 80);
      c.lineTo(x + w, 560);
      c.closePath();
      c.fill();
      for (let y = top + 110; y < 540; y += 62) {
        c.fillStyle = 'rgba(60,55,50,0.9)';
        c.fillRect(x + 8, y + 50, w - 16, 6);
        let bx = x + 12;
        while (bx < x + w - 16) {
          const bw = 6 + rnd() * 10, bh = 30 + rnd() * 18;
          const g = 40 + Math.floor(rnd() * 50);
          c.fillStyle = `rgb(${g},${g - 3},${g - 6})`;
          c.fillRect(bx, y + 50 - bh, bw, bh);
          bx += bw + 1;
        }
      }
      c.strokeStyle = 'rgba(150,140,128,0.35)';
      c.lineWidth = 3;
      c.beginPath();
      c.moveTo(x, 560);
      c.lineTo(x, top + 80);
      c.quadraticCurveTo(x + w / 2, top - 30, x + w, top + 80);
      c.lineTo(x + w, 560);
      c.stroke();
    }
    // 바닥
    const floor = c.createLinearGradient(0, 556, 0, H);
    floor.addColorStop(0, '#3b3734');
    floor.addColorStop(1, '#151311');
    c.fillStyle = floor;
    c.fillRect(0, 556, W, H - 556);
    c.strokeStyle = 'rgba(0,0,0,0.35)';
    c.lineWidth = 2;
    for (let i = -12; i <= 12; i++) {
      c.beginPath();
      c.moveTo(W / 2 + i * 40, 556);
      c.lineTo(W / 2 + i * 150, H);
      c.stroke();
    }
    for (let y = 580; y < H; y += 26 + (y - 580) * 0.3) {
      c.beginPath();
      c.moveTo(0, y);
      c.lineTo(W, y);
      c.stroke();
    }
    // 가운데 빛
    const light = c.createRadialGradient(W / 2, 420, 40, W / 2, 420, 620);
    light.addColorStop(0, 'rgba(255,245,225,0.18)');
    light.addColorStop(1, 'rgba(0,0,0,0)');
    c.fillStyle = light;
    c.fillRect(0, 0, W, H);
    const vig = c.createRadialGradient(W / 2, H / 2, 300, W / 2, H / 2, 820);
    vig.addColorStop(0, 'rgba(0,0,0,0)');
    vig.addColorStop(1, 'rgba(0,0,0,0.65)');
    c.fillStyle = vig;
    c.fillRect(0, 0, W, H);
    tex.refresh();
  }

  function makeShapes() {
    const g = scene.make.graphics({ add: false });
    g.fillStyle(0xffffff, 1);
    g.beginPath();
    const pts = [];
    for (let i = 0; i < 16; i++) {
      const r = i % 2 ? 12 : 64;
      const a = (i / 16) * Math.PI * 2;
      pts.push({ x: 64 + Math.cos(a) * r, y: 64 + Math.sin(a) * r });
    }
    g.fillPoints(pts, true);
    g.generateTexture('burst', 128, 128);
    g.clear();
    g.fillStyle(0xffffff, 1);
    g.fillPoints([{ x: 16, y: 0 }, { x: 19, y: 13 }, { x: 32, y: 16 }, { x: 19, y: 19 }, { x: 16, y: 32 }, { x: 13, y: 19 }, { x: 0, y: 16 }, { x: 13, y: 13 }], true);
    g.generateTexture('star', 32, 32);
    g.clear();
    g.fillStyle(0xffffff, 1);
    g.fillRect(0, 0, 400, 4);
    g.generateTexture('streak', 400, 4);
    g.clear();
    g.lineStyle(6, 0x9fd0ff, 1);
    g.strokeCircle(70, 70, 60);
    g.generateTexture('ring', 140, 140);
    g.destroy();
  }

  // ---------- 캐릭터 ----------
  function rolandKey(pose) {
    return hasRuina && scene.textures.exists('r_' + pose) ? 'r_' + pose : 'r_fallback';
  }

  function applyRolandPose(pose) {
    const a = st.roland;
    a.pose = pose;
    const key = rolandKey(pose);
    a.spr.setTexture(key);
    const m = meta[pose];
    if (m && key !== 'r_fallback') {
      a.spr.setOrigin(1 - m.head[0] / m.w, m.foot[1] / m.h);
    } else {
      a.spr.setOrigin(0.5, 1);
    }
  }

  function applyTigerPose(pose) {
    const a = st.tiger;
    a.pose = pose;
    const key = tigerTex(pose);
    if (!scene.textures.exists(key)) return;
    a.spr.setTexture(key);
    const b = TG.build(pose, rank);
    a.spr.setOrigin(b.foot[0] / b.w, b.foot[1] / b.h);
  }

  function setPoseOf(who, pose) {
    if (!st[who]) return;
    if (who === 'roland') applyRolandPose(pose);
    else applyTigerPose(pose);
  }

  function makeActor(who, x) {
    const shadow = scene.add.ellipse(x, GROUND + 4, 170, 26, 0x000000, 0.45);
    const spr = scene.add.image(x, GROUND, 'bg').setScale(SCALE);
    if (who === 'roland') spr.setFlipX(true);
    // 발밑 링: 왼쪽 빨강 = 체력, 오른쪽 노랑 = 흐트러짐 저항
    const feet = scene.add.container(x, GROUND + 8);
    const ring = scene.add.graphics();
    const txt = { fontFamily: 'JetBrains Mono, monospace', fontSize: '22px', fontStyle: '700', stroke: '#000', strokeThickness: 5 };
    const hpT = scene.add.text(-74, 18, '', { ...txt, color: '#ff5a4a' }).setOrigin(0.5, 0);
    const stT = scene.add.text(74, 18, '', { ...txt, color: '#f0cf4a' }).setOrigin(0.5, 0);
    feet.add([ring, hpT, stT]);
    return { who, spr, shadow, feet, ring, hpT, stT, x, pose: 'idle', broken: false };
  }

  function moveActor(who, x, ms = 380) {
    const a = st[who];
    a.x = x;
    scene.tweens.add({ targets: [a.spr, a.shadow, a.feet], x, duration: dur(ms), ease: 'Cubic.easeOut' });
  }

  // ---------- 주사위와 화살표 ----------
  function plate(x, y, die) {
    const objs = [];
    const frame = scene.add.rectangle(x, y, 46, 58, 0x111111).setStrokeStyle(3, die.rarityColor || 0x555555);
    objs.push(frame);
    if (die.cardKey && scene.textures.exists(die.cardKey)) {
      const img = scene.add.image(x, y, die.cardKey);
      const src = img.texture.getSourceImage();
      const ch = src.height, cw = Math.min(src.width, Math.round(ch * 42 / 54));
      img.setCrop((src.width - cw) / 2, 0, cw, ch);
      img.setScale(54 / ch);
      objs.push(img);
    } else if (die.tigerPose && scene.textures.exists(tigerTex(die.tigerPose))) {
      // 머리 쪽만 잘라 판에 맞춘다
      const img = scene.add.image(0, 0, tigerTex(die.tigerPose));
      const cx = 30, cy = 0, cw = 320, chh = 410;
      const sc = 54 / chh;
      img.setCrop(cx, cy, cw, chh).setScale(sc);
      img.setPosition(x - (cx + cw / 2 - img.width / 2) * sc, y - (cy + chh / 2 - img.height / 2) * sc);
      objs.push(img);
    } else if (!die.cardKey) {
      frame.setFillStyle(0x000000, 0.35);
      frame.setStrokeStyle(2, 0xbfefff, 0.6);
    }
    return objs;
  }

  function renderDice(data) {
    pending.dice = data;
    if (!scene) return;
    diceObjs.forEach((o) => o.destroy());
    diceObjs = [];
    const { rDice, tDice, onR, onT, busy } = data;
    if (busy) { drawArrows([]); return; }
    const place = (list, who, cb) => {
      const a = st[who];
      const top = GROUND - 400;
      list.forEach((d, i) => {
        const x = a.x + (i - (list.length - 1) / 2) * 58;
        const y = top;
        const objs = plate(x, y - 40, d);
        const hex = [];
        for (let k = 0; k < 6; k++) {
          const a = Math.PI / 6 + (k * Math.PI) / 3;
          hex.push(Math.cos(a) * 22, Math.sin(a) * 22);
        }
        const col = who === 'roland' ? 0xbfefff : 0xff7ac0;
        const glow = scene.add.polygon(x, y + 8, hex.map((v) => v * 1.25), col, 0.18);
        const face = scene.add.polygon(x, y + 8, hex, 0x140a14, 0.92).setStrokeStyle(3, col);
        const shine = scene.add.polygon(x, y + 8, hex.map((v) => v * 0.72), col, 0.12);
        objs.push(glow);
        const num = scene.add.text(x, y + 8, String(d.speed), {
          fontFamily: 'JetBrains Mono, monospace', fontSize: '22px', fontStyle: '700', color: '#ffffff', stroke: '#000', strokeThickness: 3,
        }).setOrigin(0.5);
        objs.push(face, shine, num);
        if (d.sel || d.acting) {
          const ring = scene.add.rectangle(x, y - 14, 54, 104).setStrokeStyle(3, d.acting ? 0xffffff : 0xe6bd5c);
          objs.push(ring);
        }
        const hit = scene.add.zone(x, y - 14, 56, 108).setInteractive({ useHandCursor: true });
        hit.on('pointerdown', () => cb(i));
        objs.push(hit);
        objs.forEach((o) => o.setDepth(20));
        diceObjs.push(...objs);
        d._x = x;
        d._y = y - 70;
      });
    };
    place(rDice, 'roland', onR);
    place(tDice, 'tiger', onT);
    drawArrows(data.actions.map((act) => {
      const r = act.r != null ? rDice[act.r] : null;
      const t = act.t != null ? tDice[act.t] : null;
      const body = (who) => ({ _x: st[who].x, _y: GROUND - 200 });
      if (act.type === 'clash') return { a: r, b: t, kind: 'clash' };
      if (act.type === 'oneR') return { a: r, b: t || body('tiger'), kind: 'mine' };
      return { a: t, b: r || body('roland'), kind: 'foe' };
    }));
  }

  function drawArrows(list) {
    const g = st.arrows;
    g.clear();
    const COLORS = { clash: 0xe08a2c, mine: 0x8fe8ff, foe: 0xff4f93 };
    for (const { a, b, kind } of list) {
      if (!a || !b) continue;
      const lift = Math.min(170, 60 + Math.abs(b._x - a._x) * 0.25);
      const p0 = new Phaser.Math.Vector2(a._x, a._y);
      const p2 = new Phaser.Math.Vector2(b._x, b._y);
      const p1 = new Phaser.Math.Vector2((a._x + b._x) / 2, Math.min(a._y, b._y) - lift);
      const curve = new Phaser.Curves.QuadraticBezier(p0, p1, p2);
      const pts = curve.getPoints(40);
      const col = COLORS[kind];
      g.lineStyle(12, col, 0.18);
      g.strokePoints(pts);
      if (kind === 'clash') {
        g.lineStyle(5, col, 1);
        g.strokePoints(pts);
      } else {
        g.lineStyle(4, col, 1);
        for (let i = 0; i < pts.length - 1; i += 2) g.lineBetween(pts[i].x, pts[i].y, pts[i + 1].x, pts[i + 1].y);
      }
      const head = (p, q) => {
        const ang = Math.atan2(p.y - q.y, p.x - q.x);
        g.fillStyle(col, 1);
        g.fillTriangle(
          p.x, p.y,
          p.x - Math.cos(ang - 0.45) * 18, p.y - Math.sin(ang - 0.45) * 18,
          p.x - Math.cos(ang + 0.45) * 18, p.y - Math.sin(ang + 0.45) * 18,
        );
      };
      head(pts[pts.length - 1], pts[pts.length - 4]);
      if (kind === 'clash') head(pts[0], pts[3]);
    }
  }

  // ---------- 연출 ----------
  function float(who, text, kind) {
    if (!scene || !st[who]) return;
    const a = st[who];
    const COLORS = { dmg: '#ff4a3a', st: '#e8c23a', heal: '#6fe08f', light: '#e6bd5c', evade: '#8fe8ff', brk: '#e8c23a', max: '#ff3b2f' };
    const big = kind === 'dmg' || kind === 'max';
    const t = scene.add.text(a.x + Phaser.Math.Between(-30, 30), GROUND - 330 - (kind === 'max' ? 60 : 0), text, {
      fontFamily: kind === 'dmg' || kind === 'st' || kind === 'heal' ? 'JetBrains Mono, monospace' : 'Nanum Myeongjo, serif',
      fontSize: big ? '54px' : '36px', fontStyle: '800', color: COLORS[kind] || '#fff', stroke: '#140404', strokeThickness: 7,
    }).setOrigin(0.5).setDepth(40).setScale(1.6).setAlpha(0);
    scene.tweens.add({ targets: t, scale: 1, alpha: 1, duration: dur(140), ease: 'Back.easeOut' });
    scene.tweens.add({ targets: t, y: t.y - 70, alpha: 0, delay: dur(520), duration: dur(600), onComplete: () => t.destroy() });
  }

  function fxImage(key, x, y, opts = {}) {
    if (!scene.textures.exists('fx_' + key)) return null;
    const img = scene.add.image(x, y, 'fx_' + key).setDepth(30);
    img.setScale((opts.scale || 0.8) * 0.85).setAlpha(0);
    if (opts.flip) img.setFlipX(true);
    if (opts.angle) img.setAngle(opts.angle);
    if (opts.tint) img.setTint(opts.tint);
    if (opts.blend) img.setBlendMode(opts.blend);
    scene.tweens.add({ targets: img, alpha: 1, scale: opts.scale || 0.8, duration: dur(90) });
    scene.tweens.add({ targets: img, alpha: 0, delay: dur(opts.hold || 260), duration: dur(320), onComplete: () => img.destroy() });
    return img;
  }

  function burst(x, y, color = 0xffffff, scale = 1) {
    const b = scene.add.image(x, y, 'burst').setDepth(31).setTint(color).setScale(0.2 * scale).setBlendMode(Phaser.BlendModes.ADD);
    scene.tweens.add({ targets: b, scale: 1.4 * scale, alpha: 0, angle: 30, duration: dur(380), onComplete: () => b.destroy() });
  }

  function flash(color = 0xffffff, alpha = 0.35) {
    const r = scene.add.rectangle(W / 2, H / 2, W, H, color, alpha).setDepth(50);
    scene.tweens.add({ targets: r, alpha: 0, duration: dur(220), onComplete: () => r.destroy() });
  }

  function knock(who, dist) {
    const a = st[who];
    const dir = who === 'roland' ? -1 : 1;
    scene.tweens.add({ targets: [a.spr, a.shadow, a.feet], x: a.x + dir * dist, duration: dur(110), yoyo: true, hold: dur(140), ease: 'Quad.easeOut' });
    a.spr.setTintFill(0xffffff);
    scene.time.delayedCall(dur(60), () => a.spr.setTint(0xff6a5a));
    scene.time.delayedCall(dur(260), () => a.spr.clearTint());
  }

  // ---------- 흰 초승달 베기 ----------
  // 중심 (cx, cy), 반지름 r, 각도 a0 -> a1 (도, 화면 기준). 두께는 가운데가 가장 두껍다.
  function crescent(cx, cy, r, a0, a1, thick, color = 0xffffff, ms = 130) {
    const g = scene.add.graphics().setDepth(36).setBlendMode(Phaser.BlendModes.ADD);
    const N = 40;
    const draw = (p) => {
      g.clear();
      const n = Math.max(2, Math.floor(N * p));
      const outer = [], inner = [];
      for (let i = 0; i <= n; i++) {
        const t = i / N;
        const a = Phaser.Math.DegToRad(a0 + (a1 - a0) * t);
        const w = thick * Math.sin(Math.PI * Math.min(1, t / Math.max(p, 0.01)) ** 0.8);
        outer.push({ x: cx + Math.cos(a) * r, y: cy + Math.sin(a) * r });
        inner.push({ x: cx + Math.cos(a) * (r - w), y: cy + Math.sin(a) * (r - w) });
      }
      const poly = outer.concat(inner.reverse());
      g.lineStyle(thick * 1.6, color, 0.10);
      g.strokePoints(outer);
      g.lineStyle(thick * 0.7, color, 0.22);
      g.strokePoints(outer);
      g.fillStyle(color, 0.55);
      g.fillPoints(poly, true);
      g.lineStyle(3, 0xffffff, 1);
      g.strokePoints(outer);
    };
    const prog = { p: 0 };
    scene.tweens.add({
      targets: prog, p: 1, duration: dur(ms), ease: 'Cubic.easeOut', onUpdate: () => draw(prog.p),
      onComplete: () => scene.tweens.add({ targets: g, alpha: 0, duration: dur(260), onComplete: () => g.destroy() }),
    });
    for (let k = 0; k < 5; k++) {
      const a = Phaser.Math.DegToRad(a0 + (a1 - a0) * Math.random());
      const sp = scene.add.image(cx + Math.cos(a) * r, cy + Math.sin(a) * r, 'star').setDepth(37).setScale(0.35).setBlendMode(Phaser.BlendModes.ADD);
      scene.tweens.add({ targets: sp, alpha: 0, scale: 0.8, delay: dur(ms * 0.6), duration: dur(380), onComplete: () => sp.destroy() });
    }
  }

  // 책장별 공격 동작(롤랑, 오른쪽을 본다). t: 시작 시각(ms), dx: 그 단계에서 미끄러지는 거리,
  // arc: [중심 x 오프셋(롤랑 기준), 중심 y(바닥 위 높이), 반지름, 시작 각, 끝 각, 두께]
  const MOVES = {
    // 뒤랑달: 아래로 베고, 위로 한 번 더
    durandal_down: [
      { t: 0, pose: 'slash_ready' },
      { t: 110, pose: 'move', dx: 70, arc: [70, 230, 210, -75, 85, 22] },
    ],
    durandal_up: [
      { t: 0, pose: 'move' },
      { t: 100, pose: 'slash', dx: 50, arc: [80, 170, 220, 80, -85, 22] },
    ],
    // 크리스탈 아틀리에: 왼쪽으로 물러나며 두 번, 오른쪽으로 파고들며 두 번
    crystal_left: [
      { t: 0, pose: 'crystal', dx: -60, arc: [120, 210, 170, -60, 70, 16], color: 0xffd0ec },
      { t: 130, pose: 'move', dx: -60, arc: [110, 200, 160, 70, -55, 16], color: 0xd0f6ff },
    ],
    crystal_right: [
      { t: 0, pose: 'crystal', dx: 90, arc: [120, 210, 170, -60, 70, 16], color: 0xd0f6ff },
      { t: 130, pose: 'move', dx: 90, arc: [110, 200, 160, 70, -55, 16], color: 0xffd0ec },
    ],
    // 묵 공방: 칼집을 쥐고 멈췄다가 상대를 지나치며 거대한 초승달 한 번
    mook: [
      { t: 0, pose: 'mook_slash' },
      { t: 230, pose: 'mook_thrust', dx: 230, arc: [60, 260, 330, 115, -40, 36] },
    ],
  };

  function runMove(who, key, contactX) {
    const steps = MOVES[key];
    let x = contactX;
    for (const st0 of steps) {
      later(st0.t, () => {
        const a = st[who];
        if (!a.broken) setPoseOf(who, st0.pose);
        if (st0.dx) { x += st0.dx; slide(who, x, 90, 'Quad.easeOut'); }
        if (st0.arc) {
          const [ox, h, r, a0, a1, th] = st0.arc;
          later(40, () => crescent(st[who].x + ox, GROUND - h, r, a0, a1, th, st0.color || 0xffffff));
        }
      });
    }
    return steps[steps.length - 1].t + 90;
  }

  // ---------- 합 한 번의 연출 ----------
  // game.js가 판정하는 동안 begin()~play() 사이의 연출 호출을 모아 두었다가 한 흐름으로 재생한다.
  const DIR = { roland: 1, tiger: -1 };
  const WINDUP = { wheels_smash: 'wheels_swing' };
  const ZOOM = 1.5;
  const CENTER = (POS.clash.roland + POS.clash.tiger) / 2;
  let rec = null;
  const later = (ms, fn) => scene.time.delayedCall(dur(ms), fn);

  function slide(who, x, ms, ease = 'Quad.easeOut') {
    const a = st[who];
    a.x = x;
    scene.tweens.add({ targets: [a.spr, a.shadow, a.feet], x, duration: dur(ms), ease });
  }

  function hop(who, h, ms) {
    scene.tweens.add({ targets: st[who].spr, y: GROUND - h, duration: dur(ms / 2), yoyo: true, ease: 'Quad.easeOut' });
  }

  function redFlash(who) {
    const spr = st[who].spr;
    spr.setTint(0xff5040);
    later(320, () => spr.clearTint());
  }

  // 주사위가 날아오르는 분홍·하늘색 궤적
  function tracers() {
    for (const who of ['roland', 'tiger']) {
      const other = who === 'roland' ? 'tiger' : 'roland';
      const a = st[who], b = st[other];
      const curve = new Phaser.Curves.QuadraticBezier(
        new Phaser.Math.Vector2(a.x, GROUND - 120),
        new Phaser.Math.Vector2((a.x + b.x) / 2 + DIR[who] * 40, GROUND - 560),
        new Phaser.Math.Vector2(b.x + DIR[who] * 60, GROUND - 30),
      );
      const pts = curve.getPoints(48);
      const g = scene.add.graphics().setDepth(34).setBlendMode(Phaser.BlendModes.ADD);
      const col = who === 'roland' ? 0x8fe8ff : 0xff4f93;
      const prog = { t: 0 };
      scene.tweens.add({
        targets: prog, t: 1, duration: dur(300), ease: 'Sine.easeOut',
        onUpdate: () => {
          const n = Math.max(2, Math.floor(prog.t * pts.length));
          const from = Math.max(0, n - 18);
          g.clear();
          g.lineStyle(14, col, 0.25);
          g.strokePoints(pts.slice(from, n));
          g.lineStyle(5, col, 1);
          g.strokePoints(pts.slice(from, n));
        },
        onComplete: () => scene.tweens.add({ targets: g, alpha: 0, duration: dur(180), onComplete: () => g.destroy() }),
      });
    }
  }

  function hitFx(h, ownArcs) {
    const t = st[h.target];
    const x = t.x;
    const y = GROUND - 180;
    const fxKey = h.attacker === 'roland' ? POSE_FX[h.pose] : TIGER_FX[h.pose];
    const flip = h.attacker === 'tiger';
    if (ownArcs) {
      // 책장 동작이 이미 초승달을 그렸다
    } else if (fxKey === 'muzzle') {
      const a = st[h.attacker];
      fxImage('muzzle', a.x + (flip ? -240 : 240), GROUND - 230, { flip: !flip, scale: 0.95 });
      burst(x, y, 0xffffff, 1);
    } else if (fxKey === 'debris') {
      fxImage('debris', x, GROUND - 170, { scale: 0.8, hold: 420 });
    } else if (fxKey === 'dash_trail') {
      fxImage('dash_trail', x - DIR[h.attacker] * 160, y, { flip: !flip, scale: 0.95 });
    } else if (fxKey) {
      fxImage(fxKey, x, y, { flip: !flip, angle: Phaser.Math.Between(-15, 15), scale: 1.15, hold: 320,
        tint: h.attacker === 'tiger' && h.pose === 'claw' ? 0xffb070 : undefined });
    }
    burst(x, y, h.attacker === 'roland' ? 0xbfefff : 0xffb0c8, 1.1);
    flash(0xffffff, h.isMax ? 0.35 : 0.15);
    redFlash(h.target);
    float(h.target, `-${h.real}`, 'dmg');
    if (h.isMax) float(h.target, '최대피해!', 'max');
    scene.cameras.main.shake(dur(h.isMax || h.real >= 12 ? 260 : 150), h.isMax || h.real >= 12 ? 0.012 : 0.006);
  }

  function exchange(r, done) {
    const contact = { roland: CENTER - 105, tiger: CENTER + 105 };
    const rest = { roland: POS.clash.roland, tiger: POS.clash.tiger };
    const cam = scene.cameras.main;
    const furioso = r.hit && r.hit.opts && r.hit.opts.furioso;
    tracers();
    // 1. 맞닿을 거리까지 돌진
    for (const who of ['roland', 'tiger']) {
      if (!st[who].broken) setPoseOf(who, 'move');
      slide(who, contact[who], 160, 'Cubic.easeOut');
    }
    // 2. 준비 동작
    later(140, () => {
      for (const [who, pose] of Object.entries(r.strikes)) {
        if (!st[who].broken) setPoseOf(who, WINDUP[pose] || 'move');
      }
    });
    // 3. 적중 순간: 공격 자세로 파고들고, 아주 잠깐 멈춘 뒤 결과
    let resultAt = 70;
    later(250, () => {
      for (const [who, pose] of Object.entries(r.strikes)) {
        if (r.moves[who] && !st[who].broken) {
          resultAt = Math.max(resultAt, runMove(who, r.moves[who], contact[who]));
          continue;
        }
        if (!st[who].broken) setPoseOf(who, pose);
        slide(who, contact[who] + DIR[who] * 60, 70, 'Quad.easeOut');
      }
      cam.zoomTo(ZOOM + 0.07, dur(60), 'Quad.easeOut');
      later(90, () => cam.zoomTo(ZOOM, dur(220), 'Sine.easeOut'));
      if (furioso) {
        const seq = ['zelkova_axe', 'ranga_claw', 'zelkova_crouch', 'thrust', 'mook_thrust', 'logic_pistols', 'slash', 'crystal', 'wheels_smash'];
        seq.forEach((p, i) => later(115 * i, () => api.afterimage(p, st[r.hit.target].x)));
        later(1080, () => {
          const t = r.hit.target;
          flash(0xffffff, 0.6);
          burst(st[t].x, GROUND - 180, 0xffffff, 2.4);
          if (!st[t].broken) setPoseOf(t, 'hurt');
          redFlash(t);
          slide(t, contact[t] - DIR[t] * 200, 300, 'Cubic.easeOut');
          hop(t, 40, 300);
          float(t, `-${r.hit.real}`, 'dmg');
          if (r.hit.isMax) float(t, '최대피해!', 'max');
          cam.shake(dur(400), 0.018);
          r.floats.forEach((f) => float(...f));
        });
        return;
      }
      later(resultAt, () => {
        if (r.hit) {
          const t = r.hit.target;
          hitFx(r.hit, !!r.moves[r.hit.attacker]);
          if (!st[t].broken) setPoseOf(t, 'hurt');
          slide(t, contact[t] - DIR[t] * (r.hit.isMax ? 190 : 140), 260, 'Cubic.easeOut');
          hop(t, r.hit.isMax ? 36 : 22, 260);
        }
        for (const g of r.guards) {
          if (!st[g.who].broken) setPoseOf(g.who, g.pose);
          const ring = scene.add.image(st[g.who].x + DIR[g.who] * 70, GROUND - 190, 'ring').setDepth(30).setScale(0.5);
          scene.tweens.add({ targets: ring, scale: 2, alpha: 0, duration: dur(450), onComplete: () => ring.destroy() });
          burst(st[g.who].x + DIR[g.who] * 70, GROUND - 190, 0x9fd0ff, 0.8);
          slide(g.who, contact[g.who] - DIR[g.who] * 50, 180);
          const other = g.who === 'roland' ? 'tiger' : 'roland';
          if (r.strikes[other]) slide(other, contact[other] - DIR[other] * 40, 180);
          cam.shake(dur(120), 0.005);
        }
        if (r.dodge) {
          const w = r.dodge;
          if (!st[w].broken) setPoseOf(w, w === 'roland' ? 'evade' : 'move');
          slide(w, contact[w] - DIR[w] * 170, 200, 'Cubic.easeOut');
          scene.tweens.add({ targets: st[w].spr, alpha: 0.3, duration: dur(90), yoyo: true, repeat: 1 });
          const other = w === 'roland' ? 'tiger' : 'roland';
          slide(other, contact[other] + DIR[other] * 50, 160);
          float(w, '회피', 'evade');
        }
        if (r.spark) {
          spark();
          for (const who of ['roland', 'tiger']) slide(who, contact[who] - DIR[who] * 60, 200);
        }
        r.floats.forEach((f) => float(...f));
      });
    });
    const moveLen = Math.max(0, ...Object.values(r.moves).map((k) => MOVES[k][MOVES[k].length - 1].t + 90));
    const end = furioso ? 250 + 1450 : 250 + 600 + moveLen;
    // 4. 제자리로
    later(end, () => {
      for (const who of ['roland', 'tiger']) {
        if (!st[who].broken) setPoseOf(who, 'idle');
        slide(who, rest[who], 220, 'Sine.easeInOut');
      }
    });
    later(end + 240, done);
  }

  function spark() {
    const x = (st.roland.x + st.tiger.x) / 2;
    burst(x, GROUND - 190, 0xfff2c0, 1.3);
    for (let i = 0; i < 8; i++) {
      const sp = scene.add.image(x, GROUND - 190, 'star').setDepth(31).setScale(0.7);
      scene.tweens.add({ targets: sp, x: x + Phaser.Math.Between(-160, 160), y: GROUND - 190 + Phaser.Math.Between(-110, 110), alpha: 0, duration: dur(460), onComplete: () => sp.destroy() });
    }
  }

  const api = {
    ready,
    begin() {
      rec = { strikes: {}, moves: {}, hit: null, guards: [], dodge: null, spark: false, floats: [] };
    },
    play() {
      const r = rec;
      rec = null;
      if (!r || !scene || !st.roland) return Promise.resolve();
      return new Promise((res) => exchange(r, res));
    },
    W, H,
    init(parent) {
      const game = new Phaser.Game({
        type: Phaser.AUTO,
        parent,
        width: W,
        height: H,
        backgroundColor: '#111111',
        scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
        render: { antialias: true },
        scene: {
          preload() {
            scene = this;
            this.load.json('poses', ASSET + 'poses.json');
            ROLAND_POSES.forEach((n) => this.load.image('r_' + n, `${ASSET}poses/${n}.png`));
            FX.forEach((n) => this.load.image('fx_' + n, `${ASSET}fx/${n}.png`));
            CARDS.forEach((n) => this.load.image('card_' + n, `${ASSET}cards/${n}.png`));
            this.load.on('loaderror', () => {});
          },
          create() {
            scene = this;
            meta = this.cache.json.get('poses') || {};
            hasRuina = this.textures.exists('r_idle');
            makeBackground();
            makeShapes();
            this.add.image(W / 2, H / 2, 'bg').setDepth(0);
            if (!hasRuina) {
              const g = this.make.graphics({ add: false });
              g.fillStyle(0x151312, 1).fillRoundedRect(20, 140, 120, 230, 30).fillCircle(80, 100, 70);
              g.generateTexture('r_fallback', 160, 380);
              g.destroy();
            }
            st.arrows = this.add.graphics().setDepth(15);
            st.dim = this.add.rectangle(W / 2, H / 2, W * 3, H * 3, 0x000000, 0).setDepth(2);
            st.roland = makeActor('roland', POS.idle.roland);
            st.tiger = makeActor('tiger', POS.idle.tiger);
            [st.roland, st.tiger].forEach((a) => { a.spr.setDepth(10); a.shadow.setDepth(5); a.feet.setDepth(11); });
            applyRolandPose('idle');
            this.tweens.add({ targets: st.roland.spr, scaleY: SCALE * 1.012, duration: 1400, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
            this.tweens.add({ targets: st.tiger.spr, scaleY: SCALE * 1.015, duration: 1200, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
            this.cameras.main.setBounds(0, 0, W, H);
            buildTigerTextures(rank).then(() => {
              applyTigerPose('idle');
              readyResolve({ cards: CARDS.filter((c) => this.textures.exists('card_' + c)) });
              if (pending.dice) renderDice(pending.dice);
            });
          },
        },
      });
      return game;
    },
    hasCardArt: (id) => !!scene && scene.textures.exists('card_' + id),
    async setRank(r) {
      rank = r;
      if (!scene || !st.tiger) return;
      await buildTigerTextures(r);
      applyTigerPose(st.tiger.pose || 'idle');
    },
    setFast(v) {
      fast = v;
      if (scene) scene.tweens.timeScale = 1;
    },
    renderDice,
    setFeet(who, hp, stg, maxHp, maxSt) {
      const a = st[who];
      if (!a) return;
      a.hpT.setText(String(hp));
      a.stT.setText(String(stg));
      const g = a.ring;
      const R0 = 92, SY = 0.3;
      const arc = (from, to, anti, color, width) => {
        g.lineStyle(width, color, 1);
        g.beginPath();
        const n = 28;
        for (let i = 0; i <= n; i++) {
          const t = from + ((to - from) * i) / n;
          const px = Math.cos(t) * R0, py = Math.sin(t) * R0 * SY;
          if (i === 0) g.moveTo(px, py); else g.lineTo(px, py);
        }
        g.strokePath();
      };
      g.clear();
      g.fillStyle(who === 'roland' ? 0xe6bd5c : 0xc04ad0, 0.12);
      g.fillEllipse(0, 0, R0 * 2, R0 * 2 * SY);
      arc(0, Math.PI * 2, false, 0x1a1210, 14);
      const hpF = Math.max(0, Math.min(1, hp / (maxHp || 1)));
      const stF = Math.max(0, Math.min(1, stg / (maxSt || 1)));
      if (hpF > 0) arc(Math.PI / 2, Math.PI / 2 + Math.PI * hpF, false, 0xd23b35, 9);
      if (stF > 0) arc(Math.PI / 2, Math.PI / 2 - Math.PI * stF, true, 0xe8c23a, 9);
      g.lineStyle(2, who === 'roland' ? 0xe6bd5c : 0xc04ad0, 0.8);
      g.strokeEllipse(0, 0, R0 * 1.25, R0 * 1.25 * SY);
    },
    setBroken(who, v) {
      const a = st[who];
      if (!a || a.broken === v) return;
      a.broken = v;
      if (v) {
        a.wob = scene.tweens.add({ targets: a.spr, angle: who === 'roland' ? -6 : 6, duration: 600, yoyo: true, repeat: -1 });
        setPoseOf(who, who === 'roland' ? 'hurt' : 'hurt');
      } else {
        if (a.wob) a.wob.stop();
        a.spr.setAngle(0);
        setPoseOf(who, 'idle');
      }
    },
    place(name) {
      if (!scene || !st.roland) return;
      const p = name === 'idle' ? POS.idle : POS.clash;
      const cam = scene.cameras.main;
      if (name === 'idle') {
        slide('roland', p.roland, 380, 'Sine.easeInOut');
        slide('tiger', p.tiger, 380, 'Sine.easeInOut');
        if (!st.roland.broken) setPoseOf('roland', 'idle');
        if (!st.tiger.broken) setPoseOf('tiger', 'idle');
        cam.zoomTo(1, dur(420), 'Sine.easeInOut');
        cam.pan(W / 2, H / 2, dur(420), 'Sine.easeInOut');
        scene.tweens.add({ targets: st.dim, alpha: 0, duration: dur(400) });
      } else if (!api.inCombat) {
        if (!st.roland.broken) setPoseOf('roland', 'move');
        if (!st.tiger.broken) setPoseOf('tiger', 'move');
        slide('roland', p.roland, 360, 'Cubic.easeOut');
        slide('tiger', p.tiger, 360, 'Cubic.easeOut');
        later(360, () => {
          if (!st.roland.broken) setPoseOf('roland', 'idle');
          if (!st.tiger.broken) setPoseOf('tiger', 'idle');
        });
        cam.zoomTo(ZOOM, dur(420), 'Cubic.easeOut');
        cam.pan(CENTER, 420, dur(420), 'Cubic.easeOut');
        scene.tweens.add({ targets: st.dim, alpha: 0.55, duration: dur(400) });
      }
      api.inCombat = name !== 'idle';
    },
    pose: setPoseOf,
    // 공격 순간: 공격자 자세와 앞으로 내딛기
    strike(who, pose, move) {
      if (rec) { rec.strikes[who] = pose; if (move && MOVES[move]) rec.moves[who] = move; return; }
      const a = st[who];
      if (!a) return;
      if (!a.broken) setPoseOf(who, pose);
      const dir = who === 'roland' ? 1 : -1;
      scene.tweens.add({ targets: [a.spr, a.shadow, a.feet], x: a.x + dir * 40, duration: dur(90), yoyo: true, hold: dur(220), ease: 'Quad.easeOut' });
    },
    hit(attacker, target, pose, real, isMax, opts = {}) {
      if (rec) { rec.hit = { attacker, target, pose, real, isMax, opts }; return; }
      const t = st[target];
      if (!t) return;
      const x = t.x;
      const y = GROUND - 170;
      const fxKey = attacker === 'roland' ? POSE_FX[pose] : TIGER_FX[pose];
      const flip = attacker === 'tiger';
      if (opts.furioso) {
        // 아홉 공방 무기를 차례로 바꿔 들며 베고, 마지막에 한 번에 피해가 들어간다
        const seq = ['zelkova_axe', 'ranga_claw', 'wheels_swing', 'thrust', 'mook_thrust', 'logic_pistols', 'slash', 'crystal', 'wheels_smash'];
        seq.forEach((p, i) => scene.time.delayedCall(dur(115 * i), () => api.afterimage(p, x)));
        scene.time.delayedCall(dur(1080), () => {
          flash(0xffffff, 0.6);
          burst(x, y, 0xffffff, 2.2);
          if (!t.broken) setPoseOf(target, 'hurt');
          knock(target, 90);
          float(target, `-${real}`, 'dmg');
          if (isMax) float(target, '최대피해!', 'max');
          scene.cameras.main.shake(dur(380), 0.016);
        });
        return;
      } else if (fxKey === 'muzzle') {
        const a = st[attacker];
        fxImage('muzzle', a.x + (flip ? -220 : 220), GROUND - 230, { flip: !flip, scale: 0.75 });
        burst(x, y, 0xffffff, 0.7);
      } else if (fxKey === 'debris') {
        fxImage('debris', x, GROUND - 160, { scale: 0.55, hold: 380 });
      } else if (fxKey === 'dash_trail') {
        fxImage('dash_trail', x - (flip ? -120 : 120), y, { flip: !flip, scale: 0.7 });
      } else if (fxKey) {
        fxImage(fxKey, x, y, { flip: !flip, angle: Phaser.Math.Between(-20, 20), scale: 0.7, tint: attacker === 'tiger' && pose === 'claw' ? 0xffb070 : undefined });
      }
      burst(x, y, attacker === 'roland' ? 0xbfefff : 0xffb0c8, 0.6);
      if (!t.broken) setPoseOf(target, 'hurt');
      knock(target, isMax ? 60 : 34);
      float(target, `-${real}`, 'dmg');
      if (isMax) {
        float(target, '최대피해!', 'max');
        flash(0xffffff, 0.25);
      }
      if (isMax || real >= 12) scene.cameras.main.shake(dur(220), 0.008);
    },
    guard(who, pose = 'guard') {
      if (rec) { rec.guards.push({ who, pose }); return; }
      if (!st[who]) return;
      if (!st[who].broken) setPoseOf(who, pose);
      const r = scene.add.image(st[who].x + (who === 'roland' ? 60 : -60), GROUND - 180, 'ring').setDepth(30).setScale(0.4);
      scene.tweens.add({ targets: r, scale: 1.6, alpha: 0, duration: dur(450), onComplete: () => r.destroy() });
    },
    dodge(who) {
      if (rec) { rec.dodge = who; return; }
      const a = st[who];
      if (!a) return;
      if (!a.broken) setPoseOf(who, who === 'roland' ? 'evade' : 'move');
      const dir = who === 'roland' ? -1 : 1;
      scene.tweens.add({ targets: [a.spr, a.shadow, a.feet], x: a.x + dir * 90, duration: dur(130), yoyo: true, hold: dur(200), ease: 'Quad.easeOut' });
      scene.tweens.add({ targets: a.spr, alpha: 0.35, duration: dur(120), yoyo: true, hold: dur(160) });
      float(who, '회피', 'evade');
    },
    spark() {
      if (rec) { rec.spark = true; return; }
      if (st.roland) spark();
    },
    float(who, text, kind) {
      if (rec) { rec.floats.push([who, text, kind]); return; }
      float(who, text, kind);
    },
    ready2: () => !!scene,
    furioso(on) {
      if (!scene) return;
      const cam = scene.cameras.main;
      if (on) {
        if (!cam.postFX) return;
        api._gray = cam.postFX.addColorMatrix();
        api._gray.grayscale(1);
        api._gray.contrast(0.35, true);
        st.roland.spr.setAlpha(0.15);
      } else {
        if (api._gray && cam.postFX) cam.postFX.remove(api._gray);
        api._gray = null;
        st.roland.spr.setAlpha(1);
      }
    },
    // Furioso 잔상: 검은 실루엣이 무기를 바꿔 들고 사방에서 베고 지나간다
    afterimage(pose, x) {
      const key = rolandKey(pose);
      const side = Math.random() < 0.5 ? -1 : 1;
      const img = scene.add.image(x + side * Phaser.Math.Between(60, 160), GROUND - Phaser.Math.Between(0, 60), key)
        .setDepth(29).setScale(SCALE * Phaser.Math.FloatBetween(0.9, 1.25)).setTintFill(0x050505).setAlpha(0)
        .setAngle(Phaser.Math.Between(-18, 18));
      const m = meta[pose];
      if (m && key !== 'r_fallback') img.setOrigin(side < 0 ? 1 - m.head[0] / m.w : m.head[0] / m.w, m.foot[1] / m.h);
      img.setFlipX(side < 0);
      scene.tweens.add({ targets: img, alpha: 0.95, x: img.x - side * 70, duration: dur(120) });
      scene.tweens.add({ targets: img, alpha: 0, delay: dur(260), duration: dur(260), onComplete: () => img.destroy() });
      for (let k = 0; k < 3; k++) {
        const s = scene.add.image(x + Phaser.Math.Between(-60, 60), GROUND - Phaser.Math.Between(90, 300), 'streak')
          .setDepth(32).setAngle(Phaser.Math.Between(0, 180)).setScale(0, 1.4).setBlendMode(Phaser.BlendModes.ADD);
        scene.tweens.add({ targets: s, scaleX: 2.2, alpha: { from: 1, to: 0 }, duration: dur(380), onComplete: () => s.destroy() });
      }
      for (let k = 0; k < 4; k++) {
        const s = scene.add.image(x + Phaser.Math.Between(-140, 140), GROUND - Phaser.Math.Between(60, 360), 'star').setDepth(33).setScale(0.3);
        scene.tweens.add({ targets: s, scale: 1, alpha: 0, angle: 90, duration: dur(500), onComplete: () => s.destroy() });
      }
      flash(0xffffff, 0.18);
    },
  };
  return api;
})();
