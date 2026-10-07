#!/usr/bin/env node
// Klärung der offenen Web-Punkte aus Plan 12.5 (wiederholbar):
//  (a) Fake-Uhr mit CanvasKit: rendert Flutter weiter, folgen Dart-Timer?
//  (b) Browser-Signal Hoher Kontrast (forced-colors) und Bewegung reduzieren
//      (prefers-reduced-motion): kommt es als Systemsignal an, wirkt es?
// Aufruf: node tool/screens/web_checks.mjs [--base=http://127.0.0.1:8765]
import crypto from 'node:crypto';

import { launch, openScenario } from './lib.mjs';

const base = (process.argv.find((a) => a.startsWith('--base=')) ?? '').slice(7) || 'http://127.0.0.1:8765';
const NOW = '2026-10-07T23:59:50+02:00';
const results = [];
const check = (name, ok, detail) => {
  results.push({ name, ok, detail });
  console.log(`${ok ? 'ok     ' : 'FEHLER '} ${name}${detail ? ' – ' + detail : ''}`);
};
const info = (name, detail) => {
  results.push({ name, ok: null, detail });
  console.log(`info    ${name} – ${detail}`);
};
const md5 = (b) => crypto.createHash('md5').update(b).digest('hex').slice(0, 8);

const browser = await launch();
const ctxOptions = { viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, timezoneId: 'Europe/Berlin', locale: 'de-DE' };

// (a) Fake-Uhr --------------------------------------------------------------
{
  const ctx = await browser.newContext(ctxOptions);
  const s = await openScenario(ctx, base, { scenario: 'cmp-snackbar' }, { clock: 'fixed', now: NOW });
  check('(a) setFixedTime: Szenario rendert und wird ruhig', s.ready);
  check(
    '(a) setFixedTime: Dart-DateTime.now() = gesetzte Zeit',
    s.env?.dartNow === '2026-10-07T23:59:50.000',
    s.env?.dartNow,
  );
  const before = md5(await s.page.screenshot());
  await s.page.waitForTimeout(9500); // Snackbar-Timer (8 s) läuft in Echtzeit
  const after = md5(await s.page.screenshot());
  check('(a) setFixedTime: Dart-Timer und Frames laufen weiter (Snackbar endet nach 8 s)', before !== after);
  await ctx.close();
}
{
  const ctx = await browser.newContext(ctxOptions);
  const s = await openScenario(ctx, base, { scenario: 'cmp-snackbar' }, { clock: 'install', now: NOW });
  check('(a) clock.install: Szenario rendert und wird ruhig', s.ready);
  const before = md5(await s.page.screenshot());
  const t0 = await s.page.evaluate(() => new Date().toString());
  await s.page.clock.runFor(30000); // 30 s: über Mitternacht, Snackbar-Timer läuft ab
  await s.page.waitForTimeout(500);
  const t1 = await s.page.evaluate(() => new Date().toString());
  const after = md5(await s.page.screenshot());
  check('(a) clock.install: Zeitsprung über Mitternacht (Date)', t0.includes('Oct 07') && t1.includes('Oct 08'), `${t0.slice(0, 24)} -> ${t1.slice(0, 24)}`);
  check('(a) clock.install: Dart-Timer folgen der Fake-Uhr, Flutter rendert danach weiter', before !== after);
  await ctx.close();
}

// (b) Browser-Signale -------------------------------------------------------
{
  const normal = await openScenario(await browser.newContext(ctxOptions), base, { scenario: 'cmp-surfaces', dumpText: 1 });
  const forced = await openScenario(await browser.newContext({ ...ctxOptions, forcedColors: 'active' }), base, { scenario: 'cmp-surfaces', dumpText: 1 });
  check('(b) Ohne Emulation: highContrast=false, Glow vorhanden', normal.env?.system.highContrast === false && normal.dump?.hasGlow === true);
  check('(b) forced-colors: active kommt als Systemsignal highContrast=true an', forced.env?.system.highContrast === true);
  check('(b) forced-colors: active wirkt ohne hc-Parameter (Theme HC, kein Glow)', forced.dump?.hasGlow === false);
  const a = md5(await normal.page.screenshot());
  const b = md5(await forced.page.screenshot());
  check('(b) forced-colors: Darstellung weicht ab', a !== b);
  const reduced = await openScenario(await browser.newContext({ ...ctxOptions, reducedMotion: 'reduce' }), base, { scenario: 'cmp-snackbar' });
  info('(b) prefers-reduced-motion: reduce -> Systemsignale', JSON.stringify(reduced.env?.system));
  check(
    '(b) prefers-reduced-motion: reduce kommt an (disableAnimations oder reduceMotion)',
    reduced.env?.system.disableAnimations === true || reduced.env?.system.reduceMotion === true,
  );
  try {
    const more = await openScenario(await browser.newContext({ ...ctxOptions, contrast: 'more' }), base, { scenario: 'cmp-surfaces' });
    info('(b) prefers-contrast: more -> Systemsignale', JSON.stringify(more.env?.system));
  } catch (e) {
    info('(b) prefers-contrast: more', 'nicht emulierbar: ' + e.message.split('\n')[0]);
  }
}
await browser.close();
const bad = results.filter((r) => r.ok === false);
console.log(`\n${results.length - bad.length}/${results.length} ohne Fehler`);
process.exit(bad.length ? 1 : 0);
