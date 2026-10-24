'use strict';
(() => {
  const D = window.JJAM_DATA;
  const A = window.JJAM_ART;
  const STG = window.JJAM_STAGE;
  const TG = window.JJAM_TIGER;
  const $ = (id) => document.getElementById(id);
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const rand = (a, b) => a + Math.floor(Math.random() * (b - a + 1));
  const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
  const shuffle = (arr) => {
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
  };
  let fast = false;
  const sleep = (ms) => new Promise((r) => setTimeout(r, fast || reduceMotion ? Math.min(ms, 70) : ms));

  let uidSeq = 0;
  const inst = (id) => ({ uid: ++uidSeq, id, resolved: false });
  const tInst = (id) => ({ id, def: D.TIGER_CARDS[id], used: false, broken: false });
  const rCard = (c) => D.ROLAND_CARDS[c.id];
  const kindOf = (die) => D.DICE[die.t].kind;
  const nm = (side) => (side.who === 'roland' ? '롤랑' : '짬타이거');
  const WORKSHOPS = D.ROLAND_DECK;

  let S;

  // ---------- 게임 진행 ----------

  function newGame() {
    const r = D.ROLAND;
    S = {
      scene: 0, phase: 0, busy: false, over: null, phaseEnded: false,
      roland: {
        hp: r.hp, maxHp: r.hp, st: r.stagger, maxSt: r.stagger, broken: false, skip: false,
        light: r.baseLight, maxLight: r.baseLight, status: {}, pending: {}, counters: [],
      },
      tiger: null,
      deck: shuffle(D.ROLAND_DECK.map(inst)), discard: [], hand: [],
      used: new Set(), rDice: [], tDice: [], sel: -1, peek: -1, acting: null,
    };
    setupTiger(0);
    draw(r.startHand + r.blackSilenceDraw);
    $('log').innerHTML = '';
    $('overlay').hidden = true;
    STG.setRank('이병');
    say('roland', pick(D.LINES.roland.start));
    say('tiger', D.PHASES[0].intro);
    addLog(`${D.PHASES[0].rank} 짬타이거가 나타났다.`);
    actCard(1);
    startScene(true);
  }

  function setupTiger(p) {
    const ph = D.PHASES[p];
    const prev = S.tiger;
    S.tiger = {
      hp: ph.hp, maxHp: ph.hp, st: ph.stagger, maxSt: ph.stagger, broken: false, skip: false,
      ammo: ph.maxAmmo, maxAmmo: ph.maxAmmo,
      status: {}, pending: prev ? prev.pending : {},
    };
  }

  function draw(n) {
    for (let k = 0; k < n; k++) {
      if (!S.deck.length) {
        if (!S.discard.length) return;
        S.deck = shuffle(S.discard);
        S.discard = [];
        addLog('버린 책장을 섞어 덱으로 되돌렸다.');
      }
      S.hand.push(S.deck.pop());
    }
  }

  function startScene(first) {
    const R = S.roland, T = S.tiger, ph = D.PHASES[S.phase];
    S.scene++;
    if (!first) {
      R.light = Math.min(R.maxLight, R.light + D.ROLAND.lightRegen);
      draw(D.ROLAND.drawPerScene);
    }
    R.status = R.pending;
    R.pending = {};
    R.counters = [];
    T.status = T.pending;
    T.pending = {};
    S.destroyTiger = false;
    R.skip = R.broken;
    T.skip = T.broken;
    const extra = S.phase >= 2 ? 1 : 0;
    const nR = R.skip ? 0 : Math.max(1, D.ROLAND.speedDice + extra - (R.status.pushup ? 1 : 0));
    const nT = T.skip ? 0 : ph.dice;
    S.rDice = Array.from({ length: nR }, () => ({ speed: rand(...D.ROLAND.speed), card: null, target: null }))
      .sort((a, b) => b.speed - a.speed);
    const bind = T.status.bind || 0;
    S.tDice = tigerChoose(nT).map((card) => ({ speed: Math.max(1, rand(...ph.speed) - bind), card, target: nR ? rand(0, nR - 1) : -1 }))
      .sort((a, b) => b.speed - a.speed);
    S.sel = nR ? 0 : -1;
    S.peek = -1;
    S.acting = null;
    S.busy = false;
    if (R.status.pushup) {
      say('roland', pick(D.LINES.roland.pushup));
      addLog('엎드려뻗쳐 여파로 롤랑의 속도 주사위가 하나 줄었다.');
    }
    if (R.status.duckwalk) {
      say('roland', pick(D.LINES.roland.duckwalk));
      addLog('오리걸음 여파로 이번 장면에는 회피 주사위를 쓸 수 없다.');
    }
    if (bind) addLog(`속박 ${bind}: 짬타이거의 속도가 느려졌다.`);
    if (R.skip) addLog('롤랑이 흐트러져 이번 장면에는 행동할 수 없다.');
    if (T.skip) addLog('짬타이거가 흐트러졌다. 이번 장면은 일방 공격 기회다.');
    readoutHelp();
    render();
  }

  function tigerChoose(n) {
    const ph = D.PHASES[S.phase], T = S.tiger;
    const k2Cost = D.TIGER_CARDS.k2.ammo;
    const out = [];
    let ammo = T.ammo, ate = false;
    for (let i = 0; i < n; i++) {
      if (ph.pool.includes('k2') && ammo < k2Cost && !out.some((c) => c.id === 'supply')) {
        out.push(tInst('supply'));
        continue;
      }
      const opts = ph.pool.filter((id) => !(id === 'k2' && ammo < k2Cost) && !(id === 'eat' && ate));
      const w = opts.map((id) => {
        if (id === 'eat') return T.hp < T.maxHp * 0.5 ? 2.5 : 0.7;
        return D.TIGER_CARDS[id].weight || 1;
      });
      let r = Math.random() * w.reduce((a, b) => a + b, 0);
      let id = opts[opts.length - 1];
      for (let j = 0; j < opts.length; j++) {
        r -= w[j];
        if (r <= 0) { id = opts[j]; break; }
      }
      if (id === 'k2') ammo -= k2Cost;
      if (id === 'eat') ate = true;
      out.push(tInst(id));
    }
    return out;
  }

  // ---------- 책장 배치 ----------

  function reservedLight() {
    if (S.busy) return 0;
    return S.rDice.reduce((s, d) => s + (d.card ? rCard(d.card).cost : 0), 0);
  }
  const availableLight = () => S.roland.light - reservedLight();

  function defaultTarget(i) {
    if (!S.tDice.length) return null;
    const taken = new Set(S.rDice.filter((d, k) => k !== i && d.card).map((d) => d.target));
    const rd = S.rDice[i];
    let t = S.tDice.findIndex((td, k) => td.target === i && !taken.has(k));
    if (t < 0) t = S.tDice.findIndex((td, k) => rd.speed > td.speed && !taken.has(k));
    if (t < 0) t = S.tDice.findIndex((td, k) => !taken.has(k));
    return t < 0 ? 0 : t;
  }

  function onRDieTap(i) {
    if (S.busy || S.over) return;
    const rd = S.rDice[i];
    if (S.sel === i && rd.card) {
      S.hand.push(rd.card);
      rd.card = null;
      rd.target = null;
    }
    S.sel = i;
    S.peek = -1;
    render();
  }

  function onTDieTap(t) {
    if (S.busy || S.over) return;
    const rd = S.rDice[S.sel];
    if (rd && rd.card) rd.target = t;
    S.peek = t;
    render();
  }

  function onHandTap(uid) {
    if (S.busy || S.over || !S.rDice.length) return;
    const idx = S.hand.findIndex((c) => c.uid === uid);
    if (idx < 0) return;
    const c = S.hand[idx];
    if (rCard(c).cost > availableLight()) {
      notice('빛이 부족하다. 비용이 낮은 책장을 고르거나 배치한 책장을 빼자.');
      return;
    }
    let i = S.sel >= 0 && !S.rDice[S.sel].card ? S.sel : S.rDice.findIndex((d) => !d.card);
    if (i < 0) {
      notice('빈 속도 주사위가 없다. 롤랑 머리 위 주사위를 두 번 눌러 책장을 빼자.');
      return;
    }
    S.rDice[i].card = c;
    S.rDice[i].target = defaultTarget(i);
    S.hand.splice(idx, 1);
    S.sel = i;
    S.peek = -1;
    render();
  }

  // 합 판정: 같은 대상을 서로 노리거나, 롤랑 주사위가 더 빠르면 상대 주사위를 끌어와 합을 한다.
  function computeActions() {
    const acts = [];
    const claimed = new Set();
    const order = S.rDice.map((d, i) => i).filter((i) => S.rDice[i].card)
      .sort((a, b) => S.rDice[b].speed - S.rDice[a].speed);
    for (const i of order) {
      const rd = S.rDice[i];
      const t = rd.target;
      const td = t != null ? S.tDice[t] : null;
      if (td && !claimed.has(t) && (td.target === i || rd.speed > td.speed)) {
        claimed.add(t);
        acts.push({ type: 'clash', r: i, t, speed: Math.max(rd.speed, td.speed) });
      } else {
        acts.push({ type: 'oneR', r: i, t: td ? t : null, speed: rd.speed });
      }
    }
    S.tDice.forEach((td, t) => {
      if (!claimed.has(t)) acts.push({ type: 'oneT', r: td.target >= 0 ? td.target : null, t, speed: td.speed });
    });
    acts.sort((a, b) => b.speed - a.speed || (a.type === 'oneT') - (b.type === 'oneT'));
    return acts;
  }

  // ---------- 합 처리 ----------

  async function commit() {
    if (S.busy || S.over) return;
    const R = S.roland;
    const acts = computeActions();
    R.light -= reservedLight();
    S.busy = true;
    S.sel = -1;
    render();
    await sleep(250);
    for (const act of acts) {
      if (S.over || S.phaseEnded) break;
      const rc = act.type !== 'oneT' ? S.rDice[act.r].card : null;
      const tc = act.type !== 'oneR' ? S.tDice[act.t].card : null;
      S.acting = act;
      renderDice();
      await resolvePair(rc, tc);
      renderHUD();
    }
    S.acting = null;
    hideBanners();
    STG.furioso(false);
    STG.place('idle');
    await sleep(350);
    endScene();
  }

  function side(who, def, ref, q) {
    const u = who === 'roland' ? S.roland : S.tiger;
    if (!q) {
      q = def ? def.dice.filter((x) => !x.counter) : [];
      if (who === 'roland' && S.roland.status.duckwalk) q = q.filter((x) => x.t !== 'evade');
    }
    return { who, u, def, ref, q, i: 0, hitApplied: false };
  }

  async function resolvePair(rc, tc) {
    const R = S.roland, T = S.tiger;
    if (rc && R.broken) { addLog(`롤랑이 흐트러져 ${rCard(rc).name} 책장이 취소됐다.`); rc = null; }
    if (tc && T.broken) { addLog(`짬타이거가 흐트러져 ${tc.def.name} 책장이 취소됐다.`); tc = null; }
    if (tc && S.destroyTiger) { addLog(`Furioso에 주사위가 모두 파괴되어 ${tc.def.name} 책장이 취소됐다.`); tc = null; }
    if (!rc && !tc) return;

    let Aside;
    if (rc) {
      Aside = side('roland', rCard(rc), rc);
    } else if (R.counters.length && !R.broken) {
      // 반격 주사위가 남아 있으면 일방 공격 대신 합을 한다
      const c = R.counters.shift();
      Aside = side('roland', { id: c.id, name: `반격 · ${c.from}`, weapon: c.weapon, pose: c.pose, rarity: 'hardcover', dice: [c.die] }, null, [c.die]);
      addLog(`반격 주사위로 받아친다 (${c.from}).`);
    } else {
      Aside = side('roland', null, null);
    }
    const Bside = side('tiger', tc ? tc.def : null, tc);
    if (rc) useRoland(rc);
    if (tc) useTiger(tc);

    const furioso = Aside.def && Aside.def.special === 'furioso';
    const hasA = Aside.q.length > 0 || !!rc;
    if (hasA && tc) addLog(`합: ${Aside.def.name} 대 ${Bside.def.name}`);
    else if (hasA) addLog(`일방 공격: ${Aside.def.name}`);
    else addLog(`일방 공격: 짬타이거의 ${Bside.def.name}`);

    STG.place(hasA && tc ? 'clash' : hasA ? 'rAttack' : 'tAttack');
    showBanners(Aside, Bside);
    if (furioso) await furiosoIntro();
    await sleep(480);

    while (!S.over && !S.phaseEnded) {
      const aHas = Aside.i < Aside.q.length && !R.broken;
      const bHas = Bside.i < Bside.q.length && !T.broken;
      if (aHas && bHas) await dicePair(Aside, Bside);
      else if (aHas) await oneSided(Aside, Bside);
      else if (bHas) await oneSided(Bside, Aside);
      else break;
    }
    await sleep(200);
    hideBanners();
    if (furioso) STG.furioso(false);
  }

  function useRoland(rc) {
    rc.resolved = true;
    const def = rCard(rc);
    for (const die of def.dice) {
      if (die.counter) S.roland.counters.push({ die, from: def.name, weapon: def.weapon, id: def.id, pose: def.pose });
    }
    if (def.onUse) {
      const R = S.roland;
      if (def.onUse.light) {
        const got = Math.min(def.onUse.light, R.maxLight - R.light);
        R.light += got;
        if (got) fxFloat('roland', `빛 +${got}`, 'light');
      }
      if (def.onUse.draw) draw(def.onUse.draw);
      addLog(`${def.name}: 빛 회복, 책장 뽑기.`);
    }
    if (def.special === 'furioso') say('roland', pick(D.LINES.roland.furioso));
    else if (Math.random() < 0.2) say('roland', pick(D.LINES.roland.attack));
  }

  // 출혈: 짬타이거가 공격 주사위를 굴릴 때 피해를 입고, 출혈은 2/3로 줄어든다
  function bleed(sd, die) {
    if (sd.who !== 'tiger' || kindOf(die) !== 'atk') return;
    const T = S.tiger;
    const b = T.status.bleed || 0;
    if (!b) return;
    T.hp = Math.max(0, T.hp - b);
    T.status.bleed = Math.floor((b * 2) / 3);
    fxFloat('tiger', `출혈 -${b}`, 'dmg');
    addLog(`출혈로 짬타이거가 피해 ${b}를 입었다.`);
    checkDeath(sd);
  }

  function useTiger(tc) {
    const T = S.tiger;
    tc.used = true;
    if (tc.id === 'k2') {
      T.ammo = Math.max(0, T.ammo - tc.def.ammo);
      say('tiger', pick(D.LINES.tiger.k2));
    } else if (tc.id === 'supply') {
      T.ammo = T.maxAmmo;
      say('tiger', pick(D.LINES.tiger.supply));
      addLog('짬타이거가 탄약을 가득 채웠다.');
    } else if (tc.id === 'eat') {
      say('tiger', pick(D.LINES.tiger.eat));
    } else if (tc.def.onHit) {
      say('tiger', pick(D.LINES.tiger[tc.def.onHit]));
    }
  }

  // A는 항상 롤랑, B는 항상 짬타이거
  async function dicePair(Aside, Bside) {
    const da = Aside.q[Aside.i], db = Bside.q[Bside.i];
    const va = rand(da.min, da.max), vb = rand(db.min, db.max);
    setEmblem('roland', da, va);
    setEmblem('tiger', db, vb);
    markQueue(Aside, Bside);
    bleed(Bside, db);
    if (S.phaseEnded) return;
    await sleep(200);
    STG.begin();
    const ka = kindOf(da), kb = kindOf(db);
    let useA = true, useB = true, result;
    if (ka === 'atk' && kb === 'atk') {
      if (va > vb) result = hit(Aside, Bside, va, da);
      else if (vb > va) result = hit(Bside, Aside, vb, db);
      else { result = '동점, 서로 상쇄'; tie(Aside, Bside, da, db); }
    } else if (ka === 'atk') {
      [useA, useB, result] = atkVsDef(Aside, Bside, va, vb, da, db);
    } else if (kb === 'atk') {
      [useB, useA, result] = atkVsDef(Bside, Aside, vb, va, db, da);
    } else if (da.t === 'block' && db.t === 'block' && va !== vb) {
      const [w, l] = va > vb ? [Aside, Bside] : [Bside, Aside];
      STG.guard(w.who, defPose(w, w === Aside ? da : db));
      STG.guard(l.who, defPose(l, l === Aside ? da : db));
      result = staggerHit(l, Math.abs(va - vb), w);
    } else {
      result = '서로 수비, 효과 없음';
      tie(Aside, Bside, da, db);
    }
    if (da.furioso && va > vb && !S.phaseEnded) {
      Bside.i = Bside.q.length;
      S.destroyTiger = true;
      result += ', 짬타이거의 주사위 전부 파괴';
    }
    showReadout(da, va, db, vb, result);
    addLog(`${D.DICE[da.t].label} ${va} 대 ${D.DICE[db.t].label} ${vb}: ${result}`);
    if (useA) Aside.i++;
    if (useB) Bside.i++;
    markQueue(Aside, Bside);
    await STG.play();
  }

  // ---------- 자세 고르기 ----------

  function atkPose(sd, die) {
    if (sd.who === 'tiger') return (sd.def && sd.def.tpose) || 'claw';
    if (die.w) return D.WEAPON_POSE[die.w] || 'slash';
    const map = (sd.def && sd.def.pose) || {};
    return map[die.t] || (die.t === 'pierce' ? 'thrust' : 'slash');
  }

  function defPose(sd, die) {
    if (sd.who === 'tiger') return sd.def && sd.def.tpose === 'eat' ? 'eat' : 'guard';
    return die.t === 'evade' ? 'evade' : 'guard';
  }

  function tie(Aside, Bside, da, db) {
    for (const [sd, die] of [[Aside, da], [Bside, db]]) {
      if (kindOf(die) === 'atk') STG.strike(sd.who, atkPose(sd, die));
      else STG.guard(sd.who, defPose(sd, die));
    }
    STG.spark();
  }


  // X가 공격, Y가 수비. [X 주사위 소모, Y 주사위 소모, 결과 문구]
  function atkVsDef(X, Y, vx, vy, dx, dy) {
    if (dy.t === 'block') {
      if (vx > vy) return [true, true, hit(X, Y, vx - vy, dx)];
      STG.strike(X.who, atkPose(X, dx));
      STG.guard(Y.who, defPose(Y, dy));
      if (vy > vx) {
        onWin(Y, dy);
        return [true, true, staggerHit(X, vy - vx, Y)];
      }
      return [true, true, `${nm(Y)} 방어, 완벽하게 막아냄`];
    }
    if (vy > vx) {
      onWin(Y, dy);
      if (!Y.u.broken) Y.u.st = Math.min(Y.u.maxSt, Y.u.st + vy);
      STG.strike(X.who, atkPose(X, dx));
      STG.dodge(Y.who);
      return [true, false, `${nm(Y)} 회피 성공, 흐트러짐 ${vy} 회복 (회피 주사위 재사용)`];
    }
    if (vx > vy) return [true, true, hit(X, Y, vx, dx)];
    tie(X, Y, dx, dy);
    return [true, true, '동점, 서로 상쇄'];
  }

  function onWin(sd, die) {
    if (die.onWin === 'light' && sd.who === 'roland') {
      const R = S.roland;
      if (R.light < R.maxLight) {
        R.light++;
        fxFloat('roland', '빛 +1', 'light');
      }
    }
  }

  function resistOf(who, t) {
    const table = who === 'roland' ? D.ROLAND.resist : D.TIGER_RESIST;
    return D.RESIST[table[t] || 'normal'];
  }

  function hit(X, Y, value, die) {
    const u = Y.u;
    const res = resistOf(Y.who, die.t);
    const mult = u.broken ? 2 : 1;
    const fragile = (u.status && u.status.fragile) || 0;
    const real = Math.max(1, Math.round(value * res.mult * mult) + fragile);
    const stDmg = Math.max(1, Math.round(value * res.mult));
    u.hp = Math.max(0, u.hp - real);
    const isMax = value >= die.max;
    const pose = atkPose(X, die);
    STG.strike(X.who, pose);
    STG.hit(X.who, Y.who, pose, real, isMax, { furioso: !!(X.def && X.def.special === 'furioso') });
    let txt = `${nm(X)} 승리, ${nm(Y)} 피해 ${real}`;
    if (res.mult !== 1) txt += ` (${res.label})`;
    if (mult > 1) txt += ' (흐트러짐 2배)';
    if (fragile) txt += ` (취약 +${fragile})`;
    txt += damageStagger(Y, stDmg);
    if (die.onHitSt && !X.u.broken) {
      X.u.st = Math.min(X.u.maxSt, X.u.st + die.onHitSt);
      txt += `, 흐트러짐 ${die.onHitSt} 회복`;
    }
    if (X.def && X.def.inflict && Y.who === 'tiger') {
      const P = S.tiger.pending;
      for (const [k, n] of Object.entries(X.def.inflict)) P[k] = Math.max(P[k] || 0, n);
      txt += ', 다음 장면 출혈·속박·취약';
    }
    if (Y.ref && Y.def && Y.def.gimmick === 'heal') Y.ref.broken = true;
    if (X.def && X.def.onHit && !X.hitApplied && Y.who === 'roland') {
      X.hitApplied = true;
      S.roland.pending[X.def.onHit] = true;
      txt += `, 다음 장면 ${D.STATUS[X.def.onHit].name}`;
    }
    checkDeath(Y);
    return txt;
  }

  function staggerHit(Y, n, W) {
    fxFloat(Y.who, `-${n}`, 'st');
    return `${nm(W)} 방어 성공, ${nm(Y)} 흐트러짐 피해 ${n}` + damageStagger(Y, n);
  }

  function damageStagger(Y, n) {
    const u = Y.u;
    if (u.broken) return '';
    u.st = Math.max(0, u.st - n);
    if (u.st > 0) return '';
    u.broken = true;
    fxFloat(Y.who, '흐트러짐!', 'brk');
    if (Y.who === 'tiger') {
      say('tiger', pick(D.LINES.tiger.stagger));
      say('roland', pick(D.LINES.roland.tigerStagger));
    } else {
      say('roland', pick(D.LINES.roland.stagger));
    }
    return `, ${nm(Y)} 흐트러짐!`;
  }

  function checkDeath(Y) {
    if (Y.u.hp > 0) return;
    if (Y.who === 'roland') S.over = 'lose';
    else S.phaseEnded = true;
  }

  async function oneSided(X, Y) {
    const dx = X.q[X.i];
    X.i++;
    markQueue(X.who === 'roland' ? X : Y, X.who === 'roland' ? Y : X);
    if (kindOf(dx) !== 'atk') return; // 남은 수비 주사위는 아무 일도 하지 않는다
    const v = rand(dx.min, dx.max);
    setEmblem(X.who, dx, v);
    setEmblem(Y.who, null, null);
    bleed(X, dx);
    if (S.phaseEnded) return;
    await sleep(180);
    STG.begin();
    const result = hit(X, Y, v, dx);
    if (X.who === 'roland') showReadout(dx, v, null, null, result);
    else showReadout(null, null, dx, v, result);
    addLog(`일방 ${D.DICE[dx.t].label} ${v}: ${result}`);
    await STG.play();
  }

  // ---------- 장면 종료 ----------

  function cleanupDice() {
    const R = S.roland;
    for (const d of S.rDice) {
      const c = d.card;
      if (!c) continue;
      const def = rCard(c);
      if (!c.resolved) {
        // 취소된 책장은 손으로 돌려주고 빛도 돌려준다
        R.light = Math.min(R.maxLight, R.light + def.cost);
        S.hand.push(c);
        continue;
      }
      c.resolved = false;
      if (def.special === 'furioso') {
        S.used.clear();
        addLog('Furioso를 썼다. 공방 기록이 처음부터 다시 쌓인다.');
        continue;
      }
      S.used.add(c.id);
      S.discard.push(c);
    }
    S.rDice = [];
    if (S.used.size === WORKSHOPS.length && !S.hand.some((c) => c.id === 'furioso')) {
      S.hand.push(inst('furioso'));
      say('roland', pick(D.LINES.roland.furiosoReady));
      addLog('아홉 공방을 모두 썼다. Furioso가 손에 들어왔다!');
    }
  }

  function endScene() {
    const R = S.roland, T = S.tiger;
    cleanupDice();
    if (S.over) return finish();
    if (S.phaseEnded) return nextPhase();
    for (const td of S.tDice) {
      const tc = td.card;
      if (tc.def.gimmick !== 'heal' || !tc.used) continue;
      if (!tc.broken && !T.broken) {
        const amt = Math.round(T.maxHp * tc.def.heal);
        T.hp = Math.min(T.maxHp, T.hp + amt);
        fxFloat('tiger', `+${amt}`, 'heal');
        say('tiger', pick(D.LINES.tiger.ate));
        addLog(`짬타이거가 짬밥을 다 먹고 체력을 ${amt} 회복했다.`);
      } else {
        say('roland', pick(D.LINES.roland.eatBlocked));
        addLog('짬통이 엎어졌다. 짬타이거는 밥을 먹지 못했다.');
      }
    }
    for (const [u, name] of [[R, '롤랑'], [T, '짬타이거']]) {
      if (!u.skip) continue;
      u.broken = false;
      u.skip = false;
      u.st = u.maxSt;
      addLog(`${name}: 흐트러짐에서 회복했다.`);
    }
    startScene(false);
  }

  async function nextPhase() {
    if (S.phase === D.PHASES.length - 1) {
      S.over = 'win';
      return finish();
    }
    const R = S.roland;
    say('tiger', pick(D.LINES.tiger.phaseDown));
    addLog(`${D.PHASES[S.phase].rank} 짬타이거를 쓰러뜨렸다.`);
    renderHUD();
    await sleep(700);
    S.phase++;
    setupTiger(S.phase);
    S.phaseEnded = false;
    R.hp = Math.min(R.maxHp, R.hp + D.ROLAND.phaseHeal);
    R.st = R.maxSt;
    R.broken = false;
    R.pending = {};
    R.maxLight = D.ROLAND.baseLight + S.phase;
    R.light = R.maxLight;
    await STG.setRank(D.PHASES[S.phase].rank);
    tigerArtCache.clear();
    actCard(S.phase + 1);
    say('tiger', D.PHASES[S.phase].intro);
    addLog(`짬타이거가 ${D.PHASES[S.phase].rank}으로 진급했다. 롤랑은 체력 ${D.ROLAND.phaseHeal}을 회복하고 빛을 모두 채웠다.`);
    startScene(false);
  }

  function finish() {
    S.busy = false;
    const win = S.over === 'win';
    if (win) {
      say('tiger', pick(D.LINES.tiger.final));
      say('roland', pick(D.LINES.roland.win));
    } else {
      say('roland', pick(D.LINES.roland.lose));
    }
    render();
    $('ovTitle').textContent = win ? 'VICTORY' : 'DEFEAT';
    $('ovSub').textContent = win ? '짬타이거 접대 완료' : '롤랑이 쓰러졌다';
    $('ovText').textContent = win
      ? `${S.scene}장면 만에 병장 짬타이거까지 쓰러뜨렸다. 부대에 평화가 찾아왔다.`
      : `${D.PHASES[S.phase].rank} 짬타이거에게 당했다. 짬밥의 힘은 생각보다 강했다.`;
    $('overlay').classList.toggle('lose', !win);
    $('overlay').hidden = false;
    $('restartBtn').focus();
  }

  // ---------- 무대 연출 ----------

  function restart(el, cls) {
    el.classList.remove(cls);
    void el.offsetWidth;
    el.classList.add(cls);
  }

  const fxFloat = (who, text, cls) => STG.float(who, text, cls);

  // 책장 그림: 롤랑은 원작 책장 일러스트, 짬타이거는 그 책장 자세의 짬타이거
  const tigerArtCache = new Map();
  function tigerArt(def) {
    const rank = D.PHASES[S.phase].rank;
    const key = def.tpose + rank;
    if (!tigerArtCache.has(key)) {
      const svg = TG.build(def.tpose || 'idle', rank).svg;
      tigerArtCache.set(key, 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg));
    }
    return tigerArtCache.get(key);
  }
  function cardArt(def, cls = '') {
    if (def.tpose) return `<img class="art tiger ${cls}" src="${tigerArt(def)}" alt="">`;
    if (def.id && STG.hasCardArt(def.id)) return `<img class="art ${cls}" src="assets/ruina/cards/${def.id}.png" alt="">`;
    return A.glyph(def.weapon || def.prop);
  }

  function showBanners(Aside, Bside) {
    const fill = (el, sd) => {
      if (!sd.def || (!sd.q.length && !sd.ref)) { el.hidden = true; return; }
      el.className = `cbanner ${sd.who} rar-${sd.def.rarity || 'enemy'}`;
      el.innerHTML =
        `<div class="cbHead"><b class="cbName">${sd.def.name}</b></div>` +
        `<div class="cbBody"><div class="cbArt">${cardArt(sd.def)}</div>` +
        `<div class="cbSide"><div class="emblem"><span class="emIcon"></span><b class="emVal"></b></div>` +
        `<span class="cbQueue">${sd.q.map((x) => A.dieIcon(x)).join('')}</span></div></div>`;
      el.hidden = false;
    };
    fill($('bannerR'), Aside);
    fill($('bannerT'), Bside);
  }

  function hideBanners() {
    $('bannerR').hidden = true;
    $('bannerT').hidden = true;
  }

  function setEmblem(who, die, v) {
    const el = $(who === 'roland' ? 'bannerR' : 'bannerT');
    if (el.hidden) return;
    const em = el.querySelector('.emblem');
    if (!die) { em.classList.remove('on'); return; }
    em.querySelector('.emIcon').innerHTML = A.dieIcon(die);
    em.querySelector('.emVal').textContent = v;
    em.className = `emblem on ${kindOf(die)}${die.counter ? ' counter' : ''}`;
    restart(em, 'pulse');
  }

  function markQueue(Aside, Bside) {
    for (const sd of [Aside, Bside]) {
      const el = $(sd.who === 'roland' ? 'bannerR' : 'bannerT');
      if (el.hidden) continue;
      el.querySelectorAll('.cbQueue .di').forEach((n, k) => n.classList.toggle('spent', k < sd.i));
    }
  }

  async function furiosoIntro() {
    STG.furioso(true);
    const t = $('furiosoTitle');
    t.hidden = false;
    restart(t, 'show');
    await sleep(900);
    t.hidden = true;
  }

  function actCard(n) {
    const el = $('actCard');
    el.querySelector('.acBig').textContent = `제 ${n}막`;
    el.querySelector('.acSub').textContent = `${D.PHASES[n - 1].rank} 짬타이거`;
    el.hidden = false;
    restart(el, 'show');
    clearTimeout(actCard.t);
    actCard.t = setTimeout(() => { el.hidden = true; }, 1700);
  }

  function say(who, text) {
    const el = $(who + 'Line');
    el.textContent = text;
    restart(el, 'fresh');
  }

  function addLog(text) {
    const li = document.createElement('li');
    li.textContent = `[${S.scene || 1}] ${text}`;
    const log = $('log');
    log.prepend(li);
    while (log.children.length > 80) log.lastChild.remove();
  }

  function readoutHelp() {
    const R = S.roland;
    let msg = '롤랑 머리 위 속도 주사위를 고르고 손패에서 책장을 누르세요. 짬타이거 주사위를 누르면 대상을 바꿉니다.';
    if (R.skip) msg = '롤랑이 흐트러져 이번 장면은 행동할 수 없습니다. 합 진행을 눌러 넘기세요.';
    $('readout').innerHTML = `<p class="roHelp">${msg}</p>`;
  }

  function notice(msg) {
    $('readout').innerHTML = `<p class="roHelp warn">${msg}</p>`;
  }

  const dieTag = (die, v) => die
    ? `<span class="roDie">${A.dieIcon(die)}<b>${v}</b></span>`
    : '<span class="roDie none">—</span>';

  function showReadout(da, va, db, vb, result) {
    $('readout').innerHTML =
      `<div class="ro"><span class="roWho">롤랑</span>${dieTag(da, va)}<span class="vsx">VS</span>${dieTag(db, vb)}<span class="roWho">짬타이거</span></div>` +
      `<p class="roRes">${result}</p>`;
  }

  // ---------- 화면 갱신 ----------

  function render() {
    renderHUD();
    renderDice();
    renderPanel();
    renderHand();
    renderTracker();
    const go = $('goBtn');
    go.disabled = S.busy || !!S.over;
    go.textContent = S.busy ? '합 진행 중…' : '합 진행';
  }

  function renderHUD() {
    const R = S.roland, T = S.tiger, ph = D.PHASES[S.phase];
    $('sceneNo').textContent = `장면 ${S.scene}`;
    $('tigerRank').textContent = ph.rank;
    const ring = (id, u) => {
      $(id).style.setProperty('--hp', `${(u.hp / u.maxHp) * 100}%`);
      $(id).style.setProperty('--st', `${(u.st / u.maxSt) * 100}%`);
    };
    ring('rRing', R);
    ring('tRing', T);
    $('rHp').textContent = R.hp;
    $('rSt').textContent = R.st;
    $('tHp').textContent = T.hp;
    $('tSt').textContent = T.st;
    if (S.faceRank !== ph.rank) {
      S.faceRank = ph.rank;
      $('tFace').innerHTML = `<span class="faceImg tiger" style="background-image:url('${tigerArt({ tpose: 'idle' })}')"></span>`;
    }
    STG.setFeet('roland', R.hp, R.st, R.maxHp, R.maxSt);
    STG.setFeet('tiger', T.hp, T.st, T.maxHp, T.maxSt);
    STG.setBroken('roland', R.broken);
    STG.setBroken('tiger', T.broken);

    const avail = availableLight();
    $('lightPips').innerHTML = Array.from({ length: R.maxLight }, (_, i) =>
      `<i class="${i < avail ? 'on' : i < R.light ? 'res' : ''}"></i>`).join('');

    const tChips = [];
    if (T.maxAmmo) {
      const pips = Array.from({ length: T.maxAmmo }, (_, i) => `<i class="${i < T.ammo ? 'on' : ''}"></i>`).join('');
      tChips.push(`<span class="chip ammo">탄약 <span class="pips">${pips}</span></span>`);
    }
    if (T.broken) tChips.push('<span class="chip bad">흐트러짐 · 받는 피해 2배</span>');
    for (const [k, n] of Object.entries(T.status || {})) if (n) tChips.push(`<span class="chip bad">${D.STATUS[k].name} ${n}</span>`);
    for (const [k, n] of Object.entries(T.pending || {})) if (n) tChips.push(`<span class="chip warn">다음 장면 · ${D.STATUS[k].name} ${n}</span>`);
    $('tigerExtra').innerHTML = tChips.join('');
    const rChips = [];
    if (R.broken) rChips.push('<span class="chip bad">흐트러짐 · 받는 피해 2배</span>');
    for (const k of Object.keys(R.status)) rChips.push(`<span class="chip bad">${D.STATUS[k].name} · ${D.STATUS[k].desc}</span>`);
    for (const k of Object.keys(R.pending)) rChips.push(`<span class="chip warn">다음 장면 · ${D.STATUS[k].name}</span>`);
    $('rolandExtra').innerHTML = rChips.join('');
    $('phaseDots').innerHTML = D.PHASES.map((p, i) =>
      `<li class="${i < S.phase ? 'done' : i === S.phase ? 'now' : ''}">${p.rank}</li>`).join('');
  }

  const RAR_COLOR = { paperback: 0x5fbf4a, hardcover: 0x4a8fe0, limited: 0x9a5ae0, art: 0xe6bd5c };

  function renderDice() {
    const acting = S.acting;
    STG.renderDice({
      busy: S.busy,
      rDice: S.rDice.map((d, i) => ({
        speed: d.speed,
        cardKey: d.card ? 'card_' + d.card.id : null,
        rarityColor: d.card ? RAR_COLOR[rCard(d.card).rarity] : 0x555555,
        sel: S.sel === i,
        acting: !!(acting && acting.r === i && acting.type !== 'oneT'),
      })),
      tDice: S.tDice.map((d, t) => ({
        speed: d.speed,
        tigerPose: d.card.def.tpose,
        rarityColor: 0x8e9b54,
        sel: S.peek === t,
        acting: !!(acting && acting.t === t && acting.type !== 'oneR'),
      })),
      actions: S.busy ? [] : computeActions(),
      onR: onRDieTap,
      onT: onTDieTap,
    });
  }

  function cardFull(def, label) {
    const cost = def.cost != null ? `<span class="cost">${def.cost}</span>` : '';
    const dice = def.dice.length
      ? `<ul class="cfDice">${def.dice.map((x) => {
        const off = S.roland.status.duckwalk && def.cost != null && x.t === 'evade' ? ' off' : '';
        return `<li class="${off}">${A.dieIcon(x)}<span>${D.DICE[x.t].label}${x.counter ? ' (반격)' : ''}</span><b>${x.min}–${x.max}</b></li>`;
      }).join('')}</ul>`
      : '<p class="cfText">주사위 없음</p>';
    return `<div class="cardFull rar-${def.rarity || 'enemy'}">
      <span class="cfLabel">${label}</span>
      <div class="cfTop"><div class="cfArt">${cardArt(def)}</div><div class="cfHead">${cost}<b>${def.name}</b></div></div>
      ${dice}${def.text ? `<p class="cfText">${def.text}</p>` : ''}
    </div>`;
  }

  function renderPanel() {
    const panel = $('panel');
    if (S.busy || S.over) { panel.classList.add('dim'); return; }
    panel.classList.remove('dim');
    const rd = S.rDice[S.sel];
    let rHtml, tHtml, verdict = '';
    let t = -1;
    if (rd && rd.card) t = rd.target != null ? rd.target : -1;
    else if (S.peek >= 0) t = S.peek;
    else if (rd) t = S.tDice.findIndex((td) => td.target === S.sel);
    if (S.peek >= 0) t = S.peek;

    if (rd && rd.card) {
      rHtml = cardFull(rCard(rd.card), `롤랑 · 속도 ${rd.speed}`);
      const act = computeActions().find((a) => a.r === S.sel && a.type !== 'oneT');
      verdict = act && act.type === 'clash' ? '합' : '일방 공격';
    } else if (rd) {
      rHtml = `<div class="cardFull hint"><span class="cfLabel">롤랑 · 속도 ${rd.speed}</span><p>손패에서 책장을 눌러 이 주사위에 놓으세요.</p></div>`;
    } else {
      rHtml = `<div class="cardFull hint"><span class="cfLabel">롤랑</span><p>${S.roland.skip ? '흐트러져 행동할 수 없습니다.' : '속도 주사위를 고르세요.'}</p></div>`;
    }
    const td = S.tDice[t];
    if (td) {
      tHtml = cardFull(td.card.def, `짬타이거 · 속도 ${td.speed}`);
      if (!verdict) verdict = td.target === S.sel ? '이 주사위를 노림' : '';
    } else {
      tHtml = `<div class="cardFull hint"><span class="cfLabel">짬타이거</span><p>${S.tiger.skip ? '흐트러져 행동할 수 없습니다.' : '짬타이거 주사위를 누르면 책장을 볼 수 있어요.'}</p></div>`;
    }
    panel.innerHTML = `${rHtml}<div class="verdict">${verdict ? `<span>${verdict}</span>` : ''}</div>${tHtml}`;
  }

  function renderHand() {
    const avail = availableLight();
    const canPlace = !S.busy && !S.over && S.rDice.length > 0;
    $('hand').innerHTML = S.hand.map((c) => {
      const def = rCard(c);
      const ok = canPlace && def.cost <= avail;
      return `<button type="button" class="hcard rar-${def.rarity}" data-uid="${c.uid}" id="hand${c.uid}" ${ok ? '' : 'aria-disabled="true"'}>
        <span class="hcTop"><span class="cost">${def.cost}</span><span class="hcName">${def.name}</span></span>
        <span class="hcArt">${cardArt(def)}</span>
        <span class="hcDice">${def.dice.map((x) => A.dieIcon(x)).join('')}</span>
      </button>`;
    }).join('') || '<p class="emptyHand">손패가 비었습니다.</p>';
    $('deckInfo').textContent = `덱 ${S.deck.length} · 버림 ${S.discard.length}`;
  }

  function renderTracker() {
    $('tracker').innerHTML = WORKSHOPS.map((id) => {
      const def = D.ROLAND_CARDS[id];
      return `<li class="${S.used.has(id) ? 'done' : ''}" title="${def.name}">${A.glyph(def.weapon)}<span>${def.name}</span></li>`;
    }).join('');
    $('trackerNum').textContent = `${S.used.size}/${WORKSHOPS.length}`;
  }

  // ---------- 입력 ----------

  $('stage').addEventListener('click', (e) => {
    const r = e.target.closest('[data-r]');
    if (r) return onRDieTap(Number(r.dataset.r));
    const t = e.target.closest('[data-t]');
    if (t) onTDieTap(Number(t.dataset.t));
  });
  $('hand').addEventListener('click', (e) => {
    const b = e.target.closest('[data-uid]');
    if (b) onHandTap(Number(b.dataset.uid));
  });
  $('goBtn').addEventListener('click', commit);
  $('restartBtn').addEventListener('click', newGame);
  $('fastBtn').addEventListener('click', () => {
    fast = !fast;
    STG.setFast(fast);
    $('fastBtn').setAttribute('aria-pressed', String(fast));
  });
  $('rFace').innerHTML = A.faceRoland;
  $('tFace').innerHTML = A.faceTiger;
  STG.init($('phaser'));
  STG.ready.then(() => {
    if (STG.hasCardArt('durandal')) {
      $('rFace').innerHTML = '<span class="faceImg roland"></span>';
    }
    render();
  });
  newGame();
})();
