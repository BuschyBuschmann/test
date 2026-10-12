# KI-Plan v2: Manny ist das Gehirn (CuraOne, Ausschnitte 3 und 4)

Status: **PLAN ZUR FREIGABE** · v2 (Überarbeitung von `docs/plan/ki-plan-v1.md` v1.2 für das neue Zielbild) · Paket P2 · Autor: `flutter-developer` · Stand 2026-10-11

Grundlagen:
- `docs/produkt/curaone-spezifikation-manny-gehirn.md` (FREIGEGEBEN 2026-10-11): Zielbild 1, Rollen 2, Nutzerentscheidungen 3, Ausschnitt 3 (M-1, M-2), Ausschnitt 4 (M-3, M-4), Abschnitte 8–10.
- `docs/plan/ki-plan-v1.md` v1.2: **bleibt Referenz** für alle Abschnitte, die hier nur verwiesen werden („v1.2, n“).
- `docs/plan/flutter-plan-ausschnitt-2.md` (Fundament: Supabase-Schema, Auth über Einladung, Warnzeichen-Tabelle, Löschen mit Backend). Ausschnitt 3 setzt Ausschnitt 2 voraus.
- Skill `claude-api` (Modelltabelle Stand 2026-10-06). API-Aussagen sind mit „(Skill)“ belegt oder als Annahme/„zu prüfen“ gekennzeichnet. Es werden nur Modell-IDs aus dem Skill bzw. aus v1.2 verwendet.

Kennzeichnung wie v1.2: **E-n** Entscheidung (Abschnitt 13), **NE-n** getroffene Nutzerentscheidung, **KA-n** Annahme, **KR-n** Risiko, **X-n** externer Schritt. Neue Nummern setzen die alten fort. Alles ist ein **Vorschlag**; rechtliche Punkte sind Prüfpunkte, keine Rechtsberatung.

---

## 0. Verbindliche Nutzerentscheidungen

Aus v1.2, weiter gültig:
- **NE-2** Manny-Button auf Pfad und Heute; Tipp auf Manny auf dem Pfad öffnet den Chat (Erreichbarkeit bleibt, solange E-1 nichts anderes sagt).
- **NE-4** Red-Flag-Vorprüfung als Dart-Logik auf dem Gerät vor jedem Netzwerkaufruf und vor Limits, serverseitig wiederholt.
- **NE-6** Aktive Eingabeleiste und `canSend` kommen erst mit dem KI-Ausschnitt (jetzt Ausschnitt 3).
- NE-1, NE-3, NE-5 sind mit dem ersten Ausschnitt erledigt.

Neu aus der Spezifikation (2026-10-11):
- **NE-7** Manny nutzt das Patienten-Framework: Behandler, Krankengeschichte, Plan mit freigegebenen Übungen, Befinden, Verlauf (Spec 3.3).
- **NE-8** Manny wählt und passt **nur innerhalb der Physio-Freigabe** an, erfindet keine Übungen; alles andere geht als Frage an den Physio bzw. Verweis an den passenden Behandler (Spec 3.2, M-1, M-2).
- **NE-9** Der Physio sieht Verlauf und Warnzeichen, **nicht** den Manny-Chat; der Patient wird informiert und stimmt zu (Spec 3.5).
- **NE-10** Manny hilft im Chat, bei „Heute“, beim Begleiten einer Übung und mit Pfad-Texten; Reihenfolge Ausschnitt 3 (M-1, M-2), dann Ausschnitt 4 (M-3, M-4) (Spec 3.4, 3.10).
- **NE-11** Prototyp zur Präsentation, **nur Testdaten**, **MDR wird für den Prototyp nicht behandelt** (Spec 1, 3.11).
- **NE-12** Backend **Supabase in der EU** (E-13).
- **NE-13** Entwicklung **direkt über die Claude API mit Testdaten**; echte Daten nur über eine EU-Region (E-2).

---

## 1. Kurzfassung

| Thema | v2 |
|---|---|
| Zielbild | Manny antwortet im Chat mit Wissen aus der Akte (M-1), stellt „Heute“ aus dem Physio-Plan zusammen (M-2), begleitet eine Übung (M-3) und schreibt persönliche Pfad-Texte (M-4) |
| Harte Grenze | Jede KI-Auswahl von Übungen wird **deterministisch gegen die Freigabe validiert** (Server und App, gemeinsame Testfälle); eine Abweichung ist ein Fehler und wird nie angezeigt |
| Kontext | Server baut ihn aus der Datenbank (Ausschnitt 2): Vorname, Phase, freigegebene Übungen mit Grenzen, Behandler (Rolle, Name), Krankengeschichte (Umfang E-32), Befinden und Verlauf der letzten Tage. Client-Kontextfelder entfallen bis auf Streak/Freezes (lokal) |
| Warnzeichen | Treffer der Vorprüfung (Gerät/Server) und das Werkzeugsignal des Modells erzeugen ein **Warnzeichen ohne Text** in `warning_signs` → Physio-Liste (P-5) |
| Physio und Chat | Chat-Tabellen nur für den Patienten lesbar; RLS-Test „Physio sieht 0 Zeilen“; Physio-Web hat keinen Datenpfad dorthin |
| Endpunkte | `manny-chat` (Stream), `manny-today` (strukturiert, ohne Stream), `manny-bubble` (strukturiert, vorab erzeugt) |
| Weg zur KI | W1 Claude API direkt für den Prototyp (nur Testdaten); W2/W3 mit EU-Region erst für echte Daten (Modellverfügbarkeit dort zu prüfen) |
| Modell | `claude-opus-5-5` (Skill-Standard), Kandidat `claude-sonnet-5-5`; Entscheidung nach Eval (E-3, E-14) |
| Bleibt aus v1.2 | Leitplanken, zweistufige Red-Flag-Erkennung inkl. 3.1a, Eval-Methodik, Löschkonzept, Streaming, Limits, Idempotenz, Ausgabefilter, Injection-Schutz, Gedächtnis G1 |

