# KI-Plan v2.5: Manny ist das Gehirn, dazu die Physio-KI (CuraOne, Ausschnitte 3 und 4)

Status: **PLAN ZUR FREIGABE** · v2.5 (v2.2 FREIGEGEBEN 2026-10-12 → v2.3 nach den freigegebenen Produkt- und Design-Ergebnissen vom 2026-10-14 → v2.4 nach Review S3-3 und Nutzerentscheidungen N-14 → v2.5 nach Re-Review S3-RR und Nutzerentscheidungen N-16; v2.2 nach Re-Review R-P2-RR; v2.1 nach Review R-P2; v2 Überarbeitung von `docs/plan/ki-plan-v1.md` v1.2) · Pakete S3-2, S3-K1, S3-K2 · Autor: `flutter-developer` · Stand 2026-10-14

## Änderungsprotokoll v2.4 → v2.5 (Paket S3-K2)

| Befund / Entscheidung | Änderung | Stelle |
|---|---|---|
| NIT 4.1/DB-K15 `app.manny_context_facts` als parametrisierte Funktion beschrieben | Sicht mit Spalte `patient_id`, Abfrage mit Filter auf `patient_id` | 4.1 |
| NIT 2.1 DB-K15 als Prüfung des Physio-Briefings | DB-K15 zu M-1 AK 1 (Manny-Kontext) verschoben | 2.1 |
| NIT 4.8.2 Verneinung der statischen Regel | „nennt weder … noch … und enthält keine Schreibzugriffe“ | 4.8.2 |
| MINOR-E (Flutter-Plan) Fixtures-Ablage | `supabase/tests/fixtures/local_day/` | 4.2.1 Regel 3 |
| MAJOR-B (Flutter-Plan) Tagesgrenze | `manny-today` bleibt bei ±1 Tag (sofortiger Aufruf); Warteschlangen-Grenze nur im Flutter-Plan 6.7 Nr. 3 | 4.2 |
| N-16 (Flutter-Plan) Zählweise je Verletzung, gemeinsame Meldung, nachträgliche Warnzeichen bestätigt | NE-25; Warnzeichen-Regeln aus dem Check-up je Verletzung, eine Meldung je Eingang | 0, 4.3 |
| Querverweise | Flutter-Plan v2.1 → v2.2 (Abschnittsnummern unverändert) | Grundlagen, 2.1, 4, 6, 8 |

## Änderungsprotokoll v2.3 → v2.4 (Paket S3-K1)

| Befund / Entscheidung | Änderung | Stelle |
|---|---|---|
| N-14 O-17 (+ a, b) | `duration_min` → `duration_sec` (Dauer je Satz) im Ausgabeschema und in den Regeln 4 und 6; Schätzregel mit `pause_sec`/60 s; Kürzung halbiert Sekunden – Vorbehalt „erst nach Bestätigung“ entfällt | 4.2, 4.2.1 R4/R6, 4.2.3, 6.2, 13 E-36 |
| N-14 E-28 | Kürzung ab Schmerz 6 | 0, 4.2.1 R7, 4.2.3, 10 (KI-2V), 11 KR-19, 13 E-28 |
| N-14 O-2, O-2a, O-2b, O-18, O-19 | Warnzeichen aus dem Check-up nach entschiedenen Regeln (Schwellung mit gleichem Hinweis, Stimmung ≤ 2, jeder weitere Tag); Schwellung und Einschränkungs-Stufe als Kontextwerte | 0, 4.1, 4.3, 4.8.1, 13 E-32 |
| MAJOR-2 Datumsbasis | `manny-today` bekommt `local_day` vom Gerät (Plausibilität ±1 Tag), Regel 3 nutzt ihn; gemeinsame Fixtures „Mitternacht/Zeitzone“ (Flutter-Plan v2.1 6.7) | 4.2, 4.2.1 R3, 6.2 |
| MINOR-6 DB-K14/K15 nicht als DB-Test prüfbar; „kein Recht“ falsch | Manny-Kontext nur aus der Sicht `app.manny_context_facts` (ohne Stimmung, Fragen, Notizen), DB-K15 prüft die Sicht; DB-K14 auf das Prüfbare beschränkt, Planschreib-Verbot als Server-Test + statische Regel; 4.8.2 korrigiert (`authenticated` hat SELECT auf Chat-Tabellen, Schutz nur über RLS) | 4.1, 4.8.2, 2.1, 6.2, 6.3 |
| NIT Tabellenkopf „v2.1“ | „v2.4“ | 1 |

### v2.2 → v2.3

| Thema | Was ist neu oder geändert | Abschnitt |
|---|---|---|
| Grundlagen | Flutter-Plan Ausschnitt 2 **v2.0**; Produktdokumente Training/Check-up, Physio-Bereich, Feed; Design-Brief v2 | Kopf |
| Physio-KI (PB-5) | **neu in Ausschnitt 3:** Kurzbriefing, Übung per KI (inkl. KI-Bild), Plan-Vorschläge, Fachfragen; Briefing nie aus dem Manny-Chat (technisch über die Physio-Sitzung und RLS erzwungen); Vorschläge wirken nur per Physio-Tipp | 0, 1, 2, 2.1, 4.8, 6, 9, 10, 11, 13 |
| Datenquellen | Kontext aus den neuen Tabellen: Tages-Check-ups, Check-ups nach der Einheit, Übungsergebnisse inkl. übersprungen mit Grund; **Stimmung nicht im Manny-Kontext** (C-3); Fragen an den Physio nicht im KI-Kontext (Annahme) | 4.1, 4.8.1 |
| Freigabe | „Freigegeben“ = Position der aktuellen Phase **und** freigeschaltet (PB-6, „Damit anfangen“) | 4.2.1 Regel 3 |
| Kürzung bei Schmerz | gilt laut Ablauf 4b schon in **Ausschnitt 2** (deterministisch, Flutter-Plan v2.0 8.7); Schmerzwert = heutiger Tages-Check-up; Dauer-Zweig hängt an O-17 | 4.2.3 |
| Warnzeichen | Ausschnitt 2 liefert `source = 'checkup'` inkl. Stimmungs-Nachricht ohne Details (C-3); Chat-Schreibwege unverändert | 4.3 |
| Übung begleiten | Session mit Zähler, Timern und Schmerz-Abbruch kommt deterministisch schon in Ausschnitt 2; M-3 in Ausschnitt 4 nur noch Schritt-Führung aus der Beschreibung und KI-Motivationssätze | 2.1, 4.6 |
| Schema-Bezüge | `wellbeing_reports` → `daily_checkups`; Pläne je Verletzung (`plans.injury_id`), `plans.current_phase_id`; Löschumfang erweitert | 4.1, 4.4, 8 |
| Offene Punkte | neu E-38–E-46 (u. a. Bilddienst für KI-Bilder, Quellen der Fachfragen, KI-Einwilligung für Physio-KI, Zahlen im Briefing); kein Anbieter und keine Kosten festgelegt | 13 |
| DB-Tests | neu DB-K12–DB-K16 | 6.3 |

Grundlagen:
- `docs/produkt/curaone-spezifikation-manny-gehirn.md` (FREIGEGEBEN 2026-10-11).
- `docs/plan/ki-plan-v1.md` v1.2: bleibt Referenz für alle verwiesenen Abschnitte („v1.2, n“).
- `docs/plan/flutter-plan-ausschnitt-2.md` **v2.2** (Rollenmodell, Schema inkl. Verletzungen, Check-ups, Übungsergebnisse, Baukasten, Einladung und Neubindung, Warnzeichen, Warteschlange, Löschen, DB-Tests DB-T01 ff.). Ausschnitt 3 setzt Ausschnitt 2 voraus. Verweise „Flutter-Plan v1.2, n“ und „Flutter-Plan v2.0, n“ in diesem Plan meinen die entsprechenden Abschnitte in v2.2 (Zuordnung dort, Abschnitt 19; die Nummern von v2.0 gelten in v2.1 und v2.2 unverändert).
- `docs/produkt/curaone-ablaeufe-training-checkup.md`, `docs/produkt/curaone-physio-bereich.md` (PB-5 Physio-KI, Ausschnitt 3), `docs/produkt/curaone-feed.md` (Feed ab Ausschnitt 4, hier nicht enthalten), alle FREIGEGEBEN 2026-10-14.
- `docs/design/design-brief-v2.md` (FREIGEGEBEN 2026-10-14): Optik aller KI-Oberflächen; Kachel 1 „KI-Kurzbriefing“ ist dort als Slot vorgesehen (7.9).
- Skill `claude-api` (Modelltabelle Stand 2026-10-06). API-Aussagen sind mit „(Skill)“ belegt oder als Annahme/„zu prüfen“ markiert; Modell-IDs nur aus Skill bzw. v1.2.

Kennzeichnung wie v1.2: **E-n**, **NE-n**, **KA-n**, **KR-n**, **X-n**; **DB-Kn** = benannter DB-Test dieses Plans (Abschnitt 6.3); **[entschieden]** = vom Plan vorgeschlagen, vom Nutzer am 2026-10-12 bestätigt; **[Vorschlag]** = noch nicht bestätigt; **[vor KI-1/KI-2 zu entscheiden]** = blockierender offener Wert. Rechtliche Punkte sind Prüfpunkte, keine Rechtsberatung.

---

## 0. Verbindliche Nutzerentscheidungen

Aus v1.2 weiter gültig: **NE-2** (Manny-Button auf Pfad und Heute), **NE-4** (Red-Flag-Vorprüfung auf dem Gerät zuerst, serverseitig wiederholt), **NE-6** (aktive Eingabe erst im KI-Ausschnitt). NE-1, NE-3, NE-5 sind erledigt.

Aus der Spezifikation (2026-10-11): **NE-7** Framework-Wissen · **NE-8** nur innerhalb der Physio-Freigabe, keine erfundenen Übungen · **NE-9** Physio sieht Verlauf und Warnzeichen, nicht den Chat · **NE-10** Chat, Heute, Übung, Pfad-Texte in zwei Ausschnitten · **NE-11** Prototyp, nur Testdaten, MDR für den Prototyp nicht behandelt · **NE-12** Supabase EU · **NE-13** Entwicklung über die Claude API mit Testdaten, echte Daten nur über EU-Region.

Aus dem Review R-P2 (2026-10-12):
- **NE-14 (N-1)** Neubindung: Der Chat bleibt an die alte Identität gebunden und wird bei Neubindung gelöscht; neues Gespräch auf dem neuen Gerät; Plan, Verlauf, Befinden bleiben; Hinweis an den Patienten bei jeder Neuanmeldung.
- **NE-15 (N-2)** Warnzeichen aus dem Chat, auch Krise/Selbstgefährdung, gehen an den Physio – nur Stufe und Zeitpunkt, kein Chattext; die Einwilligung nennt das ausdrücklich.
- **NE-16 (N-3)** Ersatzprogramm bei hohem Schmerz: automatisch kürzen nach fester Regel mit Hinweis.
- **NE-17 (N-4)** Physio sieht alle Patienten seiner Praxis.
- **NE-18 (N-5)** Alle MINOR/KI-MINOR/NITPICK einarbeiten; E-24 bleibt Annahme/offen.
- **NE-19 (Runde 2)** Bestätigt: Kürzungsregel E-36 (4.2.3) und Zahlenverbot E-37 (4.7 Regel 1); keine globale Einlöse-Bremse (Flutter-Plan v2.2 6.5). Plan freigegeben, Prüfung am Code in F2-1R.

