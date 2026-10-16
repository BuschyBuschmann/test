#!/usr/bin/env node
// Browser-Prüfungen der Navigation (U2b, U2c, Plan 4.3, 12.5): Browser-Zurück =
// Android-Zurück (`page.goBack()`), Reload im Onboarding, Tabwechsel, Zeitsprung
// über Mitternacht mit der Fake-Uhr (`page.clock.install` + `runFor`), Manny-
// Chat über den Manny-Knopf, Chats und Profil als Ziele der Leiste mit
// Manny-Look-Wechsel (Abschnitt 5, F2-R3), Pfad-Abläufe (U3a,
// Abschnitt 6): Zurück schließt zuerst die Blase, dann den Hinweis; Manny-Tipp
// öffnet den Chat; Tipp auf die aktuelle Unit wechselt auf Heute; Hinweis an
// einer gesperrten Unit (Escape, Zurück, 5 s); Heute-Abläufe (U3b, Abschnitt 7):
// Training eintragen → Rückgängig, Heute → Pfad zeigt die Feier erst danach,
// Entfernen → Rückgängig, Eigene Übung, Tageswechsel über Mitternacht bei offenem
// Trainings-Sheet (Eintrag zählt für den Vortag); Deine Daten (U4, Abschnitt 8):
// Profil ändern und Speichern (Name auf Heute, bleibt nach Reload), Verwerfen
// (Schließen, Browser-Zurück, Weiter bearbeiten, Verwerfen), Löschen →
// Onboarding Schritt 1 (Zurück erreicht den Pfad nicht, Reload bleibt bei
// Schritt 1, localStorage ist leer). Das Onboarding hat fünf Schritte; Schritt 1
// ist die Wahl „Wie soll Manny aussehen?“ (F2-R4, Ergänzung 1, 6a).
//
// Fake-Uhr und Klicks sind gegen die langsame Software-Darstellung der
// Prüfumgebung abgesichert (`advanceClock`, `click`): Die erste Darstellung
// eines Sheets oder Dialogs braucht in SwiftShader Sekunden; in dieser Zeit
// verwirft Playwright `clock.runFor` still (siehe dort) und das Ziel liegt
// noch außerhalb des Fensters.
//
//   export PATH=/opt/flutter/bin:$PATH
//   flutter build web --release --no-web-resources-cdn -t lib/main_preview.dart
//   (cd build/web && python3 -m http.server 8765 --bind 127.0.0.1) &
//   CHROME_EXECUTABLE=/opt/pw-browsers/chromium-1194/chrome-linux/chrome \
//     node tool/screens/nav_checks.mjs [--base=http://127.0.0.1:8765] [--out=DIR]
//
// Die App läuft mit `live=1` (echter Speicher = localStorage, Systemuhr, die
// `page.clock` steuert) und `a11y=1` (Semantik-Baum als ARIA, darüber bedient
// das Skript die App). Exit-Code 1 bei einem fehlgeschlagenen Punkt.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { launch, openScenario } from './lib.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const appRoot = path.resolve(here, '..', '..');
const arg = (name, fallback) => {
  const hit = process.argv.find((a) => a.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3) : fallback;
};
const base = arg('base', process.env.BASE_URL || 'http://127.0.0.1:8765');
const outDir = path.resolve(arg('out', path.join(appRoot, 'build', 'screens', 'nav')));
fs.mkdirSync(outDir, { recursive: true });

const results = [];
function check(name, ok, detail) {
  results.push({ name, ok, detail });
  console.log(`${ok ? 'ok     ' : 'FEHLER '} ${name}${detail ? ' – ' + detail : ''}`);
}

const ctxOptions = {
  viewport: { width: 390, height: 844 },
  deviceScaleFactor: 1,
  timezoneId: 'Europe/Berlin',
  locale: 'de-DE',
};
const FIXTURE = fs.readFileSync(path.join(appRoot, 'test', 'fixtures', 'state_v1.json'), 'utf8');

/** Flutter-Web setzt Beschriftungen als Textinhalt der `flt-semantics`-Knoten; Radio- und Schalter-Rollen tragen sie als `aria-label`. */
const textNode = (page, text) =>
  page.getByText(text, { exact: false }).or(page.getByLabel(text, { exact: false })).first();
/** Wartet, bis im Semantik-Baum ein Knoten mit diesem (Teil-)Text steht. */
async function seen(page, text, timeout = 8000) {
  try {
    await textNode(page, text).waitFor({ state: 'attached', timeout });
    return true;
  } catch {
    return false;
  }
}
async function gone(page, text, timeout = 4000) {
  try {
    await textNode(page, text).waitFor({ state: 'detached', timeout });
    return true;
  } catch {
    return false;
  }
}
// „Heute“ und „Pfad“ sind die Nav-Einträge: exakter Treffer, denn auch die Units
// des Pfads tragen „Öffnet Heute.“ im Label. „Hinzufügen“ (Dialog) ebenso: „Eigene
// Übung hinzufügen“ enthält das Wort.
const button = (page, name) =>
  page
    .locator('flt-semantics[role="button"]', {
      hasText:
        name === 'Heute' || name === 'Pfad' || name === 'Chats' || name === 'Profil' || name === 'Fertig' || name === 'Hinzufügen' || name === 'Schließen' || name === 'Eintragen'
          ? new RegExp(`^${name}$`)
          : name,
    })
    .first();
/**
 * Wartet, bis der Knoten innerhalb des Fensters steht und sich nicht mehr
 * bewegt, und klickt dann. Grund: Sheets und Dialoge schieben sich ein
 * (`dur-base`); die erste Darstellung braucht in der Software-Darstellung
 * (SwiftShader, Shader-Übersetzung) Sekunden. Ein Klick, der in dieser Zeit
 * erfolgt, trifft einen Knoten außerhalb des Fensters („Element is outside of
 * the viewport“).
 */
async function settleBox(page, node, timeout = 8000) {
  const vp = page.viewportSize();
  let last = null;
  const started = Date.now();
  while (Date.now() - started < timeout) {
    const box = await node.boundingBox();
    if (box) {
      const inside = box.y >= 0 && box.y + box.height <= vp.height && box.x >= 0 && box.x + box.width <= vp.width;
      const still = last && Math.abs(box.x - last.x) < 0.5 && Math.abs(box.y - last.y) < 0.5;
      if (inside && still) return box;
      last = box;
    }
    await page.waitForTimeout(150);
  }
  return null;
}
/**
 * Holt einen Knoten in das Fenster, der in einem Flutter-Scrollbereich unterhalb
 * (oder oberhalb) des sichtbaren Bereichs liegt. Playwrights Scroll-Hilfe
 * („scrolling into view if needed“) kennt Flutters Bildlauf nicht: die
 * `flt-semantics`-Knoten liegen im DOM ohne scrollbaren Vorfahren, der Klick
 * endet mit „Element is outside of the viewport“. Das Skript rollt deshalb mit
 * dem Mausrad über der Fenstermitte, bis der Knoten mit Abstand zum unteren
 * Rand (Leiste, Fußleiste) im Fenster steht.
 */
