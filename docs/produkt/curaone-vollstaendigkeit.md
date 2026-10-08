# Vollständigkeits-Check: CuraOne, erster Ausschnitt – 2026-10-07

Erstellt mit `/app-experience` (Bereich 2). Gegenstand: Onboarding (4 Schritte), Pfad/Home
mit Manny und Streak, minimales „Heute“.
**Grundlage:** `docs/design/design-brief-v1.md` (freigegeben), Specs 1–3 (`Spec 1-7.docx`),
`docs/UEBERGABE.md`. **Nicht geprüft:** Code (existiert noch nicht).

## Wichtigste Lücken

| # | Punkt | Bewertung | Begründung |
|---|---|---|---|
| 1 | Daten löschen / Consent widerrufen | ❌ fehlt | Spec 1: „Consent-Widerruf löscht alle Daten“. Brief 9 sagt „löschbar“, nennt aber keinen UI-Einstieg. Ohne ihn kommt man (auch beim Testen) nur per Neuinstallation zurück ins Onboarding. |
| 2 | Onboarding-Daten nachträglich ändern | ❌ fehlt | Spec 1: „Onboarding-Daten nachträglich editierbar“. Falscher Name oder falsches Datum ergibt dauerhaft falsche Woche und Phase. Keine Profil- oder Einstellungsansicht im Brief. |
| 3 | „Training eintragen“ rückgängig | ⚠️ lückenhaft | Entfernen einer Übung hat „Rückgängig“, Eintragen nicht. Ein Fehltipp erhöht den Streak und erledigt eine Pfad-Unit, ohne dass man es zurücknehmen kann. |
| 4 | Tageswechsel „Heute“ | ⚠️ lückenhaft | Offen: Wird das Programm am nächsten Tag neu erzeugt und „Heute erledigt“ zurückgesetzt? Bleiben Tauschen/Entfernen/eigene Übungen über einen App-Neustart erhalten? Was passiert bei einem Datumswechsel, während die App offen ist? |
| 5 | Antippen von Pfad-Units | ⚠️ lückenhaft | Nicht festgelegt. Bei der aktuellen Unit erwartet man das Training. Gesperrte Units geben beim Antippen keine Rückmeldung. |
| 6 | Streak-Regel Freeze | ⚠️ unklar | Spec 3: 1 verpasster Tag friert automatisch ein, Freezes sind „einlösbar“. Offen: Verbraucht das automatische Einfrieren einen der 2 Freezes? Was bewirkt ein Freeze bei 2 verpassten Tagen? |
| 7 | „Abends“ bei Streak-Gefahr | ⚠️ unklar | Keine Uhrzeit festgelegt, für Logik und Test aber nötig. |
| 8 | Zurück-Taste (Android) | ⚠️ lückenhaft | Im Onboarding naheliegend: ein Schritt zurück. Auf den Tabs nicht festgelegt: App schließen oder zum Pfad wechseln. |
| 9 | Hilfe & Feedback | ❌ fehlt | Kein Weg, Probleme zu melden. Für einen Prototyp mit Testpersonen eventuell nützlich, nicht nötig. |

## Bereits abgedeckt bzw. nicht relevant

- ✅ Erster Start und Onboarding: Manny-Führung, „Schritt X von 4“, Zurück behält Eingaben, Fortsetzen nach Abbruch.
- ✅ Barrierefreiheit: sehr gründlich (Labels, 200 % Schrift, Kontrast, Zielgrößen, reduzierte Bewegung).
- ✅ Fehler- und Leerzustände auf Pfad und Heute, Rückgängig beim Entfernen.
- ✅ Datenschutz-Schritt: Consent mit Zeitstempel und Version, Link vorhanden. Platzhaltertext vor Echtbetrieb juristisch prüfen (bekannt, keine Rechtsberatung).
- ✅ Platzhalter gekennzeichnet („Beispielpfad“, „Beispiel“-Termin).
- ✅ Berechtigungen: Mikrofon ist nur Platzhalter. Hinweis für die Umsetzung: keine Mikrofon-Berechtigung anfragen.
- ➖ Konto und Anmeldung (alles lokal), Offline (kein Backend), Sync und Export (später), Benachrichtigungen (bewusst nicht im Ausschnitt).

## Verbesserungsvorschläge (Nutzen zu Aufwand)

| V | Zu | Vorschlag | Nutzen | Aufwand | Nachteil |
|---|---|---|---|---|---|
| V1 | #3 | Snackbar „Eingetragen. Rückgängig“ nach „Training eintragen“, wie beim Entfernen | Fehltipps verfälschen Streak und Pfad nicht | klein | – |
| V2 | #4 | Tageswechsel als Logikregel festlegen: neues Programm pro Kalendertag, Tagesänderungen bis Mitternacht persistent, Datumswechsel beim Zurückkehren in die App erkennen | Keine verwirrenden Zustände am Folgetag, testbar | klein (Logik) | – |
| V3 | #1 | Unauffälliger Einstieg (z. B. Icon in der Pfad-Kopfzeile) zu Sheet „Deine Daten“ mit „Alle Daten löschen und neu starten“ samt Bestätigungsdialog | Erfüllt den Spec-1-Widerruf, erleichtert Tests | klein–mittel, Mini-Abstimmung mit `ui-designer` | ein zusätzliches UI-Element |
| V4 | #2 | Im selben Sheet Name, Verletzungstyp und Datum ändern (gleiche Auswahlkarten wie im Onboarding) | Korrektur falscher Eingaben, erfüllt Spec 1 | mittel | Pfad und Woche neu berechnen |
| V5 | #5 | Tipp auf aktuelle Unit wechselt zu „Heute“; Tipp auf gesperrte Unit zeigt kurzen Hinweis („Kommt in Woche N“) | Pfad und Training hängen erkennbar zusammen | klein | Hinweistext mit `ui-designer` abstimmen |

Die Punkte #6, #7 und #8 sind Klärungsfragen und keine Features.
