// Gemeinsame Helfer für shoot.mjs und web_checks.mjs (Plan 12.5).
// Playwright kommt aus der globalen Installation (`npm ls -g playwright`,
// Version 1.56.1 passt zu chromium-1194 unter /opt/pw-browsers). Es wird nichts
// installiert; `playwright install` ist nicht nötig.
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';

const here = createRequire(import.meta.url);

export function loadPlaywright() {
  const candidates = [
    () => here('playwright'),
    () => here('playwright-core'),
    () => createRequire('/opt/node22/lib/node_modules/')('playwright'),
    () => createRequire(path.join(process.env.NODE_GLOBAL || '/usr/lib/node_modules', '/'))('playwright'),
  ];
  for (const c of candidates) {
    try {
      return c();
    } catch {
      /* nächster Versuch */
    }
  }
  throw new Error('playwright nicht gefunden (global installieren oder NODE_PATH setzen)');
}

export function chromeExecutable() {
  const fromEnv = process.env.CHROME_EXECUTABLE;
  if (fromEnv) return fromEnv;
  const base = process.env.PLAYWRIGHT_BROWSERS_PATH || '/opt/pw-browsers';
  const dir = fs.readdirSync(base).filter((d) => /^chromium-\d+$/.test(d)).sort().pop();
  if (!dir) throw new Error(`kein chromium-* unter ${base}`);
  return path.join(base, dir, 'chrome-linux', 'chrome');
}

export async function launch() {
  const { chromium } = loadPlaywright();
  return chromium.launch({
    executablePath: chromeExecutable(),
    // CanvasKit braucht WebGL; ohne GPU über SwiftShader.
    args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--hide-scrollbars'],
  });
}

export function query(params) {
  const q = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== '') q.set(k, String(v));
  }
  return q.toString();
}

/**
 * Öffnet ein Szenario in einer neuen Seite von [context], wartet auf
 * `CURA_READY` und liefert die Seite samt `CURA_ENV`/`CURA_DUMP`.
 * clock: 'fixed' (Date.now() eingefroren), 'install' (Fake-Uhr ab Zeitpunkt,
 * Zeit läuft weiter) oder 'none'.
 */
export async function openScenario(context, baseUrl, params, opts = {}) {
  const { clock = 'fixed', now, timeoutMs = 30000, beforeGoto } = opts;
  const page = await context.newPage();
  const messages = [];
  const errors = [];
  page.on('console', (m) => messages.push(m.text()));
  page.on('pageerror', (e) => errors.push(String(e)));
  if (now && clock === 'fixed') await page.clock.setFixedTime(new Date(now));
  if (now && clock === 'install') await page.clock.install({ time: new Date(now) });
  if (beforeGoto) await beforeGoto(page);
  await page.goto(`${baseUrl}/?${query(params)}`);
  const started = Date.now();
  let ready = false;
  while (Date.now() - started < timeoutMs) {
    if (messages.some((m) => m.startsWith('CURA_READY'))) {
      ready = true;
      break;
    }
    await page.waitForTimeout(50);
  }
  const find = (marker) => {
    const line = messages.find((m) => m.startsWith(marker + ' '));
    return line ? JSON.parse(line.slice(marker.length + 1)) : null;
  };
  const readyLine = messages.find((m) => m.startsWith('CURA_READY'));
  const readyInfo = readyLine && readyLine.slice(10).trim() ? JSON.parse(readyLine.slice(10)) : null;
  const settled = readyInfo ? readyInfo.settled : null;
  const flutterError = messages.find((m) => m.startsWith('CURA_ERROR'));
  return {
    page,
    ready,
    settled,
    readyInfo,
    env: find('CURA_ENV'),
    dump: find('CURA_DUMP'),
    error: flutterError ?? (errors.length ? errors.join('\n') : null),
    messages,
  };
}

// --- Farben und Kontrast ----------------------------------------------------

export function hexToRgb(hex) {
  const h = hex.replace('#', '');
  return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
}

export function rgbToHex([r, g, b]) {
  return '#' + [r, g, b].map((v) => v.toString(16).padStart(2, '0')).join('').toUpperCase();
}

function lin(c) {
  const v = c / 255;
  return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
}

export function luminance([r, g, b]) {
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
}

export function contrast(a, b) {
  const la = luminance(a);
  const lb = luminance(b);
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}

// --- Pixel-Analyse im Browser ----------------------------------------------
// Das PNG wird in einer leeren Seite des Browsers dekodiert (kein Node-Paket
// nötig); gemessen wird nur dort, zurück kommen kleine Ergebnisse.

