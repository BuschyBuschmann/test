#!/usr/bin/env node
// Browser-Prüfungen der Navigation (U2b, U2c, Plan 4.3, 12.5): Browser-Zurück =
// Android-Zurück (`page.goBack()`), Reload im Onboarding, Tabwechsel, Zeitsprung
// über Mitternacht mit der Fake-Uhr (`page.clock.install` + `runFor`), Manny-
// Chat und Nachrichten über die Button-Gruppe (Abschnitt 5), Pfad-Abläufe (U3a,
// Abschnitt 6): Zurück schließt zuerst die Blase, dann den Hinweis; Manny-Tipp
// öffnet den Chat; Tipp auf die aktuelle Unit wechselt auf Heute; Hinweis an
// einer gesperrten Unit (Escape, Zurück, 5 s).
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

/** Flutter-Web setzt Beschriftungen als Textinhalt der `flt-semantics`-Knoten. */
const textNode = (page, text) => page.getByText(text, { exact: false }).first();
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
// des Pfads tragen „Öffnet Heute.“ im Label.
const button = (page, name) =>
  page
    .locator('flt-semantics[role="button"]', {
      hasText: name === 'Heute' || name === 'Pfad' ? new RegExp(`^${name}$`) : name,
    })
    .first();
async function click(page, name) {
  const b = button(page, name);
  await b.waitFor({ state: 'attached', timeout: 8000 });
  await b.click({ force: true });
  await page.waitForTimeout(450);
}
async function shot(page, name) {
  await page.screenshot({ path: path.join(outDir, `${name}.png`) });
}
/** Zählt die History-Einträge, die `goBack` noch erreicht. */
const historyLength = (page) => page.evaluate(() => history.length);

const browser = await launch();

// 1. Onboarding live: Weiter, Weiter, Zurück per Browser, Reload -------------
{
  const ctx = await browser.newContext(ctxOptions);
  const s = await openScenario(
    ctx,
    base,
    { scenario: 'ob1-empty', live: 1, a11y: 1 },
    { clock: 'none' },
  );
  const page = s.page;
  check('Start (live): Onboarding Schritt 1', await seen(page, 'Schritt 1 von 4'));
  const field = page.locator('input[data-semantics-role="text-field"]:not([disabled])').first();
  const hasInput = (await field.count()) > 0;
  check('Namensfeld im Semantik-Baum vorhanden', hasInput);
  if (hasInput) {
    await field.click({ force: true });
    await page.keyboard.type('Jakob');
    await page.waitForTimeout(300);
  }
  await click(page, 'Weiter');
  check('Weiter → Schritt 2 von 4', await seen(page, 'Schritt 2 von 4'));
  await click(page, 'Verstanden, weiter');
  check('Verstanden, weiter → Schritt 3 von 4', await seen(page, 'Schritt 3 von 4'));
  await shot(page, 'ob-schritt3');

  // Reload (live = localStorage): Fortsetzen am gespeicherten Schritt (UI-16).
  await page.reload();
  check('Reload: Onboarding setzt bei Schritt 3 fort (UI-16)', await seen(page, 'Schritt 3 von 4', 15000));
  check('Reload: Manny-Text mit dem Namen', await seen(page, 'Jakob'));
  await shot(page, 'ob-reload-schritt3');

  // Browser-Zurück wie Android-Zurück: je Schritt einen Schritt (Plan 4.3, n6).
  const before = await historyLength(page);
  await page.goBack();
  await page.waitForTimeout(700);
  check(
    'Browser-Zurück auf Schritt 3 → Schritt 2 (wie Android-Zurück)',
    await seen(page, 'Schritt 2 von 4'),
    `history.length ${before}`,
  );
  await page.goBack();
  await page.waitForTimeout(700);
  check('Browser-Zurück auf Schritt 2 → Schritt 1', await seen(page, 'Schritt 1 von 4'));
  // Die Semantik-Eingabe spiegelt den Text erst, wenn das Feld Fokus hat.
  await page.locator('input[data-semantics-role="text-field"]:not([disabled])').first().click({ force: true });
  await page.waitForTimeout(400);
  const typed = await page.evaluate(() => document.activeElement?.value ?? null);
  check('Name blieb erhalten (Zurück behält Eingaben)', typed === 'Jakob', JSON.stringify(typed));

  // Auf Schritt 1: Android-Zurück schließt die App (`SystemNavigator.pop`). Im Web
  // ist das `history.back()`: die Seite wird verlassen (Plan 4.3 nahm „bleibt
  // stehen“ an; hier gemessen, siehe Bericht).
  const urlBefore = page.url();
  await page.goBack();
  await page.waitForTimeout(800);
  const stayed = page.url() === urlBefore && (await seen(page, 'Schritt 1 von 4', 1500));
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
  await page.clock.runFor(30000); // 30 s: über Mitternacht
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
  await page.clock.runFor(8000);
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
  await page.clock.runFor(30000);
  await page.mouse.click(284, 790); // Nav-Eintrag „Heute“
  await page.waitForTimeout(600);
  const withSnackbar = await page.screenshot();
  await page.clock.runFor(6000);
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
  await page.clock.runFor(30000);
  await page.evaluate(() => window.__setVisibility('visible'));
  const resumed = await seen(page, 'Neuer Tag, neues Programm.', 10000);
  console.log(
    `${resumed ? 'ok     ' : 'info   '} Fortsetzen (visibilitychange hidden → visible) über Mitternacht auf Heute: Snackbar ${resumed ? 'erscheint' : 'erscheint nicht (Web-Lebenszyklus nicht auslösbar; Resume per Widget-Test)'}`,
  );
  results.push({ name: 'Fortsetzen über visibilitychange', ok: null, detail: resumed ? 'Snackbar' : 'nicht ausgelöst' });
  await ctx.close();
}