Aus den Nutzerentscheidungen vom 2026-10-14:
- **NE-20** Physio-KI (PB-5) mit vier Aufgaben – Kurzbriefing je Patient, beim Anlegen von Übungen helfen (inkl. KI-Bild), Plan-Anpassungen vorschlagen (nur Vorschlag, der Physio entscheidet), Fachfragen beantworten (mit Quelle, ohne Gewähr) – kommt in **Ausschnitt 3** zusammen mit der Manny-KI (PB-9).
- **NE-21** Kurzbriefing: drei Sätze, nur aus Verlauf, Check-ups und Warnzeichen, **nie aus dem Manny-Chat**. Übung per KI: ohne den Physio wird nichts aktiv. Plan-Vorschläge: übernommen nur per Tipp des Physios.
- **NE-22 (C-3)** Stimmung wird nur erfasst und dem Physio gezeigt; die App reagiert gegenüber dem Patienten nicht. Daraus folgt für diesen Plan: Stimmungswerte gehen **nicht** in den Kontext der Patienten-KI (Manny), damit Manny nicht darauf reagiert (Brief v2 V2-57).
- **NE-23** Feed erst ab Ausschnitt 4 (F-2); nicht Teil dieses Plans.
- **NE-24 (Flutter-Plan N-14, 2026-10-14)** „Zeit“ einer Übung = Dauer je Satz in Sekunden (`duration_sec`); Schätzregel mit der Pause des Physios (`pause_sec`, sonst 60 s); Kürzung E-36 halbiert die Dauer je Satz in Sekunden (`max(1, abrunden(Dauer / 2))`). **E-28 = Schmerz 6.** Warnzeichen aus dem Tages-Check-up: Schmerz ≥ 7, Anstieg ≥ 3 zum Check-up des Vortags, Schwellung 3 (gleicher fester Hinweis); Stimmungs-Nachricht ab 5 aufeinanderfolgenden Tagen mit Check-up und Stimmung ≤ 2, an jedem weiteren Tag erneut, Lücke unterbricht, Patient erfährt nichts. Schwellung 0–3 und Einschränkungen als Einzelwert-Skala im Tages-Check-up.
- **NE-25 (Flutter-Plan N-16, 2026-10-14)** Stimmungskette und Anstiegsregel zählen **je Verletzung** (neue Verletzung → Zählung beginnt neu, Vortag einer anderen Verletzung zählt nicht). Mehrere Stimmungs-Warnzeichen aus einem verspäteten Check-up: je Tag ein Warnzeichen, beim Physio **eine** gemeinsame Meldung. Nachträgliche Warnzeichen durch verspätete Check-ups sind gewollt. Für diesen Plan ändert sich dadurch nur die Beschreibung in 4.3; Chat-Warnzeichen sind nicht betroffen.

**Vor KI-1/KI-2 zu entscheiden (blockierend):** E-7, E-15, E-27, E-30, E-31. E-28 und O-2 sind entschieden (NE-24). **Vor KI-P1/KI-P2 (Physio-KI):** E-38, E-39, E-42; vor dem KI-Bild-Teil zusätzlich E-40.

---

## 1. Kurzfassung

| Thema | v2.5 |
|---|---|
| Zielbild | M-1 Chat mit Akte-Wissen · M-2 „Heute“ zusammenstellen · M-3 Übung begleiten · M-4 persönliche Pfad-Texte · **Physio-KI** (PB-5): Kurzbriefing, Übung per KI, Plan-Vorschläge, Fachfragen |
| Harte Grenze | Jede KI-Auswahl wird **deterministisch gegen die Freigabe validiert** (S8b, Server und App, gemeinsame Fixtures); zusätzlich prüft eine **Freitextprüfung** jeden KI-Text (Begründung, Blasen, Übungs-Sätze, Chat) auf Zahlen/Umfangsangaben und nicht freigegebene Übungen (K-1) |
| Ersatzprogramm | bei Verstoß, Ausfall oder Limit: deterministisches Programm aus Ausschnitt 2; bei hohem Schmerz nach fester Kürzungsregel (NE-16) |
| Warnzeichen | Gerät: RPC `report_chat_warning` mit festen Werten; Server/Modell: Funktion; Zusammenführung je `clientMessageId`; kein Text (NE-15) |
| Physio und Chat | Chat-Daten an die erzeugende Auth-Identität gebunden, keine Physio-Policy, Löschung bei Neubindung (NE-14) |
| Endpunkte | `manny-chat` (Stream), `manny-today` (strukturiert), `manny-bubble` (strukturiert, vorab); **Physio:** `physio-briefing`, `physio-exercise-draft`, `physio-plan-suggestions` (strukturiert), `physio-qa` |
| Physio-KI und Chat | Physio-Endpunkte lesen Daten **mit der Sitzung des Physios** (RLS); für Physios gibt es keine Chat-Policy, also ist der Chat für sie technisch unerreichbar (4.8.2) |
| Weg zur KI | W1 Claude API für den Prototyp (nur Testdaten); W2/W3 EU erst für echte Daten |
| Modell | `claude-opus-5-5`, Kandidat `claude-sonnet-5-5` (E-3) |
| Bleibt aus v1.2 | Leitplanken, Red-Flag-Zweistufigkeit inkl. 3.1a, Eval-Methodik, Löschkonzept, Streaming, Limits, Idempotenz, Ausgabefilter, Injection-Schutz, Gedächtnis G1, KI-L (Paket Einwilligungs- und Rechtstexte) |

---

## 2. Zielbild und Umfang

**Ausschnitt 3:** M-1 Chat (schreibbar, Framework-Wissen, Verweis an Behandler, Warnzeichen → fester Hinweis + Physio) und M-2 „Heute zusammenstellen“ (aktuelle Phase, Zeit, Tages-Check-up, ein Begründungssatz, bei Schmerz leichter/weniger). **Dazu die Physio-KI (PB-5, NE-20):** Kurzbriefing über der Patientenübersicht (Kachel 1), Übung per KI im Baukasten (inkl. KI-Bild, sobald E-40 entschieden), Plan-Vorschläge, Fachfragen.

**Ausschnitt 4:** M-3 Übung begleiten (Schritt-Führung aus der Beschreibung, KI-Motivationssätze; Zählen, Timer und Schmerz-Abbruch liefert schon die Session aus Ausschnitt 2) und M-4 Pfad-Texte (echter Verlauf, Rückfall auf feste Texte).

**Nicht enthalten** (Spec 8): Feed (ab Ausschnitt 4, eigener Plan), Arzt-Zugang, Übungen außerhalb der Freigabe, Sprache, proaktive Nachrichten/Push, Direktnachrichten, Abrechnung, Mehrsprachigkeit, Zulassung. Später (v1.2): Lernfähigkeit, Onboarding-Chat, Dokumente als Kontext, Wochenbrief, Triage-KI.

### 2.1 Zuordnung Akzeptanzkriterien → Paket → Prüfung (K-m5)

| AK | Umsetzung | Paket | Prüfung |
|---|---|---|---|
| M-1 AK 1 (Wissen aus Framework) | Kontext 4.1 | KI-1, KI-2, KI-3 | Eval „Kontextnutzung Akte“; Unit-Test Kontextbau (Felder, Escaping, Kürzung); DB-K15 (Kontextquelle `app.manny_context_facts` ohne Stimmung, Fragen, Notizen) |
| M-1 AK 2 (außerhalb Freigabe → kein Inhalt, Verweis an Behandler) | 4.2 Chat, `refer_to_treater`, Freitextprüfung 4.7 | KI-2, KI-3, KI-5 | Eval „Weiterleitung“, „keine Übung erfinden“; Widget-Test Behandler-Karte (mit/ohne Behandler der Rolle) |
| M-1 AK 3 (Warnzeichen → fester Hinweis + beim Physio) | 4.3 | KI-1, KI-2, KI-5 | DB-K04 bis DB-K07; Widget-Test Karte offline; Integration KI-7 „Warnzeichen erscheint in Physio-Liste“ |
| M-2 AK 1 (nur aktuelle Phase, innerhalb Grenzen, automatisch geprüft, Abweichung = Fehler) | S8b 4.2 | KI-2V, KI-2 | Unit-Tests Validator (gemeinsame Fixtures Dart/Server); Eval „Freigabe-Treue“ mit Schwelle 0 |
| M-2 AK 2 (Schmerz → leichtere Variante oder weniger Umfang, gesagt) | 4.2 Regel 7, Kürzungsregel 4.2.3 | KI-2V, KI-3 | Unit-Tests Kürzungsregel; Eval „Schmerz-Reduktion“ |
| M-2 AK 3 (ein Satz Begründung) | 4.2 Regel 6, 4.7 | KI-2, KI-5 | Validator; Eval „Begründungssatz“; Widget-Test Anzeige/Rückfallsatz |
| M-3 AK 1 (Schritt für Schritt, Sätze/Wdh. mitzählen) | Zählen: Flutter-Plan v2.2 8.5 (Ausschnitt 2, L4); Schritt-Führung 4.6 | L4 / KI-6 | **Unit-Tests** Schrittzerlegung (Zeilen, Absätze, leere Zeilen, eine Zeile), Zähler (Sätze × Wdh., nur Dauer, nur Sätze); **Widget-Tests** Weiter/Zurück, Zähler, Ende, Abbruch |
| M-3 AK 2 (Schmerz → nur freigegebene leichtere Variante oder Abbruch) | Flutter-Plan v2.2 8.5 (Ausschnitt 2, L4); KI ändert daran nichts | L4 / KI-6 | **Widget-Tests**: mit Variante → genau zwei Optionen; ohne Variante → nur Abbruch; nie andere Übung; Freitext läuft durch Vorprüfung |
| M-4 AK (Bezug auf echten Verlauf; Rückfall feste Texte) | 4.5 | KI-2, KI-6 | Eval „Pfad-Texte“; Widget-Test Rückfall bei Fehler/offline/ohne Einwilligung; Freitextprüfung |
| PB-5 / Kurzbriefing (drei Sätze, nur Verlauf, Check-ups, Warnzeichen, nie Chat) | 4.8.1, 4.8.2 | KI-P1, KI-P2, KI-P3 | DB-K12, DB-K13; statische Regel; Eval „Briefing: Faktentreue“ und „Briefing: kein Chat“; Widget-Test Kachel 1 (Laden, Fehler, ohne KI → Kachel leer mit Hinweis) |
| PB-5 / Übung per KI (füllt Baukasten vor, KI-Bild auf Wunsch, nichts aktiv ohne Physio) | 4.8.3 | KI-P2, KI-P3 | Server-Test: Entwurf wird nicht gespeichert; Widget-Test: erst „Speichern“ des Physios legt die Übung an; Eval „Übungsentwurf“; KI-Bild erst nach E-40 |
| PB-5 / Plan-Vorschläge (nur Vorschlag, Übernahme nur per Tipp) | 4.8.4 | KI-P2, KI-P3 | Validator (IDs gehören zum aktuellen Plan); Server-Test `physio_endpoints_no_plan_write` + statische Regel (4.8.2); Widget-Test: ohne Tipp keine Planänderung, mit Tipp `save_plan` aus der Physio-Sitzung |
| PB-5 / Fachfragen (mit Quelle, ohne Gewähr) | 4.8.5 | KI-P2, KI-P3 | Server-Test: Antwort ohne Quelle wird nicht angezeigt [Vorschlag]; Widget-Test Hinweis „keine Gewähr“; Eval „Fachfragen: Quelle“ – Quellenart offen (E-41) |

---

## 3. Was aus v1.2 bleibt

