## App-Prüfung: CuraOne, erster Ausschnitt – 2026-10-11

**Geprüft über:**
- Web-Build der echten App (`lib/main.dart`) in Chromium über Playwright und den Semantik-Baum, bei 390×844 und Stichproben bei 320×568.
- Simulierte Uhr für Tageswechsel, verpasste Tage, Reset und Abend.
- Kaputter Browser-Speicher in 5 Varianten.
- Tastatur (Tab, Enter, Escape).
- Code ergänzend gelesen.

**Nicht geprüft:**
- Android-Zurück (nur im Code gelesen).
- Echte Geräte, TalkBack und VoiceOver.
- Große Systemschrift (im Web nicht einstellbar).
- Landscape.
- Datumsauswahl per Texteingabe.
- Tageswechsel bei laufender App: Mit der simulierten Uhr war das Ergebnis unklar. Per Reload am Folgetag ist der Wechsel bestätigt.

Screenshots: Scratchpad `app-pruefung/` (nicht im Repository).

### 🔴 Blockiert Nutzer
- **Verletzungstypen ohne eigenen Pfad**
  - Was passiert: Wer im Onboarding oder in „Deine Daten“ Sprunggelenk, Muskelfaserriss oder „Anderes“ wählt, bekommt denselben Kreuzband-Pfad und dasselbe Programm. Nur die Kopfzeile ändert sich. Es gibt keinen Hinweis.
  - Belege: `19d-muskel.png`, `19e-gespeichert.png`, `path_generator.dart:160-176`.
  - Vorschlag: einen Hinweis „Für diese Verletzung gibt es noch keinen eigenen Pfad“ anzeigen oder nur ACL anbieten.
  - Einordnung: Mit der Spezifikation „Manny als Gehirn“ kommt der Plan künftig vom Physio, dann entfällt der Punkt.

### 🟡 Reibung
- **Eintrag nur 8 s rückgängig**
  - Was passiert: Nach „Training eintragen“ endet das Rückgängig nach 8 s oder beim Tabwechsel. Danach ist „Heute erledigt“ dauerhaft, und ein Fehltipp verfälscht Streak und Pfad. Das war im früheren Check schon Lücke V1.
  - Belege: `14a-erledigt-reload.png`, `transient_ui.dart:34-52`.
  - Vorschlag: Rücknahme bis Tagesende, über „Heute erledigt“ antippbar.
- **Freezes und Streak unerklärt**
  - Was passiert: Die Chips „❄ 2“ und „🔥 0“ sind nicht antippbar. Den Verbrauch eines Freezes meldet die App nicht. Nach einem Reset bleibt die Anzeige bei „❄ 0“.
  - Belege: `16a-nach-2-verpasst.png`, `17a-reset.png`.
  - Vorschlag: Ein Tipp auf die Chips erklärt sie. Manny meldet, wenn ein Freeze eingesetzt wurde.
- **„Training starten“ startet nichts**
  - Was passiert: Der Button öffnet nur „Wie willst du trainieren?“. Dort ist nur „Manuell“ wählbar, danach folgt ein zweiter Button.
  - Belege: `12a-modus-sheet.png`.
  - Vorschlag: Solange nur manuell geht, den Button „Training eintragen“ nennen.
- **Übungen ohne Anleitung**
  - Was passiert: Die Karten zeigen nur Name und Umfang, ein Antippen tut nichts.
  - Belege: `10a-tap-card.png`.
  - Vorschlag: ein Detailsheet mit Kurzbeschreibung. Ist in der neuen Spezifikation als A-2 vorgesehen.
- **„Erledigt“ ohne Training**
  - Was passiert: Vergangene Kalenderwochen gelten als erledigt, auch ohne Training. Das ist die bekannte Grenze K-1.
  - Belege: `06b-nach-onb.png`, `path_generator.dart:140`.
  - Vorschlag: Hinweis „Beispielpfad folgt dem Kalender“.
- **Datumsfrage doppeldeutig**
  - Was passiert: „Wann war die Verletzung oder OP?“ fragt nach nur einem Datum. Unklar, welches gemeint ist.
  - Belege: `04-schritt4.png`.
  - Vorschlag: klarstellen, welches Datum zählt.
- **Speichern ohne sichtbare Bestätigung** in „Deine Daten“. Nicht abschließend geklärt. Beleg: `19e-gespeichert.png`.
- **Automatisches Löschen unlesbarer Daten**, auch bei neuerem Datenstand. Das ist eine bewusste Entscheidung und hier als Risiko genannt. Belege: `corrupt-garbage.png`, `corrupt-newer.png`.
- **Fokus und erste Karte unter der Button-Gruppe** bei 320×568. Belege: `31a-focus.png`, `32b-heute-320.png`.
- **Kleinigkeiten:**
  - Das Mikrofon-Feld steht auch auf den Schritten zu Einwilligung und Datum.
  - Eine ungültige Dauer bei „Eigene Übung“ wird ohne Meldung zu 5 Min.
  - „Return to Sport“ und „Wochenziel“ werden nicht erklärt.
  - „Tauschen“ lässt sich nicht rückgängig machen.
  - Tauschen und Entfernen bleiben aktiv, wenn das Training erledigt ist.
  - „Weiter“ ist bei leerem Namen ohne Hinweis deaktiviert.

### 🔵 Lücken im Funktionsumfang (gegen `curaone-vollstaendigkeit.md`)
- **Umgesetzt und bestätigt:**
  - Daten löschen
  - Profil ändern
  - Rückgängig (zeitlich begrenzt)
  - Tageswechsel
  - Pfad-Tipps
  - Freeze-Regel
  - Abendhinweis
  - Android-Zurück (nur im Code)
- **Offen:**
  - Die Datenschutzerklärung ist nach dem Onboarding nicht mehr erreichbar und noch ein Platzhalter.
  - Hilfe, Feedback, Version und Impressum fehlen.
  - Zurücksetzen des Tagesprogramms ist nicht erklärt.
- **Bewusst später:**
  - KI-Antworten und Chat-Eingabe
  - Direktnachrichten
  - Push
  - Konto und Sync
  - Export
  - eigene Termine
  - Passiv- und Aktiv-Training
  - Freezes verdienen
  - Präventionsphase

### ✅ Was gut gelöst ist
- Das Onboarding ist ohne Anleitung verständlich: Schritt X von 4, Zurück behält die Eingaben, Fortsetzen nach Reload.
- Platzhalter sind klar gekennzeichnet (Beispielpfad, Beispieltermin, Beispielverlauf, Disclaimer).
- Chat und Nachrichten können nicht fälschlich als funktionierend wirken.
- Feier, Streak-Zählung, Abend- und Reset-Text sind verständlich.
- Den Leerzustand „Heute“ gibt es, mit einem Weg weiter.
- Verwerfen- und Löschdialog sind klar.
- Kaputter Speicher führt zu klarem Hinweis und Neustart, ohne Absturz.
- Die Tastaturbedienung ist logisch, der Fokusring sichtbar.
- Die Semantik-Labels sind vollständig.
- Es gab keine Konsolenfehler.

### Offene Fragen
1. Sollen andere Verletzungstypen bis Ausschnitt 2 weiter den Kreuzband-Pfad zeigen, und mit welchem Hinweis?
2. Soll Rückgängig nach dem Eintragen länger möglich sein?
3. Sollen vergangene Wochen ohne Training weiter „erledigt“ heißen (K-1)?
4. Soll „Training starten“ umbenannt werden?
5. Sollen Kurzanleitungen schon vor Ausschnitt 2 kommen?
6. Bleibt das automatische Löschen unlesbarer Daten so?
