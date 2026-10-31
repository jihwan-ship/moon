"""정시우 모드 책장 그림. 마우스로 대충 그린 낙서처럼 삐뚤빼뚤한 선으로 그린다.
로직 아틀리에는 직접 그린 권총/샷건 그림(art_src/sium)을 그대로 쓴다. -> game/art/sium/cards/"""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFont

W, H = 300, 210
OUT = 'game/art/sium/cards/'
INK = (20, 18, 16)
FONT = 'game/fonts/BlackHanSans.ttf'


def wobble(pts, amp=2.5, step=5):
    """점 사이를 잘게 나누고 천천히 흔들리는 손떨림을 더한다"""
    out = []
    ox = oy = 0.0
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / step))
        for i in range(n):
            t = i / n
            ox = max(-amp, min(amp, ox + random.uniform(-0.8, 0.8)))
            oy = max(-amp, min(amp, oy + random.uniform(-0.8, 0.8)))
            out.append((x0 + (x1 - x0) * t + ox, y0 + (y1 - y0) * t + oy))
    out.append((pts[-1][0] + ox, pts[-1][1] + oy))
    return out


class Pen:
    def __init__(self):
        self.im = Image.new('RGBA', (W, H), (250, 248, 240, 255))
        self.d = ImageDraw.Draw(self.im)

    def line(self, *pts, w=4, fill=INK):
        self.d.line(wobble(list(pts)), fill=fill, width=w, joint='curve')

    def loop(self, cx, cy, rx, ry, w=4, fill=INK, start=0):
        pts = [(cx + rx * math.cos(a), cy + ry * math.sin(a)) for a in np.linspace(start, start + math.tau * 1.08, 30)]
        self.d.line(wobble(pts), fill=fill, width=w, joint='curve')

    def poly(self, *pts, fill=None, w=4):
        if fill:
            self.d.polygon(list(pts), fill=fill)
        self.line(*pts, pts[0], w=w)

    def save(self, name):
        self.im.save(OUT + name + '.png')