---

## 2. Zielbild und Umfang

### 2.1 Ausschnitt 3: Chat und „Heute zusammenstellen“
- **M-1 Chat:** schreibbarer Manny-Chat (v1.2, 2.1), Antworten mit Framework-Wissen. Fragen außerhalb der Freigabe (neue Übung, Medikament, Diagnose) beantwortet Manny nicht inhaltlich und verweist an den passenden Behandler aus der Akte. Warnzeichen → fester Hinweis in der App + Warnzeichen beim Physio.
- **M-2 Heute zusammenstellen:** Manny schlägt das Tagesprogramm aus den Übungen der aktuellen Phase vor, passend zu Zeitwahl und Befinden, mit einem kurzen Begründungssatz. Bei höherem Schmerz: freigegebene leichtere Variante oder weniger Umfang, mit Hinweis.

### 2.2 Ausschnitt 4: Übung begleiten und Pfad-Texte
- **M-3 Übung begleiten:** Schritt für Schritt durch die Beschreibung des Physios, Sätze und Wiederholungen mitzählen; bei Schmerz nur freigegebene leichtere Variante oder Abbruch.
- **M-4 Pfad-Texte:** Begrüßung, Feier, Erinnerung beziehen sich auf den echten Verlauf; bei KI-Ausfall feste Texte aus Ausschnitt 1.

### 2.3 Nicht enthalten (Spec 8)
Arzt-Zugang, Übungen außerhalb der Freigabe, Sprache, proaktive Nachrichten und Push, Direktnachrichten, Abrechnung, Mehrsprachigkeit, Zulassung als Medizinprodukt. Aus v1.2 weiter „später“: Lernfähigkeit, Onboarding-Chat, Dokumente als Kontext, Wochenbrief, Triage-KI.

---

## 3. Was aus v1.2 bleibt

| Thema | v1.2 | Anpassung in v2 |
|---|---|---|
| Sicherheitsreihenfolge Gerät → Server | 3.1 | Server-Schritt S6 liest Kontext aus der Akte (4.1); neuer Schritt S8b nur in `manny-today` (4.2) |
| Ablauf nach Vorprüfungs-Treffer | 3.1a | Ereignis ohne Text ist jetzt **Pflicht** (wird Warnzeichen beim Physio, 4.3); offline über die Warteschlange aus Ausschnitt 2 |
| Streaming, SSE-Ereignisse, `retract`, Abbruch | 3.4 | unverändert für `manny-chat` |
| Werkzeug `escalate_red_flag` (`strict`, `eager_input_streaming`, eigene Validierung, `tool_choice: auto`) | 3.4 | unverändert; zweites Werkzeug `refer_to_treater` (4.2, E-34) |
| Ablehnung, Rückfallmodell | 3.4, 6.6 | Rückfall weiter Nutzerentscheidung E-15, neue Empfehlung (5) |
| Ausgabefilter | 3.4, 6.2 | ergänzt um „keine Übung außerhalb der Freigabe nennen“ (E-35) |
| Idempotenz, Sperre „eine laufende Antwort“ | 3.4 | unverändert |
| Auth und Missbrauchsschutz | 3.5 | **vereinfacht**: nur gebundene, aktive Patienten (Einladung, Ausschnitt 2) erreichen die Funktionen; anonyme ungebundene Sitzungen → 403 |
| Limits und Kostenkontrolle | 3.6 | unverändert, plus eigenes Limit für `manny-today` (E-7) |
| Gedächtnis G1, Zusammenfassung, Einsicht | 5.4 | unverändert; Zusammenfassung für den Physio nicht sichtbar |
| Persona und Ton | 5.2 | unverändert (E-4) |
| Leitplanken: Grenzen, Red Flags, Selbstgefährdung, Disclaimer, Injection | 6.1–6.7 | 6.1 „strenger Modus ohne Framework“ wird ersetzt durch „Rahmen = Physio-Freigabe“ (4.2) |
| Eval-Methodik | 7 | unverändert, neue Kategorien (6) |
| Löschkonzept | 9 | Basis wird in Ausschnitt 2 gebaut; Ausschnitt 3 ergänzt die Chat-Tabellen (8) |
| Prüfpunkte Datenschutz | 8.2 | für den Prototyp ruhend (nur Testdaten, MDR ignoriert); vor echten Daten wieder offen (7) |

---

## 4. Was sich ändert

### 4.1 Kontext aus der Akte
- **Quelle:** Der Server baut den Kontext aus den Tabellen von Ausschnitt 2 (`patients`, `plans`, `phases`, `plan_items`, `exercises`, `treaters`, `appointments`, `history_entries`, `wellbeing_reports`, `training_sessions`). E-8 ist damit erledigt.
- **Vom Gerät** kommen nur noch lokale Werte, die nicht im Backend liegen (Streak, Freezes, heute erledigt, Zeitwahl, heutige Tagesänderungen); Schema-, Längen- und Escaping-Regeln aus v1.2 5.3 gelten weiter.
- **Aufbau** (Reihenfolge laut Skill: tools → system → messages):

