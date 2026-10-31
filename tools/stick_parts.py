"""직접 그린 쫄라맨 정시우 그림으로 인형 부위(k_*)를 만든다.
머리와 무기는 그림에서 오려 내고(흰 바탕은 투명하게, 선 안쪽 흰색은 남긴다), 몸과 팔다리는 같은 굵기의 선으로 그린다.
입력: art_src/sium/{sium,pistol,shotgun,greatsword}.png  출력: game/art/parts/k_*.png, game/art/parts.json에 추가
사용: python3 tools/stick_parts.py
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(__file__), '..')
SRC = os.path.join(ROOT, 'art_src', 'sium')
OUT = os.path.join(ROOT, 'game', 'art', 'parts')
META = os.path.join(ROOT, 'game', 'art', 'parts.json')
S = 2            # 부위 그림은 2배 해상도(parts.json의 scale과 같다)
F = 1.5          # 원본 그림 -> 게임 크기 배율
LINE = 5         # 몸 선 굵기(게임 크기)
PAD = 6

meta = json.load(open(META))
assert meta['scale'] == S


def cutout(path, box=None, seed=None, thicken=0):
    """흰 바탕을 투명하게 만든다. 선의 작은 틈은 메워서 판단한다.
    seed가 있으면 그 점을 포함한 안쪽(얼굴)만 흰색으로 남기고, 없으면 선 안쪽을 모두 흰색으로 채운다.
    thicken: 줄여서 쓸 그림의 선이 너무 가늘어지지 않게 선을 굵힌다(픽셀)."""
    im = Image.open(path).convert('RGB')
    if box:
        im = im.crop(box)
    a = np.array(im).astype(int)
    ink = a.sum(2) / 3 < 170
    if thicken:
        ink = ndimage.binary_dilation(ink, iterations=thicken)
    closed = ndimage.binary_closing(ink, iterations=3) | ink
    lab, _ = ndimage.label(~closed)
    if seed is not None:
        fill = lab == lab[seed[1], seed[0]]
    else:
        edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
        fill = (~closed) & ~np.isin(lab, list(edge))
    out = np.zeros(a.shape[:2] + (4,), np.uint8)
    out[..., :3] = 255
    out[fill, 3] = 255
    out[closed & ~ink, 3] = np.where(fill.any(), 255, 0)  # 메운 틈은 흰색으로
    out[ink, :3] = 20
    out[ink, 3] = 255
    img = Image.fromarray(out, 'RGBA')
    bb = img.getbbox()
    return img.crop(bb), bb


def save(name, img, ox, oy):
    """img는 게임 크기 기준 S배 그림. (ox, oy)는 그림 왼쪽 위 모서리의 피벗 기준 좌표(게임 크기)."""
    img.save(os.path.join(OUT, name + '.png'))
    meta['parts'][name] = {'ox': ox, 'oy': oy, 'w': img.width / S, 'h': img.height / S}


def line_part(name, length):
    w = LINE + PAD * 2
    h = length + LINE + PAD * 2
    img = Image.new('RGBA', (int(w * S), int(h * S)))
    d = ImageDraw.Draw(img)
    x = w / 2 * S
    d.line([(x, (PAD + LINE / 2) * S), (x, (PAD + LINE / 2 + length) * S)], fill=(20, 20, 20, 255), width=int(LINE * S))
    r = LINE / 2 * S
    for y in [(PAD + LINE / 2) * S, (PAD + LINE / 2 + length) * S]:
        d.ellipse([x - r, y - r, x + r, y + r], fill=(20, 20, 20, 255))
    save(name, img, -w / 2, -(PAD + LINE / 2))


def scaled(img):
    return img.resize((int(img.width * F * S / 1), int(img.height * F * S / 1)), Image.LANCZOS)


# 머리: 그림의 목 위쪽(원본 y 140까지). 목 아래 끝이 피벗
head, bb = cutout(os.path.join(SRC, 'sium.png'), (180, 25, 345, 141), seed=(262 - 180, 100 - 25))
neck_x = 247 - (180 + bb[0])
hs = scaled(head)
save('k_head', hs, -neck_x * F, -head.height * F)

# 팔다리와 몸통
# SD(쪼꼬미) 비율: 큰 머리에 짧은 몸과 팔다리
TORSO = 60
line_part('k_thigh', 32)
line_part('k_shin', 28)
line_part('k_upper', 26)
line_part('k_fore', 22)
# 몸통은 엉덩이(피벗)에서 위로 뻗는다
w = LINE + PAD * 2
img = Image.new('RGBA', (int(w * S), int((TORSO + LINE + PAD * 2) * S)))
d = ImageDraw.Draw(img)
d.line([(w / 2 * S, (PAD + LINE / 2) * S), (w / 2 * S, (PAD + LINE / 2 + TORSO) * S)], fill=(20, 20, 20, 255), width=int(LINE * S))
save('k_torso', img, -w / 2, -(TORSO + PAD + LINE / 2))
# 손은 작은 점, 발은 짧은 선
img = Image.new('RGBA', (int(16 * S), int(16 * S)))
ImageDraw.Draw(img).ellipse([5 * S, 5 * S, 11 * S, 11 * S], fill=(20, 20, 20, 255))
save('k_hand', img, -8, -8)
img = Image.new('RGBA', (int(28 * S), int(12 * S)))
ImageDraw.Draw(img).line([(4 * S, 6 * S), (24 * S, 6 * S)], fill=(20, 20, 20, 255), width=int(LINE * S))
save('k_boot', img, -10, -6)

# 무기: 원본은 총구(칼날)가 왼쪽. 좌우를 뒤집어 총구가 앞(+x)을 보게 하고, 손잡이를 피벗으로
WEAPONS = {'pistol': ((245, 128), 0.24), 'shotgun': ((262, 128), 0.42), 'greatsword': ((295, 122), 0.55)}
for name, ((gx, gy), wf) in WEAPONS.items():
    img, bb = cutout(os.path.join(SRC, name + '.png'), thicken=2)
    img = img.transpose(Image.FLIP_LEFT_RIGHT)
    gx2 = (bb[2] - gx)          # 뒤집은 뒤 손잡이 x(오려낸 그림 기준)
    gy2 = gy - bb[1]
    k = F * wf
    big = img.resize((int(img.width * k * S), int(img.height * k * S)), Image.LANCZOS)
    save('k_' + name, big, -gx2 * k, -gy2 * k)

json.dump(meta, open(META, 'w'), indent=1)
print('ok', [k for k in meta['parts'] if k.startswith('k_')])