// 5. Manny-Chat und Nachrichten (U2c, Ergänzung 2, UI-86) -----------------------
// Öffnen über die Button-Gruppe auf dem Pfad, Browser-Zurück = Android-Zurück:
// Chat → Pfad; Nachrichten → Beispiel-Chat → Nachrichten → Pfad.
{
  const ctx = await browser.newContext(ctxOptions);
  await ctx.addInitScript((doc) => localStorage.setItem('curaone.state.v1', JSON.stringify(doc)), FIXTURE);
  const s = await openScenario(ctx, base, { live: 1, a11y: 1 }, { clock: 'install', now: '2026-10-07T12:00:00+02:00' });
  const page = s.page;
  check('Chat-Ablauf: Home auf Pfad, Button-Gruppe vorhanden', (await seen(page, 'Woche 5')) && (await button(page, 'Manny, Chat öffnen').count()) > 0 && (await button(page, 'Nachrichten').count()) > 0);
  await shot(page, 'pfad-gruppe');

  await click(page, 'Manny, Chat öffnen');
  check('Manny-Button öffnet den Manny-Chat (Kopf „Dein Reha-Begleiter“)', await seen(page, 'Dein Reha-Begleiter'));
  check('Manny-Chat: Beispielverlauf mit Namen aus dem Onboarding', await seen(page, 'Moin Jakob. Wie läuft dein Tag?'));
  check('Manny-Chat: Hinweiszeile, Leiste und Disclaimer sichtbar', (await seen(page, 'Schreiben kann ich bald, heute noch nicht.', 2000)) && (await seen(page, 'Manny ersetzt keine medizinische Beratung.', 2000)));
  check('Manny-Chat: keine Button-Gruppe, keine Nav', (await button(page, 'Manny, Chat öffnen').count()) === 0 && (await button(page, 'Pfad').count()) === 0);
  await shot(page, 'chat-manny');
  await page.goBack();
  await page.waitForTimeout(700);
  check('Browser-Zurück im Manny-Chat → Pfad (Tab bleibt)', (await seen(page, 'Woche 5')) && (await gone(page, 'Dein Reha-Begleiter')));

  await click(page, 'Nachrichten');
  check('Nachrichten-Button öffnet die Nachrichten (Beispiel-Hinweis)', await seen(page, 'Beispiel-Ansicht. Echte Chats folgen.'));
  check('Nachrichten: sechs Beispielkontakte', (await page.locator('flt-semantics[role="button"]', { hasText: 'Beispielkontakt' }).count()) === 6, String(await page.locator('flt-semantics[role="button"]', { hasText: 'Beispielkontakt' }).count()));
  await shot(page, 'nachrichten');
  await click(page, 'Beispielkontakt Praxis Müller');
  check('Zeile öffnet den Beispiel-Chat („Physio · Beispiel“)', await seen(page, 'Physio · Beispiel'));
  check('Beispiel-Chat: Hinweis „Nur zum Ansehen.“, kein Disclaimer', (await seen(page, 'Beispiel-Chat. Nur zum Ansehen.', 2000)) && (await page.getByText('Manny ersetzt keine medizinische Beratung.').count()) === 0);
  await shot(page, 'beispiel-chat');
  await page.goBack();
  await page.waitForTimeout(700);
  check('Browser-Zurück im Beispiel-Chat → Nachrichten', (await seen(page, 'Beispiel-Ansicht. Echte Chats folgen.')) && (await gone(page, 'Physio · Beispiel')));
  await page.goBack();
  await page.waitForTimeout(700);
  check('Browser-Zurück in den Nachrichten → Pfad (Ausgangs-Tab)', (await seen(page, 'Woche 5')) && (await gone(page, 'Beispiel-Ansicht. Echte Chats folgen.')));
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
  await page.clock.runFor(6500);
  check('a11y aktiv: Hinweis bleibt über 5 s stehen', await seen(page, 'Kommt noch diese Woche', 1500));
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);

  // Erledigte Unit.
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
    await p2.clock.runFor(6000);
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

await browser.close();
const bad = results.filter((r) => r.ok === false);
console.log(`\n${results.filter((r) => r.ok !== null).length - bad.length}/${results.filter((r) => r.ok !== null).length} ohne Fehler`);
fs.writeFileSync(path.join(outDir, 'nav_checks.json'), JSON.stringify(results, null, 2));
process.exit(bad.length ? 1 : 0);
