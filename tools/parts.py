"""시트 PNG를 알파 기준 덩어리로 나누고, 번호를 매긴 미리보기를 만든다.
사용: python3 tools/parts.py <시트 폴더> <출력 폴더>"""
import sys, os, json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
report = {}
for name in sorted(os.listdir(src)):
    im = Image.open(os.path.join(src, name)).convert('RGBA')
    a = np.array(im)[:, :, 3]
    mask = ndimage.binary_dilation(a > 20, iterations=4)
    lab, n = ndimage.label(mask)
    boxes = []
    for i, sl in enumerate(ndimage.find_objects(lab)):
        y0, y1, x0, x1 = sl[0].start, sl[0].stop, sl[1].start, sl[1].stop
        area = int(((lab[sl] == i + 1) & (a[sl] > 20)).sum())
        if area < 60:
            continue
        boxes.append([x0, y0, x1, y1, area])
    report[name] = boxes
    prev = Image.new('RGBA', im.size, (90, 90, 90, 255))
    prev.alpha_composite(im)
    d = ImageDraw.Draw(prev)
    for k, (x0, y0, x1, y1, _) in enumerate(boxes):
        d.rectangle([x0, y0, x1, y1], outline=(255, 40, 40, 255), width=3)
        d.text((x0 + 4, y0 + 2), str(k), fill=(255, 255, 0, 255), font_size=34)
    prev.convert('RGB').save(os.path.join(out, os.path.splitext(name)[0] + '.jpg'), quality=80)
json.dump(report, open(os.path.join(out, 'boxes.json'), 'w'), indent=1)
for k, v in report.items():
    print(k, len(v), [b[:4] for b in v])
