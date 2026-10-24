// parts.js의 부위를 2배 해상도 투명 PNG로 렌더링하고, 피벗 정보를 parts.json으로 남긴다.
// 사용: node tools/art/render.js
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');
const { P, DEFS } = require('./parts');

const OUT = path.join(__dirname, '..', '..', 'game', 'art', 'parts');
const SCALE = 2;

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const b = await chromium.launch();
  const page = await b.newPage();
  const meta = {};
  for (const [name, part] of Object.entries(P)) {
    const [x, y, w, h] = part.vb;
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${x} ${y} ${w} ${h}" width="${w * SCALE}" height="${h * SCALE}">
      <defs>${DEFS}</defs><g filter="url(#ink)">${part.body}</g></svg>`;
    await page.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
    const el = await page.$('svg');
    await el.screenshot({ path: path.join(OUT, name + '.png'), omitBackground: true });
    meta[name] = { ox: x, oy: y, w, h };
  }
  fs.writeFileSync(path.join(OUT, '..', 'parts.json'), JSON.stringify({ scale: SCALE, parts: meta }, null, 1));
  console.log('rendered', Object.keys(meta).length);
  await b.close();
})();
