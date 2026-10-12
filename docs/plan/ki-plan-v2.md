# KI-Plan v2.1: Manny ist das Gehirn (CuraOne, Ausschnitte 3 und 4)

Status: **zur Freigabe (nach Review R-P2)** · v2.1 (v2 überarbeitet nach Review R-P2 und Nutzerentscheidungen vom 2026-10-12; v2 war Überarbeitung von `docs/plan/ki-plan-v1.md` v1.2) · Paket P2-K1 · Autor: `flutter-developer` · Stand 2026-10-12

Grundlagen:
- `docs/produkt/curaone-spezifikation-manny-gehirn.md` (FREIGEGEBEN 2026-10-11).
- `docs/plan/ki-plan-v1.md` v1.2: bleibt Referenz für alle verwiesenen Abschnitte („v1.2, n“).
- `docs/plan/flutter-plan-ausschnitt-2.md` v1.1 (Rollenmodell, Schema, Einladung und Neubindung, Warnzeichen, Warteschlange, Löschen, DB-Tests DB-T01 ff.). Ausschnitt 3 setzt Ausschnitt 2 voraus.
- Skill `claude-api` (Modelltabelle Stand 2026-10-06). API-Aussagen sind mit „(Skill)“ belegt oder als Annahme/„zu prüfen“ markiert; Modell-IDs nur aus Skill bzw. v1.2.

Kennzeichnung wie v1.2: **E-n**, **NE-n**, **KA-n**, **KR-n**, **X-n**; **DB-Kn** = benannter DB-Test dieses Plans (Abschnitt 6.3); **[Vorschlag]** = vom Plan festgelegter Wert mit Begründung. Rechtliche Punkte sind Prüfpunkte, keine Rechtsberatung.

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

---

## 1. Kurzfassung

| Thema | v2.1 |
|---|---|
| Zielbild | M-1 Chat mit Akte-Wissen · M-2 „Heute“ zusammenstellen · M-3 Übung begleiten · M-4 persönliche Pfad-Texte |
| Harte Grenze | Jede KI-Auswahl wird **deterministisch gegen die Freigabe validiert** (S8b, Server und App, gemeinsame Fixtures); zusätzlich prüft eine **Freitextprüfung** jeden KI-Text (Begründung, Blasen, Übungs-Sätze, Chat) auf Zahlen/Umfangsangaben und nicht freigegebene Übungen (K-1) |
| Ersatzprogramm | bei Verstoß, Ausfall oder Limit: deterministisches Programm aus Ausschnitt 2; bei hohem Schmerz nach fester Kürzungsregel (NE-16) |
| Warnzeichen | Gerät: RPC `report_chat_warning` mit festen Werten; Server/Modell: Funktion; Zusammenführung je `clientMessageId`; kein Text (NE-15) |
| Physio und Chat | Chat-Daten an die erzeugende Auth-Identität gebunden, keine Physio-Policy, Löschung bei Neubindung (NE-14) |
| Endpunkte | `manny-chat` (Stream), `manny-today` (strukturiert), `manny-bubble` (strukturiert, vorab) |
| Weg zur KI | W1 Claude API für den Prototyp (nur Testdaten); W2/W3 EU erst für echte Daten |
| Modell | `claude-opus-5-5`, Kandidat `claude-sonnet-5-5` (E-3) |
| Bleibt aus v1.2 | Leitplanken, Red-Flag-Zweistufigkeit inkl. 3.1a, Eval-Methodik, Löschkonzept, Streaming, Limits, Idempotenz, Ausgabefilter, Injection-Schutz, Gedächtnis G1, KI-L (Paket Einwilligungs- und Rechtstexte) |

---

## 2. Zielbild und Umfang

**Ausschnitt 3:** M-1 Chat (schreibbar, Framework-Wissen, Verweis an Behandler, Warnzeichen → fester Hinweis + Physio) und M-2 „Heute zusammenstellen“ (aktuelle Phase, Zeit, Befinden, ein Begründungssatz, bei Schmerz leichter/weniger).

**Ausschnitt 4:** M-3 Übung begleiten (Schritte, Zählen, bei Schmerz nur freigegebene leichtere Variante oder Abbruch) und M-4 Pfad-Texte (echter Verlauf, Rückfall auf feste Texte).

