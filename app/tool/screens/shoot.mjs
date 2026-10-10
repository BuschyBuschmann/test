#!/usr/bin/env node
// Web-Screenshots der Preview (Plan 12.1, 12.5): alle Szenarien aus
// scenarios.json in Viewports und Varianten, Pixel-Pipette (UI-2),
// Pixel-Kontrast (UI-7, Brief-E-1), CDP-Farbsehschwäche-Simulation (UI-18/19),
// Kontaktbogen. Nichts davon wird eingecheckt (Ausgabe unter build/screens).
//
//   export PATH=/opt/flutter/bin:$PATH
//   flutter build web --release --no-web-resources-cdn -t lib/main_preview.dart
//   npx http-server build/web -p 8765 -s &
//   CHROME_EXECUTABLE=/opt/pw-browsers/chromium-1194/chrome-linux/chrome \
//     node tool/screens/shoot.mjs [Optionen]
//
// Optionen (alle optional):
//   --base=URL         Server (Standard http://127.0.0.1:8765)
//   --out=DIR          Ausgabe (Standard build/screens)
//   --only=a,b         nur diese Szenario-Kennungen
//   --variants=a,b     nur diese Varianten (normal, scale2, hc, rm)
//   --viewports=a,b    nur diese Viewports (z. B. 390x844)
//   --no-sims          ohne Farbsehschwäche-Simulation
//   --no-extras        ohne Tablet- und Querformat-Stichproben
//   --workers=N        parallele Seiten (Standard 4)
//   --clock=fixed|install|none   Fake-Uhr (Standard fixed, siehe web_checks.mjs)
//
// Exit-Code 1 bei: Pipette außerhalb der Toleranz, Kontrast < Schwelle bei
// Glow-nahem Text, Seitenfehler, Szenario nicht bereit.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  PixelAnalyzer,
  contrast,
  hexToRgb,
  launch,
  openScenario,
  rgbToHex,
} from './lib.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const appRoot = path.resolve(here, '..', '..');
const config = JSON.parse(fs.readFileSync(path.join(here, 'scenarios.json'), 'utf8'));

function arg(name, fallback) {
  const hit = process.argv.find((a) => a.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3) : fallback;
}
const flag = (name) => process.argv.includes(`--${name}`);

const base = arg('base', process.env.BASE_URL || 'http://127.0.0.1:8765');
const outDir = path.resolve(arg('out', path.join(appRoot, 'build', 'screens')));
const only = arg('only', '')?.split(',').filter(Boolean);
const onlyVariants = arg('variants', '')?.split(',').filter(Boolean);
const onlyViewports = arg('viewports', '')?.split(',').filter(Boolean);
// Dauer-Animationen (cmp-busy) rendern in Software sehr langsam (ca. 12 s je
// Bild allein, mehr bei 4 Workern): großzügige Frist bis CURA_READY.
const READY_TIMEOUT_MS = 120000;
const workers = Number(arg('workers', '4'));
const clock = arg('clock', 'fixed');
const DPR = 2;

const scenarios = config.scenarios.filter((s) => !only.length || only.includes(s));

// --- Aufträge -----------------------------------------------------------------
const jobs = [];
const pick = (list, filter, key = (x) => x) => list.filter((x) => !filter.length || filter.includes(key(x)));
// Szenarien mit festem Skalierungswert (z. B. chat-manny-scale15) ignorieren den
// Parameter `scale`: die Variante scale2 entfällt für sie.
const fixedScale = new Set(config.fixedScale ?? []);
for (const variant of pick(Object.keys(config.variants), onlyVariants)) {
  for (const vp of pick(config.viewports, onlyViewports, (v) => v.name)) {
    for (const id of scenarios) {
      if (variant === 'scale2' && fixedScale.has(id)) continue;
      jobs.push({ kind: 'shot', variant, vp, id, params: { scenario: id, ...config.variants[variant] } });
    }
  }
}
if (!flag('no-extras')) {
  for (const id of config.tablet.scenarios.filter((s) => scenarios.includes(s))) {
    jobs.push({ kind: 'shot', variant: 'normal', vp: config.tablet.viewport, id, params: { scenario: id } });
  }
  for (const vp of config.landscape.viewports) {
    for (const id of config.landscape.scenarios.filter((s) => scenarios.includes(s))) {
      jobs.push({ kind: 'shot', variant: 'normal', vp, id, params: { scenario: id } });
    }
  }
}
if (!flag('no-sims')) {
  const sim = config.simulations;
  for (const id of scenarios) {
    for (const type of sim.all) jobs.push({ kind: 'sim', type, vp: sim.viewport, id });
  }
  for (const id of sim.colorBlind.scenarios.filter((s) => scenarios.includes(s))) {
    for (const type of sim.colorBlind.types) jobs.push({ kind: 'sim', type, vp: sim.viewport, id });
  }
}