async function scrollIntoWindow(page, node) {
  const vp = page.viewportSize();
  const margin = 200; // Leiste, Manny-Knopf und Primärbutton-Reihe unten
  let moved = false;
  let lastY = null;
  for (let i = 0; i < 30; i++) {
    const box = await node.boundingBox();
    if (!box) return;
    const below = box.y + box.height > vp.height || (moved && box.y + box.height > vp.height - margin);
    const above = box.y < 0;
    if (!below && !above) return;
    if (lastY !== null && Math.abs(box.y - lastY) < 1) return; // Ende des Scrollwegs
    lastY = box.y;
    await page.mouse.move(vp.width / 2, vp.height / 2);
    await page.mouse.wheel(0, below ? 200 : -200);
    moved = true;
    await page.waitForTimeout(250);
  }
}
async function click(page, name) {
  const b = button(page, name);
  await b.waitFor({ state: 'attached', timeout: 8000 });
  await scrollIntoWindow(page, b);
  await settleBox(page, b);
  await b.click({ force: true });
  await page.waitForTimeout(450);
}
/** Wahl-Karte (Radio) über ihren Screenreader-Text. */
async function clickRadio(page, label) {
  const node = page.getByLabel(label, { exact: false }).first();
  await node.waitFor({ state: 'attached', timeout: 8000 });
  await settleBox(page, node);
  await node.click({ force: true });
  await page.waitForTimeout(450);
}
/**
 * Stellt die Fake-Uhr um [ms] weiter und prüft den Sprung. `page.clock.runFor`
 * wertet sein Skript über `safeNonStallingEvaluateInAllFrames` aus: Ist die
 * Seite gerade beschäftigt (erste Darstellung eines Sheets in SwiftShader,
 * mehrere Sekunden), verwirft Playwright den Aufruf **still**, ohne Fehler.
 * Die Uhr läuft dann nur in Echtzeit weiter und der Tageswechsel bleibt aus
 * (gemessen: 30 s Sprung = 2,6 s Vorschub; ein zweiter Aufruf wirkte voll). Das
 * Skript wiederholt deshalb den Rest bis zum Ziel.
 */
async function advanceClock(page, ms) {
  const target = (await page.evaluate(() => Date.now())) + ms;
  for (let i = 0; i < 20; i++) {
    const rest = target - (await page.evaluate(() => Date.now()));
    if (rest <= 0) return true;
    await page.clock.runFor(rest);
    await page.waitForTimeout(300);
  }
  return (await page.evaluate(() => Date.now())) >= target;
}
async function shot(page, name) {
  await page.screenshot({ path: path.join(outDir, `${name}.png`) });
}
/** Zählt die History-Einträge, die `goBack` noch erreicht. */
const historyLength = (page) => page.evaluate(() => history.length);

const browser = await launch();

// 1. Onboarding live: Look, Weiter, Zurück, Reload ---------------------------------
{
  const ctx = await browser.newContext(ctxOptions);
  const s = await openScenario(
    ctx,
    base,
    { scenario: 'ob1-empty', live: 1, a11y: 1 },
    { clock: 'none' },
  );
  const page = s.page;
  check('Start (live): Onboarding Schritt 1 von 5 „Wie soll Manny aussehen?“', (await seen(page, 'Schritt 1 von 5')) && (await seen(page, 'Wie soll Manny aussehen?')));
  check('Look-Schritt: „Mit Brille“ vorgewählt, „Ohne Brille“ nicht (V2-66, V2-67)', (await seen(page, 'Manny mit Brille, ausgewählt, 1 von 2', 3000)) && (await seen(page, 'Manny ohne Brille, nicht ausgewählt, 2 von 2', 3000)));
  check('Look-Schritt: Weiter ist aktiv, „Zurück“ steht daneben', (await button(page, 'Weiter').isEnabled()) && (await button(page, 'Zurück').count()) > 0);
  await shot(page, 'ob-schritt1-look');
  await clickRadio(page, 'Manny ohne Brille');
  check('Wahl „Ohne Brille“ gilt sofort (ausgewählt)', await seen(page, 'Manny ohne Brille, ausgewählt, 2 von 2', 3000));
  await click(page, 'Weiter');
  check('Weiter → Schritt 2 von 5 (Name)', await seen(page, 'Schritt 2 von 5'));
  const field = page.locator('input[data-semantics-role="text-field"]:not([disabled])').first();
  const hasInput = (await field.count()) > 0;
  check('Namensfeld im Semantik-Baum vorhanden', hasInput);
  if (hasInput) {
    await field.click({ force: true });
    await page.keyboard.type('Jakob');
    await page.waitForTimeout(300);
  }
  await shot(page, 'ob-schritt2-name');
  await click(page, 'Weiter');
  check('Weiter → Schritt 3 von 5 (Datenschutz)', await seen(page, 'Schritt 3 von 5'));
  await click(page, 'Verstanden, weiter');
  check('Verstanden, weiter → Schritt 4 von 5', await seen(page, 'Schritt 4 von 5'));
  await shot(page, 'ob-schritt4');

  // Reload (live = localStorage): Fortsetzen am gespeicherten Schritt (UI-16).
  await page.reload();
  check('Reload: Onboarding setzt bei Schritt 4 fort (UI-16)', await seen(page, 'Schritt 4 von 5', 15000));
  check('Reload: Manny-Text mit dem Namen', await seen(page, 'Jakob'));
  await shot(page, 'ob-reload-schritt4');

  // „Zurück“ (Schaltfläche) und Browser-Zurück wie Android-Zurück: je Schritt
  // einen Schritt (Plan 4.3, n6).
  await click(page, 'Zurück');
  check('Schaltfläche „Zurück“: Schritt 4 → Schritt 3', await seen(page, 'Schritt 3 von 5'));
  const before = await historyLength(page);
  await page.goBack();
  await page.waitForTimeout(700);
  check(
    'Browser-Zurück auf Schritt 3 → Schritt 2 (wie Android-Zurück)',
    await seen(page, 'Schritt 2 von 5'),
    `history.length ${before}`,
  );
  // Die Semantik-Eingabe spiegelt den Text erst, wenn das Feld Fokus hat.
  await page.locator('input[data-semantics-role="text-field"]:not([disabled])').first().click({ force: true });
  await page.waitForTimeout(400);
  const typed = await page.evaluate(() => document.activeElement?.value ?? null);
  check('Name blieb erhalten (Zurück behält Eingaben)', typed === 'Jakob', JSON.stringify(typed));
  await page.goBack();
  await page.waitForTimeout(700);
  check('Browser-Zurück auf Schritt 2 → Schritt 1 mit erhaltener Wahl „Ohne Brille“ (V2-67)', (await seen(page, 'Schritt 1 von 5')) && (await seen(page, 'Manny ohne Brille, ausgewählt, 2 von 2', 3000)));
  await page.reload();
  check('Reload mitten im Onboarding: die Wahl „Ohne Brille“ bleibt (V2-67)', await seen(page, 'Manny ohne Brille, ausgewählt, 2 von 2', 15000));

  // Auf Schritt 1: Android-Zurück schließt die App (`SystemNavigator.pop`). Im Web
  // ist das `history.back()`: die Seite wird verlassen (Plan 4.3 nahm „bleibt
  // stehen“ an; hier gemessen, siehe Bericht).
  const urlBefore = page.url();
  await page.goBack();
  await page.waitForTimeout(800);
  const stayed = page.url() === urlBefore && (await seen(page, 'Schritt 1 von 5', 1500));
  console.log(
    `info    Browser-Zurück auf Schritt 1: ${stayed ? 'Seite bleibt stehen' : 'Seite wird verlassen'} (URL ${urlBefore} → ${page.url()})`,
  );
  results.push({ name: 'Browser-Zurück auf Schritt 1', ok: null, detail: stayed ? 'bleibt stehen' : `verlässt die Seite (${page.url()})` });
  await ctx.close();
}

