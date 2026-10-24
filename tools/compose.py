"""원작 시트의 부위 조각(몸통, 머리, 머리카락, 표정)을 자세별 완성 이미지로 조립한다.
원작 그림은 왼쪽을 보고 있으므로 결과도 왼쪽을 본다. 게임에서 좌우를 뒤집어 쓴다.

사용: python3 tools/compose.py [미리보기.png]
입력: assets/ruina/roland/*, 출력: assets/ruina/poses/*.png (+ fx/*.png)
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'ruina')
SRC = os.path.join(ROOT, 'roland')
OUT = os.path.join(ROOT, 'poses')
FX = os.path.join(ROOT, 'fx')

# 머리 조립 비율(머리 조각 크기 기준)
HAIR_OFF = (-0.13, -0.11)   # 머리카락 왼쪽 위 모서리
FACE_AT = (0.42, 0.62)      # 표정 중심(정면)
SIDE_FACE_AT = (0.19, 0.64)  # 표정 중심(옆모습)
NECK_ON_HEAD = (0.55, 0.93)  # 머리에서 목에 닿는 점

# body/head/hair/face: 시트 안의 대략적인 상자 [x0, y0, x1, y1]
# neck: 몸통 상자 기준 목 위치, tilt: 머리 기울기(도, 양수 = 시계 방향)
POSES = {
    # 기본 자세: 몸통, 다리, 팔이 따로 나뉜 시트를 조립한다(넥타이를 만지며 칼을 늘어뜨린 자세)
    'idle': dict(sheet='durandal_parts.png', head=[133, 348, 291, 520], hair=[0, 520, 191, 700],
                 face=('durandal_parts.png', [193, 642, 293, 680]),
                 layers=[([0, 701, 311, 1024], (80, 20)), ([0, 309, 133, 520], (-6, 135)),
                         ([0, 138, 124, 304], (0, 0)), ([0, 26, 106, 138], (-20, 20))],
                 neck=(62, 10), tilt=0),
    # 맞았을 때: 가슴을 움켜쥐고 칼을 떨군 몸통에 멍든 표정
    'hurt': dict(sheet='durandal_idle_hurt.png', body=[0, 682, 372, 1024], head=[0, 265, 158, 439], hair=[0, 439, 192, 613],
                 face=('durandal_idle_hurt.png', [26, 204, 185, 264]), neck=(270, 14), tilt=-8),
    'move': dict(sheet='durandal_move.png', body=[1, 715, 490, 1024], head=[0, 365, 157, 538], hair=[0, 538, 191, 715],
                 face=('durandal_move.png', [1, 303, 101, 347]), neck=(92, 14), tilt=-6),
    'evade': dict(sheet='durandal_evade.png', body=[1, 710, 499, 1020], head=[1, 359, 158, 533], hair=[0, 534, 191, 710],
                  face=('durandal_evade.png', [0, 291, 101, 341]), neck=(96, 14), tilt=6),
    'guard': dict(sheet='durandal_guard.png', body=[0, 592, 347, 1024], head=[0, 241, 158, 414], hair=[0, 414, 191, 592],
                  face=('durandal_guard.png', [1, 181, 101, 221]), neck=(170, 14), tilt=0, ground=(215, 272)),
    'slash': dict(side=True, sheet='durandal_slash.png', body=[0, 614, 528, 1024], head=[718, 852, 868, 1024], hair=[529, 841, 717, 1024],
                  face=('durandal_slash.png', [871, 899, 917, 941]), neck=(72, 122), tilt=-18),
    'thrust': dict(side=True, sheet='durandal_thrust.png', body=[0, 751, 652, 1024], head=[190, 578, 340, 750], hair=[1, 567, 189, 750],
                   face=('durandal_thrust.png', [927, 900, 973, 942]), neck=(548, 10), tilt=-14),
    'crystal': dict(sheet='crystal_slash.png', body=[412, 425, 996, 685], head=[820, 854, 973, 1023], hair=[630, 840, 820, 1024],
                    face=('crystal_slash.png', [821, 787, 863, 824]), neck=(50, 16), tilt=-10),
    'mook_slash': dict(sheet='mook_slash.webp', body=[0, 960, 659, 1282], head=[803, 1829, 958, 2000], hair=[662, 1112, 849, 1281],
                       face=('mook_slash.webp', [663, 1052, 758, 1110]), face_pad=2, neck=(100, 14), tilt=-6, ground=(120, 292)),
    'mook_thrust': dict(side=True, sheet='mook_thrust2.png', body=[0, 152, 770, 527], head=[771, 173, 923, 343], hair=[771, 343, 960, 527],
                        face=('mook_thrust2.png', [961, 462, 1004, 499]), neck=(150, 12), tilt=-14, ground=(155, 290)),
    'wheels_swing': dict(sheet='wheels_swing.png', body=[0, 704, 535, 1009], head=[726, 850, 883, 1024], hair=[535, 848, 726, 1024],
                         face=('wheels_swing.png', [726, 787, 826, 832]), neck=(80, 14), tilt=0),
    'wheels_smash': dict(side=True, sheet='wheels_smash.webp', body=[971, 1692, 1969, 1991], head=[0, 715, 148, 883], hair=[1, 882, 185, 1062],
                         face=('wheels_smash.webp', [0, 650, 42, 715]), neck=(800, 58), tilt=-24),
    'ranga_claw': dict(side=True, sheet='ranga_claw.webp', body=[1029, 150, 1499, 500], head=[1725, 334, 1873, 500], hair=[1514, 141, 1701, 321],
                       face=('ranga_claw.webp', [1515, 77, 1557, 114]), neck=(250, 100), tilt=-20),
    'logic_pistols': dict(sheet='logic_pistols2.png', body=[1, 223, 640, 584], head=[832, 426, 990, 598], hair=[640, 417, 831, 598],
                          face=('logic_pistols2.png', [640, 357, 740, 395]), neck=(325, 18), tilt=0),
    'zelkova_axe': dict(sheet='zelkova_axe.webp', body=[0, 1179, 593, 1994], head=[0, 380, 155, 549], hair=[0, 549, 186, 725],
                        face=('zelkova_axe.webp', [0, 321, 98, 360]), neck=(145, 278), tilt=-4, ground=(115, 548)),
    'zelkova_crouch': dict(side=True, sheet='zelkova_crouch.webp', body=[6, 1485, 836, 2000], head=[837, 1834, 985, 2000], hair=[0, 765, 185, 945],
                           face=('zelkova_crouch.webp', [837, 1769, 879, 1808]), neck=(386, 262), tilt=-12),
}

# 이펙트 조각: 이름 -> (시트, 상자)
EFFECTS = {
    'ink_arc': ('crystal_slash.png', [155, 337, 410, 641]),
    'ink_arc_big': ('mook_slash.webp', [243, 1330, 802, 1987]),
    'ink_arc_wide': ('mook_thrust2.png', [273, 609, 603, 1009]),
    'ink_swipe': ('zelkova_axe.webp', [51, 929, 490, 1176]),
    'ink_rise': ('zelkova_crouch.webp', [75, 1031, 281, 1484]),
    'claw_arc': ('ranga_claw.webp', [187, 269, 424, 465]),
    'dash_trail': ('ranga_dagger_dash.png', [24, 388, 939, 492]),
    'smoke_trail': ('wheels_swing_fx.png', [27, 560, 440, 656]),
    'debris': ('wheels_smash.webp', [70, 1329, 936, 1986]),
    'muzzle': ('logic_pistols2.png', [12, 600, 516, 883]),
    'muzzle_big': ('logic_shotgun.webp', [30, 1526, 841, 1813]),
}

_cache = {}


def load(sheet):
    if sheet not in _cache:
        im = Image.open(os.path.join(SRC, sheet)).convert('RGBA')
        a = np.array(im)[:, :, 3]
        lab, _ = ndimage.label(ndimage.binary_dilation(a > 20, iterations=4))
        _cache[sheet] = (im, np.array(im), lab)
    return _cache[sheet]


def piece(sheet, box, pad=0, group=False):
    """상자 안에서 가장 큰 덩어리(group=True면 상자 안의 모든 덩어리)를 잘라낸다."""
    im, arr, lab = load(sheet)
    x0, y0, x1, y1 = box
    x0, y0 = max(0, x0 - pad), max(0, y0 - pad)
    x1, y1 = min(im.width, x1 + pad), min(im.height, y1 + pad)
    sub = lab[y0:y1, x0:x1]
    ids, counts = np.unique(sub[sub > 0], return_counts=True)
    if not len(ids):
        raise ValueError(f'{sheet} {box}: 비어 있음')
    keep = ids if group else [ids[np.argmax(counts)]]
    mask = np.isin(lab, keep)
    if group:
        rect = np.zeros_like(mask)
        rect[y0:y1, x0:x1] = True
        mask &= rect
    ys, xs = np.where(mask)
    bx0, by0, bx1, by1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    out = arr[by0:by1, bx0:bx1].copy()
    out[~mask[by0:by1, bx0:bx1]] = 0
    return Image.fromarray(out), (bx0, by0)


def head_image(cfg):
    head, _ = piece(cfg['sheet'], cfg['head'])
    hair, _ = piece(cfg['sheet'], cfg['hair'])
    fsheet, fbox = cfg['face']
    face, _ = piece(fsheet, fbox, pad=cfg.get('face_pad', 14), group=True)
    face_at = SIDE_FACE_AT if cfg.get('side') else FACE_AT
    hw, hh = head.size
    hx, hy = int(HAIR_OFF[0] * hw), int(HAIR_OFF[1] * hh)
    left, top = min(0, hx), min(0, hy)
    W = max(hw, hx + hair.width) - left
    H = max(hh, hy + hair.height) - top
    canvas = Image.new('RGBA', (W, H))
    canvas.alpha_composite(head, (-left, -top))
    fx = int(face_at[0] * hw - face.width / 2) - left
    fy = int(face_at[1] * hh - face.height / 2) - top
    canvas.alpha_composite(face, (fx, fy))
    canvas.alpha_composite(hair, (hx - left, hy - top))
    neck = (NECK_ON_HEAD[0] * hw - left, NECK_ON_HEAD[1] * hh - top)
    return canvas, neck


def layered_body(cfg):
    """layers: [(상자, (x, y))] 를 뒤에서부터 차례로 겹쳐 몸통 하나로 만든다. 좌표는 첫 조각 기준이 아니라 공통 원점 기준."""
    parts = [(piece(cfg['sheet'], box)[0], off) for box, off in cfg['layers']]
    x0 = min(o[0] for _, o in parts)
    y0 = min(o[1] for _, o in parts)
    x1 = max(o[0] + im.width for im, o in parts)
    y1 = max(o[1] + im.height for im, o in parts)
    canvas = Image.new('RGBA', (x1 - x0, y1 - y0))
    for im, (ox, oy) in parts:
        canvas.alpha_composite(im, (ox - x0, oy - y0))
    return canvas, (x0, y0)


def compose(name, cfg):
    if cfg.get('layers'):
        body, (ox, oy) = layered_body(cfg)
        nx, ny = cfg['neck'][0] - ox, cfg['neck'][1] - oy
        bx = by = 0
        cfg = dict(cfg, body=[0, 0, 0, 0])
    else:
        body, (bx, by) = piece(cfg['sheet'], cfg['body'])
        # 몸통 상자 기준 목 좌표를 실제로 잘린 몸통 기준으로 바꾼다
        nx = cfg['neck'][0] + cfg['body'][0] - bx
        ny = cfg['neck'][1] + cfg['body'][1] - by
    head, (hnx, hny) = head_image(cfg)
    if cfg.get('tilt'):
        # 목 위치를 중심으로 회전
        big = Image.new('RGBA', (head.width * 3, head.height * 3))
        big.alpha_composite(head, (head.width, head.height))
        cx, cy = hnx + head.width, hny + head.height
        big = big.rotate(-cfg['tilt'], resample=Image.BICUBIC, center=(cx, cy))
        bb = big.getbbox()
        head = big.crop(bb)
        hnx, hny = cx - bb[0], cy - bb[1]
    hx, hy = int(nx - hnx), int(ny - hny)
    left, top = min(0, hx), min(0, hy)
    W = max(body.width, hx + head.width) - left
    H = max(body.height, hy + head.height) - top
    canvas = Image.new('RGBA', (W, H))
    canvas.alpha_composite(body, (-left, -top))
    canvas.alpha_composite(head, (hx - left, hy - top))
    # 발 기준점: 무기가 발보다 아래로 내려가는 자세는 ground로 직접 지정한다
    if cfg.get('ground'):
        gx = cfg['ground'][0] + cfg['body'][0] - bx - left
        gy = cfg['ground'][1] + cfg['body'][1] - by - top
        head_center = (hx - left + head.width / 2, hy - top + head.height / 2)
        return canvas, dict(w=W, h=H, foot=[int(gx), int(gy)], head=[round(head_center[0]), round(head_center[1])])
    # 그 밖에는 바닥에 닿는 불투명 픽셀들의 가운데
    a = np.array(canvas)[:, :, 3]
    rows = np.where(a.max(axis=1) > 40)[0]
    foot_y = rows.max()
    band = a[max(0, foot_y - 30):foot_y + 1]
    cols = np.where(band.max(axis=0) > 40)[0]
    foot_x = int((cols.min() + cols.max()) / 2)
    head_center = (hx - left + head.width / 2, hy - top + head.height / 2)
    return canvas, dict(w=W, h=H, foot=[foot_x, int(foot_y)], head=[round(head_center[0]), round(head_center[1])])


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(FX, exist_ok=True)
    meta = {}
    previews = []
    for name, cfg in POSES.items():
        img, info = compose(name, cfg)
        img.save(os.path.join(OUT, name + '.png'))
        meta[name] = info
        previews.append((name, img, info))
    for name, (sheet, box) in EFFECTS.items():
        img, _ = piece(sheet, box, group=True)
        img.save(os.path.join(FX, name + '.png'))
        meta['fx:' + name] = dict(w=img.width, h=img.height)
    json.dump(meta, open(os.path.join(ROOT, 'poses.json'), 'w'), indent=1)
    if len(sys.argv) > 1:
        from PIL import ImageDraw
        H = 360
        tiles = []
        for name, img, info in previews:
            s = H / img.height
            t = Image.new('RGBA', (max(1, int(img.width * s)), H), (120, 120, 120, 255))
            t.alpha_composite(img.resize(t.size))
            d = ImageDraw.Draw(t)
            fx, fy = info['foot']
            d.ellipse([fx * s - 5, fy * s - 5, fx * s + 5, fy * s + 5], outline=(255, 0, 0, 255), width=2)
            d.text((4, 4), name, fill=(255, 255, 0, 255), font_size=18)
            tiles.append(t)
        rows, cur, cw = [], [], 0
        for t in tiles:
            if cw + t.width > 1800 and cur:
                rows.append(cur)
                cur, cw = [], 0
            cur.append(t)
            cw += t.width + 8
        rows.append(cur)
        sheet = Image.new('RGB', (1800, len(rows) * (H + 8)), (30, 30, 30))
        for r, row in enumerate(rows):
            x = 0
            for t in row:
                sheet.paste(t.convert('RGB'), (x, r * (H + 8)))
                x += t.width + 8
        sheet.save(sys.argv[1])
    print('poses', len(POSES), 'fx', len(EFFECTS))


if __name__ == '__main__':
    main()