// --- Ausführung ---------------------------------------------------------------
const started = Date.now();
const browser = await launch();
const analyzer = await PixelAnalyzer.create(browser);
const results = [];
const problems = [];

const ctxCache = new Map(); // je Worker und Viewport ein Kontext
async function contextFor(worker, vp) {
  const key = `${worker}:${vp.name}`;
  if (!ctxCache.has(key)) {
    ctxCache.set(
      key,
      await browser.newContext({
        viewport: { width: vp.w, height: vp.h },
        deviceScaleFactor: DPR,
        timezoneId: 'Europe/Berlin',
        locale: 'de-DE',
      }),
    );
  }
  return ctxCache.get(key);
}

function save(rel, buffer) {
  const file = path.join(outDir, rel);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, buffer);
  return rel;
}

async function runShot(worker, job) {
  const ctx = await contextFor(worker, job.vp);
  const s = await openScenario(ctx, base, { ...job.params, dumpText: 1 }, { clock, now: config.now, timeoutMs: READY_TIMEOUT_MS });
  try {
    if (!s.ready) problems.push(`${job.variant}/${job.vp.name}/${job.id}: nicht bereit (Timeout)`);
    if (s.ready && s.settled === false && !s.env?.loops) {
      problems.push(`${job.variant}/${job.vp.name}/${job.id}: nicht zur Ruhe gekommen (Animation läuft weiter, Szenario nicht als loops markiert; ${JSON.stringify(s.readyInfo)})`);
    }
    if (s.error) problems.push(`${job.variant}/${job.vp.name}/${job.id}: ${s.error.slice(0, 200)}`);
    const png = await s.page.screenshot();
    const rel = save(path.join(job.variant, job.vp.name, `${job.id}.png`), png);
    const rec = { ...job, rel, env: s.env, dump: s.dump, contrast: [], pipette: [] };
    if (s.dump) {
      rec.contrast = await measureContrast(png, s.dump, job);
      if (job.id === config.pipette.scenario && job.variant === 'normal') {
        rec.pipette = await measurePipette(png, s.dump, job);
      }
    }
    results.push(rec);
  } finally {
    await s.page.close();
  }
}

async function measureContrast(png, dump, job) {
  const rows = [];
  // Scrollender Inhalt, der unter einem festen Overlay (Nav, Button-Gruppe,
  // Primärbutton-Reihe) liegt, ist dort verdeckt: Das Median-Verfahren würde die
  // Farbe des Overlays als Untergrund lesen. Nur Texte des Overlays selbst
  // und Texte ohne Überschneidung zählen.
  const overlays = Object.values(dump.overlays ?? {});
  const hidden = (t) =>
    !t.inOverlay &&
    overlays.some((o) => t.x < o.x + o.w && t.x + t.w > o.x && t.y < o.y + o.h && t.y + t.h > o.y);
  const texts = dump.texts.filter(
    (t) => t.onScreen && !hidden(t) && t.glowAlpha > 0 && t.ground !== 'opaque' && t.colorAlpha >= 0.999,
  );
  if (!texts.length) return rows;
  const requests = texts.map((t, i) => ({
    id: i,
    kind: 'textBackground',
    rect: { x: t.x, y: t.y, w: t.w, h: t.h },
    color: hexToRgb(t.color),
  }));
  const { results: res } = await analyzer.analyze(png, dump.view.dpr, requests, config.contrast.textTolerance);
  texts.forEach((t, i) => {
    const m = res[i];
    const fg = hexToRgb(t.color);
    const ratio = m.rgb && m.n >= 20 ? contrast(fg, m.rgb) : null;
    const row = {
      variant: job.variant,
      viewport: job.vp.name,
      scenario: job.id,
      text: t.text.replace(/\s+/g, ' ').slice(0, 40),
      ground: t.ground,
      glowAlpha: t.glowAlpha,
      textColor: t.color,
      measuredBackground: m.rgb ? rgbToHex(m.rgb) : '',
      samples: m.n,
      ratio,
      kind: t.isIcon ? 'icon' : 'text',
      limit: t.isIcon ? config.contrast.minRatioIcon : config.contrast.minRatio,
      status: ratio === null ? 'n/a' : ratio >= (t.isIcon ? config.contrast.minRatioIcon : config.contrast.minRatio) ? 'ok' : 'FEHLER',
    };
    rows.push(row);
    if (row.status === 'n/a') {
      problems.push(
        `Kontrast ${job.variant}/${job.vp.name}/${job.id} ${row.kind === 'icon' ? 'Symbol' : `„${row.text}“`}: nicht messbar (${m.n} Messpunkte < 20)`,
      );
    }
    if (row.status === 'FEHLER') {
      problems.push(
        `Kontrast ${job.variant}/${job.vp.name}/${job.id} ${row.kind === 'icon' ? 'Symbol' : `„${row.text}“`}: ${ratio.toFixed(2)} < ${row.limit}`,
      );
    }
  });
  return rows;
}