**Nicht enthalten** (Spec 8): Arzt-Zugang, Übungen außerhalb der Freigabe, Sprache, proaktive Nachrichten/Push, Direktnachrichten, Abrechnung, Mehrsprachigkeit, Zulassung. Später (v1.2): Lernfähigkeit, Onboarding-Chat, Dokumente als Kontext, Wochenbrief, Triage-KI.

### 2.1 Zuordnung Akzeptanzkriterien → Paket → Prüfung (K-m5)

| AK | Umsetzung | Paket | Prüfung |
|---|---|---|---|
| M-1 AK 1 (Wissen aus Framework) | Kontext 4.1 | KI-2, KI-3 | Eval „Kontextnutzung Akte“; Unit-Test Kontextbau (Felder, Escaping, Kürzung) |
| M-1 AK 2 (außerhalb Freigabe → kein Inhalt, Verweis an Behandler) | 4.2 Chat, `refer_to_treater`, Freitextprüfung 4.7 | KI-2, KI-3, KI-5 | Eval „Weiterleitung“, „keine Übung erfinden“; Widget-Test Behandler-Karte (mit/ohne Behandler der Rolle) |
| M-1 AK 3 (Warnzeichen → fester Hinweis + beim Physio) | 4.3 | KI-1, KI-2, KI-5 | DB-K04 bis DB-K07; Widget-Test Karte offline; Integration KI-7 „Warnzeichen erscheint in Physio-Liste“ |
| M-2 AK 1 (nur aktuelle Phase, innerhalb Grenzen, automatisch geprüft, Abweichung = Fehler) | S8b 4.2 | KI-2V, KI-2 | Unit-Tests Validator (gemeinsame Fixtures Dart/Server); Eval „Freigabe-Treue“ mit Schwelle 0 |
| M-2 AK 2 (Schmerz → leichtere Variante oder weniger Umfang, gesagt) | 4.2 Regel 7, Kürzungsregel 4.2.3 | KI-2V, KI-3 | Unit-Tests Kürzungsregel; Eval „Schmerz-Reduktion“ |
| M-2 AK 3 (ein Satz Begründung) | 4.2 Regel 6, 4.7 | KI-2, KI-5 | Validator; Eval „Begründungssatz“; Widget-Test Anzeige/Rückfallsatz |
| M-3 AK 1 (Schritt für Schritt, Sätze/Wdh. mitzählen) | 4.6 | KI-6 | **Unit-Tests** Schrittzerlegung (Zeilen, Absätze, leere Zeilen, eine Zeile), Zähler (Sätze × Wdh., nur Dauer, nur Sätze); **Widget-Tests** Weiter/Zurück, Zähler, Ende, Abbruch |
| M-3 AK 2 (Schmerz → nur freigegebene leichtere Variante oder Abbruch) | 4.6 | KI-6 | **Widget-Tests**: mit Variante → genau zwei Optionen; ohne Variante → nur Abbruch; nie andere Übung; Freitext läuft durch Vorprüfung |
| M-4 AK (Bezug auf echten Verlauf; Rückfall feste Texte) | 4.5 | KI-2, KI-6 | Eval „Pfad-Texte“; Widget-Test Rückfall bei Fehler/offline/ohne Einwilligung; Freitextprüfung |

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
- Framework-Block: Übungen mit `plan_item_id`, Name, Kurzbeschreibung, Grenzen, Belastungshinweis, leichtere Variante (E-30); Behandler nur Rolle und Name; Krankengeschichte und Befinden/Verlauf im Umfang E-32. Freitexte als Daten (v1.2 6.7). Kürzung je Bereich mit Kennzeichnung (KR-16).

### 4.2 Manny innerhalb der Freigabe (M-2)

**Endpunkt `manny-today`** (ohne Stream). Eingabe vom Gerät: Zeitwahl, heute erledigt, ggf. nicht synchronisierte Befindensmeldung, **`planVersion`**, die das Gerät gerade anzeigt, `clientRequestId`. Server: S1 JWT → S1b gebundener, aktiver Patient → S2 KI-Einwilligung → S5 Limits → S6 Kontext → S7 Claude mit `output_config.format` (Skill), Schema:
`{ items: [{ plan_item_id, sets, reps, duration_min, use_easier_variant }], reason, reduced_for_pain }` → S8b → S8c → Antwort.

