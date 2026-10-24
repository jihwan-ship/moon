"""효과음과 배경음을 코드로 합성해 game/audio에 WAV로 저장한다. 사용: python3 tools/sfx.py"""
import os
import wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'game', 'audio')
rng = np.random.default_rng(7)


def t(d):
    return np.linspace(0, d, int(SR * d), endpoint=False)


def env(n, a=0.005, d=0.2, curve=4.0):
    x = np.arange(n) / SR
    e = np.minimum(1, x / max(a, 1e-4)) * np.exp(-np.maximum(0, x - a) * curve / max(d, 1e-4))
    return e


def lp(x, k=0.2):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def save(name, x, vol=0.8):
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.max(np.abs(x)) + 1e-9) * vol
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def sweep(f0, f1, d):
    f = np.linspace(f0, f1, int(SR * d))
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


os.makedirs(OUT, exist_ok=True)

# 휘두르기: 대역 통과 잡음이 빠르게 지나감
d = 0.22
n = noise(d)
band = lp(n, 0.35) - lp(n, 0.06)
save('swing', band * env(len(n), 0.06, 0.08, 6) * np.sin(np.linspace(0, np.pi, len(n))) ** 2)

# 베기 적중: 날카로운 잡음 + 고음 쨍
d = 0.35
x = (noise(d) * env(int(SR * d), 0.001, 0.06, 5) + 0.5 * sweep(2400, 1400, d) * env(int(SR * d), 0.001, 0.12, 4))
save('slash', x)

# 타격 적중: 낮은 쿵 + 짧은 잡음
d = 0.4
x = sweep(150, 45, d) * env(int(SR * d), 0.001, 0.18, 4) + 0.6 * lp(noise(d), 0.25) * env(int(SR * d), 0.001, 0.04, 6)
save('hit', x)

# 무거운 타격
d = 0.7
x = sweep(110, 30, d) * env(int(SR * d), 0.001, 0.35, 4) + 0.8 * lp(noise(d), 0.15) * env(int(SR * d), 0.001, 0.1, 5)
save('heavy', x)

# 합(금속 부딪힘): 비조화 배음
d = 0.8
tt = t(d)
x = sum(np.sin(2 * np.pi * f * tt) * a for f, a in [(1180, 1), (1730, .6), (2510, .4), (3320, .25)]) * env(len(tt), 0.001, 0.3, 4)
x += 0.6 * noise(d) * env(len(tt), 0.001, 0.02, 6)
save('clash', x)

# 막기: 둔탁한 쿵 + 짧은 금속
d = 0.45
tt = t(d)
x = sweep(220, 90, d) * env(len(tt), 0.001, 0.12, 4) + 0.35 * np.sin(2 * np.pi * 900 * tt) * env(len(tt), 0.001, 0.1, 5)
save('block', x)

# 회피: 짧은 휙
d = 0.18
n = noise(d)
save('dodge', (lp(n, 0.5) - lp(n, 0.15)) * np.sin(np.linspace(0, np.pi, len(n))) ** 3, 0.6)

# 총소리
d = 0.35
x = noise(d) * env(int(SR * d), 0.0005, 0.05, 5) + 0.8 * sweep(400, 60, d) * env(int(SR * d), 0.0005, 0.12, 4)
save('gun', x)

# 폭발
d = 1.4
x = lp(noise(d), 0.08) * env(int(SR * d), 0.002, 0.6, 3) + 0.7 * sweep(80, 25, d) * env(int(SR * d), 0.002, 0.5, 3)
save('boom', x)

# 고양이 울음: 위로 올라갔다 내려오는 음높이 + 배음
d = 0.55
tt = t(d)
f = 500 + 450 * np.sin(np.pi * tt / d) ** 0.7
ph = 2 * np.pi * np.cumsum(f) / SR
x = (np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.25 * np.sin(3 * ph)) * np.sin(np.pi * tt / d) ** 0.6
save('meow', x, 0.6)