async function analyzeInPage(args) {
  const { b64, dpr, requests, textTolerance } = args;
  const blob = await (await fetch('data:image/png;base64,' + b64)).blob();
  const bmp = await createImageBitmap(blob, { colorSpaceConversion: 'none', premultiplyAlpha: 'none' });
  const canvas = new OffscreenCanvas(bmp.width, bmp.height);
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  ctx.drawImage(bmp, 0, 0);
  const img = ctx.getImageData(0, 0, bmp.width, bmp.height);
  const d = img.data;
  const W = bmp.width, H = bmp.height;
  const px = (x, y) => { const i = (y * W + x) * 4; return [d[i], d[i + 1], d[i + 2]]; };
  const median = (arr) => { const s = arr.slice().sort((a, b) => a - b); return s[Math.floor(s.length / 2)]; };
  const clampRect = (r) => {
    const x0 = Math.max(0, Math.floor(r.x * dpr)), y0 = Math.max(0, Math.floor(r.y * dpr));
    const x1 = Math.min(W, Math.ceil((r.x + r.w) * dpr)), y1 = Math.min(H, Math.ceil((r.y + r.h) * dpr));
    return { x0, y0, x1, y1 };
  };
  const out = [];
  for (const q of requests) {
    if (q.kind === 'point') {
      const x = Math.min(W - 1, Math.max(0, Math.round(q.x * dpr)));
      const y = Math.min(H - 1, Math.max(0, Math.round(q.y * dpr)));
      out.push({ id: q.id, rgb: px(x, y) });
    } else if (q.kind === 'dominant') {
      // häufigste Farbe, die sich vom Untergrund (Median) deutlich unterscheidet
      const { x0, y0, x1, y1 } = clampRect(q.rect);
      const all = [[], [], []];
      for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) { const p = px(x, y); for (let c = 0; c < 3; c++) all[c].push(p[c]); }
      const bg = all.map(median);
      const hist = new Map();
      for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
        const p = px(x, y);
        if (Math.max(Math.abs(p[0] - bg[0]), Math.abs(p[1] - bg[1]), Math.abs(p[2] - bg[2])) < 60) continue;
        const k = p[0] * 65536 + p[1] * 256 + p[2];
        hist.set(k, (hist.get(k) || 0) + 1);
      }
      let best = null, n = 0;
      for (const [k, v] of hist) if (v > n) { n = v; best = k; }
      out.push({ id: q.id, rgb: best === null ? null : [(best >> 16) & 255, (best >> 8) & 255, best & 255], count: n, bg });
    } else if (q.kind === 'textBackground') {
      // Untergrund = Median der Pixel im Text-Rechteck, die nicht der Textfarbe entsprechen
      const { x0, y0, x1, y1 } = clampRect(q.rect);
      const tc = q.color, tol = textTolerance;
      const rs = [], gs = [], bs = [];
      for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
        const p = px(x, y);
        if (Math.abs(p[0] - tc[0]) <= tol && Math.abs(p[1] - tc[1]) <= tol && Math.abs(p[2] - tc[2]) <= tol) continue;
        rs.push(p[0]); gs.push(p[1]); bs.push(p[2]);
      }
      out.push({ id: q.id, n: rs.length, rgb: rs.length ? [median(rs), median(gs), median(bs)] : null });
    } else if (q.kind === 'grayscale') {
      let gray = 0, total = 0;
      for (let i = 0; i < d.length; i += 4) {
        total++;
        if (Math.abs(d[i] - d[i + 1]) <= q.tol && Math.abs(d[i + 1] - d[i + 2]) <= q.tol) gray++;
      }
      out.push({ id: q.id, share: gray / total });
    } else if (q.kind === 'saturated') {
      let sat = 0, total = 0;
      for (let i = 0; i < d.length; i += 4) {
        total++;
        if (Math.max(d[i], d[i + 1], d[i + 2]) - Math.min(d[i], d[i + 1], d[i + 2]) > q.tol) sat++;
      }
      out.push({ id: q.id, share: sat / total });
    }
  }
  return { w: W, h: H, results: out };
}

export class PixelAnalyzer {
  constructor(page) {
    this.page = page;
  }

  static async create(browser) {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    await page.goto('about:blank');
    return new PixelAnalyzer(page);
  }

  /** [png]: Buffer; [requests]: Messaufträge (siehe analyzeInPage). */
  async analyze(png, dpr, requests, textTolerance = 12) {
    return this.page.evaluate(analyzeInPage, {
      b64: png.toString('base64'),
      dpr,
      requests,
      textTolerance,
    });
  }
}