def paste(pen, path, box, flip=False):
    """직접 그린 그림(흰 바탕 검은 선)을 붙인다"""
    src = Image.open(path).convert('RGBA')
    a = np.array(src).astype(int)
    dark = a[..., :3].max(axis=2) < 140
    bb = Image.fromarray((dark * 255).astype(np.uint8)).getbbox()
    src = src.crop(bb)
    if flip:
        src = src.transpose(Image.FLIP_LEFT_RIGHT)
    x0, y0, x1, y1 = box
    s = min((x1 - x0) / src.width, (y1 - y0) / src.height)
    src = src.resize((int(src.width * s), int(src.height * s)))
    m = np.array(src).astype(int)
    from scipy import ndimage
    alpha = ndimage.binary_dilation(m[..., :3].max(axis=2) < 160, iterations=2).astype(np.uint8) * 255
    ink = Image.new('RGBA', src.size, INK + (255,))
    ink.putalpha(Image.fromarray(alpha))
    pen.im.alpha_composite(ink, (x0 + (x1 - x0 - src.width) // 2, y0 + (y1 - y0 - src.height) // 2))


def spark(pen, x, y, n=5, r=16):
    for k in range(n):
        a = random.uniform(0, math.tau)
        pen.line((x + math.cos(a) * r * 0.4, y + math.sin(a) * r * 0.4), (x + math.cos(a) * r, y + math.sin(a) * r), w=3)


def user_card(src, name, rot=0):
    from scipy import ndimage
    im = Image.open(src).convert('RGBA')
    bg = Image.new('RGBA', im.size, (255, 255, 255, 255))
    bg.alpha_composite(im)
    dark = np.array(bg.convert('L')) < 128
    ys, xs = np.where(dark)
    m = 14
    box = (max(xs.min() - m, 0), max(ys.min() - m, 0), min(xs.max() + m, im.width), min(ys.max() + m, im.height))
    line = ndimage.binary_dilation(dark, iterations=2)[box[1]:box[3], box[0]:box[2]]
    out = np.zeros(line.shape + (4,), np.uint8)
    out[...] = (250, 248, 240, 255)
    out[line] = INK + (255,)
    img = Image.fromarray(out, 'RGBA')
    if rot:
        # 납작한 그림은 책장 칸에서 너무 작아지므로 비스듬히 세운다
        img = img.rotate(rot, expand=True, resample=Image.BICUBIC, fillcolor=(250, 248, 240, 255))
    img.save(OUT + name + '.png')


random.seed(7)

# 느티나무: 도끼와 메이스를 X자로
p = Pen()
p.line((80, 190), (200, 40), w=6)
p.poly((185, 35), (235, 25), (245, 75), (205, 70), fill=(190, 190, 200))
p.line((220, 190), (100, 50), w=6)
p.loop(95, 45, 26, 24, w=5)
for a in range(0, 360, 60):
    r = math.radians(a)
    p.line((95 + math.cos(r) * 26, 45 + math.sin(r) * 24), (95 + math.cos(r) * 40, 45 + math.sin(r) * 38), w=4)
p.save('zelkova')

# 랑아: 손톱 달린 장갑과 단검
p = Pen()
p.loop(110, 130, 45, 40, w=5)
for k in range(3):
    p.line((90 + k * 22, 95), (80 + k * 26, 30), w=4)
p.line((200, 180), (250, 60), w=5)
p.poly((240, 75), (262, 20), (262, 80), fill=(200, 200, 210))
spark(p, 70, 40)
p.save('ranga')

# 늙은소년: 방패 같은 큰 망치
p = Pen()
p.line((150, 200), (150, 80), w=7)
p.poly((80, 30), (220, 30), (225, 95), (75, 95), fill=(150, 130, 110))
p.line((95, 50), (205, 50), w=3)
spark(p, 60, 120, r=22)
p.save('oldboys')

# 알라스: 길게 내지르는 창
p = Pen()
p.line((20, 170), (230, 70), w=6)
p.poly((225, 55), (290, 45), (240, 95), fill=(200, 200, 210))
for k in range(4):
    p.line((40 + k * 30, 120 + k * 10), (10 + k * 30, 135 + k * 10), w=3)
p.save('allas')

# 묵: 직접 그린 책장 그림
user_card('art_src/sium/card_mook.png', 'mook')

# 로직: 직접 그린 책장 그림(정시우가 샷건 쏘는 장면). 작게 줄어도 보이게 선을 굵게 한다

user_card('art_src/sium/card_logic.png', 'logic')

# 뒤랑달: 큰 검 한 자루와 휙 선
p = Pen()
p.line((60, 180), (90, 150), w=8)
p.line((70, 135), (110, 170), w=6)
p.poly((92, 148), (240, 30), (252, 40), (108, 162), fill=(220, 220, 230))
p.d.arc((40, 10, 290, 230), 200, 320, fill=INK, width=3)
p.save('durandal')

# 크리스탈: 반짝이는 두 칼
p = Pen()
p.poly((70, 190), (130, 30), (150, 40), (90, 195), fill=(170, 220, 240))
p.poly((230, 190), (170, 30), (150, 40), (210, 195), fill=(170, 220, 240))
for x, y in ((60, 50), (240, 60), (150, 120)):
    p.line((x - 12, y), (x + 12, y), w=3)
    p.line((x, y - 12), (x, y + 12), w=3)
p.save('crystal')

# 휠즈: 직접 그린 대검 그림
user_card('art_src/sium/greatsword.png', 'wheels', rot=-28)

# 퓨리오소: 아홉 무기가 막 날아다니는 낙서
p = Pen()
for k in range(9):
    a = k / 9 * math.tau
    cx, cy = 150 + math.cos(a) * 95, 105 + math.sin(a) * 70
    p.line((cx - 18, cy + 10), (cx + 18, cy - 10), w=5)
font = ImageFont.truetype(FONT, 40)
p.d.text((150, 105), 'FURIOSO', font=font, fill=(160, 20, 20), anchor='mm')
p.save('furioso')
print('ok')