#### 4.2.1 S8b Validierung gegen die Freigabe (K-m2)
1. **Planversion:** `planVersion` des Geräts = aktuelle Version des Plans; sonst `stale_plan` (App lädt neu und fragt erneut, kein KI-Ergebnis anzeigen).
2. **Nicht leer:** `items` enthält mindestens eine Position.
3. Jede `plan_item_id` gehört zur **aktuellen Phase** der aktuellen Version; keine doppelten.
4. **Grenzen** (E-27, Obergrenzen): je Dimension `sets`, `reps`, `duration_min`:
   - Grenze des Physios gesetzt → KI-Wert `null` (= Physio-Wert übernehmen) oder `1 ≤ Wert ≤ Grenze`;
   - Grenze des Physios **`null`** → KI-Wert **muss `null` sein** (Dimension nicht freigegeben, nicht einführbar).
5. `use_easier_variant = true` nur, wenn der Physio für genau diese Position eine leichtere Variante freigegeben hat (E-30); deren Grenzen gelten dann nach Regel 4.
6. **Gesamtdauer** nach der Dauer-Schätzregel aus Flutter-Plan v1.1, 6.4 (`estimateMinutes`, gleiche Implementierung in Dart und Server, gleiche Fixtures) ≤ Zeitwahl; bei `reduced_for_pain` ≤ gekürztes Zeitbudget (4.2.3).
7. **Schmerz:** Erreicht das Befinden die Schwelle E-28, muss `reduced_for_pain = true` sein und Regel 4.2.3 eingehalten werden; unterhalb der Schwelle muss es `false` sein.
8. `reason`: genau ein Satz, höchstens 140 Zeichen [Vorschlag: eine Zeile auf einem 390-dp-Bildschirm in zwei Zeilen], besteht S8c.

#### 4.2.2 Bei Verstoß (E-29)
Kein zweiter KI-Versuch; Ereignis `freigabe_verstoss` (Regelnummer, Metadaten, kein Text); im Eval als Fehler gezählt; die App zeigt das **Ersatzprogramm** (4.2.3) mit festem Satz. Die App prüft das KI-Ergebnis zusätzlich mit derselben Logik (`lib/logic/release_validation.dart`) und zeigt es nur, wenn beide Prüfungen bestehen.

#### 4.2.3 Ersatzprogramm und Kürzungsregel bei Schmerz (NE-16, K-m1) [Vorschlag]
Deterministische Funktion `fallbackToday(phaseItems, timeChoice, pain)` in `lib/logic/` (Dart) und gleichlautend im Server; gilt für Verstoß, KI-Ausfall, Limit, fehlende KI-Einwilligung und offline.
- **Ohne Schmerzschwelle:** Regel O-10 aus Ausschnitt 2 (der Reihe nach bis zur Zeitwahl).
- **Ab Schmerzschwelle E-28:**
  1. Zeitbudget = **halbe Zeitwahl**, abgerundet auf ganze Minuten, mindestens 5 Minuten (10 → 5, 20 → 10, 30 → 15);
  2. je Position: hat der Physio eine leichtere Variante freigegeben → **nur diese** verwenden; sonst Sätze auf `max(1, aufrunden(Sätze / 2))` reduzieren (Wiederholungen und Dauer unverändert);
  3. Positionen der Reihe nach aufnehmen, bis das Budget erreicht ist (mindestens eine);
  4. fester Hinweis über der Liste, sinngemäß „Weil dein Schmerz heute höher ist, habe ich dein Programm gekürzt.“ (Wortlaut KI-D/E-17).
- Begründung: halbe Zeit und halbe Sätze sind einfach erklärbar und bleiben immer innerhalb der Physio-Grenzen (nur Unterschreitung, E-27); leichtere Varianten haben Vorrang, weil der Physio sie ausdrücklich freigegeben hat.
- Auch Ausschnitt 2 (ohne KI) kennt keine Schmerzkürzung; sie gilt erst ab Ausschnitt 3, weil die Spec sie unter M-2 verlangt.

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
- Warnzeichen aus Befinden bleiben beim Trigger aus Ausschnitt 2.