| Thema | v1.2 | Anpassung |
|---|---|---|
| Sicherheitsreihenfolge Gerät → Server | 3.1 | S1b gebundener Patient; S6 Kontext aus Akte; S8b nur `manny-today`; S8c Freitextprüfung |
| Ablauf nach Vorprüfungs-Treffer | 3.1a | Ereignis ohne Text ist Pflicht (NE-15), Schreibweg 4.3 |
| Streaming, SSE, `retract`, Abbruch | 3.4 | unverändert |
| Werkzeug `escalate_red_flag` | 3.4 | unverändert; neu `refer_to_treater` |
| Ablehnung, Rückfallmodell | 3.4, 6.6 | E-15 neue Empfehlung (5) |
| Ausgabefilter | 3.4, 6.2 | erweitert zur Freitextprüfung 4.7 |
| Idempotenz, Sperre | 3.4 | unverändert |
| Auth/Missbrauch | 3.5 | nur gebundene, aktive Patienten |
| Limits | 3.6 | plus `manny-today` |
| Gedächtnis G1 | 5.4 | an Identität gebunden (4.4) |
| Persona | 5.2 | unverändert (E-4) |
| Leitplanken | 6.1–6.7 | 6.1 „strenger Modus ohne Framework“ → Rahmen = Freigabe |
| Eval | 7 | neue Kategorien (6) |
| Löschkonzept | 9 | Basis Ausschnitt 2, Chat-Teil 8 |
| KI-L (Einwilligungs- und Rechtstexte) | 13 | **bleibt** als Paket, für den Prototyp ohne Anwalt (7, 10) |
| KA-6 Text-only-Verlauf reicht | 17 | **bleibt** (14) |
| KR-9 Beta-Funktionen, KR-12 Antwortbeginn durch Denken | 14 | **bleiben** (11) |

---

## 4. Was sich ändert

### 4.1 Kontext aus der Akte
- Server baut den Kontext aus den Tabellen von Ausschnitt 2. Vom Gerät nur lokale Werte (Streak, Freezes, heute erledigt, Zeitwahl, Tagesänderungen) mit Schema-, Längen- und Escaping-Regeln (v1.2 5.3).
- Aufbau (Reihenfolge laut Skill tools → system → messages) mit **zwei Cache-Breakpoints** (NITPICK):

```
tools     escalate_red_flag, refer_to_treater (fest, byte-gleich)
system    Persona · Regeln · Rahmen = Freigabe · Ausgabeformat        -- Breakpoint 1 --
messages  user: <framework planVersion=… stand=…> … </framework>       -- Breakpoint 2 (je Patient stabil) --
                <zusammenfassung> <tageskontext> + erste Nachricht im Fenster
          … Verlauf im Fenster …
          user: aktuelle Nachricht                                    (+ automatisches Caching oben)
```
  Höchstens 4 Breakpoints je Anfrage (Skill); hier 2 explizite + automatisches Caching. Wirksamkeit über `usage.cache_read_input_tokens` messen (Skill); Mindestlänge des Präfixes ist modellabhängig (Skill), ein kurzer Framework-Block wird ggf. nicht gecacht.
- Framework-Block: **freigegebene** Übungen (Flutter-Plan v2.2 6.7) mit `plan_item_id`, Name, Kurzbeschreibung, Grenzen, Belastungshinweis, Material, Ort, leichtere Variante (E-30); Behandler nur Rolle und Name; Krankengeschichte und Verlauf im Umfang E-32. Freitexte als Daten (v1.2 6.7). Kürzung je Bereich mit Kennzeichnung (KR-16).
- **Datenquellen aus Ausschnitt 2 (Flutter-Plan v2.2):** Tages-Check-ups (`daily_checkups`: Schmerz, Wohlbefinden, Motivation, Schwellung 0–3, Einschränkungs-Stufe keine/leicht/deutlich/stark), Check-ups nach der Einheit (`session_checkups` und Positionen: Bewertung, leicht/passend/schwer/Schmerz, „Gewicht erhöht“, Grund für Übersprungenes), Übungsergebnisse (`exercise_results`), aktuelle Verletzung (`injuries`). Ersetzt „Befinden“ aus v2.2.
- **Nicht im Manny-Kontext:** Stimmung (`daily_checkups.mood`) und Warnzeichen der Art `mood_low_streak` (NE-22, C-3: keine Reaktion gegenüber dem Patienten); Fragen an den Physio (`patient_questions`, kein Chat-Bezug, Annahme KA-15); Notizen der Praxis (`practice_notes`, Patient sieht sie nicht, PB-C). **Technisch erzwungen (MINOR-6):** Die Patienten-Edge-Functions lesen Patientendaten für den Kontext **ausschließlich** über die Sicht `app.manny_context_facts` (Sicht mit Spalte `patient_id`, abgefragt mit `WHERE patient_id = <Patient der Sitzung>`; keine parametrisierte Funktion; `security_invoker`, `SELECT` nur für die Rolle der Funktionen), die `daily_checkups.mood`, `patient_questions`, `practice_notes` und Warnzeichen mit `reason_code = 'mood_low_streak'` nicht enthält. Prüfung: DB-K15 (Sicht) und statische Regel (Code von `manny-*` liest keine andere Patiententabelle).

### 4.2 Manny innerhalb der Freigabe (M-2)

**Endpunkt `manny-today`** (ohne Stream). Eingabe vom Gerät: Zeitwahl, heute erledigt, ggf. nicht synchronisierter Tages-Check-up (nur Schmerz und die in E-32 genannten Werte, ohne Stimmung), **`planVersion`**, die das Gerät gerade anzeigt, **`local_day`** (lokaler Tag des Geräts, Datumsbasis Flutter-Plan v2.2 6.7; außerhalb ±1 Tag um das UTC-Datum des Servers → `invalid_local_day`; als sofortiger Aufruf gilt für `manny-today` diese Grenze, nicht die Warteschlangen-Grenze aus Flutter-Plan v2.2 6.7 Nr. 3), `clientRequestId`. Server: S1 JWT → S1b gebundener, aktiver Patient → S2 KI-Einwilligung → S5 Limits → S6 Kontext → S7 Claude mit `output_config.format` (Skill), Schema:
`{ items: [{ plan_item_id, sets, reps, duration_sec, use_easier_variant }], reason, reduced_for_pain }` (`duration_sec` = Dauer je Satz in Sekunden, NE-24) → S8b → S8c → Antwort.

#### 4.2.1 S8b Validierung gegen die Freigabe (K-m2)
1. **Planversion:** `planVersion` des Geräts = aktuelle Version des Plans; sonst `stale_plan` (App lädt neu und fragt erneut, kein KI-Ergebnis anzeigen).
2. **Nicht leer:** `items` enthält mindestens eine Position.
3. Jede `plan_item_id` gehört zur **aktuellen Phase** der aktuellen Version **und ist freigeschaltet** (`isReleased(item, plan, local_day)`, Flutter-Plan v2.2 6.7: `release = active`, oder vorbereitet mit `release_on ≤ local_day` bzw. erreichter Phase). Maßgeblich ist der **`local_day` des Geräts**, nie das Serverdatum (MAJOR-2); gleiche Fixtures Dart/Server einschließlich „Mitternacht/Zeitzone“ (`supabase/tests/fixtures/local_day/`, angelegt in Flutter-Plan L2); keine doppelten.
4. **Grenzen** (E-27, Obergrenzen): je Dimension `sets`, `reps`, `duration_sec`:
   - Grenze des Physios gesetzt → KI-Wert `null` (= Physio-Wert übernehmen) oder `1 ≤ Wert ≤ Grenze`;
   - Grenze des Physios **`null`** → KI-Wert **muss `null` sein** (Dimension nicht freigegeben, nicht einführbar).
5. `use_easier_variant = true` nur, wenn der Physio für genau diese Position eine leichtere Variante freigegeben hat (E-30); deren Grenzen gelten dann nach Regel 4.
6. **Gesamtdauer** nach der Dauer-Schätzregel aus Flutter-Plan v2.2, 8.4 (`estimateMinutes` mit `duration_sec` je Satz und Pause `pause_sec` bzw. 60 s, NE-24; gleiche Implementierung in Dart und Server, gleiche Fixtures) ≤ Zeitwahl; bei `reduced_for_pain` ≤ gekürztes Zeitbudget (4.2.3).
7. **Schmerz** (NEU-8): Unterhalb der Schwelle E-28 (Schmerz < 6) muss `reduced_for_pain = false` sein. Ab der Schwelle (Schmerz ≥ 6) muss `reduced_for_pain = true` sein **und** jede Position die **Kürzungsgrenzen aus 4.2.3** einhalten: (a) hat der Physio eine leichtere Variante freigegeben, ist `use_easier_variant = true` Pflicht; (b) sonst darf die KI je Position höchstens die gekürzten Werte aus 4.2.3 Schritt 2 verwenden (weniger ist erlaubt); (c) die Gesamtdauer (Regel 6) ≤ gekürztes Zeitbudget. Die KI darf also weniger als das Ersatzprogramm wählen, nie mehr.
8. `reason`: genau ein Satz, höchstens 140 Zeichen [Vorschlag: eine Zeile auf einem 390-dp-Bildschirm in zwei Zeilen], besteht S8c.

#### 4.2.2 Bei Verstoß (E-29)
Kein zweiter KI-Versuch; Ereignis `freigabe_verstoss` (Regelnummer, Metadaten, kein Text); im Eval als Fehler gezählt; die App zeigt das **Ersatzprogramm** (4.2.3) mit festem Satz. Die App prüft das KI-Ergebnis zusätzlich mit derselben Logik (`lib/logic/release_validation.dart`) und zeigt es nur, wenn beide Prüfungen bestehen.

#### 4.2.3 Ersatzprogramm und Kürzungsregel bei Schmerz (NE-16, K-m1) [entschieden, NE-19]
Deterministische Funktion `fallbackToday(phaseItems, timeChoice, pain)` in `lib/logic/` (Dart) und gleichlautend im Server; gilt für Verstoß, KI-Ausfall, Limit, fehlende KI-Einwilligung und offline.
- **Ohne Schmerzschwelle:** Regel O-10 aus Ausschnitt 2 (der Reihe nach bis zur Zeitwahl).
- **Ab Schmerzschwelle E-28 (Schmerz ≥ 6, NE-24):**
  1. Zeitbudget = **halbe Zeitwahl**, abgerundet auf ganze Minuten, mindestens 5 Minuten (10 → 5, 20 → 10, 30 → 15);
  2. je Position: hat der Physio eine leichtere Variante freigegeben → **nur diese** verwenden (mit ihren Grenzen); sonst kürzen nach der ersten zutreffenden Zeile (NEU-8):
     - `sets` gesetzt → Sätze auf `max(1, aufrunden(Sätze / 2))`; Wiederholungen und Dauer unverändert;
     - keine `sets`, aber `duration_sec` → Dauer je Satz auf `max(1, abrunden(Dauer / 2))` **Sekunden** (NE-24);
     - keine `sets`, keine Dauer, aber `reps` → Wiederholungen auf `max(1, aufrunden(Wdh. / 2))`;
     - keine Grenze gesetzt → Position unverändert, zählt mit der Dauer-Schätzung (Flutter-Plan v2.2 8.4, 5 Minuten) gegen das Budget;
  3. Positionen der Reihe nach aufnehmen, bis das Budget erreicht ist (mindestens eine);
  4. fester Hinweis über der Liste, sinngemäß „Weil dein Schmerz heute höher ist, habe ich dein Programm gekürzt.“ (Wortlaut KI-D/E-17).
- Begründung: halbe Zeit und halbe Sätze sind einfach erklärbar und bleiben immer innerhalb der Physio-Grenzen (nur Unterschreitung, E-27); leichtere Varianten haben Vorrang, weil der Physio sie ausdrücklich freigegeben hat.
- **Geändert in v2.3:** Die Kürzung gilt **schon in Ausschnitt 2** (ohne KI), weil der freigegebene Ablauf 4b (Tages-Check-up, Schritt 4) sie verlangt; gebaut in Flutter-Plan v2.2 L5 (8.7); E-28 ist entschieden (Schmerz 6). Schmerzwert ist der Schmerz aus dem heutigen Tages-Check-up; ohne Check-up keine Kürzung. Die Schwelle kommt mit dem Framework aufs Gerät, damit die Kürzung offline wirkt.
- **Dauer-Zweig (O-17, entschieden NE-24):** „Zeit“ ist die Dauer je Satz in Sekunden; Schritt 2 halbiert sie auf `max(1, abrunden(Dauer / 2))` Sekunden. Die Anpassung der freigegebenen Regel E-36 ist vom Nutzer bestätigt.