# 호루라기
d = 0.6
tt = t(d)
ph = 2 * np.pi * np.cumsum(2900 + 120 * np.sin(2 * np.pi * 32 * tt)) / SR
x = np.sin(ph) * np.minimum(1, tt / 0.02) * np.minimum(1, (d - tt) / 0.05) + 0.1 * noise(d)
save('whistle', x, 0.5)

# 버튼
d = 0.07
tt = t(d)
save('click', np.sin(2 * np.pi * 1300 * tt) * env(len(tt), 0.001, 0.02, 5), 0.4)

# 카드 놓기
d = 0.12
n = noise(d)
save('card', (lp(n, 0.4) - lp(n, 0.1)) * env(len(n), 0.002, 0.03, 5), 0.5)

# 회복
d = 0.7
tt = t(d)
x = sum(np.sin(2 * np.pi * f * tt) * env(len(tt), 0.01 + i * 0.08, 0.25, 3) for i, f in enumerate([660, 880, 1320]))
save('heal', x, 0.5)

# 흐트러짐(멘탈 붕괴)
d = 0.9
x = sweep(900, 120, d) * env(int(SR * d), 0.005, 0.5, 2) + 0.3 * sweep(910, 125, d)
save('break', x, 0.6)


def tone(freq, d, kind='square'):
    tt = t(d)
    if kind == 'square':
        w = np.sign(np.sin(2 * np.pi * freq * tt)) * 0.5 + 0.5 * np.sin(2 * np.pi * freq * tt)
    else:
        w = np.sin(2 * np.pi * freq * tt)
    return w * env(len(tt), 0.005, d * 0.9, 2.5)


def notes(seq, bpm):
    beat = 60 / bpm
    return np.concatenate([tone(440 * 2 ** ((n - 69) / 12), beat * l) if n else np.zeros(int(SR * beat * l)) for n, l in seq])

# 진급 팡파르
save('fanfare', notes([(67, .5), (72, .5), (76, .5), (79, 1.5), (76, .5), (79, 2)], 220), 0.55)
# 승리
save('victory', notes([(72, .5), (72, .5), (72, .5), (72, 1.5), (68, 1.5), (70, 1.5), (72, 1), (70, .5), (72, 3)], 240), 0.55)
# 패배
save('defeat', notes([(67, 1), (66, 1), (65, 1), (64, 3)], 120), 0.5)

# 배경음: 행진곡풍 4마디 반복(스네어 + 베이스 + 멜로디)
bpm = 132
beat = 60 / bpm
bars = 8
L = int(SR * beat * 4 * bars)
mix = np.zeros(L)
def put(sig, at):
    i = int(SR * at)
    j = min(L, i + len(sig))
    mix[i:j] += sig[:j - i]
snare = lambda: lp(noise(0.18), 0.6) * env(int(SR * .18), 0.001, 0.05, 5) * 0.35
kick = lambda: sweep(120, 40, 0.25) * env(int(SR * .25), 0.001, 0.12, 4) * 0.6
for b in range(bars * 4):
    put(kick(), b * beat)
    put(snare(), (b + 0.5) * beat)
    if b % 2 == 1:
        put(snare() * 0.7, (b + 0.75) * beat)
bass = [43, 43, 38, 38, 41, 41, 36, 38]
for i, n in enumerate(bass):
    for k in range(4):
        put(tone(440 * 2 ** ((n - 69) / 12), beat * 0.9, 'square') * 0.22, (i * 4 + k) * beat)
mel = [(67, 1), (67, .5), (69, .5), (70, 1), (67, 1), (65, 1), (62, 1), (65, 2),
       (67, 1), (70, .5), (72, .5), (74, 1.5), (72, .5), (70, 1), (69, 1), (67, 2),
       (67, 1), (67, .5), (69, .5), (70, 1), (67, 1), (74, 1), (72, 1), (70, 2),
       (69, 1), (70, .5), (69, .5), (67, 1), (65, 1), (67, 4)]
pos = 0
for n, l in mel:
    put(tone(440 * 2 ** ((n - 69) / 12), beat * l * 0.95, 'square') * 0.16, pos * beat)
    pos += l
save('bgm', mix, 0.5)
print('ok', sorted(os.listdir(OUT)))