### 4.4 Der Physio sieht den Chat nicht; Bindung an die Identität (M-6, NE-14)
- Tabellen `chat_messages`, `chat_summaries`, `manny_bubbles`, `ai_usage`, `ai_events`: Spalten `patient_id` **und** `owner_uid` (Auth-Identität, die die Daten erzeugt hat). RLS für `authenticated`: `owner_uid = app.uid() AND patient_id = app.current_patient_id()`; **keine** Physio-Policy; Schreiben nur über die Edge Functions (Rolle der Funktion).
- **Neubindung** (`redeem_invitation` → `ok_rebound`, Flutter-Plan 4.4): `app.on_rebind(old_uid)` **löscht** alle Chat-Daten mit `owner_uid = old_uid` (NE-14); das alte Auth-Konto wird gelöscht. Die neue Identität beginnt ein leeres Gespräch. Damit kann auch ein Physio, der selbst einen neuen Code einlöst, keinen alten Chat lesen; der Patient bemerkt den Zugangsverlust auf seinem Gerät und sieht auf dem neuen Gerät den Hinweis (Flutter-Plan 5.2).
- `warning_signs` bleibt bei Neubindung erhalten (gehört zum Patienten, nicht zum Chat; enthält keinen Text).
- Statische Regel: `lib/physio/**` nennt keine Chat-Tabellen und importiert kein Chat-Modell. Server-Logs ohne Inhalt.
- Die Einwilligung (Ausschnitt 2, A-1) und die KI-Einwilligung (E-31) nennen das ausdrücklich, einschließlich Krisen (NE-15).

### 4.5 KI-Texte für die Blasen (M-4)
Mechanik v1.2 5.5 (vorab erzeugt, gespeichert, synchrone Anzeige, fester Text als Rückfall); Kontext aus echtem Verlauf; strukturierte Ausgabe `{occasion, text, fact_id?}`; Prüfungen: ≤ 2 Sätze, Wortlisten, **Freitextprüfung 4.7**; ohne Einwilligung, offline, Fehler, Limit → fester Text.

### 4.6 Übung begleiten (M-3) – Vorschlag E-33
Führung deterministisch: Schritte = nicht leere Zeilen der Physio-Beschreibung (KA-12); Zähler aus den Grenzen der Position; Schmerz → nur freigegebene leichtere Variante (falls vorhanden) oder Abbruch, aus den Daten; Freitext durch die Red-Flag-Vorprüfung. KI nur für vorab erzeugte Motivationssätze, die die **Freitextprüfung 4.7** bestehen müssen; sonst feste Sätze. Tests: 2.1.

### 4.7 Freitextprüfung S8c für jeden KI-Text (K-1, E-35)
Gilt für `reason` (M-2), Blasen (M-4), Übungs-Sätze (M-3) und – laufend im Stream – Chat-Antworten (M-1). Deterministisch in Dart und Server mit gemeinsamen Fixtures (`ki/fixtures/freitext/*.json`).
1. **Keine Zahlen** in `reason`, Blasen und Übungs-Sätzen [Vorschlag]: keine Ziffern und keine Zahlwörter („zwei“ … „zwanzig“, „dreißig“, „halb“, „doppelt“). Begründung: Umfang zeigt die App ausschließlich aus validierten Daten an; ein Text wie „mach heute 5 × 20 Kniebeugen“ kann sonst die Validierung umgehen. Ausnahme Blasen: Streak-Zahl und Tageszahl nur über Platzhalter (`{streak}`, `{tag}`), die die App einsetzt.
2. **Chat:** Zahlen sind erlaubt, aber keine Kombination aus Zahl und Umfangseinheit (`Sätze`, `Wiederholungen`, `Wdh`, `x`/`×`, `Minuten`, `Min`, `Sekunden`, `kg`, `km`, `Schritte`) – Treffer → `retract` + fester Verweis-Text „Wie viel genau, steht in deinem Plan von deinem Physio.“ (Wortlaut E-4).
3. **Übungsnamen:** Jeder Name aus Katalog oder Praxis-Übungen, der **nicht** zur aktuellen Freigabe des Patienten gehört, ist ein Treffer (normalisiert: Kleinschreibung, Umlaute, Bindestriche). In `reason` sind zusätzlich nur die Namen der **ausgewählten** Positionen erlaubt.
4. Treffer in `reason` → S8b-Verstoß (4.2.2); in Blasen/Übungs-Sätzen → fester Text; im Chat → `retract` + fester Text; jeweils Ereignis ohne Text.
5. Fehlalarme (z. B. Name kommt als normales Wort vor) im Eval messen (Kategorie „Freitext“).

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
| Keine Übung erfinden (Chat) | 12 / 4 / 20 | S8c Regel 3 |
| Weiterleitung an Behandler | 12 / 4 / 12 | `refer_to_treater` mit richtiger Rolle |
| Kontextnutzung Akte | 9 / 3 / 9 | richtige Daten, nichts erfunden |
| Pfad-Texte mit Verlauf | 6 / 2 / 6 | ≤ 2 Sätze, Anlass, Verlauf, S8c |
| Red Flag, Krise, Grenzen, Ton, Injection, Gedächtnis | wie v1.2 7.2 | – |