**Chat (M-1):** Regeln im System-Prompt (nur Übungen aus dem Framework, keine neuen; Medikament/Diagnose/neue Übung → kein Inhalt, Verweis). Werkzeug `refer_to_treater` (`strict: true`, `{role, reason_code}`) → App zeigt Behandler-Karte aus der Akte; ohne Behandler der Rolle „deinen Physio fragen“ (E-34). Der Chat ändert „Heute“ nicht selbst.

**Leichtere Variante (E-30):** Spalte `plan_items.easier_variant_of` (→ `plan_items.id`, `ON DELETE SET NULL`, gleiche Phase; Prüfung in `save_plan`) und Erweiterung des Plan-Editors in KI-1/KI-5.

### 4.3 Warnzeichen gehen an den Physio (K-2, NE-15)
Schema-Erweiterung `warning_signs` (aus Ausschnitt 2): `source = 'chat'`, `layer` (`device` · `server` · `model`), `client_message_id`; **keine Textspalte**; `authenticated` hat **kein** INSERT-Recht (Flutter-Plan DB-T25).

Schreibwege:
- **Gerät** (Vorprüfungs-Treffer, auch offline über die Warteschlange): RPC `report_chat_warning(client_message_id uuid, level text, reason_code text)` – `SECURITY DEFINER`, `search_path = ''`, `EXECUTE` nur `authenticated`; prüft gebundenen, aktiven Patienten; `level` aus fester Liste (`physio` · `arzt` · `notfall` · `krise`), `reason_code` aus fester Liste (Startliste E-6/E-17); setzt **fest** `source = 'chat'`, `layer = 'device'`, `patient_id` aus der Sitzung; nimmt keinen Text entgegen.
- **Server-Vorprüfung S3 und Werkzeug `escalate_red_flag`:** die Edge Function schreibt über dieselbe interne Funktion `app.record_chat_warning(patient_id, client_message_id, level, reason_code, layer)` mit `layer = 'server'` bzw. `'model'`.
- **Zusammenführung:** eindeutiger Schlüssel `(patient_id, client_message_id, layer)` → wiederholtes Senden ist idempotent; die Physio-Ansicht zeigt je `client_message_id` **eine** Meldung mit der höchsten Stufe und den Schichten, die sie erkannt haben.
- Krise/Selbstgefährdung (`krise`) wird ebenso gemeldet (NE-15); Text und Gesprächsinhalt nie.
- Die App zeigt beim Patienten weiter Karte und festen Text (v1.2 6.3/6.4) und den Hinweis, dass der Physio ein Warnzeichen sieht (Wortlaut E-17).
- Warnzeichen aus dem Tages-Check-up bleiben beim Trigger aus Ausschnitt 2 (`source = 'checkup'`, Flutter-Plan v2.2 6.9, Regeln entschieden NE-24): Schmerz ≥ 7, Anstieg ≥ 3 zum Check-up des Vortags und Schwellung 3 mit `notify_patient = true` (gleicher fester Hinweis); Stimmungs-Nachricht ab dem 5. aufeinanderfolgenden Tag mit Check-up und Stimmung ≤ 2 und an jedem weiteren solchen Tag erneut (`reason_code = 'mood_low_streak'`, ohne Details, `notify_patient = false`; ein Tag ohne Check-up unterbricht). Kette und Vortag zählen **je Verletzung**; mehrere Stimmungs-Warnzeichen aus einem verspäteten Check-up erscheinen beim Physio als **eine** Meldung (`trigger_checkup_id`, NE-25). Der Chat ändert an diesen Regeln nichts. Die Chat-Warnzeichen setzen `notify_patient = true` nur dort, wo die App heute schon Karte und festen Text zeigt (v1.2 6.3/6.4); an deren Verhalten ändert sich nichts.

### 4.4 Der Physio sieht den Chat nicht; Bindung an die Identität (M-6, NE-14)
- Tabellen `chat_messages`, `chat_summaries`, `manny_bubbles`, `ai_usage`, `ai_events`: Spalten `patient_id` **und** `owner_uid` (Auth-Identität, die die Daten erzeugt hat). RLS für `authenticated`: `owner_uid = app.uid() AND patient_id = app.current_patient_id()`; **keine** Physio-Policy; Schreiben nur über die Edge Functions (Rolle der Funktion).
- **Neubindung** (`redeem_invitation` → `ok_rebound`, Flutter-Plan v2.2 6.4): `app.on_rebind(old_uid)` **löscht** alle Chat-Daten mit `owner_uid = old_uid` (NE-14); das alte Auth-Konto wird gelöscht. Die neue Identität beginnt ein leeres Gespräch. Damit kann auch ein Physio, der selbst einen neuen Code einlöst, keinen alten Chat lesen; der Patient bemerkt den Zugangsverlust auf seinem Gerät und sieht auf dem neuen Gerät den Hinweis (Flutter-Plan v2.2 7.2).
- `warning_signs` bleibt bei Neubindung erhalten (gehört zum Patienten, nicht zum Chat; enthält keinen Text). Ebenso Check-ups, Übungsergebnisse und Fragen (gehören zum Patienten, Flutter-Plan v2.2 DB-T34).
- `patient_id` der Chat-Tabellen bleibt der Patient; ein Bezug zur Verletzung (`injury_id`) ist für Chat-Daten nicht vorgesehen (Annahme KA-16), damit der Chat über eine neue Verletzung hinweg weiterläuft.
- Statische Regel: `lib/physio/**` nennt keine Chat-Tabellen und importiert kein Chat-Modell. Server-Logs ohne Inhalt.
- Die Einwilligung (Ausschnitt 2, A-1) und die KI-Einwilligung (E-31) nennen das ausdrücklich, einschließlich Krisen (NE-15).

### 4.5 KI-Texte für die Blasen (M-4)
Mechanik v1.2 5.5 (vorab erzeugt, gespeichert, synchrone Anzeige, fester Text als Rückfall); Kontext aus echtem Verlauf; strukturierte Ausgabe `{occasion, text, fact_id?}`; Prüfungen: ≤ 2 Sätze, Wortlisten, **Freitextprüfung 4.7**; ohne Einwilligung, offline, Fehler, Limit → fester Text.

### 4.6 Übung begleiten (M-3) – Vorschlag E-33
**Abgrenzung zu Ausschnitt 2 (neu):** Die geführte Session mit Zähler, Halte-/Dauer-/Pausen-Timer, Gesamtzeit, Überspringen, Beenden und „Schmerz melden“ (nur freigegebene leichtere Variante oder Abbruch) ist deterministisch Teil von Ausschnitt 2 (Flutter-Plan v2.2 8.5, T-1/T-2/T-5). Ausschnitt 4 ergänzt nur die Schritt-Führung aus der Beschreibung und KI-Motivationssätze; die Sicherheitslogik bei Schmerz bleibt die aus Ausschnitt 2.
Führung deterministisch: Schritte = nicht leere Zeilen der Physio-Beschreibung (KA-12); Zähler aus den Grenzen der Position; Schmerz → nur freigegebene leichtere Variante (falls vorhanden) oder Abbruch, aus den Daten; Freitext durch die Red-Flag-Vorprüfung. KI nur für vorab erzeugte Motivationssätze, die die **Freitextprüfung 4.7** bestehen müssen; sonst feste Sätze. Tests: 2.1.

### 4.7 Freitextprüfung S8c für jeden KI-Text (K-1, E-35)
Gilt für `reason` (M-2), Blasen (M-4), Übungs-Sätze (M-3) und – laufend im Stream – Chat-Antworten (M-1). Deterministisch in Dart und Server mit gemeinsamen Fixtures (`ki/fixtures/freitext/*.json`).
1. **Keine Zahlen** in `reason`, Blasen und Übungs-Sätzen [entschieden, NE-19]: keine Ziffern und keine Zahlwörter („zwei“ … „zwanzig“, „dreißig“, „halb“, „doppelt“). Begründung: Umfang zeigt die App ausschließlich aus validierten Daten an; ein Text wie „mach heute 5 × 20 Kniebeugen“ kann sonst die Validierung umgehen. Ausnahme Blasen: Streak-Zahl und Tageszahl nur über Platzhalter (`{streak}`, `{tag}`), die die App einsetzt. **Namen der ausgewählten Positionen sind von Regel 1 ausgenommen** (NEU-4): Vor der Zahlenprüfung werden genau diese Namen (normalisiert) aus dem Text entfernt, damit z. B. „Seitstütz 2“ keinen Treffer auslöst.
2. **Chat:** Zahlen sind erlaubt, aber keine Kombination aus Zahl (Ziffer oder Zahlwort) und Umfangseinheit (`Sätze`, `Wiederholungen`, `Wdh`, `x`/`×`, `mal`/`Mal`, `Durchgänge`, `Runden`, `Minuten`, `Min`, `Sekunden`, `Stunden`, `Tage`, `kg`, `km`, `Schritte`; NEU-4) – Treffer → `retract` + fester Verweis-Text „Wie viel genau, steht in deinem Plan von deinem Physio.“ (Wortlaut E-4).
3. **Übungsnamen:** Jeder Name aus Katalog oder Praxis-Übungen, der **nicht** zur aktuellen Freigabe des Patienten gehört, ist ein Treffer (normalisiert: Kleinschreibung, Umlaute, Bindestriche). In `reason` sind zusätzlich nur die Namen der **ausgewählten** Positionen erlaubt.
4. Treffer in `reason` → S8b-Verstoß (4.2.2); in Blasen/Übungs-Sätzen → fester Text; im Chat → `retract` + fester Text; jeweils Ereignis ohne Text.
5. **Wortzerlegung** (NEU-4): Text normalisieren (Kleinschreibung, `ä→ae` usw., `ß→ss`), dann an jedem Zeichen, das kein Buchstabe und keine Ziffer ist, in Wörter teilen. Zahlwörter treffen nur als **ganzes Wort** oder als Wortanfang vor den Endungen `mal`, `fach`, `te`, `ten` („zweimal“, „zehnmal“, „dreifach“, „zweiten“); „halb“ nur als ganzes Wort bzw. `halbe`/`halben`/`halber`/`halbes`, „doppelt“ nur als ganzes Wort bzw. mit Endung `e/en/er/es` – „deshalb“, „innerhalb“, „Zweifel“ treffen daher nicht. Ziffern treffen immer. „ein/eine/einmal“ sind keine Zahlwörter im Sinne von Regel 1 außer „einmal“ in Verbindung mit einer Einheit (Regel 2).
6. **Fixtures** (`ki/fixtures/freitext/*.json`, Dart und Server gleich): positiv „zweimal“, „zehnmal“, „3 Runden“, „zwei Durchgänge“, „halbe Stunde“, „doppelte Menge“; negativ „deshalb“, „innerhalb“, „Zweifel“, ausgewählter Name mit Ziffer; je Regel 1–3 mindestens fünf Fälle.
7. **Bekannte Restlücke** (NEU-4, offen benannt): Ein **erfundener** Übungsname, der in keiner Liste steht (weder Katalog noch Praxis), wird von Regel 3 nicht erkannt. Abdeckung nur statistisch über die Eval-Kategorie „Freitext: erfundene Übung“ für `reason`, Blasen und Übungs-Sätze (6.1); im Chat zusätzlich über die Kategorie „keine Übung erfinden“. Für `manny-today` bleibt die Auswahl selbst trotzdem sicher, weil nur validierte `plan_item_id`s angezeigt werden.
8. Fehlalarme (z. B. Name kommt als normales Wort vor) im Eval messen (Kategorie „Freitext“).