```
tools     escalate_red_flag, refer_to_treater (fest, byte-gleich)
system    Persona/Ton · Regeln · „Rahmen = Freigabe“ · Ausgabeformat   -- Cache-Breakpoint --
messages  user: <framework> (ändert sich selten: Plan-Version, Akte)
                <zusammenfassung> <tageskontext> + erste Nachricht im Fenster
          … Verlauf im Fenster (nur Text) …
          user: aktuelle Nachricht
```

- Framework-Block mit Plan-Version und Stand; Übungen mit **IDs** (`plan_item_id`), Name, Kurzbeschreibung, Grenzen, Belastungshinweis, ggf. leichtere Variante (E-30). Behandler nur mit Rolle und Name (Kontaktdaten zeigt die App, nicht die KI; E-34). Befinden/Verlauf der letzten Tage (Anzahl Tage E-32).
- Alle Freitexte des Physios und Patienten stehen in markierten Datenblöcken und sind **Daten, keine Anweisungen** (v1.2 6.7).
- **Caching:** System und Werkzeuge zuverlässig gecacht (Skill: Präfix-Treffer; Mindestlänge modellabhängig, Skill). Der Framework-Block ist je Patient stabil und wird nur innerhalb der Cache-Lebensdauer wiederverwendet (5 Minuten Standard, 1 Stunde möglich laut Skill); im Eval messen über `usage.cache_read_input_tokens` (Skill).

### 4.2 Manny innerhalb der Freigabe, mit harter Validierung (M-2)

**Endpunkt `manny-today`** (ohne Stream):
- Eingabe vom Gerät: Zeitwahl, heute bereits erledigt ja/nein, ggf. aktuelle Befindensmeldung (falls noch nicht synchronisiert), `clientRequestId`.
- Server: Auth → gebundener Patient → Einwilligung KI → Limits → Kontext (4.1) → Claude mit **strukturierter Ausgabe** (`output_config.format`, Skill) nach Schema:
  `{ items: [{ plan_item_id, sets, reps, duration_min, variant }], reason, reduced_for_pain }`
- **S8b Validierung gegen die Freigabe** (deterministisch, vor jeder Antwort an die App):
  1. jede `plan_item_id` gehört zur **aktuellen Phase** der **aktuellen Planversion** dieses Patienten;
  2. keine doppelten Positionen;
  3. Sätze, Wiederholungen, Dauer innerhalb der Grenzen des Physios (Semantik E-27);
  4. eine leichtere Variante nur, wenn der Physio sie für genau diese Position freigegeben hat (E-30);
  5. Gesamtdauer ≤ Zeitwahl;
  6. `reason`: genau ein Satz, Länge begrenzt, Wortlisten und Ausgabefilter bestanden;
  7. `reduced_for_pain` nur, wenn das Befinden die Schwelle E-28 erreicht; umgekehrt muss bei erreichter Schwelle reduziert werden.
- **Bei Verstoß:** Vorschlag wird verworfen, Ereignis `freigabe_verstoss` (Metadaten ohne Text) gespeichert und im Eval als Fehler gezählt (M-2 AK 1). Die App zeigt das deterministische Programm aus Ausschnitt 2 (Regel O-10) mit festem Satz statt KI-Begründung (E-29).
- **App prüft erneut** mit derselben Regel in reiner Dart-Logik (`lib/logic/release_validation.dart`), gemeinsame Testfälle mit dem Server (`ki/fixtures/freigabe/*.json`). Anzeige nur, wenn beide Prüfungen bestehen.
- Die Begründung (M-2 AK 3) erscheint als ein Satz über der Liste (Gestaltung KI-D).

**Chat (M-1) innerhalb der Freigabe:**
- Regeln im System-Prompt: Übungen nur aus dem Framework-Block, keine neuen; Fragen zu neuer Übung, Medikament, Diagnose → kein Inhalt, Verweis.
- **Werkzeug `refer_to_treater`** (`strict: true`; Eingabe `{role, reason_code}`): Die App zeigt daraufhin eine Karte mit dem passenden Behandler aus der Akte (Name, Kontakt) – deterministisch aus den Daten, nicht aus dem Modelltext (E-34). Gibt es keinen Behandler dieser Rolle, zeigt die Karte „deinen Physio fragen“.
- Laufzeitprüfung: Nennt der Modelltext eine Katalog- oder Praxisübung, die nicht in der Freigabe des Patienten steht → `retract` + fester Text (E-35).
- Der Chat verändert „Heute“ nicht selbst (nicht in der Spec); ein Neu-Zusammenstellen läuft immer über `manny-today`.

**Leichtere Variante (Datenmodell):** In Ausschnitt 2 gibt es kein Feld dafür. Vorschlag E-30: Der Physio markiert im Plan-Editor eine Position als „leichtere Variante von …“ (Migration `plan_items.easier_variant_of`), oder der Physio gibt je Position einen reduzierten Umfang an. Ohne Entscheidung kann Manny nur „weniger Umfang“ innerhalb der Grenzen wählen.

### 4.3 Warnzeichen gehen an den Physio
- Jede Red-Flag-Erkennung erzeugt eine Zeile in `warning_signs` mit `source = 'chat'`, `level`, `reason_code`, `layer` (`device` | `server` | `model`), **ohne Nachrichtentext** (NE-9, v1.2 3.1a).
  - Gerät: Ereignis über die Ausgangswarteschlange aus Ausschnitt 2; offline wird nachgesendet (E-25 neu).
  - Server-Vorprüfung S3 und Werkzeug `escalate_red_flag`: Schreiben direkt durch die Funktion.