// 2. Home: Tabs, Browser-Zurück Heute → Pfad ---------------------------------
{
  const ctx = await browser.newContext(ctxOptions);
  await ctx.addInitScript((doc) => localStorage.setItem('curaone.state.v1', JSON.stringify(doc)), FIXTURE);
  const s = await openScenario(ctx, base, { live: 1, a11y: 1 }, { clock: 'install', now: '2026-10-07T12:00:00+02:00' });
  const page = s.page;
  check('Home startet auf Tab Pfad (A-1)', await seen(page, 'Woche 5'));
  check('Home: Nav mit Pfad und Heute', (await button(page, 'Heute').count()) > 0 && (await button(page, 'Pfad').count()) > 0);
  await click(page, 'Heute');
  check('Tab Heute zeigt „Heute, Jakob“', await seen(page, 'Heute, Jakob'));
  await shot(page, 'home-heute');
  await page.goBack();
  await page.waitForTimeout(600);
  check('Browser-Zurück auf Heute → Tab Pfad', await seen(page, 'Woche 5'));
  const homeUrl = page.url();
  await page.goBack();
  await page.waitForTimeout(800);
  const homeStayed = page.url() === homeUrl && (await seen(page, 'Woche 5', 1500));
  console.log(`info    Browser-Zurück auf Pfad: ${homeStayed ? 'Seite bleibt stehen' : 'Seite wird verlassen'} (URL ${homeUrl} → ${page.url()})`);
  results.push({ name: 'Browser-Zurück auf Pfad', ok: null, detail: homeStayed ? 'bleibt stehen' : `verlässt die Seite (${page.url()})` });
  await ctx.close();
}

// 3. Tageswechsel mit der Fake-Uhr (page.clock) -------------------------------
{
  const ctx = await browser.newContext(ctxOptions);
  await ctx.addInitScript((doc) => localStorage.setItem('curaone.state.v1', JSON.stringify(doc)), FIXTURE);
  const s = await openScenario(ctx, base, { live: 1, a11y: 1 }, { clock: 'install', now: '2026-10-07T23:59:40+02:00' });
  const page = s.page;
  check('Zeitsprung: Home geladen', await seen(page, 'Woche 5'));
  await advanceClock(page, 30000); // 30 s: über Mitternacht
  await page.waitForTimeout(300);
  const date = await page.evaluate(() => new Date().toString());
  check('page.clock: Datum ist der 8. Oktober', date.includes('Oct 08'), date.slice(0, 24));
  await click(page, 'Heute');
  check(
    'Tabwechsel auf Heute nach Mitternacht: Snackbar „Neuer Tag, neues Programm.“ (A-31, UI-44)',
    await seen(page, 'Neuer Tag, neues Programm.', 10000),
  );
  await shot(page, 'tageswechsel-snackbar');
  // Mit aktivem Semantik-Baum (a11y=1) gilt `accessibleNavigation`: die Snackbar
  // schließt nicht von selbst (Ergänzung 1, 3.3). Das Verhalten steht hier fest.
  await advanceClock(page, 8000);
  check(
    'a11y aktiv: Snackbar bleibt stehen (kein Timer bei accessibleNavigation)',
    await seen(page, 'Neuer Tag, neues Programm.', 1500),
  );
  await ctx.close();
}

// 3b. Dieselbe Snackbar ohne Semantik-Baum: endet nach 5 s (Pixelvergleich) ------
{
  const ctx = await browser.newContext(ctxOptions);
  await ctx.addInitScript((doc) => localStorage.setItem('curaone.state.v1', JSON.stringify(doc)), FIXTURE);
  const s = await openScenario(ctx, base, { live: 1 }, { clock: 'install', now: '2026-10-07T23:59:40+02:00' });
  const page = s.page;
  await advanceClock(page, 30000);
  await page.mouse.click(284, 790); // Nav-Eintrag „Heute“
  await page.waitForTimeout(600);
  const withSnackbar = await page.screenshot();
  await advanceClock(page, 6000);
  await page.waitForTimeout(500);
  const afterTimeout = await page.screenshot();
  await page.waitForTimeout(1200);
  const stable = await page.screenshot();
  fs.writeFileSync(path.join(outDir, 'tageswechsel-snackbar-ohne-a11y.png'), withSnackbar);
  check(
    'ohne a11y: Snackbar endet nach 5 s (Bild ändert sich, danach stabil)',
    Buffer.compare(withSnackbar, afterTimeout) !== 0 && Buffer.compare(afterTimeout, stable) === 0,
  );
  await ctx.close();
}