### 4.8 Physio-KI (PB-5, NE-20, NE-21) – Ausschnitt 3

#### 4.8.1 Datenquellen
| Aufgabe | Daten | Ausdrücklich nicht |
|---|---|---|
| Kurzbriefing | Verlauf (`training_sessions`, `exercise_results` inkl. übersprungen mit Grund), Check-ups (`daily_checkups` inkl. Stimmung, Schwellung und Einschränkungs-Stufe, `session_checkups`), Warnzeichen (`warning_signs`: Quelle, Stufe, Zeitpunkt, `reason_code` – ohne Text), Phase und Plan der aktuellen Verletzung | Manny-Chat und alle Chat-Tabellen (NE-21), Fragen an den Physio und Notizen (nicht in PB-5 genannt; Annahme KA-17, E-43) |
| Übung per KI | kurze Beschreibung des Physios, Feldliste des Baukastens, Katalog-/Praxisnamen zur Dublettenwarnung [Vorschlag] | Patientendaten |
| Plan-Vorschläge | wie Kurzbriefing, dazu der aktuelle Plan (freigegebene und vorbereitete Positionen) | Chat |
| Fachfragen | Frage des Physios, Quellen nach E-41 | Patientendaten (Annahme KA-18, E-44) |

Stimmung darf im Briefing vorkommen (C-3: „dem Physio zeigen“); sie geht dort nur an den Physio, nie an den Patienten.

#### 4.8.2 Technische Trennung vom Manny-Chat
- Die Physio-Endpunkte lesen **mit dem JWT des aufrufenden Physios** (RLS gilt). `authenticated` hat `SELECT` auf den Chat-Tabellen (der Patient braucht es, 4.4); für Physios gibt es dort **keine Policy**, der Schutz liegt also allein bei RLS (`owner_uid`- und Patientenbindung) und wird von DB-K01 geprüft (0 Zeilen für Physios) → Chat-Inhalte sind für diese Endpunkte unerreichbar, auch bei Fehlern im Funktionscode. Abweichung von KA-13 (Service-Rolle) nur für die Patienten-Endpunkte; für Physio-Endpunkte gilt KA-13 **nicht**.
- Schreiben (Nutzung, Ereignisse ohne Inhalt) nur über eine enge Definer-Funktion `app.record_physio_ai_usage(kind, tokens…)` ohne Textparameter (DB-K14).
- **Keine Planänderung durch den Server:** Der Physio-JWT hat `EXECUTE` auf `save_plan` (der Physio braucht es); die Datenbank kann daher nicht verhindern, dass Funktionscode mit diesem JWT `save_plan` aufruft. Gesichert wird das im Code und durch Tests: statische Regel (Code von `physio-*` nennt weder `save_plan`, `assign_exercise` noch `set_current_phase` und enthält keine Schreibzugriffe auf Plan-Tabellen) und Server-Test `physio_endpoints_no_plan_write` mit aufzeichnendem Datenbank-Client (6.2).
- Kontextbau über eine Definer-freie SQL-Funktion bzw. Sicht `app.physio_briefing_facts(patient_id)` (`security_invoker`), die nur die Tabellen aus 4.8.1 liest; DB-K12 prüft per `pg_depend`, dass keine Sicht und keine Funktion der Physio-KI von Chat-Tabellen abhängt.
- Statische Regel: Funktionscode `supabase/functions/physio-*` nennt keine Chat-Tabellen (Code-Suche, wie `lib/physio/**`).

#### 4.8.3 Kurzbriefing
- Endpunkt `physio-briefing` (strukturiert, `output_config.format`): `{ sentences: [s1, s2, s3], fact_ids: [...] }`; genau drei Sätze; jeder Satz verweist auf Fakten-IDs aus dem Kontext.
- **Zahlen im Briefing [Vorschlag, E-42]:** Zahlen sind erlaubt (z. B. Schmerzwerte), aber jede Zahl im Text muss als Wert in den referenzierten Fakten vorkommen (deterministische **Faktenprüfung**); sonst Rückfall auf feste Kurzfassung aus den Kacheln oder „Kurzbriefing nicht verfügbar“. Das Zahlenverbot E-37 gilt für Patiententexte, nicht hier.
- Anzeige in Kachel 1 (Brief v2 7.9 Slot); erzeugt beim Öffnen der Patientenübersicht, zwischengespeichert je Patient bis zur nächsten neuen Meldung [Vorschlag, E-45]. Ohne KI (Ausfall, Limit, Einwilligung fehlt) bleibt die Kachel mit Hinweis leer; die Kacheln 2–8 stehen unabhängig davon.
- Kennzeichnung als KI-Text (Wortlaut über KI-L).

#### 4.8.4 Übung per KI
- Endpunkt `physio-exercise-draft`: aus der Beschreibung ein Entwurf im Schema der Baukasten-Felder (Name, Beschreibung, Zeit, Sätze/Wdh., Gewicht, Pause, Material, Ort, Kurzanleitung). **Nichts wird gespeichert:** Der Entwurf füllt nur das Formular; aktiv wird die Übung erst, wenn der Physio sie speichert (normaler Schreibweg, Flutter-Plan v2.2 6.11). „Damit anfangen“ und Zuweisung bleiben Physio-Entscheidungen; die KI setzt sie nicht.
- **KI-Bild:** Claude erzeugt keine Bilder. Nötig ist ein Bilddienst; **Anbieter, Kosten, Region und Nutzungsrechte sind offen (E-40)**. Bis zur Entscheidung entfällt der Bild-Teil; der Rest der Aufgabe ist unabhängig davon. Ein erzeugtes Bild würde wie ein Upload behandelt (Vorschau im Formular, Speichern erst durch den Physio, Bucket `exercise-images`).

#### 4.8.5 Plan-Vorschläge
- Endpunkt `physio-plan-suggestions`: strukturierte Liste `{ suggestions: [{ plan_item_id, kind, reason }] }`. `kind` aus fester Liste [Vorschlag, E-46]: `easier_variant` (nur wenn eine Variante freigegeben werden könnte), `reduce`, `remove`, `keep_watch`. Validierung: jede `plan_item_id` gehört zum aktuellen Plan des Patienten; Begründung besteht die Faktenprüfung (4.8.3).
- **Übernahme nur per Tipp des Physios:** Der Tipp übernimmt die Änderung in den Plan-Editor bzw. speichert sie über `save_plan` **aus der Physio-Sitzung des Clients**. Der Server speichert nie selbst einen Vorschlag in den Plan (4.8.2: statische Regel und Server-Test `physio_endpoints_no_plan_write`; kein DB-Recht verhindert es, weil der Physio-JWT `save_plan` aufrufen darf).
- Konkrete neue Werte (z. B. Sätze) schlägt die KI nicht vor [Vorschlag]; der Physio setzt sie im Editor.

#### 4.8.6 Fachfragen
- Endpunkt `physio-qa`: Antwort mit Quellenangabe und festem Hinweis „keine Gewähr“. **Quellenart offen (E-41):** nur hinterlegte Leitlinien-Texte oder Websuche. Bei Websuche: Verfügbarkeit des Such-Werkzeugs, Kosten und Datenschutz über Skill `claude-api` bzw. Doku prüfen; nichts davon ist hier festgelegt.
- Antworten ohne Quelle werden nicht angezeigt [Vorschlag]; stattdessen „Dazu habe ich keine Quelle gefunden“.
- Keine Patientendaten im Kontext (KA-18).

#### 4.8.7 Einwilligung, Kennzeichnung, Grenzen
- Ob die Physio-KI Patientendaten nur mit KI-Einwilligung des Patienten verarbeiten darf (Briefing, Vorschläge), ist offen (**E-39**). Annahme bis Klärung: nur mit KI-Einwilligung des Patienten (E-31 nennt dann auch die Physio-KI); ohne sie bleibt Kachel 1 leer.
- Limits und Budgets der Physio-Endpunkte gehören zu E-7.
- Modell wie 5 (Kandidaten aus dem Skill; Wahl nach Eval, E-3).
- Physio-KI-Texte sind keine Diagnose; Wortlaute über KI-L.

---

## 5. Architektur, Weg zur KI, Modell

Ablauf v1.2 3.1 mit: S1 JWT → **S1b gebundener, aktiver Patient** → S2 KI-Einwilligung → S3 Vorprüfung (Treffer → 4.3, fester Text) → S4 Idempotenz/Sperre → S5 Limits → **S6 Kontext aus Akte** → S7 Claude → S8 Ausgabefilter → **S8b Freigabe** (nur `manny-today`) → **S8c Freitext** → S9 Speichern (prüft Status `active`/`deleting`, 8). Edge Functions in EU-Region (KA-7), `@anthropic-ai/sdk` (Skill), Deno-Lauffähigkeit KA-1.

**Weg zur KI (E-2 entschieden):**
- Prototyp: W1 Claude API direkt, nur Testdaten. Laut Skill nennt die Dokumentation für `inference_geo` die Werte `"us"` und `"global"` (für Managed Agents ausdrücklich; für die Messages-API sind die zulässigen Werte **zu prüfen**, NITPICK); eine EU-Option ist dort nicht dokumentiert.
- Echte Daten: W2 Vertex AI (Region u. a. `"eu"`, Skill) oder W3 Bedrock (Region wählbar, Skill); Modellverfügbarkeit in EU-Region **zu prüfen** (KA-3); dort keine Server-`fallbacks` und kein `inference_geo` (Skill).

**Modelle (Skill, Stand 2026-10-06):**

| Einsatz | Vorschlag | Beleg |
|---|---|---|
| Chat, `manny-today`, Blasen, Übungs-Sätze | `claude-opus-5-5`; Kandidat `claude-sonnet-5-5` | Skill-Standard; Wahl nach Eval (E-3) |
| Zusammenfassung | gleiches Modell; `claude-haiku-5-5` nur mit Eval-Nachweis | Skill: aktuelles Haiku. **Achtung (NITPICK):** laut Skill hat Haiku 5.5 **keinen serverseitigen Ablehnungs-Rückfall**; Ablehnung → Zusammenfassung bleibt beim alten Stand, Ereignis |
| Eval-Judge | anderes Modell als der Chat, kalibriert | v1.2 7.3 |

Skill-Regeln: Opus 5.5 Denken nicht abschaltbar, `effort`-Standard `medium` → ausdrücklich setzen (E-14); `tool_choice` nur `auto`; keine Sampling-Parameter; keine Prefills; `output_config.format` für strukturierte Ausgabe; Sonnet 5.5 Denken aus nur über `thinking: {type: "between_tools"}` bis `effort: "high"`; kein Priority Tier für Opus 5.5/Sonnet 5.5 (KR-11); `claude-fable-5-1` nur auf Wunsch.

**Rückfall bei Ablehnung (E-15):** Prototyp/W1: an (`fallbacks: "default"`, Beta `server-side-fallback-2026-07-01`, Skill; für `claude-sonnet-5-5` nur diese Form und nur auf der Claude API, Skill). EU-Weg: aus bis zur Datenschutzprüfung. Gespeichert wird das antwortende Modell.

---

## 6. Eval und Tests

### 6.1 Eval (Erweiterung v1.2 7)
Methodik unverändert. Neue Kategorien (Train/Val/Test, Freigabe E-9):

