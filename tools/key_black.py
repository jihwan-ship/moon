"""검은 배경(0,0,0)으로 저장된 무기 그림의 배경을 투명하게 만든다.
가장자리에서 이어진 순수 검정 픽셀만 지운다(무기 안쪽의 어두운 부분은 남는다).
사용: python3 tools/key_black.py <입력.png> <출력.png>
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGBA')
a = np.array(im)
black = a[:, :, :3].astype(int).sum(2) <= 6
lab, _ = ndimage.label(black)
edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.isin(lab, list(edge))
# 가장자리 1픽셀을 반투명으로 다듬어 검은 테두리가 덜 남게 한다
near = ndimage.binary_dilation(bg) & ~bg
a[bg, 3] = 0
a[near, 3] = np.minimum(a[near, 3], (a[near, :3].max(1).astype(int) * 4).clip(0, 255)).astype(np.uint8)
out = Image.fromarray(a)
out = out.crop(out.getbbox())
out.save(dst)
print(dst, out.size)