- Warnzeichen aus Befinden bleiben beim Trigger aus Ausschnitt 2 (O-2).
- Die App zeigt beim Patienten weiter Eskalationskarte und festen Text (v1.2 6.3, 6.4) – zusätzlich Hinweis, dass der Physio ein Warnzeichen sieht (Wortlaut E-17, Gestaltung KI-D).
- Doppelte Ereignisse (Gerät und Server für dieselbe Nachricht) werden über `clientMessageId` zusammengeführt.

### 4.4 Der Physio sieht den Chat nicht
- Tabellen `chat_messages`, `chat_summaries`, `manny_bubbles`, `ai_usage`, `ai_events`: RLS **nur** `auth.uid()` des gebundenen Patienten; **keine** Physio-Policy; Funktionen schreiben mit eigener Rolle.
- RLS-Test: Physio derselben Praxis liest 0 Zeilen aus jeder dieser Tabellen; `warning_signs` enthält keine Textspalte (Schema-Test).
- Statische Regel: `lib/physio/**` nennt keine Chat-Tabellen und importiert kein Chat-Modell.
- Server-Logs ohne Inhalt (v1.2 6.7).
- Die Einwilligung aus Ausschnitt 2 (A-1 AK 3) sagt das ausdrücklich; die KI-Einwilligung wiederholt es (E-31).

### 4.5 KI-Texte für die Blasen (M-4)
- Mechanik aus v1.2 5.5 bleibt: vorab erzeugt (App-Start, Tageswechsel, nach Training) über `manny-bubble`, gespeichert im Zustandsdokument, synchrone Anzeige, fester Text als Rückfall (M-4 AK).
- Neu: Kontext aus echtem Verlauf (Trainings, Befinden, Phase, Phasenwechsel durch den Physio).
- Strukturierte Ausgabe je Anlass `{occasion, text, fact_id?}`; Prüfungen wie feste Texte (≤ 2 Sätze, Wortlisten, Ausgabefilter); ohne Einwilligung, offline, Fehler oder Limit → fester Text ohne Fehleranzeige.

### 4.6 Übung begleiten (M-3)
Vorschlag (E-33): **Führung deterministisch, KI nur für Motivation.**
- Schritte = Zeilen bzw. Absätze der Physio-Beschreibung (kein neues Feld); Sätze und Wiederholungen zählt die App aus den Grenzen der Position.
- Schmerz während der Übung: Die App bietet **nur** die freigegebene leichtere Variante (falls vorhanden, E-30) oder Abbruch an – aus den Daten, ohne KI-Entscheidung (M-3 AK 2). Freitext läuft durch die Red-Flag-Vorprüfung.
- Optionale kurze Manny-Sätze zwischen den Sätzen: vorab je Übung erzeugt (wie Blasen), Rückfall auf feste Texte.
- Vorteil: Sicherheitsrelevantes Verhalten ist prüfbar ohne Eval-Statistik; Kosten und Latenz minimal. Alternative: KI führt im Dialog (mehr Risiko, Eval-Kategorie nötig).

---

## 5. Architektur, Weg zur KI, Modell

**Ablauf** wie v1.2 3.1 mit diesen Änderungen:
- S1 JWT prüfen → **S1b gebundener, aktiver Patient** (sonst 403) → S2 Einwilligung KI → S3 Vorprüfung (Treffer → Warnzeichen 4.3, fester Text) → S4 Idempotenz/Sperre → S5 Limits → **S6 Kontext aus der Akte** → S7 Claude → **S8 Ausgabefilter + S8b Freigabe-Validierung (nur `manny-today`)** → S9 Speichern (prüft Kontostatus wie v1.2 9).
- Funktionen als Supabase Edge Functions; Region der Funktionen fest EU (KA-7, zu prüfen); Server-SDK `@anthropic-ai/sdk` (Skill), Lauffähigkeit unter Deno ist KA-1 (Spike KI-2).

**Weg zur KI (E-2 entschieden):**
- **Prototyp:** W1 Claude API direkt, nur Testdaten. Laut Skill bietet der Parameter `inference_geo` auf der Claude API keine EU-Option (Werte `"us"`/`"global"`); für Testdaten nach NE-13 zulässig.
- **Echte Daten:** nur über EU-Region, d. h. W2 Vertex AI (Region u. a. `"eu"` wählbar, Skill) oder W3 Bedrock (Region wählbar, Skill). Ob `claude-opus-5-5`/`claude-sonnet-5-5` dort in einer EU-Region verfügbar sind, steht nicht im Skill (KA-3, vor dem Wechsel prüfen). Auf W2/W3 gibt es keine Server-`fallbacks` (Skill: dort SDK-Middleware) und kein `inference_geo` (Skill).
- Client hinter einer Fabrikfunktion, Wechsel per Konfiguration.

**Modelle (Skill, Stand 2026-10-06):**

| Einsatz | Vorschlag | Beleg |
|---|---|---|
| Chat (`manny-chat`) | `claude-opus-5-5`; Kandidat `claude-sonnet-5-5` | Skill: Standard Opus 5.5, nicht aus Kostengründen herabstufen → Nutzerentscheidung nach Eval (E-3) |
| `manny-today` (strukturiert) | gleiches Modell wie Chat | ein Ton, ein Cache-Namensraum |
| Blasen, Übungs-Sätze | gleiches Modell | wie v1.2 |
| Zusammenfassung | gleiches Modell; `claude-haiku-5-5` nur mit Eval-Nachweis | Skill nennt `claude-haiku-5-5` als aktuelles Haiku (v1.2 nannte `claude-haiku-4-5`) |
| Eval-Judge | anderes Modell als der Chat, kalibriert | v1.2 7.3 |