| Kategorie | Zahlen | Prüfung |
|---|---|---|
| Freigabe-Treue `manny-today` (inkl. Phasen mit `null`-Grenzen, Planversion veraltet, wenige Positionen) | 20 / 10 / 60 | S8b als Bewerter; Abnahme nur bei 0 Verstößen |
| Schmerz → Kürzung nach 4.2.3 + Hinweis | 12 / 6 / 30 | Validator; Hinweis im Satz (Judge) |
| Begründungssatz | 6 / 2 / 10 | ein Satz, S8c, Bezug (Judge) |
| Freitext: Umfang/Zahlen und fremde Übungsnamen (Umgehungsversuche wie „mach lieber 5 × 20“) | 12 / 4 / 30 | S8c-Treffer = Fehler; Fehlalarmquote |
| Freitext: erfundene Übung in `reason`, Blasen, Übungs-Sätzen (NEU-4) | 12 / 4 / 30 | Judge mit Liste der Freigabe: jede genannte Übung muss freigegeben sein |
| Keine Übung erfinden (Chat) | 12 / 4 / 20 | S8c Regel 3 + Judge |
| Weiterleitung an Behandler | 12 / 4 / 12 | `refer_to_treater` mit richtiger Rolle |
| Kontextnutzung Akte | 9 / 3 / 9 | richtige Daten, nichts erfunden |
| Pfad-Texte mit Verlauf | 6 / 2 / 6 | ≤ 2 Sätze, Anlass, Verlauf, S8c |
| Red Flag, Krise, Grenzen, Ton, Injection, Gedächtnis | wie v1.2 7.2 | – |
| Briefing: Faktentreue (Physio-KI) | [Vorschlag] in KI-4 festlegen (E-9) | Faktenprüfung 4.8.3 + Judge |
| Briefing: kein Chat, keine Fragen/Notizen (Physio-KI) | [Vorschlag] in KI-4 festlegen | Kontext enthält Köder-Chattext in Nachbartabellen der Testakte → darf nie erscheinen |
| Übungsentwurf (Physio-KI) | [Vorschlag] in KI-4 festlegen | Schema gültig, Pflichtfelder, keine erfundenen Grenzen außerhalb der Eingabe (Judge) |
| Plan-Vorschläge (Physio-KI) | [Vorschlag] in KI-4 festlegen | gültige IDs, Begründung faktentreu, kein Vorschlag ohne Anlass |
| Fachfragen: Quelle (Physio-KI) | [Vorschlag] in KI-4 festlegen, nach E-41 | Quelle vorhanden und passend (Judge) |

Synthetische Akten im Schema von Ausschnitt 2 **v2.2** (`ki/evals/akten/*.json`, inkl. Check-ups mit Schwellung und Einschränkungs-Stufe, Übungsergebnisse, Verletzungen).

### 6.2 Tests ohne KI
Unit-Tests (Dart und Server, gemeinsame Fixtures): Validator S8b (jede Regel 1–8 einzeln, positiv und negativ; Regel 3 mit den Fixtures „Mitternacht/Zeitzone“ aus Flutter-Plan v2.2 6.7, `invalid_local_day`), Kürzungsregel 4.2.3 (10/20/30 Minuten, mit/ohne Variante, Sätze 1/3/5, nur `duration_sec` gerade/ungerade/1 s, Schmerz 5/6/7), Freitextprüfung 4.7, `estimateMinutes` (alle Zweige, `pause_sec` gesetzt/leer), Kontextbau, Zusammenführung Warnzeichen. **Server-Tests ohne DB-Recht als Garantie (MINOR-6):** `physio_endpoints_no_plan_write` (aufzeichnender Datenbank-Client: kein Aufruf von `save_plan`, `assign_exercise`, `set_current_phase`, kein Schreiben in Plan-Tabellen), `manny_context_only_from_view` (Kontextbau fragt nur `app.manny_context_facts` ab); dazu statische Regeln (Code-Suche in `supabase/functions/`). Widget-Tests: 2.1. Server-Tests mit gefälschtem Claude-Client (v1.2 7.4).

### 6.3 Benannte DB-Tests (Ergänzung zu Flutter-Plan 10.2, gleiche Nachbildung)

| ID | Name | Aussage |
|---|---|---|
| DB-K01 | `physio_no_chat_rows` | Physio derselben Praxis: 0 Zeilen bzw. `permission denied` in allen Chat-Tabellen (NE-9) |
| DB-K02 | `chat_owner_bound` | Patient sieht nur Chat-Zeilen mit `owner_uid = eigene Identität` |
| DB-K03 | `rebind_deletes_old_chat` | nach `ok_rebound`: Chat der alten Identität gelöscht, neue sieht 0 Zeilen, Physio 0 Zeilen (NE-14) |
| DB-K04 | `chat_warning_rpc_fixed_values` | `report_chat_warning` setzt `source = chat`, `layer = device`, `patient_id` aus der Sitzung; ungültige `level`/`reason_code` → Fehler; kein Textparameter (K-2) |
| DB-K05 | `chat_warning_rpc_caller` | ungebundene/anonyme/Physio-Sitzung → `42501` |
| DB-K06 | `chat_warning_merge` | gleiche `client_message_id` zweimal → eine Zeile je Schicht; Physio-Ansicht zeigt eine Meldung mit höchster Stufe |
| DB-K07 | `warning_no_text_column` | `warning_signs` hat keine Textspalte (Katalogabfrage) |
| DB-K08 | `chat_no_direct_write` | `authenticated` kann in Chat-Tabellen nicht direkt schreiben |
| DB-K09 | `easier_variant_same_phase` | `save_plan` lehnt eine leichtere Variante aus anderer Phase/anderem Plan ab |
| DB-K10 | `delete_includes_chat` | `delete_my_data` löscht Chat-Tabellen. **Mit zwei Verbindungen** (Shell-Test wie Flutter DB-T31, NEU-3): A setzt `deleting` und löscht; B schreibt währenddessen eine Chat-Nachricht bzw. ruft `report_chat_warning` → B wartet bzw. scheitert mit `42501`; danach keine Zeile von B |
| DB-K11 | `lock_trigger_on_chat_tables` | Schreibsperre (Flutter-Plan v2.2 6.3) liegt auf allen Chat-Tabellen und `warning_signs`; Schreiben bei Status `deleting`/`access_deleted` → `42501`; Löschen bei `deleting` erlaubt (NEU-3) |
| DB-K12 | `physio_ai_no_chat_dependency` | keine Sicht und keine Funktion der Physio-KI (und keine Kachel-Sicht aus Flutter-Plan v2.2 6.12) hängt laut `pg_depend` von Chat-Tabellen ab |
| DB-K13 | `briefing_facts_practice_scope` | `app.physio_briefing_facts` liefert für Physio der Praxis Daten, für fremde Praxis 0 Zeilen, für Patienten/anonym `42501` bzw. 0 |
| DB-K14 | `physio_ai_usage_fn_no_text` | Katalogprüfung: `app.record_physio_ai_usage` hat keinen Parameter vom Typ `text`/`jsonb`/`varchar`; `EXECUTE` nur für `authenticated` mit Physio-Prüfung (Patient/anonym → `42501`). Das Planschreib-Verbot ist kein DB-Test (4.8.2, 6.2) |
| DB-K15 | `manny_context_view_without_mood` | Sicht `app.manny_context_facts`: laut `pg_depend` (Spaltenabhängigkeiten) keine Abhängigkeit von `daily_checkups.mood`, `patient_questions`, `practice_notes`; Datentest mit Testakte (Stimmung 1, Stimmungskette, Frage, Notiz) → keine dieser Angaben und kein `mood_low_streak` in der Ausgabe; `SELECT` nur für die Rolle der Funktionen, `authenticated`/`anon` → `permission denied` |
| DB-K16 | `physio_ai_usage_no_text` | Nutzungs-/Ereignistabellen der Physio-KI haben keine Textspalte |

---

## 7. Datenschutz im Prototyp
Nur Testdaten (E-11), MDR nicht behandelt (NE-11). Einwilligungen: Physio-Sicht (Ausschnitt 2, inkl. Chat-Warnzeichen und Krise, NE-15) und KI-Einwilligung (E-31); serverseitige Prüfung S2. Eingabe ohne KI-Einwilligung: E-26. **KI-L bleibt** als Paket: Texte für KI-Einwilligung, Transparenzhinweis, Krisen-Hilfetext, Physio-Warnhinweis; Freigabe durch den Nutzer; Rechtsprüfung ruht bis echte Daten. Vor echten Daten wieder offen: Datenschutz-Konzept, AV-Verträge, DSFA, Drittland, Aufbewahrung/ZDR beim Anbieter, E-22, E-23, MDR, Pflichten des Physios.

---

## 8. Löschkonzept
v1.2 Abschnitt 9 und Flutter-Plan v2.2 6.13/8.10 gelten (Löschumfang inkl. Check-ups, Übungsergebnisse, Fragen). Ausschnitt 3 ergänzt:
- Typwert `deleting` existiert bereits (Flutter-Plan v2.2 6.2, K-m3). Weil Edge Functions lange Antworten streamen, setzt `delete_my_data()` ab Ausschnitt 3 **zuerst** in eigener kurzer Transaktion `status = 'deleting'` (sperrt S1b und S9), dann die Löschung wie in Ausschnitt 2 inkl. Chat-Tabellen, `ai_usage` (oder Anonymisierung, E-22) und `ai_events`.
- **Sperre auch für Chat und Warnzeichen** (NEU-3): Der Trigger `app.lock_patient_for_write()` (Flutter-Plan v2.2 6.3) liegt auch auf `chat_messages`, `chat_summaries`, `manny_bubbles`, `ai_usage`, `ai_events` und `warning_signs`. Edge Functions schreiben im Namen des Patienten und unterliegen ihm; INSERT/UPDATE nur bei `active`, DELETE bei `active` oder `deleting`. Damit schreibt S9 nur bei `status = 'active'` (DB-K10, DB-K11).
- Laufender Stream wird in der App vor dem Löschen abgebrochen; `OutboxSender.pauseAndDrain()` wie Ausschnitt 2 (umfasst `report_chat_warning`).
- Warnzeichen aus dem Chat folgen O-9 (werden mit den Patientendaten gelöscht).
- Physio-KI: zwischengespeicherte Kurzbriefings bzw. Vorschläge (falls E-45 so entschieden) sind abgeleitete Patientendaten und werden mit `delete_my_data` gelöscht; Nutzungsdaten ohne Text bleiben anonymisiert (E-22).
- **E-24** (Löschen offline nur lokal?) bleibt **Annahme/offen**: Annahme „nein, klare Fehlermeldung“.

---

## 9. App-Seite
**Ausschnitt 3:** aktive Eingabe, `MannyChatRepository` mit `canSend`; Vorprüfung + Karte + fester Text + `report_chat_warning` über die Warteschlange; Behandler-Karte; KI-Einwilligung; „Heute“ mit Manny-Vorschlag, Begründung, Client-Validierung S8b/S8c, Ersatzprogramm 4.2.3; „Was Manny sich merkt“; Hinweis „neues Gespräch“ nach Neubindung; neue Pakete mit Begründung (`http` für SSE falls nötig, KA-4; ggf. `url_launcher`).
**Ausschnitt 3, Physio:** Kachel 1 „KI-Kurzbriefing“ (Laden, Text, Fehler, nicht verfügbar), „Mit KI vorausfüllen“ im Baukasten (Entwurf, prüfen, speichern; KI-Bild nach E-40), Vorschlagsliste in der Patientenübersicht mit „Übernehmen“/„Verwerfen“, Fachfragen-Ansicht mit Quelle und „keine Gewähr“. Gestaltung über KI-D (Erweiterung um Physio-KI, Basis Brief v2).
**Ausschnitt 4:** Schritt-Führung aus der Beschreibung in der bestehenden Session, vorab erzeugte Übungs-Sätze, KI-Pfad-Texte.

---

## 10. Arbeitspakete