// 4. Tageswechsel beim Fortsetzen (visibilitychange) ----------------------------
{
  const ctx = await browser.newContext(ctxOptions);
  await ctx.addInitScript((doc) => localStorage.setItem('curaone.state.v1', JSON.stringify(doc)), FIXTURE);
  const s = await openScenario(ctx, base, { live: 1, a11y: 1 }, { clock: 'install', now: '2026-10-07T23:59:40+02:00' });
  const page = s.page;
  await seen(page, 'Woche 5');
  await click(page, 'Heute');
  await seen(page, 'Heute, Jakob');
  // Seite „im Hintergrund“, Uhr über Mitternacht, dann zurück.
  await page.evaluate(() => {
    let state = 'hidden';
    Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => state });
    Object.defineProperty(document, 'hidden', { configurable: true, get: () => state === 'hidden' });
    window.__setVisibility = (v) => {
      state = v;
      document.dispatchEvent(new Event('visibilitychange'));
    };
    window.__setVisibility('hidden');
  });
  await advanceClock(page, 30000);
  await page.evaluate(() => window.__setVisibility('visible'));
  const resumed = await seen(page, 'Neuer Tag, neues Programm.', 10000);
  console.log(
    `${resumed ? 'ok     ' : 'info   '} Fortsetzen (visibilitychange hidden → visible) über Mitternacht auf Heute: Snackbar ${resumed ? 'erscheint' : 'erscheint nicht (Web-Lebenszyklus nicht auslösbar; Resume per Widget-Test)'}`,
  );
  results.push({ name: 'Fortsetzen über visibilitychange', ok: null, detail: resumed ? 'Snackbar' : 'nicht ausgelöst' });
  await ctx.close();
}

// 5. Manny-Chat, Chats und Profil (F2-R3, Brief v2, 5, 7.6, 7.7; V2-19, V2-68) ---
// Manny-Knopf auf dem Pfad, Ziele Chats und Profil der Leiste, Browser-Zurück =
// Android-Zurück (Chat → Pfad; Beispiel-Chat → Chats → Pfad), Manny-Look-Wechsel
// im Profil ohne Neustart.
{
  const ctx = await browser.newContext(ctxOptions);
  await ctx.addInitScript((doc) => { if (!localStorage.getItem('curaone.state.v1')) localStorage.setItem('curaone.state.v1', JSON.stringify(doc)); }, FIXTURE);
  const s = await openScenario(ctx, base, { live: 1, a11y: 1 }, { clock: 'install', now: '2026-10-07T12:00:00+02:00' });
  const page = s.page;
  check('Chat-Ablauf: Home auf Pfad, Manny-Knopf und vier Ziele in der Leiste', (await seen(page, 'Woche 5')) && (await button(page, 'Manny, Chat öffnen').count()) > 0 && (await button(page, 'Pfad').count()) > 0 && (await button(page, 'Heute').count()) > 0 && (await button(page, 'Chats').count()) > 0 && (await button(page, 'Profil').count()) > 0);
  check('Kein Nachrichten-Knopf mehr', (await button(page, 'Nachrichten').count()) === 0);
  await shot(page, 'pfad-manny-knopf');

  await click(page, 'Manny, Chat öffnen');
  check('Manny-Knopf öffnet den Manny-Chat (Kopf „Dein Reha-Begleiter“)', await seen(page, 'Dein Reha-Begleiter'));
  check('Manny-Chat: Beispielverlauf mit Namen aus dem Onboarding', await seen(page, 'Moin Jakob. Wie läuft dein Tag?'));
  check('Manny-Chat: Hinweiszeile, Leiste und Disclaimer sichtbar', (await seen(page, 'Schreiben kann ich bald, heute noch nicht.', 2000)) && (await seen(page, 'Manny ersetzt keine medizinische Beratung.', 2000)));
  check('Manny-Chat: kein Manny-Knopf, keine Leiste (V2-19)', (await button(page, 'Manny, Chat öffnen').count()) === 0 && (await button(page, 'Pfad').count()) === 0 && (await button(page, 'Chats').count()) === 0);
  await shot(page, 'chat-manny');
  await page.goBack();
  await page.waitForTimeout(700);
  check('Browser-Zurück im Manny-Chat → Pfad (Ziel bleibt)', (await seen(page, 'Woche 5')) && (await gone(page, 'Dein Reha-Begleiter')));

  await click(page, 'Chats');
  check('Ziel Chats: Beispieldaten gekennzeichnet, Manny angeheftet', (await seen(page, 'Beispiel-Ansicht. Echte Chats folgen.')) && (await seen(page, 'Angeheftet')));
  check('Chats: kein Manny-Knopf (nur Pfad und Heute)', (await button(page, 'Manny, Chat öffnen').count()) === 0);
  check('Chats: sechs Beispielkontakte', (await page.locator('flt-semantics[role="button"]', { hasText: 'Beispielkontakt' }).count()) === 6, String(await page.locator('flt-semantics[role="button"]', { hasText: 'Beispielkontakt' }).count()));
  await shot(page, 'chats');
  await click(page, 'Beispielkontakt Praxis Müller');
  check('Zeile öffnet den Beispiel-Chat („Physio · Beispiel“), ohne Leiste', (await seen(page, 'Physio · Beispiel')) && (await button(page, 'Chats').count()) === 0);
  check('Beispiel-Chat: Hinweis „Nur zum Ansehen.“, kein Disclaimer', (await seen(page, 'Beispiel-Chat. Nur zum Ansehen.', 8000)) && (await page.getByText('Manny ersetzt keine medizinische Beratung.').count()) === 0);
  await shot(page, 'beispiel-chat');
  await page.goBack();
  await page.waitForTimeout(700);
  check('Browser-Zurück im Beispiel-Chat → Chats', (await seen(page, 'Beispiel-Ansicht. Echte Chats folgen.')) && (await gone(page, 'Physio · Beispiel')));
  await page.goBack();
  await page.waitForTimeout(700);
  check('Browser-Zurück in Chats → Pfad (Ausgangs-Ziel)', (await seen(page, 'Woche 5')) && (await gone(page, 'Beispiel-Ansicht. Echte Chats folgen.')));

  // Profil: Zeilen, Manny-Look-Wechsel sofort und ohne Neustart (V2-68).
  await click(page, 'Profil');
  check('Ziel Profil: Zeilen Deine Daten, Manny-Look, Darstellung, Hilfe und Datenschutz', (await button(page, 'Deine Daten').count()) > 0 && (await button(page, 'Manny-Look, Mit Brille').count()) > 0 && (await button(page, 'Darstellung').count()) > 0 && (await button(page, 'Hilfe und Datenschutz').count()) > 0);
  await shot(page, 'profil');
  await click(page, 'Manny-Look, Mit Brille');
  check('Manny-Look: Sheet mit beiden Karten und „Gilt für die ganze App.“', (await seen(page, 'Gilt für die ganze App.')) && (await seen(page, 'Manny mit Brille, ausgewählt, 1 von 2')));
  check('Manny-Look: Leiste unter dem Sheet nicht bedienbar (V2-19)', (await button(page, 'Chats').count()) === 0);
  await textNode(page, 'Manny ohne Brille').click({ force: true });
  await page.waitForTimeout(500);
  check('Manny-Look: Wechsel sofort, ohne Neustart („Ohne Brille“ ausgewählt)', await seen(page, 'Manny ohne Brille, ausgewählt, 2 von 2'));
  await shot(page, 'profil-look-sheet');
  await click(page, 'Fertig');
  check('Manny-Look: Fertig schließt das Sheet', await gone(page, 'Gilt für die ganze App.'));
  check('Manny-Look: Zeile zeigt den neuen Wert', await seen(page, 'Manny-Look, Ohne Brille'));
  await page.reload();
  await seen(page, 'Woche 5', 15000);
  await click(page, 'Profil');
  check('Manny-Look: Wahl bleibt nach Reload', await seen(page, 'Manny-Look, Ohne Brille'));

  await click(page, 'Darstellung');
  check('Darstellung: Welt, Thema und Schalter', (await seen(page, 'Automatisch, ausgewählt')) && (await seen(page, 'System, ausgewählt')) && (await seen(page, 'Transparenz reduzieren, Aus')) && (await seen(page, 'Ton, An')) && (await seen(page, 'Vibration, An')));
  await click(page, 'Nacht');
  check('Darstellung: Welt Nacht wirkt sofort', await seen(page, 'Nacht, ausgewählt'));
  await shot(page, 'profil-darstellung');
  await click(page, 'Fertig');
  await ctx.close();
}