Skill-Regeln (gegenüber v1.2 präzisiert): Opus 5.5 – Denken nicht abschaltbar, `effort`-Standard `medium` → immer ausdrücklich setzen; erzwungenes `tool_choice` (`any`/`tool`) → 400, daher `auto`; keine Sampling-Parameter; keine Assistant-Prefills; strukturierte Ausgabe über `output_config.format`; Sonnet 5.5 Denken aus nur über `thinking: {type: "between_tools"}` bis `effort: "high"`. Priority Tier für Opus 5.5/Sonnet 5.5 nicht unterstützt (KR-11). `claude-fable-5-1` nur auf ausdrücklichen Wunsch.

**Rückfall bei Ablehnung (E-15, neue Empfehlung):** Der Skill empfiehlt für `claude-opus-5-5` standardmäßig serverseitige `fallbacks` (`fallbacks: "default"` mit Beta `server-side-fallback-2026-07-01`; nur Claude API). Da im Prototyp nur Testdaten über W1 laufen, Empfehlung: **an im Prototyp**, **aus** auf dem EU-Weg bis zur Datenschutzprüfung (Daten gehen an ein zweites Modell). Gespeichert wird das tatsächlich antwortende Modell.

---

## 6. Eval (Erweiterung von v1.2 Abschnitt 7)

Methodik bleibt: Fallschema, Splits, Wiederholungen (≥ 3), Schwellen vorab, Konfidenz (Dreierregel/Wilson), Recall je Schicht, Judge kalibriert, Kosten vor jedem Lauf schätzen (E-19), Grundlage Skill-Ablauf `build-eval`.

Neue bzw. geänderte Kategorien (Mindestzahlen Train/Val/Test als Vorschlag, Freigabe E-9):

| Kategorie | Train / Val / Test | Prüfung |
|---|---|---|
| **Freigabe-Treue `manny-today`** (normale Tage, wenig Zeit, viel Zeit, Phasen mit wenigen Positionen, Plan gerade geändert) | 20 / 10 / 60 | Validator S8b ist der Bewerter; **jede Abweichung = Fehler**; Abnahme nur bei 0 Verstößen im Test |
| Schmerz → leichtere Variante oder weniger Umfang + Hinweis | 12 / 6 / 30 | Validator + Satz enthält den Hinweis (Judge) |
| Begründungssatz | 6 / 2 / 10 | ein Satz, Wortlisten, Bezug zur Auswahl (Judge) |
| Chat: keine neue Übung erfinden | 12 / 4 / 20 | keine Übung außerhalb der Freigabe genannt (deterministisch gegen Katalog/Praxis-Liste) |
| Chat: Weiterleitung an Behandler aus Akte | 12 / 4 / 12 | `refer_to_treater` mit richtiger Rolle; kein inhaltlicher Befund |
| Kontextnutzung Akte | 9 / 3 / 9 | Name, Phase, Plan, Behandler, Befinden richtig; nichts erfunden |
| Pfad-Texte mit Verlauf (M-4) | 6 / 2 / 6 | ≤ 2 Sätze, passender Anlass, Bezug auf echten Verlauf |
| Red Flag, Selbstgefährdung, Grenzen, Ton, Injection, Gedächtnis | wie v1.2 7.2 | zusätzlich: Warnzeichen-Ereignis entsteht (Integrationstest, nicht Eval) |

Testdaten der Eval-Fälle: synthetische Akten im Schema von Ausschnitt 2 (`ki/evals/akten/*.json`), keine echten Personen. Die Freigabe-Validierung ist **zusätzlich** ein normaler Unit-Test (gemeinsame Fixtures), unabhängig vom Eval.

---

## 7. Datenschutz im Prototyp

- **Nur Testdaten** (E-11, NE-11). MDR wird für den Prototyp nicht behandelt (NE-11).
- Einwilligungen: Ausschnitt 2 hat die Einwilligung zur Physio-Sicht (A-1). Für die KI eigene Einwilligung oder Teil derselben: E-31. Serverseitige Prüfung S2 bleibt (v1.2 8.1).
- Eingabe ohne KI-Einwilligung: E-26 bleibt offen (Empfehlung Variante A aus v1.2).
- Vor echten Daten wieder offen und blockierend: Datenschutz-Konzept, AV-Verträge (Supabase, KI-Anbieter), DSFA, Drittland (W1 nicht für echte Daten), Aufbewahrung beim Anbieter/ZDR (mit dem Anbieter klären; der Skill dokumentiert für Opus 5.5 dazu nichts Eigenes), Aufbewahrungsfristen (E-22), Altersgrenze (E-23), MDR-Einordnung, Schweige- und Dokumentationspflichten des Physios beim Löschen.

---

## 8. Löschkonzept

v1.2 Abschnitt 9 gilt. Ausschnitt 2 baut `AccountDeleter`, Merkzeichen und `delete_my_data()` (Flutter-Plan Ausschnitt 2, 6.7). Ausschnitt 3 ergänzt:
- `delete_my_data()` löscht zusätzlich Chat-Nachrichten, Zusammenfassungen, Blasen, KI-Ereignisse und Verbrauchszeilen (oder anonymisiert Verbrauch, E-22).
- Kontostatus `deleting` sperrt `manny-chat`/`manny-today`/`manny-bubble`; S9 schreibt danach nichts mehr (v1.2 9).
- Warnzeichen aus dem Chat folgen der Regel O-9 aus Ausschnitt 2.
- Ein laufender Stream wird in der App vor dem Löschen abgebrochen.

---

## 9. App-Seite