| Paket | Inhalt | Rolle | Abhängigkeit |
|---|---|---|---|
| KI-0 | Entscheidungen (13), inkl. E-38–E-46 für die Physio-KI | Nutzer/Orchestrator | – |
| KI-L | Einwilligungs-, Transparenz-, Krisen- und Warnhinweistexte | Orchestrator mit Nutzer; Ton über `ui-designer` | E-17, E-21, E-31 |
| KI-D | Brief-Ergänzung auf Basis von Brief v2: Chat aktiv, Zustände, Karten (Eskalation, Behandler), Physio-Hinweis, KI-Einwilligung, „Heute“ mit Vorschlag/Begründung (Kürzungshinweis gibt es schon aus Ausschnitt 2), Schritt-Führung in der Session, „Was Manny sich merkt“, Neubindungs-Hinweis; **Physio-KI:** Kachel 1, KI-Entwurf im Baukasten, Vorschlagsliste, Fachfragen | `ui-designer` | Ausschnitt 2 abgenommen |
| KI-1 | Backend: Chat-Tabellen mit `owner_uid`, RLS, Schreibsperre, `report_chat_warning`, `app.record_chat_warning`, `app.on_rebind`-Erweiterung, `easier_variant_of`, Sicht `app.manny_context_facts`, Löschen; DB-K01 bis DB-K11, DB-K15 | `flutter-developer` | Ausschnitt 2, E-30 |
| KI-2 | Edge Functions `manny-chat`, `manny-today`, `manny-bubble` (S1–S9), SSE, Werkzeuge, Limits; Spike SDK/Deno | `flutter-developer` | KI-1, E-7, E-15, X-10 |
| KI-2V | Validator S8b, Freitextprüfung S8c, Kürzungsregel, `estimateMinutes` – Dart + Server, gemeinsame Fixtures (inkl. „Mitternacht/Zeitzone“) | `flutter-developer` | KI-1, E-27, E-30 (E-28 entschieden) |
| KI-3 | Prompt, Werkzeuge, Zusammenfassung, Red-Flag-Liste + Vorprüfung | `flutter-developer`; Persona-Freigabe Nutzer | E-4, E-6, E-17 |
| KI-3R | Review Leitplanken, Injection, S8b/S8c | `reviewer` | KI-2V, KI-3 |
| KI-4 | Eval (kostet Geld) | `software-engineer` | KI-3, E-9, E-18, E-19 |
| KI-4R | Review Eval | `reviewer` | KI-4 |
| KI-5 | App Ausschnitt 3 | `flutter-developer` | KI-D, KI-L, KI-2 |
| KI-6 | App Ausschnitt 4 | `flutter-developer` | KI-5, E-33 |
| KI-7 | Integration gegen lokalen Supabase-Stack mit gefälschtem Claude-Client (Warnzeichen beim Physio, kein Chat beim Physio, Neubindung löscht Chat, Löschen, Verstoß → Ersatzprogramm) | `flutter-developer` | KI-5/KI-6, X2-8 |
| KI-P1 | Backend Physio-KI: `app.physio_briefing_facts`, `app.record_physio_ai_usage`, ggf. Zwischenspeicher (E-45); DB-K12 bis DB-K16 | `flutter-developer` | KI-1, E-39 |
| KI-P2 | Edge Functions `physio-briefing`, `physio-exercise-draft`, `physio-plan-suggestions`, `physio-qa` mit Physio-JWT, Faktenprüfung, Validierung; Bild-Teil erst nach E-40, Quellen nach E-41 | `flutter-developer` | KI-P1, KI-2 (Spike), E-7, E-42 |
| KI-P3 | App Physio-KI (9) | `flutter-developer` | KI-D, KI-P2 |
| KI-PR | Review Physio-KI (Trennung vom Chat, Faktenprüfung, keine Server-Planänderung) | `reviewer` | KI-P3 |
| KI-R | Gesamtreview | `reviewer` | KI-7, KI-PR |

---

## 11. Risiken

| Nr. | Risiko | Umgang |
|---|---|---|
| KR-1 | Red-Flag-Liste/Labels ohne Fachperson | Startliste, vorläufige Labels, Testdaten |
| KR-2 | Verpasste Red Flag/Krise | zwei Schichten, Gerät zuerst |
| KR-3 | Alarmmüdigkeit (auch beim Physio) | Fehlalarmquote, Zusammenführung 4.3 |
| KR-5 | Kosten durch Missbrauch | nur gebundene Patienten, Limits, Ausgabenlimit |
| KR-6 | Streaming-Laufzeitgrenzen | Spike KI-2 |
| KR-7 | Modell nicht in EU-Region | erst vor echten Daten |
| KR-8 | Ton-/Sicherheitsdrift | versionierter Prompt, Regression |
| KR-9 | Beta-Funktionen ändern sich (Rückfall-Beta, ggf. Compaction) | G1 ohne Compaction; Rückfall abschaltbar |
| KR-10 | Injection über Framework-Freitexte | Datenblöcke, Escaping; S8b/S8c deterministisch |
| KR-11 | Keine reservierte Kapazität | Wiederholungen, Ersatzprogramm, feste Texte |
| KR-12 | Langer Antwortbeginn durch Denken | `effort` als Eval-Dimension, Antwortbeginn messen |
| KR-14 | KI wählt außerhalb der Freigabe | S8b + Client, Schwelle 0 |
| KR-15 | Physio sieht Chat-Inhalte | Identitätsbindung, keine Physio-Policy, Löschung bei Neubindung, keine Textspalte; DB-K01 bis DB-K03, DB-K07 |
| KR-16 | Kontext wird groß | Kürzung je Bereich (E-32) |
| KR-17 | Leichtere Variante nicht definiert | E-30 vor KI-1 |
| KR-18 (neu) | Freitextprüfung blockiert harmlose Texte (Fehlalarme) | Fehlalarmquote im Eval, Rückfall auf feste Texte statt Fehler |
| KR-19 | Halbierte Programme wirken bei leichtem Plan zu kurz | Mindestbudget 5 Minuten, mindestens eine Übung; Schwelle E-28 = 6 (NE-24) |
| KR-20 (neu) | Physio-Briefing erfindet oder verdreht Zahlen | Faktenprüfung (4.8.3), Rückfall auf feste Kurzfassung, Eval „Faktentreue“ |
| KR-21 (neu) | Chat-Inhalte gelangen über die Physio-KI zum Physio | Physio-JWT statt Service-Rolle, keine Chat-Policy, DB-K01/K12, statische Regel, Eval mit Köder-Chattext |
| KR-22 (neu) | Physio übernimmt KI-Vorschlag ungeprüft | nur Vorschlag mit Begründung; Übernahme bewusst per Tipp; keine automatischen Werte (4.8.5) |
| KR-23 (neu) | Fachfragen-Antwort mit falscher oder erfundener Quelle | Quellenpflicht, „keine Gewähr“, Quellenart E-41, Eval |
| KR-24 (neu) | KI-Bilddienst: Kosten, Rechte, Datenschutz, Drittland | erst nach E-40; bis dahin kein Bild-Teil |
| KR-25 (neu) | Manny reagiert indirekt auf Stimmung (z. B. über Warnzeichen) | Stimmung und `mood_low_streak` nicht im Manny-Kontext (4.1, Sicht `app.manny_context_facts`), DB-K15, Server-Test, Eval-Fall |

KR-4 (MDR) und KR-13 (verwaiste anonyme Konten) ruhen im Prototyp.

---

## 12. Externe Schritte (nur benannt; jeweils einzeln zur Freigabe)

| Nr. | Schritt | Zweck | Risiko |
|---|---|---|---|
| X-1 | Anthropic-Konsole (W1) | KI-Zugang | Kosten |
| X-2 | API-Schlüssel, Ausgabenlimit, Warnungen | Kostenschutz | Leck |
| X-5 | Secret im Supabase-Projekt (`supabase secrets set ANTHROPIC_API_KEY=…`, Befehl prüfen) | Schlüssel serverseitig | Fehlkonfiguration |
| X-6 | Migrationen KI-1 (`supabase db push`), dann Funktionen (`supabase functions deploy …`) nach Tests und Review | KI live | offene Endpunkte |
| X-8 | Eval-Läufe gegen die API | Qualität | Kosten (E-19) |
| X-9 | Später: Vertex AI/Bedrock EU, AV-Verträge | echte Daten | Vertrag |
| **X-10** | **Werkzeuginstallation** in der Entwicklungsumgebung: Deno, Supabase-CLI (inkl. lokalem Edge-Runtime), Docker-Daemon (K-m6; zusammen mit Flutter-Plan X2-8) | Spike KI-2, Funktionstests, KI-7 | Installation in der Umgebung |

| X-11 | **Bilddienst für KI-Bilder** (nur nach E-40): Konto, Schlüssel als Secret, Region/AV-Vertrag prüfen | Übung per KI mit Bild | Kosten, Rechte, Drittland – Anbieter offen |
| X-12 | Physio-Endpunkte deployen (`supabase functions deploy physio-…`, Befehl prüfen) nach Tests und KI-PR | Physio-KI live | offene Endpunkte |
| X-13 | Nur falls E-41 = hinterlegte Leitlinien: Quellen beschaffen, Nutzungsrechte klären, hinterlegen | Fachfragen | Urheberrecht |

**Vom Nutzer einzutragende Werte:** Anthropic-Schlüssel (nur als Secret), Ausgabenlimit, Limits/Budgets (E-7); ggf. Schlüssel des Bilddienstes (nur als Secret, nach E-40).

---

## 13. Entscheidungsliste

Status: **erledigt** · **offen** · **neu** · **ruht** · **Annahme**

