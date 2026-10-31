"""Godot 웹 내보내기 결과를 Artifact로 올릴 수 있는 형태로 바꾼다.
- index.wasm(약 35MB)을 gzip으로 줄여 index.wasm.bin으로 저장하고, 페이지에서 받아 풀어 쓴다.
- 문서 뼈대 없이 쓰는 play.html과, 뼈대를 갖춘 index.html(파일로 올리는 Artifact용)을 만든다.
사용: python3 tools/web_page.py  (build/web -> build/artifact)
"""
import gzip
import json
import os
import re
import shutil

ROOT = os.path.join(os.path.dirname(__file__), '..', 'build')
SRC = os.path.join(ROOT, 'web')
OUT = os.path.join(ROOT, 'artifact')

os.makedirs(OUT, exist_ok=True)
html = open(os.path.join(SRC, 'index.html'), encoding='utf-8').read()
config = json.loads(re.search(r'const GODOT_CONFIG = (\{.*?\});', html).group(1))
config['ensureCrossOriginIsolationHeaders'] = False

# Artifact는 .pck와 .bin을 내주지 않아서, 두 바이너리를 gzip으로 줄여 .wasm 이름으로 둔다
for src, dst in [('index.wasm', 'engine.wasm'), ('index.pck', 'data.wasm')]:
    with open(os.path.join(SRC, src), 'rb') as f, gzip.open(os.path.join(OUT, dst), 'wb', 9) as g:
        shutil.copyfileobj(f, g)
for old in ['index.wasm.bin', 'index.pck']:
    if os.path.exists(os.path.join(OUT, old)):
        os.remove(os.path.join(OUT, old))
for name in ['index.js', 'index.audio.worklet.js']:
    shutil.copy(os.path.join(SRC, name), os.path.join(OUT, name))

page = """<title>짬타이거</title>
<style>
  :root { --bg: #0b0908; --fg: #e6bd5c; color-scheme: dark; }
  html, body { height: 100%; margin: 0; background: var(--bg); overflow: hidden; }
  #canvas { display: block; width: 100%; height: 100%; outline: none; touch-action: none; }
  #status { position: fixed; inset: 0; display: grid; place-items: center; color: var(--fg); background: var(--bg);
    font: 700 20px/1.6 'Apple SD Gothic Neo', 'Malgun Gothic', system-ui, sans-serif; text-align: center; padding: 16px; }
  #bar { width: min(320px, 80vw); height: 8px; margin: 12px auto 0; border: 1px solid #6d3f14; border-radius: 4px; overflow: hidden; }
  #fill { width: 0; height: 100%; background: var(--fg); transition: width .2s; }
</style>
<canvas id="canvas">브라우저가 캔버스를 지원하지 않습니다.</canvas>
<div id="status"><div><div id="msg">짬타이거 불러오는 중…</div><div id="bar"><div id="fill"></div></div></div></div>
<script src="index.js"></script>
<script>
const GODOT_CONFIG = __CONFIG__;
// index.wasm과 index.pck는 gzip 압축본(engine.wasm, data.wasm)을 받아 브라우저에서 푼다
const MAP = { 'index.wasm': 'engine.wasm', 'index.pck': 'data.wasm' };
const realFetch = window.fetch.bind(window);
window.fetch = async (input, init) => {
  const url = typeof input === 'string' ? input : input.url;
  const key = Object.keys(MAP).find((k) => url.endsWith(k));
  if (!key) return realFetch(input, init);
  const res = await realFetch(url.slice(0, url.length - key.length) + MAP[key], init);
  const buf = new Uint8Array(await res.arrayBuffer());
  let body = buf;
  if (buf[0] === 0x1f && buf[1] === 0x8b) {
    body = await new Response(new Blob([buf]).stream().pipeThrough(new DecompressionStream('gzip'))).arrayBuffer();
  }
  const type = key.endsWith('.wasm') ? 'application/wasm' : 'application/octet-stream';
  return new Response(body, { status: 200, headers: { 'Content-Type': type } });
};
const status = document.getElementById('status');
const fill = document.getElementById('fill');
const engine = new Engine(GODOT_CONFIG);
engine.startGame({
  onProgress: (cur, total) => { if (total > 0) fill.style.width = Math.min(100, cur / total * 100) + '%'; },
}).then(() => { status.remove(); }, (err) => {
  document.getElementById('msg').textContent = '게임을 시작하지 못했습니다. 새로고침해 주세요. (' + err + ')';
});
</script>
""".replace('__CONFIG__', json.dumps(config))
open(os.path.join(OUT, 'play.html'), 'w', encoding='utf-8').write(page)
head = '<!DOCTYPE html>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n'
open(os.path.join(OUT, 'index.html'), 'w', encoding='utf-8').write(head + page)
for n in sorted(os.listdir(OUT)):
    print(n, os.path.getsize(os.path.join(OUT, n)))