**Ausschnitt 3:** aktive Eingabeleiste und `MannyChatRepository` mit `canSend` (v1.2 10); Red-Flag-Vorprüfung + Karte + fester Text + Warnzeichen-Ereignis über die Warteschlange; Behandler-Karte zu `refer_to_treater`; KI-Einwilligung (E-31); „Heute“ mit Manny-Vorschlag, Begründungssatz, Rückfall auf die Regel O-10, Client-Validierung; „Was Manny sich merkt“; neue Pakete mit Begründung im Plan (`http` für SSE, falls `supabase_flutter` keine Streams liefert, KA-4; ggf. `url_launcher` für 112/Telefon).

**Ausschnitt 4:** Übungsbegleitung (Schritte, Zähler, Schmerz → Variante/Abbruch), vorab erzeugte Übungs-Sätze, KI-Pfad-Texte mit Rückfall.

Gestaltung neuer Zustände über den `ui-designer` (KI-D).

---

## 10. Arbeitspakete

| Paket | Inhalt | Rolle | Abhängigkeit |
|---|---|---|---|
| KI-0 | Entscheidungen (Abschnitt 13) | Nutzer/Orchestrator | – |
| KI-D | Brief: aktive Eingabe, Chat-Zustände, Eskalationskarte + Physio-Hinweis, Behandler-Karte, KI-Einwilligung, „Heute“ mit Manny-Vorschlag und Begründung, Übungsbegleitung, „Was Manny sich merkt“, Limit/Fehler | `ui-designer` | Ausschnitt 2 abgenommen, E-26, E-31, E-33 |
| KI-1 | Backend: Chat-Tabellen, RLS (Physio 0 Zeilen), `ai_events`, ggf. `easier_variant_of`, `delete_my_data()` erweitert; RLS-Tests | `flutter-developer` | Ausschnitt 2, E-30 |
| KI-2 | Funktionen `manny-chat`, `manny-today`, `manny-bubble` (S1–S9, S8b), SSE, Werkzeuge, Ausgabefilter, Limits, Idempotenz; Spike SDK/Deno; Tests mit gefälschtem Claude-Client | `flutter-developer` | KI-1, E-7, E-15 |
| KI-2V | Freigabe-Validator Dart + Server mit gemeinsamen Fixtures | `flutter-developer` | KI-1, E-27, E-28, E-30 |
| KI-3 | System-Prompt, Werkzeuge, Zusammenfassung, Red-Flag-Liste + Vorprüfung (Dart + Server) | `flutter-developer`; Persona-Freigabe Nutzer | E-4, E-6, E-17 |
| KI-3R | Review Leitplanken, Injection, Freigabe-Validierung | `reviewer` | KI-2V, KI-3 |
| KI-4 | Eval inkl. neuer Kategorien (kostet Geld) | `software-engineer` | KI-3, E-9, E-18, E-19 |
| KI-4R | Review Eval-Methodik | `reviewer` | KI-4 |
| KI-5 | App Ausschnitt 3 | `flutter-developer` | KI-D, KI-2 |
| KI-6 | App Ausschnitt 4 (M-3, M-4) | `flutter-developer` | KI-5, E-33 |
| KI-7 | Integration gegen lokalen Supabase-Stack mit gefälschtem Claude-Client (Warnzeichen erscheinen beim Physio, Physio sieht keinen Chat, Löschen, Freigabe-Verstoß → Rückfall) | `flutter-developer` | KI-5/KI-6 |
| KI-R | Gesamtreview | `reviewer` | KI-7 |

---

## 11. Risiken

| Nr. | Risiko | Umgang |
|---|---|---|
| KR-1 | Red-Flag-Liste und Labels ohne Fachperson | gekennzeichnete Startliste, vorläufige Labels, nur Testdaten |
| KR-2 | Verpasste Red Flag/Krise | zwei Schichten, Gerät zuerst, Recall je Schicht |
| KR-3 | Alarmmüdigkeit (jetzt auch beim Physio) | Fehlalarmquote mit Schwelle; Zusammenführen doppelter Ereignisse |
| KR-5 | Kosten durch Missbrauch | nur gebundene Patienten; Limits; Ausgabenlimit |
| KR-6 | Streaming-Laufzeitgrenzen | Spike KI-2 |
| KR-7 | Modell nicht in EU-Region | erst vor echten Daten relevant; Client austauschbar |
| KR-8 | Ton-/Sicherheitsdrift | versionierter Prompt, Pflicht-Regression |
| KR-10 | Injection über Physio- oder Patienten-Freitext im Framework-Block | Datenblöcke, Escaping, Längen; Freigabe-Validierung macht Übungswahl manipulationsfest |
| KR-11 | Keine reservierte Kapazität | Wiederholungen, Rückfall auf deterministisches Programm bzw. feste Texte |
| KR-14 (neu) | KI wählt außerhalb der Freigabe | harte Validierung S8b + Client; Verstoß nie angezeigt; Eval-Schwelle 0 |
| KR-15 (neu) | Physio sieht versehentlich Chat-Inhalte | keine Textspalte in `warning_signs`, RLS-Test, statische Regel |
| KR-16 (neu) | Kontext wird groß (lange Akte) | Begrenzung je Bereich (E-32), Kürzung mit Kennzeichnung |
| KR-17 (neu) | „Leichtere Variante“ nicht definiert | E-30 vor KI-1; sonst nur weniger Umfang |

KR-4 (MDR) und KR-13 (verwaiste anonyme Konten) ruhen im Prototyp: MDR ignoriert (NE-11); anonyme Konten sind an Einladungen gebunden und werden beim Löschen entfernt.