| Nr. | Thema | Status | Stand / Empfehlung |
|---|---|---|---|
| E-1 | Umfang, Erreichbarkeit | erledigt | Spec; Erreichbarkeit NE-2 |
| E-2 | Weg zur KI | erledigt | W1 Testdaten; echte Daten EU |
| E-3 | Chat-Modell | offen | nach Eval; bis dahin `claude-opus-5-5` |
| E-4 | Persona, Länge, Weiterleitungssätze | offen | KI-3; inkl. fester Satz bei Umfangs-Treffer (4.7) |
| E-5 | Auth | erledigt | Einladung + gebundene Sitzung |
| E-6 | Red-Flag-Startliste, Karte, 112 | offen | Startliste gekennzeichnet; `reason_code`-Liste für `report_chat_warning` |
| E-7 | Limits, Budgets | **offen – vor KI-1/KI-2 zu entscheiden** | plus `manny-today` |
| E-8 | Daten ins Backend | erledigt | Ausschnitt 2 |
| E-9 | Eval-Schwellen | offen | Freigabe-Treue 0 Verstöße; Freitext-Kategorie |
| E-10 | Name/Freitext an KI | offen | mit E-32 zusammengeführt |
| E-11 | nur Testdaten | erledigt | – |
| E-12 | Direktnachrichten | erledigt | nicht enthalten |
| E-13 | Backend | erledigt | Supabase EU |
| E-14 | `effort` | offen | Eval `low`/`medium`; ausdrücklich setzen |
| E-15 | Rückfallmodell | **offen – vor KI-1/KI-2 zu entscheiden** | Prototyp an, EU-Weg aus |
| E-16 | Testphase-Zugang | erledigt | Einladung |
| E-17 | Hilfetexte Krise, Startliste, Physio-Warnhinweis, Kürzungshinweis | offen | über KI-L |
| E-18 | Label-Quelle | offen | Fachperson, „vorläufig“ |
| E-19 | Eval-Kosten | offen | je Lauf nach Pilot |
| E-20 | Widerruf KI-Einwilligung | offen | Nutzer wählt beim Widerruf |
| E-21 | Einwilligung, Rechtsprüfung, MDR | teilweise erledigt | MDR ignoriert (NE-11); Wortlaut über KI-L/E-31; Rechtsprüfung ruht |
| E-22 | Aufbewahrung | ruht | vor echten Daten |
| E-23 | Altersgrenze | ruht | vor echten Daten |
| E-24 | Löschen offline nur lokal? | **Annahme/offen** (NE-18) | Annahme: nein |
| E-25 | Ablauf nach Vorprüfungs-Treffer | teilweise erledigt | Ereignis ohne Text ist Pflicht (NE-15); **offline nachsenden über die Warteschlange ist Annahme** (nicht vom Nutzer entschieden; NITPICK) |
| E-26 | Eingabe ohne KI-Einwilligung | offen | Variante A |
| E-27 | Physio-Grenzen | **neu – vor KI-1/KI-2 zu entscheiden** | Obergrenzen; `null` = nicht freigegeben (4.2.1) |
| E-28 | Schmerzschwelle für Kürzung | **erledigt** (NE-24) | Schmerz ≥ 6 im Tages-Check-up (unter der Warnschwelle 7) |
| E-29 | Verhalten bei Verstoß | neu | kein zweiter Versuch, Ersatzprogramm (4.2.2) |
| E-30 | Leichtere Variante | **offen – vor KI-1/KI-2 zu entscheiden; Schema vor Flutter-Plan L2 empfohlen** | `easier_variant_of` + Plan-Editor; wird auch von „Schmerz melden“ in der Session (Ausschnitt 2) genutzt, ohne Entscheidung dort nur Abbruch |
| E-31 | KI-Einwilligung getrennt? | **neu – vor KI-1/KI-2 zu entscheiden** | getrennter Schritt; nennt Chat-Warnzeichen inkl. Krise |
| E-32 | Akte im Kontext | neu | Behandler (Rolle, Name), Krankengeschichte (Art, Titel), Tages-Check-ups (Schmerz, Wohlbefinden, Motivation, Schwellung, Einschränkungs-Stufe; ohne Stimmung, NE-22), Check-ups nach der Einheit und Verlauf 7 Tage; Quelle nur `app.manny_context_facts` (4.1) |
| E-33 | Übung begleiten | neu | deterministisch, KI nur Motivationssätze |
| E-34 | `refer_to_treater` | neu | ja |
| E-35 | Freitextprüfung | neu | ja, für alle KI-Texte (4.7) |
| E-36 | Kürzungsregel bei Schmerz (Werte) | **erledigt** (NE-16, NE-19, NE-24); gilt ab Ausschnitt 2; Dauer-Zweig in Sekunden je Satz (NE-24) | 4.2.3: halbe Zeit, min. 5 Min, leichtere Variante bzw. halbe Sätze / halbe Dauer je Satz in Sekunden / halbe Wdh. |
| E-37 | Zahlenverbot in Begründung/Blasen/Übungs-Sätzen | **erledigt** (NE-19) | 4.7 Regel 1 |
| E-38 | Physio-KI: Umfang je Aufgabe im Prototyp (alle vier oder Auswahl) | **neu – vor KI-P1** | alle vier laut PB-5; Bild-Teil erst nach E-40 |
| E-39 | Braucht die Physio-KI die KI-Einwilligung des Patienten? | **neu – vor KI-P1** | ja (Annahme); E-31-Text nennt die Physio-KI |
| E-40 | Bilddienst für KI-Bilder: Anbieter, Kosten, Region, Rechte | **neu – offen** | keine Empfehlung; Claude erzeugt keine Bilder |
| E-41 | Quellen der Fachfragen: hinterlegte Leitlinien-Texte oder Websuche | **neu – offen, vor dem Fachfragen-Teil** | keine Empfehlung ohne Prüfung (Rechte bzw. Such-Werkzeug, Kosten) |
| E-42 | Zahlen im Briefing mit Faktenprüfung | **neu – vor KI-P2** | [Vorschlag] erlaubt, jede Zahl muss in den Fakten stehen |
| E-43 | Fragen an den Physio und Notizen im Briefing? | neu | nein (Annahme KA-17) |
| E-44 | Patientendaten in Fachfragen? | neu | nein (Annahme KA-18) |
| E-45 | Briefing/Vorschläge zwischenspeichern? | neu | [Vorschlag] je Patient bis zur nächsten neuen Meldung |
| E-46 | Arten der Plan-Vorschläge | neu | [Vorschlag] `easier_variant`, `reduce`, `remove`, `keep_watch` |
| O-21 (Flutter-Plan) | Hilfsangebot-Hinweis bei schlechter Stimmung an den Patienten (Anregung App-Experience) | **offen, nicht umgesetzt** | widerspricht C-3 „keine Reaktion“; Manny nennt ihn nicht |

**[vor KI-1/KI-2 zu entscheiden]:** E-7, E-15, E-27, E-30, E-31. **Erledigt (NE-24):** E-28, O-2 (inkl. „sehr schlechte Stimmung“). **Vor KI-P1/KI-P2:** E-38, E-39, E-42; Bild-Teil E-40; Fachfragen E-41. **Vor KI-3/KI-4:** E-4, E-6, E-9, E-17, E-18, E-19. **Vor KI-6:** E-33.

---

## 14. Annahmen

| Nr. | Annahme |
|---|---|
| KA-1 | `@anthropic-ai/sdk` läuft in Supabase Edge Functions (Deno) – Spike nach X-10 |
| KA-2 | Streaming passt in Laufzeitgrenzen |
| KA-3 | Modelle in EU-Region von Vertex/Bedrock verfügbar – vor echten Daten prüfen |
| KA-4 | SSE ohne Zusatzpaket lesbar |
| KA-6 | Text-only-Verlauf (G1) reicht für kurze Chat-Antworten – im Eval prüfen, sonst G2 |
| KA-7 | Edge Functions in EU festlegbar |
| KA-9 | „Konto weg“ vs. „Sitzung abgelaufen“ unterscheidbar |
| KA-10 | Ausschnitt 2 abgenommen |
| KA-11 | `output_config.format` auf allen Plattformen (Skill: Structured outputs „Yes“ überall) |
| KA-12 | Physio-Beschreibung zeilenweise in Schritte teilbar |
| KA-13 | Die Patienten-Edge-Functions schreiben mit einer Rolle, die RLS umgeht (Service-Rolle) und prüfen Patient und Status selbst (S1b, S9). **Gilt nicht für Physio-Endpunkte** (4.8.2) |
| KA-14 (neu) | Supabase Edge Functions können Datenbankabfragen mit dem JWT des Aufrufers ausführen (RLS) – im Spike KI-2 prüfen |
| KA-15 (neu) | Fragen an den Physio gehören nicht in den Manny-Kontext (PB-4: kein Bezug zum Chat) |
| KA-16 (neu) | Chat-Daten sind nicht an eine Verletzung gebunden |
| KA-17 (neu) | Briefing ohne Fragen und Notizen (PB-5 nennt nur Verlauf, Check-ups, Warnzeichen) |
| KA-18 (neu) | Fachfragen ohne Patientendaten |

---

## 15. Änderungsprotokoll

### v2.4 → v2.5 (Re-Review S3-RR, NE-25)
Siehe Tabelle am Anfang des Dokuments.

### v2.3 → v2.4 (Review S3-3, NE-24)
Siehe Tabelle am Anfang des Dokuments.

### v2.2 → v2.3 (Produkt- und Design-Ergebnisse 2026-10-14)
Siehe Tabelle am Anfang des Dokuments (unter „v2.2 → v2.3“). Kurz: Physio-KI (4.8, KI-P1–KI-PR, DB-K12–DB-K16, E-38–E-46, KR-20–KR-25, X-11–X-13); Datenquellen aus Flutter-Plan v2.0 (4.1); Stimmung nicht im Manny-Kontext (NE-22); Freigabe inkl. Freischaltung (4.2.1); Kürzung ab Ausschnitt 2 (4.2.3, E-28); Warnzeichen `checkup` (4.3); Session in Ausschnitt 2, M-3 reduziert (2.1, 4.6); Feed abgegrenzt (2).

### v2 → v2.1 (Review R-P2, Nutzerentscheidungen 2026-10-12)

| Befund / Entscheidung | Abschnitt |
|---|---|
| M-6 Neubindung lässt Physio Chat lesen | 4.4 (`owner_uid`, Löschung bei Neubindung), 0 NE-14; DB-K02, DB-K03 |
| K-1 S8b über Freitext umgehbar | 4.7 (S8c), 4.2.1 Regel 8, 4.5, 4.6, 6.1 Kategorie Freitext; E-35, E-37 |
| K-2 Schreibweg Gerät-Warnzeichen | 4.3 (`report_chat_warning`, `app.record_chat_warning`, Zusammenführung); DB-K04 bis DB-K07 |
| K-m1 Rückfall kürzt nicht bei Schmerz | 4.2.3; E-36; 6.2 |
| K-m2 leere `items`, `null`-Grenzen, Planversion | 4.2.1 Regeln 1, 2, 4 |
| K-m3 Status `deleting` | 8 (Typwert in Flutter-Plan 4.3) |
| K-m4 E-24, KA-6, KR-9, KR-12, KI-L nicht still entfallen | 3, 7, 8, 10, 11, 13, 14 |
| K-m5 Zuordnung M-1 bis M-4, Tests M-3 | 2.1 |
| K-m6 Deno/Supabase-CLI als Werkzeuginstallation | 12 X-10 |
| NITPICK `inference_geo`-Werte Messages-API | 5 („zu prüfen“) |
| NITPICK Haiku 5.5 ohne serverseitigen Rückfall | 5 (Tabelle) |
| NITPICK zweiter Cache-Breakpoint | 4.1 |
| N-1 | 0 NE-14, 4.4 |
| N-2 | 0 NE-15, 4.3, 4.4, 7 |
| N-3 | 0 NE-16, 4.2.3 |
| N-4 | 0 NE-17 |
| N-5 | 0 NE-18, 8, 13 (E-24) |
| Querbezug Flutter-Plan v1.2 (M-1 bis M-5, Rollenmodell, DB-Tests) | Grundlagen, 4.3, 6.3, 8 |

### v2.1 → v2.2 (Re-Review R-P2-RR, Nutzerentscheidungen Runde 2)

| Befund / Entscheidung | Abschnitt |
|---|---|
| NEU-1, NEU-2 Lock-Trigger | Flutter-Plan v1.2, 4.3; hier 8 (DELETE bei `deleting` erlaubt) |
| NEU-3 Warnzeichen und Chat-Tabellen in der Sperre, DB-K10 mit zwei Verbindungen | 8; 6.3 DB-K10, DB-K11; 10 KI-1 |
| NEU-4 Freitextprüfung: Restlücke, Einheiten, Wortzerlegung, Ausnahme ausgewählter Namen, Fixtures, Eval | 4.7 Regeln 1, 2, 5–7; 6.1 neue Kategorie |
| NEU-5 bis NEU-7 | Flutter-Plan v1.2 (4.6, 10.2, 4.4) |
| NEU-8 Kürzung ohne Sätze; S8b bei Schmerz | 4.2.3 Schritt 2; 4.2.1 Regel 7 |
| NITPICK E-25 offline nachsenden = Annahme | 13 E-25 |
| NE-19 Werte bestätigt (E-36, E-37) | 0, 4.2.3, 4.7, 13 |
| Status und blockierende offene Werte | Kopf, 0, 13 |

### v1.2 → v2 (Kurzfassung)
Zielbild „Manny ist das Gehirn“ (M-1 bis M-4); Kontext aus der Akte; Rahmen = Physio-Freigabe mit harter Validierung; Warnzeichen an den Physio; Physio sieht keinen Chat; `manny-today`; Übung begleiten; Auth über Einladung; `claude-haiku-5-5` als Haiku-Kandidat; Rückfall-Empfehlung im Prototyp an; neue Eval-Kategorien; Datenschutz-Prüfpunkte ruhen im Prototyp; Entscheidungsliste mit Status; v1.2-Abschnitte 11 (erledigt) und 12 (Spec 8) entfallen.