// 6. Pfad (U3a): Blase, Hinweis, Manny-Tipp, Unit-Tipp ---------------------------
// Das Fixture enthält eine ausstehende Feier von heute: beim ersten Pfad-Besuch
// steht die Blase „Stark, Jakob. Das war Tag 12.“ (Anlass Feier, Priorität 1).
{
  const ctx = await browser.newContext(ctxOptions);
  await ctx.addInitScript((doc) => localStorage.setItem('curaone.state.v1', JSON.stringify(doc)), FIXTURE);
  const s = await openScenario(ctx, base, { live: 1, a11y: 1 }, { clock: 'install', now: '2026-10-07T12:00:00+02:00' });
  const page = s.page;
  check('Pfad: Kopfzeile „Woche 5“ und Beispielpfad', (await seen(page, 'Woche 5')) && (await seen(page, 'Beispielpfad')));
  check('Pfad: Feier-Blase beim ersten Besuch (Anlass Feier)', await seen(page, 'Stark, Jakob. Das war Tag 12.'));
  check('Pfad: Blase hat „Nachricht schließen“', (await button(page, 'Nachricht schließen').count()) > 0);
  await shot(page, 'pfad-feier-blase');

  // Zurück (Browser = Android): zuerst die Blase.
  await page.goBack();
  await page.waitForTimeout(600);
  check('Browser-Zurück: schließt zuerst die Blase, bleibt auf dem Pfad', (await gone(page, 'Stark, Jakob. Das war Tag 12.')) && (await seen(page, 'Woche 5')));

  // Hinweis an einer gesperrten Unit.
  const locked = button(page, 'Woche 5, Wochenziel, gesperrt');
  const lockedBox = await locked.boundingBox();
  await click(page, 'Woche 5, Wochenziel, gesperrt');
  check('Unit-Tipp (gesperrt): NodeHint „Kommt noch diese Woche“, Tab bleibt', (await seen(page, 'Kommt noch diese Woche')) && (await seen(page, 'Woche 5')));
  await shot(page, 'pfad-hinweis');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(400);
  check('Escape schließt den Hinweis', await gone(page, 'Kommt noch diese Woche'));

  await click(page, 'Woche 5, Wochenziel, gesperrt');
  await seen(page, 'Kommt noch diese Woche');
  await page.goBack();
  await page.waitForTimeout(600);
  check('Browser-Zurück schließt den Hinweis (danach erst die App)', (await gone(page, 'Kommt noch diese Woche')) && (await seen(page, 'Woche 5')));

  // Bei aktivem Screenreader schließt der Hinweis nicht von selbst.
  await click(page, 'Woche 5, Wochenziel, gesperrt');
  await advanceClock(page, 6500);
  check('a11y aktiv: Hinweis bleibt über 5 s stehen', await seen(page, 'Kommt noch diese Woche', 1500));
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);

  // Erledigte Unit: liegt unter der aktuellen Kugel, erst in die Sicht scrollen.
  await page.mouse.move(195, 400);
  await page.mouse.wheel(0, 300);
  await page.waitForTimeout(500);
  await click(page, 'Woche 5, Trainingstag 1, erledigt');
  check('Unit-Tipp (erledigt): „Erledigt. Das hast du geschafft.“', await seen(page, 'Erledigt. Das hast du geschafft.'));
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);

  // Manny-Tipp: Koordinaten der Bild-Semantik (Manny hat keine Button-Semantik).
  const mannyNode = page.locator('[aria-label="Manny, dein Begleiter"]').first();
  await mannyNode.waitFor({ state: 'attached', timeout: 8000 });
  // Der Tipp auf die Unit hat den Pfad verschoben: Manny wieder ins Bild holen.
  await page.mouse.move(195, 400);
  for (let i = 0; i < 12; i++) {
    const b = await mannyNode.boundingBox();
    if (b && b.y > 120 && b.y + b.height < 700) break;
    await page.mouse.wheel(0, b && b.y < 120 ? -300 : 300);
    await page.waitForTimeout(300);
  }
  const mb = await mannyNode.boundingBox();
  check(
    'Manny: Bild-Label „Manny, dein Begleiter“, aber keine Button-Semantik',
    !!mb && (await page.locator('[role="button"][aria-label*="Manny, dein Begleiter"]').count()) === 0,
  );
  await shot(page, 'pfad-manny-vor-tipp');
  if (mb) {
    await page.mouse.click(mb.x + mb.width / 2, mb.y + mb.height * 0.55);
    await page.waitForTimeout(700);
  }
  check('Manny-Tipp öffnet den Manny-Chat (Tab bleibt)', await seen(page, 'Dein Reha-Begleiter'));
  await shot(page, 'pfad-manny-chat');
  await page.goBack();
  await page.waitForTimeout(700);
  check('Browser-Zurück im Chat → Pfad (Tab Pfad, kein Tabwechsel)', (await seen(page, 'Woche 5')) && (await gone(page, 'Dein Reha-Begleiter')));

  // Aktuelle Unit → Heute.
  await click(page, 'aktuell. Öffnet Heute.');
  check('Tipp auf die aktuelle Unit wechselt auf Heute', await seen(page, 'Heute, Jakob'));
  await shot(page, 'pfad-unit-heute');
  await page.goBack();
  await page.waitForTimeout(600);
  check('Browser-Zurück auf Heute → Pfad', await seen(page, 'Woche 5'));
  await ctx.close();

  // 6b. Ohne Screenreader schließt der Hinweis nach 5 s (Pixelvergleich).
  if (lockedBox) {
    const ctx2 = await browser.newContext(ctxOptions);
    await ctx2.addInitScript((doc) => localStorage.setItem('curaone.state.v1', JSON.stringify(doc)), FIXTURE);
    const s2 = await openScenario(ctx2, base, { live: 1 }, { clock: 'install', now: '2026-10-07T12:00:00+02:00' });
    const p2 = s2.page;
    await p2.waitForTimeout(1500);
    // Blase der Feier schließen (Tipp irgendwo), dann die Unit antippen.
    await p2.mouse.click(lockedBox.x + lockedBox.width / 2, lockedBox.y + lockedBox.height / 2);
    await p2.waitForTimeout(500);
    await p2.mouse.click(lockedBox.x + lockedBox.width / 2, lockedBox.y + lockedBox.height / 2);
    await p2.waitForTimeout(700);
    const withHint = await p2.screenshot();
    fs.writeFileSync(path.join(outDir, 'pfad-hinweis-ohne-a11y.png'), withHint);
    await advanceClock(p2, 6000);
    await p2.waitForTimeout(500);
    const afterTimeout = await p2.screenshot();
    await p2.waitForTimeout(1200);
    const stable = await p2.screenshot();
    check(
      'ohne a11y: Hinweis endet nach 5 s (Bild ändert sich, danach stabil)',
      Buffer.compare(withHint, afterTimeout) !== 0 && Buffer.compare(afterTimeout, stable) === 0,
    );
    await ctx2.close();
  }
}