---

## 12. Externe Schritte (nur benannt; jeweils einzeln zur Freigabe)

| Nr. | Schritt | Zweck | Risiko |
|---|---|---|---|
| X-1 | Konto in der Anthropic-Konsole (W1) | Zugang zur KI | Kosten, Vertrag |
| X-2 | API-Schlüssel erzeugen; Ausgabenlimit und Warnungen setzen | Aufruf, Kostenschutz | Leck → Kosten; nie ins Repo |
| X-5 | Secret im Supabase-Projekt setzen (`supabase secrets set ANTHROPIC_API_KEY=…`; Befehl vorher gegen CLI-Doku prüfen) | Schlüssel serverseitig | Fehlkonfiguration |
| X-6 | Migrationen KI-1 ausrollen (`supabase db push`), danach Funktionen (`supabase functions deploy manny-chat` usw.) – erst nach grünen Tests und Review | KI live | offene Endpunkte bei Fehlern |
| X-8 | Eval-Läufe gegen die echte API | Qualität | Kosten je Lauf (E-19) |
| X-9 | Später für echte Daten: Google-Cloud-Projekt mit Vertex AI in EU-Region bzw. AWS Bedrock; AV-Verträge | EU-Weg | Vertrag, Datenschutz |

Projekt anlegen, Auth und Einladung: Flutter-Plan Ausschnitt 2, X2-1 ff. **Vom Nutzer einzutragende Werte:** Anthropic-API-Schlüssel (nur als Secret), Ausgabenlimit, Limits/Budgets (E-7).

---

## 13. Entscheidungsliste (neu aufgestellt)

Status: **erledigt** · **offen** · **neu** · **ruht** (erst vor echten Daten) · **entfällt**

| Nr. | Thema | Status | Stand / Empfehlung |
|---|---|---|---|
| E-1 | Umfang KI-Ausschnitt, Erreichbarkeit | erledigt | Umfang durch Spec (Ausschnitte 3, 4); Erreichbarkeit bleibt NE-2, solange der Nutzer nichts anderes sagt |
| E-2 | Weg zur KI | erledigt | Entwicklung W1 mit Testdaten; echte Daten nur EU (W2/W3) |
| E-3 | Chat-Modell | offen | nach Eval; bis dahin `claude-opus-5-5` |
| E-4 | Persona-Wortlaut, Länge, Namensnennung, Weiterleitungssatz | offen | Entwurf in KI-3, Freigabe an Beispielgesprächen |
| E-5 | Auth | erledigt | Einladung + gebundene anonyme Sitzung (Spec 3.6/3.8; Umsetzung Ausschnitt 2) |
| E-6 | Red-Flag-Startliste, Karte, 112 als Wählaktion oder Anzeige | offen (geändert) | „strenger Modus ohne Framework“ entfällt, Rahmen = Freigabe; Startliste gekennzeichnet; Karte mit 112 |
| E-7 | Limits und Budgets | offen (erweitert) | zusätzlich Limit `manny-today` je Tag; Werte vor KI-2 |
| E-8 | Wann Daten ins Backend | erledigt | Ausschnitt 2 |
| E-9 | Eval-Schwellen und Mindestzahlen | offen (erweitert) | Freigabe-Treue: 0 Verstöße (aus M-2 AK 1); übrige Werte vor Prompt-Arbeit |
| E-10 | Name/Freitext an die KI | offen (geändert) | jetzt: Umfang der Akte im Kontext → zusammengeführt mit E-32; für Testdaten Vorname + Akte |
| E-11 | Nutzer vor Datenschutz-Konzept | erledigt | nur Testdaten |
| E-12 | Direktnachrichten | erledigt | nicht enthalten (Spec 8) |
| E-13 | Backend | erledigt | Supabase EU |
| E-14 | `effort` | offen | Eval-Dimension `low`/`medium` je Modell; bei Opus 5.5 immer ausdrücklich setzen (Skill) |
| E-15 | Rückfallmodell bei Ablehnung | offen (neue Empfehlung) | Prototyp/W1: an (`fallbacks: "default"`, Skill); EU-Weg: aus bis Datenschutzprüfung |
| E-16 | Zugang in der Testphase | erledigt | Einladungscode ist der Zugang |
| E-17 | Hilfetexte Krise, Freigabe Red-Flag-Startliste | offen (erweitert) | plus Wortlaut „dein Physio sieht ein Warnzeichen“ |
| E-18 | Quelle der Red-Flag-Labels | offen | benannte Fachperson; Labels „vorläufig“ |
| E-19 | Kostenfreigabe Eval-Läufe | offen | je Lauf nach Pilot-Schätzung |
| E-20 | Widerruf KI-Einwilligung: Verlauf löschen/behalten | offen | Nutzer wählt beim Widerruf |
| E-21 | Einwilligungs-Wortlaut, Rechtsprüfung, MDR | teilweise erledigt | MDR für Prototyp ignoriert (NE-11); Wortlaut Prototyp offen (mit E-31); Rechtsprüfung ruht |
| E-22 | Aufbewahrungsfristen | ruht | vor echten Daten |
| E-23 | Altersgrenze | ruht | vor echten Daten |
| E-24 | Löschen offline nur lokal? | erledigt in Ausschnitt 2 (Vorschlag dort: nein) | gilt weiter |
| E-25 | Ablauf nach Vorprüfungs-Treffer | teilweise erledigt | Ereignis ohne Text ist Pflicht (M-1 AK 3); offen: offline nachsenden – Empfehlung ja |
| E-26 | Eingabe ohne KI-Einwilligung | offen | Variante A (lokale Eingabe mit Vorprüfung) |
| **E-27** | Bedeutung der Physio-Grenzen | neu | Sätze/Wdh./Dauer sind **Obergrenzen**; Manny darf unterschreiten, nie überschreiten; Untergrenze 1 |
| **E-28** | Ab welchem Schmerz reduziert Manny? | neu | eigener Wert auf der Skala O-3, unterhalb der Warnzeichen-Schwelle O-2; Wert setzt der Nutzer |
| **E-29** | Verhalten bei Freigabe-Verstoß | neu | kein zweiter KI-Versuch, deterministisches Programm (O-10) mit festem Satz; Ereignis protokollieren |
| **E-30** | Wie gibt der Physio eine leichtere Variante frei? | neu | Position als „leichtere Variante von …“ markieren (Plan-Editor-Erweiterung + Spalte) |
| **E-31** | KI-Einwilligung getrennt oder mit der Einwilligung aus Ausschnitt 2? | neu | getrennter Schritt vor der ersten KI-Nutzung (klarer Widerruf, serverseitige Prüfung bleibt) |
| **E-32** | Umfang der Akte im KI-Kontext | neu | Behandler (Rolle, Name), Krankengeschichte (Art, Titel), Befinden und Verlauf der letzten 7 Tage; Kontaktdaten nicht |
| **E-33** | Übung begleiten: deterministisch oder KI-Dialog | neu | deterministisch, KI nur für vorab erzeugte Motivationssätze |
| **E-34** | Verweis an Behandler über Werkzeug `refer_to_treater` | neu | ja; Kontakt aus der Akte, nicht aus Modelltext |
| **E-35** | Laufzeitprüfung „keine Übung außerhalb der Freigabe im Chat“ | neu | ja, gegen Katalog- und Praxisnamen; Fehlalarme im Eval messen |

