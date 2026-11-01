"""엄지척 아재(짬타이거 대신)와 직접 그린 총구 이펙트를 게임용 그림으로 만든다.
art_src/sium/thumb.png, gunfx.png, durandal_fx.png -> game/art/sium/"""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = 'art_src/sium/'
OUT = 'game/art/sium/'


def thumb():
    im = np.array(Image.open(SRC + 'thumb.png').convert('RGB')).astype(int)
    # 흰 배경과 그 둘레의 옅은 회색 번짐까지 배경으로 본다
    white = (im.min(axis=2) > 185) & (im.max(axis=2) - im.min(axis=2) < 30)
    lab, _ = ndimage.label(white)
    edge = set(lab[0]) | set(lab[-1]) | set(lab[:, 0]) | set(lab[:, -1])
    edge.discard(0)
    bg = np.isin(lab, list(edge))
    # 테두리 반 픽셀 정도 부드럽게
    bg = ndimage.binary_dilation(bg, iterations=2)
    # 떨어져 있는 부스러기 점은 지우고 가장 큰 덩어리(사람)만 남긴다
    fg, n = ndimage.label(~bg)
    sizes = ndimage.sum(np.ones_like(fg), fg, range(1, n + 1))
    bg = fg != (np.argmax(sizes) + 1)
    alpha = (~bg).astype(float)
    alpha = ndimage.gaussian_filter(alpha, 0.6)
    out = np.dstack([im, (alpha * 255).clip(0, 255)]).astype(np.uint8)
    img = Image.fromarray(out, 'RGBA')
    img = img.crop(img.getbbox())
    img.save(OUT + 'thumb.png')
    print('thumb', img.size)


def gunfx():
    im = Image.open(SRC + 'gunfx.png')
    a = np.array(im.convert('RGBA')).astype(int)
    dark = (a[..., :3].max(axis=2) < 128) & (a[..., 3] > 128)
    line = ndimage.binary_dilation(dark, iterations=2)
    rim = ndimage.binary_dilation(line, iterations=3) & ~line
    h, w = dark.shape
    out = np.zeros((h, w, 4), np.uint8)
    out[rim] = (255, 255, 255, 255)
    out[line] = (20, 18, 16, 255)
    img = Image.fromarray(out, 'RGBA')
    img = img.crop(img.getbbox())
    img.save(OUT + 'gunfx.png')
    print('gunfx', img.size)


def durandal_fx():
    """뒤랑달 이펙트: 직접 그린 초승달. 안을 하얗게 채우고 검은 테두리를 굵게"""
    im = Image.open(SRC + 'durandal_fx.png').convert('RGBA')
    bg = Image.new('RGBA', im.size, (255, 255, 255, 255))
    bg.alpha_composite(im)
    dark = np.array(bg.convert('L')) < 128
    line = ndimage.binary_dilation(dark, iterations=3)
    lab, n = ndimage.label(line)
    sizes = ndimage.sum(line, lab, range(1, n + 1))
    line = lab == (np.argmax(sizes) + 1)
    inside = ndimage.binary_fill_holes(line) & ~line
    h, w = dark.shape
    out = np.zeros((h, w, 4), np.uint8)
    out[inside] = (250, 250, 248, 240)
    out[line] = (16, 14, 14, 255)
    img = Image.fromarray(out, 'RGBA')
    img = img.crop(img.getbbox())
    img.save(OUT + 'durandal_fx.png')
    print('durandal_fx', img.size)


def durandal_fx2():
    """뒤랑달 이펙트: 직접 그린 두꺼운 \")\" 띠. 왼쪽 두 끝이 열려 있으므로 안팎 선의 끝을 이어 닫고 안을 하얗게 채운다"""
    from PIL import ImageDraw
    im = Image.open(SRC + 'durandal_fx2.png').convert('RGBA')
    bg = Image.new('RGBA', im.size, (255, 255, 255, 255))
    bg.alpha_composite(im)
    dark = np.array(bg.convert('L')) < 128
    lab, n = ndimage.label(ndimage.binary_dilation(dark, iterations=1))
    sizes = ndimage.sum(dark, lab, range(1, n + 1))
    strokes = [k + 1 for k in np.argsort(sizes)[::-1][:2]]
    ends = []
    for k in strokes:
        yy, xx = np.where(lab == k)
        mid = (yy.min() + yy.max()) / 2
        top = [(x, y) for x, y in zip(xx, yy) if y < mid]
        bot = [(x, y) for x, y in zip(xx, yy) if y >= mid]
        ends.append((min(top), min(bot)))
    d = ImageDraw.Draw(bg)
    d.line([tuple(map(int, ends[0][0])), tuple(map(int, ends[1][0]))], fill=(0, 0, 0, 255), width=3)
    d.line([tuple(map(int, ends[0][1])), tuple(map(int, ends[1][1]))], fill=(0, 0, 0, 255), width=3)
    dark = np.array(bg.convert('L')) < 128
    line = ndimage.binary_dilation(dark, iterations=3)
    lab, n = ndimage.label(line)
    sizes = ndimage.sum(line, lab, range(1, n + 1))
    line = lab == (np.argmax(sizes) + 1)
    inside = ndimage.binary_fill_holes(line) & ~line
    h, w = dark.shape
    out = np.zeros((h, w, 4), np.uint8)
    out[inside] = (250, 250, 248, 240)
    out[line] = (16, 14, 14, 255)
    img = Image.fromarray(out, 'RGBA')
    img = img.crop(img.getbbox())
    img.save(OUT + 'durandal_fx2.png')
    print('durandal_fx2', img.size)


thumb()
gunfx()