// 7. Heute (U3b): Abläufe mit echtem Speicher und Fake-Uhr -----------------------
// Frischer Tag mit Streak 12 (gestern trainiert): Eintragen erhöht auf 13.
const HEUTE_DOC = (() => {
  const d = JSON.parse(FIXTURE);
  d.onboarding = { ...d.onboarding, name: 'Jakob', injuryType: 'acl', injuryOther: '', injuryDate: '2026-09-07' };
  d.streak = { count: 12, freezes: 2, lastTrainingDay: '2026-10-06', evaluatedThrough: '2026-10-06', coveredInGap: 0, uncoveredInGap: 0, resetNoticePending: false };
  d.path = { completedUnitIds: [], pulsePending: null };
  d.day = { dayKey: '2026-10-07', removed: [], swaps: {}, custom: [], done: false };
  d.prefs = { timeChoice: 20 };
  d.manny = { lastShown: { fact: '2026-10-07' }, greetingPending: false };
  d.celebration = null;
  return JSON.stringify(d);
})();

async function openHeute(now, params = { live: 1, a11y: 1 }) {
  const ctx = await browser.newContext(ctxOptions);
  // Wie bei den anderen Abläufen: der Speicher legt den Text JSON-kodiert ab.
  await ctx.addInitScript((doc) => localStorage.setItem('curaone.state.v1', JSON.stringify(doc)), HEUTE_DOC);
  const s = await openScenario(ctx, base, params, { clock: 'install', now });
  await seen(s.page, 'Woche 5');
  await click(s.page, 'Heute');
  await seen(s.page, 'Heute, Jakob');
  return { ctx, page: s.page };
}

// 7a. Training eintragen → Rückgängig → erneut eintragen → Pfad zeigt die Feier
{
  const { ctx, page } = await openHeute('2026-10-07T12:00:00+02:00');
  check('Heute: Datum, Zeitwahl und Übungen (Wdh. und Dauer)', (await seen(page, 'Mittwoch, 7. Oktober')) && (await seen(page, 'Kniebeuge am Stuhl, 3 mal 12 Wiederholungen, 6 Minuten')) && (await seen(page, 'Beispieltermin, Physio, Physiotherapie, Praxis Müller, 17:00 Uhr')));
  check('Heute: Manny-Knopf und „Training eintragen“', (await button(page, 'Manny, Chat öffnen').count()) > 0 && (await button(page, 'Nachrichten').count()) === 0 && (await button(page, 'Training eintragen').count()) > 0);
  await shot(page, 'heute-standard');
  await click(page, 'Training eintragen');
  check('Training eintragen öffnet das Sheet „Wie willst du trainieren?“ (nur Manuell aktiv)', (await seen(page, 'Wie willst du trainieren?')) && (await seen(page, 'Manuell, Ich trainiere selbst und trage es ein, Auswahl, ausgewählt')) && (await seen(page, 'Passiv, folgt, noch nicht verfügbar')));
  check('Sheet offen: Manny-Knopf ist aus der Semantik (nicht bedienbar)', (await button(page, 'Manny, Chat öffnen').count()) === 0);
  await shot(page, 'heute-sheet');
  await click(page, 'Eintragen');
  check('Eintragen: Sheet zu, „Heute erledigt“, Snackbar „Eingetragen.“ mit Rückgängig (UI-37)', (await seen(page, 'Eingetragen.')) && (await seen(page, 'Heute erledigt')) && (await gone(page, 'Wie willst du trainieren?')));
  await shot(page, 'heute-eingetragen');
  await click(page, 'Eintrag rückgängig machen');
  check('Rückgängig: „Training eintragen“ wieder da, Snackbar weg (UI-38)', (await seen(page, 'Training eintragen')) && (await gone(page, 'Eingetragen.')));
  // Erneut eintragen, auf den Pfad: Fenster endet, die Feier folgt.
  await click(page, 'Training eintragen');
  await click(page, 'Eintragen');
  await seen(page, 'Eingetragen.');
  await click(page, 'Pfad');
  check('Heute → Pfad: Feier-Blase „Das war Tag 13.“ erst nach dem Fenster (UI-40)', await seen(page, 'Stark, Jakob. Das war Tag 13.'));
  check('Pfad: Streak 13 nach dem Eintrag', await seen(page, 'Streak: 13 Tage'));
  await shot(page, 'heute-feier-pfad');
  await ctx.close();
}