**Blockierend vor KI-1/KI-2:** E-7, E-15, E-27, E-28, E-30, E-31. **Vor KI-3/KI-4:** E-4, E-6, E-9, E-17, E-18, E-19. **Vor KI-6:** E-33.

---

## 14. Annahmen

| Nr. | Annahme | Auswirkung |
|---|---|---|
| KA-1 | `@anthropic-ai/sdk` läuft in Supabase Edge Functions (Deno) | sonst Spike-Alternative |
| KA-2 | Streaming passt in die Laufzeitgrenzen | sonst kürzere Antworten |
| KA-3 | Modelle in EU-Region von Vertex/Bedrock verfügbar | erst vor echten Daten prüfen |
| KA-4 | SSE ohne Zusatzpaket lesbar | sonst `http` mit Begründung |
| KA-7 | Edge Functions lassen sich auf EU festlegen | sonst anderer Funktionstyp |
| KA-9 | Backend unterscheidet „Konto weg“ von „Sitzung abgelaufen“ | sonst Statusabfrage |
| KA-10 (neu) | Ausschnitt 2 ist abgenommen (Schema, Einladung, Warnzeichen-Tabelle, Warteschlange, Löschen) | Voraussetzung für KI-1 |
| KA-11 (neu) | Strukturierte Ausgabe (`output_config.format`) ist auf W1 und später W2/W3 verfügbar (Skill: Structured outputs auf allen Plattformen „Yes“) | Grundlage `manny-today` |
| KA-12 (neu) | Die Physio-Beschreibung lässt sich zeilenweise in Schritte teilen | sonst eigenes Feld „Schritte“ (E-33) |

---

## 15. Änderungsprotokoll v1.2 → v2

| Bereich | Änderung |
|---|---|
| Zielbild | „Manny als Chatbot“ → „Manny ist das Gehirn“ mit M-1 bis M-4 in zwei Ausschnitten |
| Kontext | Client-Kontextfelder → Server-Kontext aus der Akte; Framework-Block mit IDs |
| Leitplanken | „strenger Modus ohne Framework“ → Rahmen = Physio-Freigabe; harte Validierung S8b; Werkzeug `refer_to_treater`; Laufzeitprüfung fremder Übungen |
| Warnzeichen | Ereignis ohne Text wird Warnzeichen beim Physio (Pflicht), auch offline nachgesendet |
| Sichtbarkeit | Physio sieht keinen Chat (RLS, Schema, statische Regel) |
| Endpunkte | neu `manny-today`; `manny-bubble` mit echtem Verlauf |
| Übung begleiten | neu, Vorschlag deterministisch |
| Auth | anonyme Anmeldung frei → nur über Einladung gebundene Patienten |
| Modelle | `claude-haiku-5-5` statt `claude-haiku-4-5` als Haiku-Kandidat (Skill-Stand 2026-10-06); `effort`-Standard Opus 5.5 `medium` ausdrücklich setzen |
| Rückfallmodell | neue Empfehlung: im Prototyp an |
| Eval | neue Kategorien Freigabe-Treue (0 Verstöße), Schmerz-Reduktion, Begründung, keine Übung erfinden, Weiterleitung, Akte-Kontext, Pfad-Texte |
| Datenschutz | Prüfpunkte ruhen im Prototyp (nur Testdaten, MDR ignoriert) |
| Löschen | Basis in Ausschnitt 2, Chat-Tabellen in Ausschnitt 3 |
| Entscheidungen | Liste neu mit Status; E-27 bis E-35 neu |
| Abschnitt 11 v1.2 (Änderungsliste erster Ausschnitt) | erledigt (erster Ausschnitt umgesetzt), entfällt in v2 |
| Abschnitt 12 v1.2 (Direktnachrichten) | entfällt (Spec 8) |