async function measurePipette(png, dump, job) {
  const p = config.pipette;
  const tol = p.tolerance;
  const bg = dump.probes['probe:bg'];
  const prim = dump.probes['probe:primary'];
  const title = dump.probes['probe:title'];
  const requests = [];
  if (bg) requests.push({ id: 'background', kind: 'point', x: bg.x + bg.w / 2, y: bg.y + bg.h / 2 });
  // Primärbutton: Pixel nahe dem linken Ende, weit vor dem Label
  if (prim) requests.push({ id: 'primary', kind: 'point', x: prim.x + prim.h / 2 + 12, y: prim.y + prim.h / 2 });
  if (title) requests.push({ id: 'title', kind: 'dominant', rect: { x: title.x, y: title.y, w: title.w, h: title.h } });
  const { results } = await analyzer.analyze(png, dump.view.dpr, requests);
  const expected = { background: p.background, primary: p.primary, title: p.title };
  const rows = [];
  for (const r of results) {
    const want = hexToRgb(expected[r.id]);
    const got = r.rgb;
    const delta = got ? Math.max(...got.map((v, i) => Math.abs(v - want[i]))) : null;
    const ok = delta !== null && delta <= tol;
    rows.push({ id: r.id, expected: expected[r.id], got: got ? rgbToHex(got) : null, delta, ok });
    if (!ok) problems.push(`Pipette ${job.vp.name} ${r.id}: erwartet ${expected[r.id]}, gemessen ${got ? rgbToHex(got) : '–'}`);
  }
  for (const id of ['background', 'primary', 'title']) {
    if (!rows.find((r) => r.id === id)) {
      problems.push(`Pipette ${job.vp.name}: Messpunkt ${id} fehlt im Szenario`);
    }
  }
  return rows;
}

async function runSim(worker, job) {
  const ctx = await contextFor(worker, job.vp);
  const s = await openScenario(ctx, base, { scenario: job.id }, { clock, now: config.now, timeoutMs: READY_TIMEOUT_MS });
  try {
    if (!s.ready) problems.push(`sim-${job.type}/${job.id}: nicht bereit`);
    const normal = await s.page.screenshot();
    const cdp = await ctx.newCDPSession(s.page);
    await cdp.send('Emulation.setEmulatedVisionDeficiency', { type: job.type });
    await s.page.waitForTimeout(200);
    const sim = await s.page.screenshot();
    await cdp.send('Emulation.setEmulatedVisionDeficiency', { type: 'none' });
    const rel = save(path.join(`sim-${job.type}`, job.vp.name, `${job.id}.png`), sim);
    // Plausibilität: Achromatopsie = Graustufen; sonst muss sich das Bild vom
    // normalen unterscheiden, sofern es farbige Pixel enthält.
    const [{ results: n }, { results: m }] = await Promise.all([
      analyzer.analyze(normal, DPR, [{ id: 'sat', kind: 'saturated', tol: 24 }, { id: 'gray', kind: 'grayscale', tol: 3 }]),
      analyzer.analyze(sim, DPR, [{ id: 'sat', kind: 'saturated', tol: 24 }, { id: 'gray', kind: 'grayscale', tol: 3 }]),
    ]);
    const normalSat = n[0].share;
    const simSat = m[0].share;
    const simGray = m[1].share;
    const differs = Buffer.compare(normal, sim) !== 0;
    let ok = differs || normalSat === 0;
    if (job.type === 'achromatopsia') ok = simGray >= 0.999;
    const rec = { ...job, rel, normalSaturatedShare: normalSat, simSaturatedShare: simSat, simGrayShare: simGray, differs, ok };
    results.push(rec);
    if (!ok) problems.push(`Simulation ${job.type}/${job.id}: wirkt nicht (grau ${simGray.toFixed(4)}, verschieden ${differs})`);
  } finally {
    await s.page.close();
  }
}

let next = 0;
async function worker(i) {
  while (next < jobs.length) {
    const job = jobs[next++];
    try {
      if (job.kind === 'shot') await runShot(i, job);
      else await runSim(i, job);
    } catch (e) {
      problems.push(`${job.kind} ${job.variant ?? job.type}/${job.vp.name}/${job.id}: ${e.message}`);
    }
  }
}
await Promise.all(Array.from({ length: workers }, (_, i) => worker(i)));
await browser.close();
const seconds = (Date.now() - started) / 1000;

