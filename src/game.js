'use strict';
(() => {
  const D = window.JJAM_DATA;
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
  const sleep = (ms) => new Promise((r) => setTimeout(r, fast || reduceMotion ? Math.min(ms, 90) : ms));

  let uidSeq = 0;
  const inst = (id) => ({ uid: ++uidSeq, id, resolved: false });
  const tInst = (id) => ({ id, def: D.TIGER_CARDS[id], used: false, broken: false });
  const rCard = (c) => D.ROLAND_CARDS[c.id];
  const kindOf = (die) => D.DICE[die.t].kind;
  const nm = (side) => (side.who === 'roland' ? '롤랑' : '짬타이거');

  let S;

  // ---------- 게임 진행 ----------

  function newGame() {
    const r = D.ROLAND;
    S = {
      scene: 0, phase: 0, busy: false, over: null, phaseEnded: false,
      roland: {
        hp: r.hp, maxHp: r.hp, st: r.stagger, maxSt: r.stagger, broken: false, skip: false,
        light: r.startLight, maxLight: r.maxLight, status: {}, pending: {},
      },
      tiger: null,
      deck: shuffle(D.ROLAND_DECK.map(inst)), discard: [], hand: [],
      used: new Set(), slots: [], intents: [], selected: -1, active: -1,
    };
    setupTiger(0);
    draw(r.startHand);
    $('log').innerHTML = '';
    $('overlay').hidden = true;
    say('roland', pick(D.LINES.roland.start));
    say('tiger', D.PHASES[0].intro);
    addLog(`${D.PHASES[0].rank} 짬타이거가 나타났다.`);
    startScene(true);
  }

  function setupTiger(p) {
    const ph = D.PHASES[p];
    S.tiger = {
      hp: ph.hp, maxHp: ph.hp, st: ph.stagger, maxSt: ph.stagger, broken: false, skip: false,
      ammo: ph.maxAmmo, maxAmmo: ph.maxAmmo,
    };
  }

  function draw(n) {
    for (let k = 0; k < n; k++) {
      if (!S.deck.length) {
        if (!S.discard.length) return;
        S.deck = shuffle(S.discard);
        S.discard = [];
        addLog('버린 카드를 섞어 덱으로 되돌렸다.');
      }
      S.hand.push(S.deck.pop());
    }
  }

  function startScene(first) {
    const R = S.roland, T = S.tiger;
    S.scene++;
    if (!first) {
      R.light = Math.min(R.maxLight, R.light + D.ROLAND.lightRegen);
      draw(D.ROLAND.drawPerScene);
    }
    R.status = R.pending;
    R.pending = {};
    R.skip = R.broken;
    T.skip = T.broken;
    const rDice = R.skip ? 0 : Math.max(1, D.ROLAND.speedDice - (R.status.pushup ? 1 : 0));
    const tDice = T.skip ? 0 : D.PHASES[S.phase].dice;
    S.slots = Array(rDice).fill(null);
    S.intents = tigerChoose(tDice);
    S.selected = rDice ? 0 : -1;
    S.active = -1;
    S.busy = false;
    if (R.status.pushup) {
      say('roland', pick(D.LINES.roland.pushup));
      addLog('엎드려뻗쳐 여파로 롤랑의 속도 주사위가 하나 줄었다.');
    }
    if (R.status.duckwalk) {
      say('roland', pick(D.LINES.roland.duckwalk));
      addLog('오리걸음 여파로 이번 장면에는 회피 주사위를 쓸 수 없다.');
    }
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

  // ---------- 카드 배치 ----------

  function reservedLight() {
    if (S.busy) return 0;
    return S.slots.reduce((s, c) => s + (c ? rCard(c).cost : 0), 0);
  }
  const availableLight = () => S.roland.light - reservedLight();

  function onSlotTap(i) {
    if (S.busy || S.over) return;
    if (S.slots[i]) {
      S.hand.push(S.slots[i]);
      S.slots[i] = null;
    }
    S.selected = i;
    render();
  }

  function onHandTap(uid) {
    if (S.busy || S.over || !S.slots.length) return;
    const idx = S.hand.findIndex((c) => c.uid === uid);
    if (idx < 0) return;
    const c = S.hand[idx];
    if (rCard(c).cost > availableLight()) {
      notice('빛이 부족하다. 비용이 낮은 카드를 고르거나 배치한 카드를 빼자.');
      return;
    }
    const slot = S.selected >= 0 && !S.slots[S.selected] ? S.selected : S.slots.findIndex((x) => !x);
    if (slot < 0) {
      notice('빈 주사위가 없다. 아래 주사위를 눌러 카드를 빼자.');
      return;
    }
    S.slots[slot] = c;
    S.hand.splice(idx, 1);
    S.selected = S.slots.findIndex((x) => !x);
    render();
  }

  // ---------- 합 처리 ----------

  async function commit() {
    if (S.busy || S.over) return;
    const R = S.roland;
    R.light -= reservedLight();
    S.busy = true;
    render();
    const n = Math.max(S.slots.length, S.intents.length);
    for (let i = 0; i < n; i++) {
      if (S.over || S.phaseEnded) break;
      const rc = S.slots[i] || null;
      const tc = S.intents[i] || null;
      if (!rc && !tc) continue;
      S.active = i;
      render();
      await resolvePair(rc, tc);
      render();
    }
    S.active = -1;
    await sleep(300);
    endScene();
  }

  function side(who, def, ref) {
    const u = who === 'roland' ? S.roland : S.tiger;
    let q = def ? def.dice.slice() : [];
    if (who === 'roland' && S.roland.status.duckwalk) q = q.filter((x) => x.t !== 'evade');
    return { who, u, def, ref, q, i: 0, hitApplied: false };
  }

  async function resolvePair(rc, tc) {
    const R = S.roland, T = S.tiger;
    if (rc && R.broken) { addLog(`롤랑이 흐트러져 ${rCard(rc).name} 카드가 취소됐다.`); rc = null; }
    if (tc && T.broken) { addLog(`짬타이거가 흐트러져 ${tc.def.name} 카드가 취소됐다.`); tc = null; }
    if (!rc && !tc) return;
    const A = side('roland', rc ? rCard(rc) : null, rc);
    const B = side('tiger', tc ? tc.def : null, tc);
    if (rc) useRoland(rc);
    if (tc) useTiger(tc);
    if (rc && tc) addLog(`합: ${A.def.name} 대 ${B.def.name}`);
    else if (rc) addLog(`일방 공격: ${A.def.name}`);
    else addLog(`일방 공격: 짬타이거의 ${B.def.name}`);
    await sleep(350);
    while (!S.over && !S.phaseEnded) {
      const aHas = A.i < A.q.length && !R.broken;
      const bHas = B.i < B.q.length && !T.broken;
      if (aHas && bHas) await dicePair(A, B);
      else if (aHas) await oneSided(A, B);
      else if (bHas) await oneSided(B, A);
      else break;
    }
  }

  function useRoland(rc) {
    rc.resolved = true;
    const def = rCard(rc);
    if (def.special === 'furioso') say('roland', pick(D.LINES.roland.furioso));
    else if (Math.random() < 0.2) say('roland', pick(D.LINES.roland.attack));
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
  async function dicePair(A, B) {
    const da = A.q[A.i], db = B.q[B.i];
    const va = rand(da.min, da.max), vb = rand(db.min, db.max);
    const ka = kindOf(da), kb = kindOf(db);
    let useA = true, useB = true, result;
    if (ka === 'atk' && kb === 'atk') {
      if (va > vb) result = hit(A, B, va);
      else if (vb > va) result = hit(B, A, vb);
      else result = '동점, 서로 상쇄';
    } else if (ka === 'atk') {
      [useA, useB, result] = atkVsDef(A, B, va, vb, da, db);
    } else if (kb === 'atk') {
      [useB, useA, result] = atkVsDef(B, A, vb, va, db, da);
    } else if (da.t === 'block' && db.t === 'block' && va !== vb) {
      const [w, l] = va > vb ? [A, B] : [B, A];
      result = staggerHit(l, Math.abs(va - vb), w);
    } else {
      result = '서로 수비, 효과 없음';
    }
    showReadout(da, va, db, vb, result);
    addLog(`${D.DICE[da.t].label} ${va} 대 ${D.DICE[db.t].label} ${vb}: ${result}`);
    if (useA) A.i++;
    if (useB) B.i++;
    await sleep(700);
  }

  // X가 공격, Y가 수비. [X 주사위 소모, Y 주사위 소모, 결과 문구]
  function atkVsDef(X, Y, vx, vy, dx, dy) {
    if (dy.t === 'block') {
      if (vx > vy) return [true, true, hit(X, Y, vx - vy)];
      if (vy > vx) {
        onWin(Y, dy);
        return [true, true, staggerHit(X, vy - vx, Y)];
      }
      return [true, true, `${nm(Y)} 방어, 완벽하게 막아냄`];
    }
    if (vy > vx) {
      onWin(Y, dy);
      if (!Y.u.broken) Y.u.st = Math.min(Y.u.maxSt, Y.u.st + vy);
      pop(Y.who, '회피', 'evade');
      return [true, false, `${nm(Y)} 회피 성공, 흐트러짐 ${vy} 회복 (회피 주사위 재사용)`];
    }
    if (vx > vy) return [true, true, hit(X, Y, vx)];
    return [true, true, '동점, 서로 상쇄'];
  }

  function onWin(side, die) {
    if (die.onWin === 'light' && side.who === 'roland') {
      const R = S.roland;
      if (R.light < R.maxLight) {
        R.light++;
        pop('roland', '빛 +1', 'light');
      }
    }
  }

  function hit(X, Y, dmg) {
    const u = Y.u;
    const mult = u.broken ? 2 : 1;
    const real = dmg * mult;
    u.hp = Math.max(0, u.hp - real);
    pop(Y.who, `-${real}`, 'dmg');
    let txt = `${nm(X)} 승리, ${nm(Y)} 피해 ${real}${mult > 1 ? ' (흐트러짐 2배)' : ''}`;
    txt += damageStagger(Y, dmg);
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
    pop(Y.who, `-${n}`, 'st');
    return `${nm(W)} 방어 성공, ${nm(Y)} 흐트러짐 피해 ${n}` + damageStagger(Y, n);
  }

  function damageStagger(Y, n) {
    const u = Y.u;
    if (u.broken) return '';
    u.st = Math.max(0, u.st - n);
    if (u.st > 0) return '';
    u.broken = true;
    pop(Y.who, '흐트러짐', 'brk');
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
    if (kindOf(dx) !== 'atk') return; // 남은 수비 주사위는 아무 일도 하지 않는다
    const v = rand(dx.min, dx.max);
    const result = hit(X, Y, v);
    if (X.who === 'roland') showReadout(dx, v, null, null, result);
    else showReadout(null, null, dx, v, result);
    addLog(`일방 ${D.DICE[dx.t].label} ${v}: ${result}`);
    await sleep(550);
  }

  // ---------- 장면 종료 ----------

  function cleanupSlots() {
    const R = S.roland;
    for (const c of S.slots) {
      if (!c) continue;
      const def = rCard(c);
      if (!c.resolved) {
        // 취소된 카드는 손으로 돌려주고 빛도 돌려준다
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
      if (def.workshop) S.used.add(c.id);
      S.discard.push(c);
    }
    S.slots = [];
    if (S.used.size === D.WORKSHOPS.length && !S.hand.some((c) => c.id === 'furioso')) {
      S.hand.push(inst('furioso'));
      say('roland', pick(D.LINES.roland.furiosoReady));
      addLog('아홉 공방을 모두 썼다. Furioso가 손에 들어왔다!');
    }
  }

  function endScene() {
    const R = S.roland, T = S.tiger;
    cleanupSlots();
    if (S.over) return finish();
    if (S.phaseEnded) return nextPhase();
    for (const tc of S.intents) {
      if (tc.def.gimmick !== 'heal' || !tc.used) continue;
      if (!tc.broken && !T.broken) {
        const amt = Math.round(T.maxHp * tc.def.heal);
        T.hp = Math.min(T.maxHp, T.hp + amt);
        pop('tiger', `+${amt}`, 'heal');
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
    render();
    await sleep(900);
    S.phase++;
    setupTiger(S.phase);
    S.phaseEnded = false;
    R.hp = Math.min(R.maxHp, R.hp + D.ROLAND.phaseHeal);
    R.st = R.maxSt;
    R.broken = false;
    R.pending = {};
    banner(`${D.PHASES[S.phase].rank} 진급`);
    say('tiger', D.PHASES[S.phase].intro);
    addLog(`짬타이거가 ${D.PHASES[S.phase].rank}으로 진급했다. 롤랑은 체력 ${D.ROLAND.phaseHeal}을 회복했다.`);
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
    $('ovTitle').textContent = win ? '짬타이거 전역' : '롤랑 패배';
    $('ovText').textContent = win
      ? `${S.scene}장면 만에 병장 짬타이거까지 쓰러뜨렸다. 부대에 평화가 찾아왔다.`
      : `${D.PHASES[S.phase].rank} 짬타이거에게 당했다. 짬밥의 힘은 생각보다 강했다.`;
    $('overlay').hidden = false;
    $('restartBtn').focus();
  }

  // ---------- 화면 ----------

  function say(who, text) {
    const el = $(who + 'Line');
    el.textContent = text;
    el.classList.remove('fresh');
    void el.offsetWidth;
    el.classList.add('fresh');
  }

  function pop(who, text, cls) {
    const wrap = $(who + 'Pop');
    const el = document.createElement('span');
    el.className = 'popItem ' + cls;
    el.textContent = text;
    wrap.appendChild(el);
    setTimeout(() => el.remove(), 1100);
    const panel = $(who + 'Panel');
    if (cls === 'dmg' || cls === 'brk') {
      panel.classList.remove('shake');
      void panel.offsetWidth;
      panel.classList.add('shake');
    }
  }

  function addLog(text) {
    const li = document.createElement('li');
    li.textContent = `[${S.scene || 1}] ${text}`;
    const log = $('log');
    log.prepend(li);
    while (log.children.length > 80) log.lastChild.remove();
  }

  function banner(text) {
    const el = $('banner');
    el.textContent = text;
    el.hidden = false;
    el.classList.remove('show');
    void el.offsetWidth;
    el.classList.add('show');
    setTimeout(() => { el.hidden = true; }, 1600);
  }

  function readoutHelp() {
    const R = S.roland;
    let msg = '아래 주사위를 고르고 손패에서 카드를 눌러 배치하세요. 같은 줄의 짬타이거 카드와 합을 겨룹니다.';
    if (R.skip) msg = '롤랑이 흐트러져 이번 장면은 행동할 수 없습니다. 합 진행을 눌러 넘기세요.';
    $('readout').innerHTML = `<p class="roHelp">${msg}</p>`;
  }

  function notice(msg) {
    $('readout').innerHTML = `<p class="roHelp warn">${msg}</p>`;
  }

  const dieTag = (die, v) => die
    ? `<span class="roDie"><i class="d ${die.t}">${D.DICE[die.t].label}</i><b>${v}</b></span>`
    : '<span class="roDie none">—</span>';

  function showReadout(da, va, db, vb, result) {
    $('readout').innerHTML =
      `<div class="ro"><span class="roWho">롤랑</span>${dieTag(da, va)}<span class="vsx">VS</span>${dieTag(db, vb)}<span class="roWho">짬타이거</span></div>` +
      `<p class="roRes">${result}</p>`;
  }

  function diceList(def, opts = {}) {
    return `<ul class="dice">${def.dice.map((x) => {
      const off = opts.duck && x.t === 'evade' ? ' off' : '';
      return `<li class="d ${x.t}${off}"><span>${D.DICE[x.t].short}</span><b>${x.min}–${x.max}</b></li>`;
    }).join('')}</ul>`;
  }

  function cardHTML(def, opts = {}) {
    const cost = def.cost != null ? `<span class="cost" title="빛 비용">${def.cost}</span>` : '';
    const text = def.text ? `<p class="cText">${def.text}</p>` : '';
    return `<div class="cHead"><span class="cName">${def.name}</span>${cost}</div>${def.dice.length ? diceList(def, opts) : ''}${text}`;
  }

  function setBar(id, v, max) {
    $(id).style.setProperty('--pct', `${Math.max(0, (v / max) * 100)}%`);
    $(id + 'Num').textContent = `${v}/${max}`;
  }

  function render() {
    const R = S.roland, T = S.tiger, ph = D.PHASES[S.phase];
    $('sceneNo').textContent = `장면 ${S.scene}`;
    $('tigerRank').textContent = ph.rank;
    $('phaseDots').innerHTML = D.PHASES.map((p, i) =>
      `<li class="${i < S.phase ? 'done' : i === S.phase ? 'now' : ''}">${p.rank}</li>`).join('');
    setBar('tigerHp', T.hp, T.maxHp);
    setBar('tigerSt', T.st, T.maxSt);
    setBar('rolandHp', R.hp, R.maxHp);
    setBar('rolandSt', R.st, R.maxSt);

    const tChips = [];
    if (T.maxAmmo) {
      const pips = Array.from({ length: T.maxAmmo }, (_, i) => `<i class="${i < T.ammo ? 'on' : ''}"></i>`).join('');
      tChips.push(`<span class="chip ammo">탄약 <span class="pips">${pips}</span></span>`);
    }
    if (T.broken) tChips.push('<span class="chip bad">흐트러짐 · 받는 피해 2배</span>');
    $('tigerExtra').innerHTML = tChips.join('');

    const avail = availableLight();
    $('lightPips').innerHTML = Array.from({ length: R.maxLight }, (_, i) =>
      `<i class="${i < avail ? 'on' : i < R.light ? 'res' : ''}"></i>`).join('');
    $('lightNum').textContent = `${avail}/${R.maxLight}`;
    const rChips = [];
    if (R.broken) rChips.push('<span class="chip bad">흐트러짐 · 받는 피해 2배</span>');
    for (const k of Object.keys(R.status)) rChips.push(`<span class="chip bad">${D.STATUS[k].name} · ${D.STATUS[k].desc}</span>`);
    for (const k of Object.keys(R.pending)) rChips.push(`<span class="chip warn">다음 장면 · ${D.STATUS[k].name}</span>`);
    $('rolandExtra').innerHTML = rChips.join('');

    renderLane();
    renderHand();
    renderTracker();

    const go = $('goBtn');
    go.disabled = S.busy || !!S.over;
    go.textContent = S.busy ? '합 진행 중…' : '합 진행';
  }

  function renderLane() {
    const T = S.tiger;
    const n = Math.max(S.slots.length, S.intents.length, 1);
    const lane = $('lane');
    lane.style.setProperty('--cols', n);
    let html = '';
    for (let i = 0; i < n; i++) {
      const tc = S.intents[i];
      const rc = S.slots[i];
      const hasSlot = i < S.slots.length;
      const top = tc
        ? `<div class="card enemy${tc.broken ? ' spent' : ''}">${cardHTML(tc.def)}</div>`
        : `<div class="empty">${T.skip ? '흐트러져 행동 불가' : '행동 없음'}</div>`;
      let mid = '';
      if (tc && rc) mid = '합';
      else if (tc && hasSlot) mid = '빈 주사위면 일방 공격 받음';
      else if (tc) mid = '일방 공격 받음';
      else if (rc) mid = '일방 공격';
      let bottom;
      if (!hasSlot) {
        bottom = `<div class="empty">${S.roland.skip ? '흐트러져 행동 불가' : '주사위 없음'}</div>`;
      } else if (rc) {
        bottom = `<button type="button" class="card slot filled${S.selected === i ? ' sel' : ''}" data-slot="${i}" id="slot${i}" aria-label="${rCard(rc).name} 빼기">${cardHTML(rCard(rc), { duck: S.roland.status.duckwalk })}</button>`;
      } else {
        bottom = `<button type="button" class="card slot${S.selected === i ? ' sel' : ''}" data-slot="${i}" id="slot${i}"><span class="slotHint">속도 주사위 ${i + 1}<br>카드 배치</span></button>`;
      }
      html += `<div class="col${S.active === i ? ' active' : ''}">${top}<div class="vs">${mid}</div>${bottom}</div>`;
    }
    lane.innerHTML = html;
  }

  function renderHand() {
    const avail = availableLight();
    const canPlace = !S.busy && !S.over && S.slots.length > 0;
    $('hand').innerHTML = S.hand.map((c) => {
      const def = rCard(c);
      const ok = canPlace && def.cost <= avail;
      const tag = def.workshop ? `<span class="wsTag${S.used.has(c.id) ? ' done' : ''}">공방</span>` : '';
      const cls = def.special === 'furioso' ? ' furioso' : '';
      return `<button type="button" class="card hcard${cls}" data-uid="${c.uid}" id="hand${c.uid}" ${ok ? '' : 'aria-disabled="true"'}>${tag}${cardHTML(def, { duck: S.roland.status.duckwalk })}</button>`;
    }).join('') || '<p class="emptyHand">손패가 비었습니다.</p>';
    $('deckInfo').textContent = `덱 ${S.deck.length} · 버림 ${S.discard.length}`;
  }

  function renderTracker() {
    $('tracker').innerHTML = D.WORKSHOPS.map((id) =>
      `<li class="${S.used.has(id) ? 'done' : ''}">${D.ROLAND_CARDS[id].name}</li>`).join('');
    $('trackerNum').textContent = `${S.used.size}/${D.WORKSHOPS.length}`;
  }

  // ---------- 입력 ----------

  $('lane').addEventListener('click', (e) => {
    const b = e.target.closest('[data-slot]');
    if (b) onSlotTap(Number(b.dataset.slot));
  });
  $('hand').addEventListener('click', (e) => {
    const b = e.target.closest('[data-uid]');
    if (b) onHandTap(Number(b.dataset.uid));
  });
  $('goBtn').addEventListener('click', commit);
  $('restartBtn').addEventListener('click', newGame);
  $('fastBtn').addEventListener('click', () => {
    fast = !fast;
    $('fastBtn').setAttribute('aria-pressed', String(fast));
  });

  newGame();
})();