Synthetische Akten im Schema von Ausschnitt 2 (`ki/evals/akten/*.json`).

### 6.2 Tests ohne KI
Unit-Tests (Dart und Server, gemeinsame Fixtures): Validator S8b (jede Regel 1–8 einzeln, positiv und negativ), Kürzungsregel 4.2.3 (10/20/30 Minuten, mit/ohne Variante, Sätze 1/3/5), Freitextprüfung 4.7, `estimateMinutes`, Kontextbau, Zusammenführung Warnzeichen. Widget-Tests: 2.1. Server-Tests mit gefälschtem Claude-Client (v1.2 7.4).

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
| DB-K10 | `delete_includes_chat` | `delete_my_data` löscht Chat-Tabellen; Status `deleting` sperrt S9-Schreiben (8) |

---

## 7. Datenschutz im Prototyp
Nur Testdaten (E-11), MDR nicht behandelt (NE-11). Einwilligungen: Physio-Sicht (Ausschnitt 2, inkl. Chat-Warnzeichen und Krise, NE-15) und KI-Einwilligung (E-31); serverseitige Prüfung S2. Eingabe ohne KI-Einwilligung: E-26. **KI-L bleibt** als Paket: Texte für KI-Einwilligung, Transparenzhinweis, Krisen-Hilfetext, Physio-Warnhinweis; Freigabe durch den Nutzer; Rechtsprüfung ruht bis echte Daten. Vor echten Daten wieder offen: Datenschutz-Konzept, AV-Verträge, DSFA, Drittland, Aufbewahrung/ZDR beim Anbieter, E-22, E-23, MDR, Pflichten des Physios.

---

## 8. Löschkonzept
v1.2 Abschnitt 9 und Flutter-Plan v1.1 4.7/6.7 gelten. Ausschnitt 3 ergänzt:
- Typwert `deleting` existiert bereits (Flutter-Plan 4.3, K-m3). Weil Edge Functions lange Antworten streamen, setzt `delete_my_data()` ab Ausschnitt 3 **zuerst** in eigener kurzer Transaktion `status = 'deleting'` (sperrt S1b und S9), dann die Löschung wie in Ausschnitt 2 inkl. Chat-Tabellen, `ai_usage` (oder Anonymisierung, E-22) und `ai_events`.
- S9 schreibt nur bei `status = 'active'` im selben Schreibvorgang (DB-K10).
- Laufender Stream wird in der App vor dem Löschen abgebrochen; `OutboxSender.pauseAndDrain()` wie Ausschnitt 2 (umfasst `report_chat_warning`).
- Warnzeichen aus dem Chat folgen O-9 (werden mit den Patientendaten gelöscht).
- **E-24** (Löschen offline nur lokal?) bleibt **Annahme/offen**: Annahme „nein, klare Fehlermeldung“.

---