// 7b. Entfernen → Rückgängig; Tauschen; Eigene Übung ------------------------------
{
  const { ctx, page } = await openHeute('2026-10-07T12:00:00+02:00');
  await click(page, 'Kniebeuge am Stuhl entfernen');
  check('Entfernen: Karte weg, Snackbar „Entfernt.“ mit Rückgängig', (await seen(page, 'Entfernt.')) && (await gone(page, 'Kniebeuge am Stuhl, 3 mal 12 Wiederholungen')));
  await shot(page, 'heute-entfernt');
  await click(page, 'Entfernen rückgängig machen');
  check('Rückgängig: die Übung ist wieder da', (await seen(page, 'Kniebeuge am Stuhl, 3 mal 12 Wiederholungen')) && (await gone(page, 'Entfernt.')));
  await click(page, 'Kniebeuge am Stuhl tauschen');
  check('Tauschen: nächste Alternative „Aufstehen vom Stuhl“', await seen(page, 'Aufstehen vom Stuhl'));
  await click(page, 'Eigene Übung hinzufügen');
  const labelled = (l) => page.locator(`[aria-label="${l}"]`).count();
  check('Eigene Übung: Dialog mit den drei Feldern (Name, Wiederholungen, Dauer in Minuten)', (await seen(page, 'Eigene Übung', 3000)) && (await labelled('Name')) > 0 && (await labelled('Wiederholungen')) > 0 && (await labelled('Dauer in Minuten')) > 0);
  await shot(page, 'heute-eigene-uebung');
  // Das Eingabefeld des Dialogs braucht einen Moment, bis sein Semantik-Knoten
  // Eingaben annimmt (erst nach dem Einblenden).
  await page.waitForTimeout(800);
  const field = page.locator('input[data-semantics-role="text-field"]:not([disabled])').first();
  await field.click({ force: true });
  await page.waitForTimeout(300);
  await page.keyboard.type('Plank', { delay: 40 });
  await page.waitForTimeout(500);
  await click(page, 'Hinzufügen');
  check('Eigene Übung: Karte mit Name, „3 × 10 · 5 Min“ (ohne Tauschen)', (await seen(page, 'Plank, 3 mal 10, 5 Minuten')) && (await button(page, 'Plank tauschen').count()) === 0);
  await ctx.close();
}

// 7c. Tageswechsel über Mitternacht bei offenem Trainings-Sheet --------------------
{
  const { ctx, page } = await openHeute('2026-10-07T23:59:40+02:00');
  await click(page, 'Training eintragen');
  await seen(page, 'Wie willst du trainieren?');
  await advanceClock(page, 30000); // 30 s: über Mitternacht
  await page.waitForTimeout(300);
  await click(page, 'Eintragen');
  check('Über Mitternacht: Sheet zu, Snackbar „Neuer Tag, neues Programm.“, neues Datum, frisches Programm', (await seen(page, 'Neuer Tag, neues Programm.', 10000)) && (await seen(page, 'Donnerstag, 8. Oktober')) && (await seen(page, 'Training eintragen')) && (await gone(page, 'Wie willst du trainieren?')));
  check('Über Mitternacht: kein „Rückgängig“ (der Wechsel beendet das Fenster)', (await button(page, 'Eintrag rückgängig machen').count()) === 0);
  await shot(page, 'heute-mitternacht');
  await click(page, 'Pfad');
  check('Über Mitternacht: der Eintrag zählte für den Vortag (Streak 13), keine Feier', (await seen(page, 'Streak: 13 Tage')) && (await page.getByText('Stark, Jakob', { exact: false }).count()) === 0);
  await ctx.close();
}

// 8. Deine Daten (U4): Profil ändern, Verwerfen, Löschen ----------------------------
async function openPfadMitDaten(now = '2026-10-07T12:00:00+02:00') {
  const ctx = await browser.newContext(ctxOptions);
  await ctx.addInitScript((doc) => {
    // Nur beim ersten Laden seeden: ein Reload soll den gespeicherten Stand zeigen.
    if (!sessionStorage.getItem('seeded')) {
      localStorage.setItem('curaone.state.v1', JSON.stringify(doc));
      sessionStorage.setItem('seeded', '1');
    }
  }, HEUTE_DOC);
  const s = await openScenario(ctx, base, { live: 1, a11y: 1 }, { clock: 'install', now });
  await seen(s.page, 'Woche 5');
  return { ctx, page: s.page };
}
const storageKeys = (page) => page.evaluate(() => Object.keys(localStorage));

// 8a. Name ändern und speichern; Heute zeigt ihn; Reload behält ihn
{
  const { ctx, page } = await openPfadMitDaten();
  check('Deine Daten: Icon in der Pfad-Kopfzeile', (await button(page, 'Deine Daten').count()) > 0);
  await click(page, 'Deine Daten');
  check(
    'Deine Daten: Sheet mit Titel, Untertitel, vorbefüllten Karten und Datum',
    (await seen(page, 'Alles bleibt auf diesem Gerät')) &&
      (await seen(page, 'Kreuzbandriss (ACL), Auswahl, ausgewählt')) &&
      (await seen(page, '7. September 2026')),
  );
  check(
    'Deine Daten: Manny-Knopf und Leiste sind aus der Semantik (unter dem Scrim)',
    (await button(page, 'Manny, Chat öffnen').count()) === 0 && (await button(page, 'Chats').count()) === 0,
  );
  await shot(page, 'daten-sheet');
  const field = page.locator('input[data-semantics-role="text-field"]:not([disabled])').first();
  await field.click({ force: true });
  // Das DOM-Eingabefeld von Flutter-Web ist direkt nach dem Klick noch leer; der
  // gespeicherte Name erscheint erst später. Aktiv warten, bis das aktive Feld
  // ihn enthält (sonst Wettlauf: Löschen und Tippen vor dem Eintragen).
  await page.waitForFunction(
    () => document.activeElement?.tagName === 'INPUT' && document.activeElement.value.length > 0,
    null,
    { timeout: 8000 },
  );
  // Ctrl+A markiert im Flutter-Web-Feld nicht zuverlässig: ans Ende, alles löschen.
  await page.keyboard.press('End');
  for (let i = 0; i < 12; i++) await page.keyboard.press('Backspace');
  await page.keyboard.type('Mia', { delay: 40 });
  await page.waitForTimeout(500);
  await shot(page, 'daten-sheet-geaendert');
  await click(page, 'Speichern');
  check('Speichern: Sheet zu, Pfad sichtbar', await gone(page, 'Alles bleibt auf diesem Gerät'));
  await click(page, 'Heute');
  check('Speichern: Heute zeigt den neuen Namen', await seen(page, 'Heute, Mia'));
  await page.reload();
  await seen(page, 'Woche 5');
  await click(page, 'Heute');
  check('Reload: der neue Name bleibt gespeichert (UI-43)', await seen(page, 'Heute, Mia'));
  await ctx.close();
}