// --- Ausgabe ------------------------------------------------------------------
const shots = results.filter((r) => r.kind === 'shot');
const sims = results.filter((r) => r.kind === 'sim');
const contrastRows = shots.flatMap((r) => r.contrast);
const csv = [
  'variant,viewport,scenario,kind,text,ground,glowAlpha,textColor,measuredBackground,samples,ratio,limit,status',
  ...contrastRows.map((c) =>
    [
      c.variant,
      c.viewport,
      c.scenario,
      c.kind,
      JSON.stringify(c.text),
      c.ground,
      c.glowAlpha.toFixed(4),
      c.textColor,
      c.measuredBackground,
      c.samples,
      c.ratio === null ? '' : c.ratio.toFixed(2),
      c.limit,
      c.status,
    ].join(','),
  ),
].join('\n');
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'contrast.csv'), csv + '\n');

const pipette = shots.flatMap((r) => r.pipette.map((p) => ({ viewport: r.vp.name, ...p })));
const report = {
  seconds,
  workers,
  clock,
  images: results.length,
  shots: shots.length,
  simulations: sims.length,
  contrast: {
    measured: contrastRows.filter((c) => c.status !== 'n/a').length,
    notMeasurable: contrastRows.filter((c) => c.status === 'n/a').length,
    failed: contrastRows.filter((c) => c.status === 'FEHLER').length,
    lowest: contrastRows.filter((c) => c.ratio !== null).sort((a, b) => a.ratio - b.ratio).slice(0, 5),
  },
  pipette,
  simulationsDetail: sims.map(({ type, id, simGrayShare, differs, ok }) => ({ type, id, simGrayShare, differs, ok })),
  systemSignals: shots[0]?.env?.system ?? null,
  problems,
};
fs.writeFileSync(path.join(outDir, 'report.json'), JSON.stringify(report, null, 2));
fs.writeFileSync(path.join(outDir, 'index.html'), contactSheet(results, contrastRows, report));

console.log(`Bilder: ${results.length} (${shots.length} Szenario-Bilder, ${sims.length} Simulationen) in ${seconds.toFixed(1)} s, ${workers} Seiten parallel`);
console.log(
  `Pixel-Kontrast: ${report.contrast.measured} Texte/Symbole gemessen, ${report.contrast.failed} unter Schwelle (${config.contrast.minRatio} Text, ${config.contrast.minRatioIcon} Symbol), ${report.contrast.notMeasurable} nicht messbar`,
);
for (const p of pipette) console.log(`Pipette ${p.viewport} ${p.id}: erwartet ${p.expected}, gemessen ${p.got} (Δ ${p.delta}) ${p.ok ? 'ok' : 'FEHLER'}`);
console.log(`Ausgabe: ${outDir}`);
if (problems.length) {
  console.log(`\n${problems.length} Problem(e):`);
  for (const p of problems) console.log(' - ' + p);
  process.exit(1);
}

function esc(s) {
  return String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
}

function contactSheet(all, contrastAll, rep) {
  const groups = new Map();
  for (const r of all) {
    const key = r.kind === 'sim' ? `sim-${r.type} · ${r.vp.name}` : `${r.variant} · ${r.vp.name}`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(r);
  }
  const fails = new Set(contrastAll.filter((c) => c.status === 'FEHLER').map((c) => `${c.variant}/${c.viewport}/${c.scenario}`));
  let html = `<!doctype html><meta charset="utf-8"><title>CuraOne Screenshots</title>
<style>body{font:14px system-ui;background:#111;color:#eee;margin:16px}h2{margin-top:32px}
.grid{display:flex;flex-wrap:wrap;gap:12px}figure{margin:0}img{height:360px;border:1px solid #444;display:block}
figcaption{font-size:12px;color:#aaa;margin-top:4px}.bad{color:#f66}</style>
<h1>CuraOne Prüfumgebung</h1><p>${rep.images} Bilder in ${rep.seconds.toFixed(1)} s · Kontrast gemessen: ${rep.contrast.measured}, unter Schwelle: ${rep.contrast.failed}</p>`;
  for (const [key, list] of groups) {
    html += `<h2>${esc(key)}</h2><div class="grid">`;
    for (const r of list) {
      const bad = r.kind === 'shot' && fails.has(`${r.variant}/${r.vp.name}/${r.id}`);
      html += `<figure><a href="${esc(r.rel)}"><img loading="lazy" src="${esc(r.rel)}"></a><figcaption class="${bad ? 'bad' : ''}">${esc(r.id)}${bad ? ' · Kontrast' : ''}</figcaption></figure>`;
    }
    html += '</div>';
  }
  return html;
}