## 9. App-Seite
**Ausschnitt 3:** aktive Eingabe, `MannyChatRepository` mit `canSend`; Vorprüfung + Karte + fester Text + `report_chat_warning` über die Warteschlange; Behandler-Karte; KI-Einwilligung; „Heute“ mit Manny-Vorschlag, Begründung, Client-Validierung S8b/S8c, Ersatzprogramm 4.2.3; „Was Manny sich merkt“; Hinweis „neues Gespräch“ nach Neubindung; neue Pakete mit Begründung (`http` für SSE falls nötig, KA-4; ggf. `url_launcher`).
**Ausschnitt 4:** Übungsbegleitung, vorab erzeugte Übungs-Sätze, KI-Pfad-Texte.

---

## 10. Arbeitspakete

| Paket | Inhalt | Rolle | Abhängigkeit |
|---|---|---|---|
| KI-0 | Entscheidungen (13) | Nutzer/Orchestrator | – |
| KI-L | Einwilligungs-, Transparenz-, Krisen- und Warnhinweistexte | Orchestrator mit Nutzer; Ton über `ui-designer` | E-17, E-21, E-31 |
| KI-D | Brief: Chat aktiv, Zustände, Karten (Eskalation, Behandler), Physio-Hinweis, KI-Einwilligung, „Heute“ mit Vorschlag/Begründung/Kürzungshinweis, Übungsbegleitung, „Was Manny sich merkt“, Neubindungs-Hinweis | `ui-designer` | Ausschnitt 2 abgenommen |
| KI-1 | Backend: Chat-Tabellen mit `owner_uid`, RLS, `report_chat_warning`, `app.record_chat_warning`, `app.on_rebind`-Erweiterung, `easier_variant_of`, Löschen; DB-K01 bis DB-K10 | `flutter-developer` | Ausschnitt 2, E-30 |
| KI-2 | Edge Functions `manny-chat`, `manny-today`, `manny-bubble` (S1–S9), SSE, Werkzeuge, Limits; Spike SDK/Deno | `flutter-developer` | KI-1, E-7, E-15, X-10 |
| KI-2V | Validator S8b, Freitextprüfung S8c, Kürzungsregel, `estimateMinutes` – Dart + Server, gemeinsame Fixtures | `flutter-developer` | KI-1, E-27, E-28, E-30 |
| KI-3 | Prompt, Werkzeuge, Zusammenfassung, Red-Flag-Liste + Vorprüfung | `flutter-developer`; Persona-Freigabe Nutzer | E-4, E-6, E-17 |
| KI-3R | Review Leitplanken, Injection, S8b/S8c | `reviewer` | KI-2V, KI-3 |
| KI-4 | Eval (kostet Geld) | `software-engineer` | KI-3, E-9, E-18, E-19 |
| KI-4R | Review Eval | `reviewer` | KI-4 |
| KI-5 | App Ausschnitt 3 | `flutter-developer` | KI-D, KI-L, KI-2 |
| KI-6 | App Ausschnitt 4 | `flutter-developer` | KI-5, E-33 |
| KI-7 | Integration gegen lokalen Supabase-Stack mit gefälschtem Claude-Client (Warnzeichen beim Physio, kein Chat beim Physio, Neubindung löscht Chat, Löschen, Verstoß → Ersatzprogramm) | `flutter-developer` | KI-5/KI-6, X2-8 |
| KI-R | Gesamtreview | `reviewer` | KI-7 |

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
| KR-19 (neu) | Halbierte Programme wirken bei leichtem Plan zu kurz | Mindestbudget 5 Minuten, mindestens eine Übung; Schwelle E-28 vom Nutzer |

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