// 8b. Verwerfen: Schließen, Browser-Zurück, Weiter bearbeiten, Verwerfen
{
  const { ctx, page } = await openPfadMitDaten();
  await click(page, 'Deine Daten');
  await seen(page, 'Alles bleibt auf diesem Gerät');
  await click(page, 'Muskelfaserriss, Auswahl, nicht ausgewählt');
  await click(page, 'Schließen');
  check('Änderung + Schließen: „Änderungen verwerfen?“ mit beiden Buttons', (await seen(page, 'Änderungen verwerfen?')) && (await seen(page, 'Du hast Änderungen noch nicht gespeichert.')));
  await shot(page, 'daten-verwerfen');
  await click(page, 'Weiter bearbeiten');
  check('Weiter bearbeiten: Dialog zu, Sheet und Änderung bleiben', (await gone(page, 'Änderungen verwerfen?')) && (await seen(page, 'Muskelfaserriss, Auswahl, ausgewählt')));
  await page.goBack();
  await page.waitForTimeout(500);
  check('Browser-Zurück (Android-Zurück) öffnet „Änderungen verwerfen?“, schließt das Sheet nicht', await seen(page, 'Änderungen verwerfen?'));
  await click(page, 'Verwerfen');
  check('Verwerfen: Sheet zu', (await gone(page, 'Änderungen verwerfen?')) && (await gone(page, 'Alles bleibt auf diesem Gerät')));
  await click(page, 'Deine Daten');
  check('Verwerfen speichert nichts: wieder der gespeicherte Typ', await seen(page, 'Kreuzbandriss (ACL), Auswahl, ausgewählt'));
  await ctx.close();
}

// 8c. Löschen → Onboarding Schritt 1
{
  const { ctx, page } = await openPfadMitDaten();
  check('Vorher: Zustand im localStorage', (await storageKeys(page)).some((k) => k.includes('curaone.state.v1')));
  await click(page, 'Deine Daten');
  await seen(page, 'Alles bleibt auf diesem Gerät');
  await click(page, 'Alle Daten löschen und neu starten');
  check('Löschen: Dialog „Alles löschen?“ mit „Abbrechen“ und „Ja, alles löschen“', (await seen(page, 'Alles löschen?')) && (await seen(page, 'Abbrechen')) && (await seen(page, 'Ja, alles löschen')));
  await shot(page, 'daten-loeschen-dialog');
  await click(page, 'Abbrechen');
  check('Abbrechen: Dialog zu, Sheet bleibt, Daten unverändert', (await gone(page, 'Alles löschen?')) && (await storageKeys(page)).some((k) => k.includes('curaone.state.v1')));
  await click(page, 'Alle Daten löschen und neu starten');
  await seen(page, 'Alles löschen?');
  await click(page, 'Ja, alles löschen');
  check('Ja, alles löschen: Onboarding Schritt 1 mit Hinweis „Alle Daten sind gelöscht.“', (await seen(page, 'Schritt 1 von 5')) && (await seen(page, 'Alle Daten sind gelöscht.')));
  await shot(page, 'daten-geloescht');
  check('Nach dem Löschen: kein Schlüssel des Zustands im localStorage (UI-51)', !(await storageKeys(page)).some((k) => k.includes('curaone.state.v1')));
  await page.reload();
  check('Reload nach dem Löschen: weiter Schritt 1', await seen(page, 'Schritt 1 von 5'));
  // Browser-Zurück auf Schritt 1 verlässt im Web die Seite (wie `SystemNavigator.pop`,
  // siehe Abschnitt 1); der Pfad und das Sheet sind nicht erreichbar.
  const urlBefore = page.url();
  await page.goBack();
  await page.waitForTimeout(800);
  const stayed = page.url() === urlBefore;
  check(
    'Browser-Zurück erreicht Pfad und Sheet nicht',
    !stayed || ((await seen(page, 'Schritt 1 von 5', 1500)) && (await button(page, 'Deine Daten').count()) === 0),
    stayed ? 'bleibt bei Schritt 1' : 'verlässt die Seite wie die App-Schließen-Taste',
  );
  await ctx.close();
}

// 8d. Chips erklären sich; Hinweis bei anderen Verletzungstypen; Datenschutz (SK-1)
{
  const { ctx, page } = await openPfadMitDaten();
  check('Pfad: Freeze- und Streak-Chip sind Schaltflächen', (await button(page, 'Streak-Freezes: 2').count()) > 0 && (await button(page, 'Streak:').count()) > 0);
  await click(page, 'Streak-Freezes: 2');
  check('Tipp auf Freeze: „Ein Freeze rettet deinen Streak an einem verpassten Tag.“', await seen(page, 'Ein Freeze rettet deinen Streak an einem verpassten Tag.'));
  await shot(page, 'pfad-hinweis-freeze');
  await click(page, 'Streak:');
  check('Tipp auf Streak: „Dein Streak zählt die Tage in Folge mit Training.“ ersetzt den Freeze-Hinweis', (await seen(page, 'Dein Streak zählt die Tage in Folge mit Training.')) && (await gone(page, 'Ein Freeze rettet deinen Streak an einem verpassten Tag.')));
  await shot(page, 'pfad-hinweis-streak');
  await page.keyboard.press('Escape');
  check('Escape schließt den Hinweis', await gone(page, 'Dein Streak zählt die Tage in Folge mit Training.'));
  await click(page, 'Deine Daten');
  await seen(page, 'Alles bleibt auf diesem Gerät');
  check('Kreuzband: kein Hinweis „noch keinen eigenen Pfad“', (await page.getByText('Für diese Verletzung gibt es noch keinen eigenen Pfad', { exact: false }).count()) === 0);
  await click(page, 'Muskelfaserriss, Auswahl, nicht ausgewählt');
  check('Muskelfaserriss gewählt: Hinweis „noch keinen eigenen Pfad … Beispielpfad“', await seen(page, 'Für diese Verletzung gibt es noch keinen eigenen Pfad. Du siehst einen Beispielpfad.'));
  await shot(page, 'daten-hinweis-pfad');
  await click(page, 'Datenschutzerklärung');
  check('„Datenschutzerklärung“ in Deine Daten öffnet die Platzhalterseite', await seen(page, 'Platzhalter. Hier steht später die Datenschutzerklärung.'));
  await shot(page, 'daten-datenschutz');
  await click(page, 'Zurück');
  check('Zurück: Sheet mit dem Entwurf bleibt', (await gone(page, 'Platzhalter. Hier steht später die Datenschutzerklärung.')) && (await seen(page, 'Muskelfaserriss, Auswahl, ausgewählt')));
  await ctx.close();
}

await browser.close();
const bad = results.filter((r) => r.ok === false);
console.log(`\n${results.filter((r) => r.ok !== null).length - bad.length}/${results.filter((r) => r.ok !== null).length} ohne Fehler`);
fs.writeFileSync(path.join(outDir, 'nav_checks.json'), JSON.stringify(results, null, 2));
process.exit(bad.length ? 1 : 0);
