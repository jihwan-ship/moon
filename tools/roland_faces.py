"""롤랑 모드 공격 자세 그림의 머리를 서 있는 그림(stand.png)의 머리로 바꾼다.
조립한 자세 그림의 얼굴이 원래 얼굴과 달라서, 모든 자세가 같은 얼굴을 쓰게 한다.
입력: assets/ruina/poses/*.png(원본 조립본), game/art/roland/stand.png
출력: game/art/roland/*.png (원작 그림이라 저장소에는 없다)
사용: python3 tools/roland_faces.py [미리보기.png]
"""
import json
import os
import sys

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
SRC = os.path.join(ROOT, 'assets', 'ruina', 'poses')
DST = os.path.join(ROOT, 'game', 'art', 'roland')
HEAD_BOTTOM = 196  # stand.png에서 턱 아래(옷깃 위)까지

meta = json.load(open(os.path.join(DST, 'poses.json')))
stand = Image.open(os.path.join(DST, 'stand.png')).convert('RGBA')
head = stand.crop((0, 0, stand.width, HEAD_BOTTOM))
bb = head.getbbox()
head = head.crop(bb)
hc = (head.width / 2, head.height * 0.52)  # 머리 그림에서 조립본 head 좌표에 맞출 점

out = []
for name in sorted(os.listdir(SRC)):
    key = name[:-4]
    if key not in meta or key == 'stand':
        continue
    im = Image.open(os.path.join(SRC, name)).convert('RGBA')
    cx, cy = meta[key]['head']
    x, y = int(cx - hc[0]), int(cy - hc[1])
    # 머리가 그림 밖으로 나가면 캔버스를 넓힌다(발 기준점과 머리 좌표도 같이 옮긴다)
    left, top = max(0, -x), max(0, -y)
    W = max(im.width + left, x + left + head.width)
    H = max(im.height + top, y + top + head.height)
    canvas = Image.new('RGBA', (W, H))
    canvas.alpha_composite(im, (left, top))
    canvas.alpha_composite(head, (x + left, y + top))
    canvas.save(os.path.join(DST, name))
    m = meta[key]
    m['w'], m['h'] = W, H
    m['foot'] = [m['foot'][0] + left, m['foot'][1] + top]
    m['head'] = [cx + left, cy + top]
    out.append((key, canvas))
json.dump(meta, open(os.path.join(DST, 'poses.json'), 'w'), indent=1)
print('done', len(out))

if len(sys.argv) > 1:
    H = 300
    tiles = []
    for key, im in out:
        s = H / im.height
        t = Image.new('RGBA', (int(im.width * s), H), (120, 120, 120, 255))
        t.alpha_composite(im.resize(t.size))
        tiles.append(t)
    W = sum(t.width + 6 for t in tiles)
    rows, cur, cw = [], [], 0
    for t in tiles:
        if cw + t.width > 1800 and cur:
            rows.append(cur); cur, cw = [], 0
        cur.append(t); cw += t.width + 6
    rows.append(cur)
    sheet = Image.new('RGB', (1800, len(rows) * (H + 6)), (30, 30, 30))
    for r, row in enumerate(rows):
        x = 0
        for t in row:
            sheet.paste(t.convert('RGB'), (x, r * (H + 6))); x += t.width + 6
    sheet.save(sys.argv[1])