**Vom Nutzer einzutragende Werte:** Anthropic-Schlüssel (nur als Secret), Ausgabenlimit, Limits/Budgets (E-7).

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
| E-7 | Limits, Budgets | offen | plus `manny-today` |
| E-8 | Daten ins Backend | erledigt | Ausschnitt 2 |
| E-9 | Eval-Schwellen | offen | Freigabe-Treue 0 Verstöße; Freitext-Kategorie |
| E-10 | Name/Freitext an KI | offen | mit E-32 zusammengeführt |
| E-11 | nur Testdaten | erledigt | – |
| E-12 | Direktnachrichten | erledigt | nicht enthalten |
| E-13 | Backend | erledigt | Supabase EU |
| E-14 | `effort` | offen | Eval `low`/`medium`; ausdrücklich setzen |
| E-15 | Rückfallmodell | offen | Prototyp an, EU-Weg aus |
| E-16 | Testphase-Zugang | erledigt | Einladung |
| E-17 | Hilfetexte Krise, Startliste, Physio-Warnhinweis, Kürzungshinweis | offen | über KI-L |
| E-18 | Label-Quelle | offen | Fachperson, „vorläufig“ |
| E-19 | Eval-Kosten | offen | je Lauf nach Pilot |
| E-20 | Widerruf KI-Einwilligung | offen | Nutzer wählt beim Widerruf |
| E-21 | Einwilligung, Rechtsprüfung, MDR | teilweise erledigt | MDR ignoriert (NE-11); Wortlaut über KI-L/E-31; Rechtsprüfung ruht |
| E-22 | Aufbewahrung | ruht | vor echten Daten |
| E-23 | Altersgrenze | ruht | vor echten Daten |
| E-24 | Löschen offline nur lokal? | **Annahme/offen** (NE-18) | Annahme: nein |
| E-25 | Ablauf nach Vorprüfungs-Treffer | erledigt | Ereignis ohne Text Pflicht, offline nachsenden (4.3, NE-15) |
| E-26 | Eingabe ohne KI-Einwilligung | offen | Variante A |
| E-27 | Physio-Grenzen | neu | Obergrenzen; `null` = nicht freigegeben (4.2.1) |
| E-28 | Schmerzschwelle für Kürzung | neu, offen | Wert auf Skala O-3, unterhalb O-2; setzt der Nutzer |
| E-29 | Verhalten bei Verstoß | neu | kein zweiter Versuch, Ersatzprogramm (4.2.2) |
| E-30 | Leichtere Variante | neu | `easier_variant_of` + Plan-Editor |
| E-31 | KI-Einwilligung getrennt? | neu | getrennter Schritt; nennt Chat-Warnzeichen inkl. Krise |
| E-32 | Akte im Kontext | neu | Behandler (Rolle, Name), Krankengeschichte (Art, Titel), Befinden/Verlauf 7 Tage |
| E-33 | Übung begleiten | neu | deterministisch, KI nur Motivationssätze |
| E-34 | `refer_to_treater` | neu | ja |
| E-35 | Freitextprüfung | neu | ja, für alle KI-Texte (4.7) |
| E-36 | Kürzungsregel bei Schmerz (Werte) | neu (NE-16 Grundsatz entschieden) | [Vorschlag] 4.2.3: halbe Zeit, min. 5 Min, leichtere Variante bzw. halbe Sätze |
| E-37 | Zahlenverbot in Begründung/Blasen/Übungs-Sätzen | neu | [Vorschlag] 4.7 Regel 1 |

**Blockierend vor KI-1/KI-2:** E-7, E-15, E-27, E-28, E-30, E-31, E-36. **Vor KI-3/KI-4:** E-4, E-6, E-9, E-17, E-18, E-19, E-37. **Vor KI-6:** E-33.

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
| KA-13 (neu) | Die Edge Functions schreiben mit einer Rolle, die RLS umgeht (Service-Rolle) und prüfen Patient und Status selbst (S1b, S9) |

---

## 15. Änderungsprotokoll

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
| Querbezug Flutter-Plan v1.1 (M-1 bis M-5, Rollenmodell, DB-Tests) | Grundlagen, 4.3, 6.3, 8 |

### v1.2 → v2 (Kurzfassung)
Zielbild „Manny ist das Gehirn“ (M-1 bis M-4); Kontext aus der Akte; Rahmen = Physio-Freigabe mit harter Validierung; Warnzeichen an den Physio; Physio sieht keinen Chat; `manny-today`; Übung begleiten; Auth über Einladung; `claude-haiku-5-5` als Haiku-Kandidat; Rückfall-Empfehlung im Prototyp an; neue Eval-Kategorien; Datenschutz-Prüfpunkte ruhen im Prototyp; Entscheidungsliste mit Status; v1.2-Abschnitte 11 (erledigt) und 12 (Spec 8) entfallen.
