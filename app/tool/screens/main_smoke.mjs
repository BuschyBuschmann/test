#!/usr/bin/env node
// Rauchtest des Produktions-Einstiegs `lib/main.dart` im Browser (U2b):
// startet die echte App (echter Speicher, Systemuhr), prüft Onboarding Schritt 1,
// Eingabe, Weiter und Fortsetzen nach Reload. Kein Szenario, keine Overrides.
//
//   flutter build web --release --no-web-resources-cdn -t lib/main.dart --output=<Verzeichnis>
//   (cd <Verzeichnis> && python3 -m http.server 8766 --bind 127.0.0.1) &
//   CHROME_EXECUTABLE=... node tool/screens/main_smoke.mjs [--base=http://127.0.0.1:8766] [--out=DIR]
import fs from 'node:fs';
import path from 'node:path';

import { launch } from './lib.mjs';

const arg = (name, fallback) => {
  const hit = process.argv.find((a) => a.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3) : fallback;
};
const base = arg('base', 'http://127.0.0.1:8766');
const outDir = path.resolve(arg('out', 'build/screens/main'));
fs.mkdirSync(outDir, { recursive: true });

const errors = [];
let failed = 0;
const check = (name, ok, detail = '') => {
  if (!ok) failed++;
  console.log(`${ok ? 'ok     ' : 'FEHLER '} ${name}${detail ? ' – ' + detail : ''}`);
};

const browser = await launch();
const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, timezoneId: 'Europe/Berlin', locale: 'de-DE' });
const page = await ctx.newPage();
page.on('pageerror', (e) => errors.push(String(e)));
page.on('console', (m) => {
  if (m.type() === 'error') errors.push(m.text());
});

async function open() {
  await page.goto(base + '/');
  // Flutter Web legt den Semantik-Baum erst nach dem Platzhalter-Klick an.
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached', timeout: 30000 });
  await placeholder.dispatchEvent('click');
}
const seen = async (text, timeout = 15000) =>
  page.getByText(text, { exact: false }).first().waitFor({ state: 'attached', timeout }).then(() => true, () => false);

await open();
check('main.dart startet: Onboarding Schritt 1', await seen('Schritt 1 von 4'));
await page.screenshot({ path: path.join(outDir, 'main-schritt1.png') });
const field = page.locator('input[data-semantics-role="text-field"]:not([disabled])').first();
await field.click({ force: true });
await page.keyboard.type('Jakob');
await page.waitForTimeout(300);
await page.locator('flt-semantics[role="button"]', { hasText: 'Weiter' }).first().click({ force: true });
check('Weiter → Schritt 2 von 4', await seen('Schritt 2 von 4'));
await page.reload();
await open();
check('Reload: Fortsetzen bei Schritt 2 (echter Speicher)', await seen('Schritt 2 von 4'));
check('Reload: Name im Manny-Text', await seen('Jakob'));
await page.screenshot({ path: path.join(outDir, 'main-nach-reload.png') });
check('keine Seiten- oder Konsolenfehler', errors.length === 0, errors.slice(0, 3).join(' | '));
await browser.close();
process.exit(failed ? 1 : 0);
