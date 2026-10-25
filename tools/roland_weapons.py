"""롤랑 모드 무기와 이펙트를 게임 폴더로 옮기고, 무기마다 손잡이 위치와 크기를 정한다.
무기 그림은 칼날(머리)이 왼쪽, 손잡이가 오른쪽을 향한다.
입력: assets/ruina/weapons, assets/ruina/fx_new (원작 그림)
출력: game/art/roland/weapons/*.png, weapons.json, game/art/roland/fx/*.png (저장소에는 없다)
사용: python3 tools/roland_weapons.py
"""
import json
import os
import shutil

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), '..')
SRC = os.path.join(ROOT, 'assets', 'ruina')
OUT = os.path.join(ROOT, 'game', 'art', 'roland')

# 이름: (손잡이의 가로 위치 비율, 게임에서의 크기)
GRIP = {
    'durandal_sword': (0.9, 1.0),
    'mook_katana': (0.92, 1.45),
    'logic_revolver': (0.86, 1.05),
    'logic_shotgun': (0.72, 1.25),
    'ranga_gauntlet': (0.74, 1.0),
    'ranga_dagger': (0.88, 1.15),
    'wheels_greatsword': (0.93, 1.7),
    'allas_spear': (0.72, 1.6),
    'oldboys_hammer': (0.88, 1.35),
    'zelkova_mace': (0.86, 1.3),
    'zelkova_axe': (0.88, 1.35),
    'crystal_sword': (0.9, 1.45),
}


def draw_durandal(path):
    """뒤랑달: 검고 곧은 장검. 받은 무기 그림과 같은 굵기의 선화로 그린다."""
    w, h = 240, 24
    im = Image.new('RGBA', (w, h))
    d = ImageDraw.Draw(im)
    cy = h // 2
    d.polygon([(2, cy), (14, cy - 4), (186, cy - 4), (186, cy + 4), (14, cy + 4)], fill=(18, 18, 20, 255), outline=(120, 124, 130, 255))
    d.line([(16, cy - 2), (184, cy - 2)], fill=(80, 84, 90, 255), width=1)
    d.rectangle([186, cy - 10, 192, cy + 10], fill=(40, 40, 44, 255), outline=(150, 150, 155, 255))
    d.rectangle([192, cy - 3, 228, cy + 3], fill=(28, 26, 26, 255), outline=(90, 90, 95, 255))
    for x in range(196, 228, 6):
        d.line([(x, cy - 3), (x + 3, cy + 3)], fill=(70, 70, 75, 255))
    d.ellipse([227, cy - 5, 237, cy + 5], fill=(60, 60, 64, 255), outline=(160, 160, 165, 255))
    im.save(path)


os.makedirs(os.path.join(OUT, 'weapons'), exist_ok=True)
os.makedirs(os.path.join(OUT, 'fx'), exist_ok=True)
draw_durandal(os.path.join(SRC, 'weapons', 'durandal_sword.png'))
meta = {}
for name, (gx, sc) in GRIP.items():
    src = os.path.join(SRC, 'weapons', name + '.png')
    im = Image.open(src).convert('RGBA')
    a = np.array(im)[:, :, 3]
    x = int(round(gx * (im.width - 1)))
    col = np.where(a[:, max(0, x - 2):x + 3].max(1) > 60)[0]
    y = float((col.min() + col.max()) / 2) if len(col) else im.height / 2
    shutil.copy(src, os.path.join(OUT, 'weapons', name + '.png'))
    meta[name] = {'grip': [x, y], 'scale': sc}
json.dump(meta, open(os.path.join(OUT, 'weapons.json'), 'w'), indent=1)
for f in os.listdir(os.path.join(SRC, 'fx_new')):
    shutil.copy(os.path.join(SRC, 'fx_new', f), os.path.join(OUT, 'fx', f))
print(json.dumps(meta))
