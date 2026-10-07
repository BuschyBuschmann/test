**Spec 8: Health Social Media (v1)**

**Problem**

Reha ist einsam. Wer sich das Kreuzband gerissen hat, kennt im eigenen
Umfeld oft niemanden, der denselben Weg gerade geht oder gegangen ist.
Gleichzeitig sehen Freunde und Familie nur von außen, dass es dem
Verletzten schlecht geht, und wissen nicht, wie sie helfen oder wie weit
er wirklich ist. Specs 1--7 sehen keine Anbindung anderer Personen
vor: Spec 3 schließt das Live-Sharing des Reha-Pfads mit Freunden und
Familie ausdrücklich aus, Spec 5 den Vergleich mit anderen Nutzern.
Teilen ist bisher nur punktuell möglich (PDF-Export per Share-Sheet,
Spec 5 und 6).

**Lösung**

Ein sozialer Bereich in der App mit zwei Teilen:

1.  **Community unter Patienten:** Ein Austausch von Patienten
    untereinander, bezogen auf Verletzungstypen (zunächst Kreuzbandriss /
    ACL; wie es mit den übrigen Verletzungstypen weitergeht, siehe
    Offene Fragen).
2.  **Freunde & Familie anbinden:** Der Patient kann Menschen aus seinem
    Umfeld einbinden. Sie können ihn unterstützen und seinen Fortschritt
    sehen.

Der Austausch zwischen Patient und Physio ist ausdrücklich **nicht** Teil
dieser Spec (siehe Out of Scope).

*Hinweis zur Form:* Die konkrete Ausgestaltung der Plattform ist vom
Auftraggeber bewusst noch offen gelassen (\"die Assoziation damit ist
noch ein bisschen frei\"). Diese Spec legt daher nur den Rahmen fest, der
aus dem Nutzerwunsch folgt. Alles Weitere steht unter Offene Fragen.

**Nutzer-Story**

*Community:* Als Patient mit einer Verletzung möchte ich mich mit anderen
austauschen können, die dieselbe Verletzung haben, damit ich
mich mit meiner Reha nicht allein fühle.

*Freunde & Familie:* Als Patient möchte ich Freunde und Familie anbinden
können, damit sie mich unterstützen und meinen Fortschritt sehen können.

**Acceptance Criteria**

**Community unter Patienten:**

-   Es gibt einen Community-Bereich in der App, in dem Patienten sich
    untereinander austauschen können

-   Die Community ist nach Verletzungstyp gegliedert; beim Launch
    existiert sie für **Kreuzbandriss (ACL)**

**Freunde & Familie anbinden:**

-   Der Patient kann Personen aus seinem Umfeld (Freunde, Familie) an
    seine Reha anbinden

-   Angebundene Personen können den Patienten unterstützen (Form der
    Unterstützung: siehe Offene Fragen)

-   Angebundene Personen können den Fortschritt des Patienten sehen (Umfang
    der sichtbaren Daten: siehe Offene Fragen)

-   Der Patient kann angebundene Personen jederzeit wieder entfernen

*Hinweis:* Die Kriterien \"unterstützen\" und \"Fortschritt sehen\" sind
erst abnahmefähig, wenn die zugehörigen offenen Fragen (Form der
Unterstützung, Sichtbarkeitsstufen) geklärt sind.

**Anpassung bestehender Specs:**

-   Der Ausschluss \"Live-Sharing des Reha-Pfads mit Freunden und Familie
    (Invite-System zum eigenen Verletzungsverlauf)\" aus **Spec 3 (Out of
    Scope)** entfällt und wird durch Spec 8 abgedeckt

-   Der Ausschluss \"Vergleich mit anderen Nutzern\" aus **Spec 5 (Out
    of Scope)** entfällt bzw. wird durch Spec 8 angepasst. Ob und in
    welcher Form Nutzer-Vergleiche entstehen, ist offen (siehe Offene
    Fragen)

**Out of Scope**

-   **Chat zwischen Patient und Physio:** Der Austausch Patient--Physio
    ist laut Auftraggeber der Hauptaustausch und gehört \"eher in den
    Reha-Bereich\". Ein eigener Chat zwischen beiden muss möglich sein,
    ist aber nicht Teil von Spec 8. Ob er als eigene Spec oder als
    Erweiterung einer bestehenden Spec beschrieben wird, ist offen.
    Hinweis: **Spec 4 führt \"In-App Chat mit Physio\" aktuell als Out of
    Scope**; diese Abgrenzung ist bei Ausarbeitung des Chats
    anzupassen

-   Ansicht oder Funktionen für Physio, Freunde oder Familie als eigene
    Nutzergruppe mit eigenem Konto-Konzept über das hinaus, was für die
    Anbindung nötig ist (Spec 8 beschreibt nur die Patientensicht)

-   Design und Screens (werden separat erarbeitet)

**Offene Fragen**

Die folgenden Punkte sind vom Auftraggeber nicht festgelegt. Die
genannten Optionen sind **Vorschläge zur Entscheidung**, keine
beschlossenen Anforderungen.

*Community*

-   **Form des Austauschs:** Was ist die Community konkret (z. B. Feed
    mit Beiträgen, Forum/Themen, Gruppenchat, Erfahrungsberichte)? ---
    Vorschlag: Entscheidung vor Design-Start; Auswirkung auf Aufwand und
    Moderation ist erheblich

-   **Anonymität / Pseudonyme:** Auftreten mit Klarnamen, Pseudonym oder
    frei wählbar? Dazu gehört, ob der in Spec 1 erfasste Name nach außen
    sichtbar ist. --- Vorschlag: Pseudonym als Standard prüfen, da
    Gesundheitsbezug (Art. 9 DSGVO)

-   **Moderation:** Wer moderiert, wie werden Meldungen und Verstöße
    behandelt, gibt es Regeln für die Community?

-   **Medizinische Ratschläge unter Patienten:** Wie wird verhindert,
    dass Nutzer sich gegenseitig Diagnosen oder Medikamentenempfehlungen
    geben, die im Widerspruch zu Physio-Framework und Spec 4/7 stehen? ---
    Vorschlag: Community-Regeln plus Hinweistext analog zum
    Haftungs-Disclaimer in Spec 4 und 7; weitere Maßnahmen offen

-   **Verbindung zu Reha-Daten:** Dürfen Beiträge auf eigene Reha-Daten
    verweisen (Phase, Wochen seit OP, Meilensteine)? Wenn ja, was ist
    freigabepflichtig? --- Vorschlag: nur aktiv vom Patienten
    freigegebene Angaben

-   **Vergleich mit anderen Nutzern (Spec 5):** Soll es überhaupt
    Vergleichsfunktionen geben (z. B. \"andere in Woche 6\")? Falls ja:
    welche Daten, anonymisiert oder aggregiert?

-   **Zugang und Abdeckung beim Launch:** Spec 1 bietet beim Launch
    ACL / Bänderriss Sprunggelenk / Muskelfaserriss / Andere; die
    Community existiert zunächst nur für ACL. Was sehen Patienten mit
    Sprunggelenk, Muskelfaserriss oder \"Andere\" im Community-Bereich
    (z. B. Hinweis, Warteliste, allgemeiner Bereich, Bereich nicht
    sichtbar)? Wie und wann erhalten weitere Verletzungstypen eine
    Community? Wie wird der Zugang bestimmt (Verletzungstyp aus
    Onboarding, Spec 1 Schritt 3)? Nur eigener Verletzungstyp oder auch
    Einsicht in andere Communities? Zugang schon vor Onboarding-Ende?
    Gehören genesene Nutzer (z. B. in der Präventions-Phase, Spec 6)
    dazu? --- Vorschlag: Zugang über den Verletzungstyp aus dem
    Onboarding; übrige Punkte offen

-   **Altersgrenzen:** Mindestalter für Community und Datenfreigabe?
    Umgang mit minderjährigen Patienten und Einwilligung der
    Erziehungsberechtigten --- mit Anwalt klären

*Freunde & Familie*

-   **Einladungsmechanik:** Wie wird jemand angebunden (z. B. Link,
    Code, Kontaktsuche, Teilen über WhatsApp)? Braucht die eingeladene
    Person die App oder genügt ein Link/Web-Ansicht? --- Vorschlag:
    Einladung über Share-Sheet (wie in Spec 5 für den PDF-Export); Konto-
    Pflicht offen

-   **Sichtbarkeitsstufen:** Was genau sehen Freunde und Familie
    (Reha-Pfad, Streak, Sessions, Schmerzkurve, Symptome)? Gleiche
    Sicht für alle oder pro Person einstellbar? --- Vorschlag:
    grobe Stufen (z. B. nur Pfad und Streak vs. mehr), Schmerz- und
    Symptomdaten standardmäßig nicht sichtbar. Entscheidung offen

-   **Form der Unterstützung:** Wie unterstützen sie (z. B.
    Nachrichten, Reaktionen, Anfeuern bei Streaks/Meilensteinen,
    Erinnerung)? --- Vorschlag: bewusst kleine, positive Interaktionen
    prüfen; keine Pflicht für den Patienten zu antworten

-   **Push-Notifications:** Werden Angebundene bei Meilensteinen
    benachrichtigt? Werden dem Patienten Reaktionen gemeldet? (Bezug:
    Ruhezeiten und einzelne Ein/Aus-Schalter aus Spec 3)

-   **Live vs. Zusammenfassung:** Sehen Angebundene den Pfad live oder
    nur ausgewählte Meilensteine bzw. die Wochenzusammenfassung aus
    Spec 5? Ist der PDF-Export aus Spec 5/6 für diese Zielgruppe
    relevant?

-   **Anzahl und Verwaltung:** Gibt es eine Obergrenze für angebundene
    Personen? Wie sieht der Patient, wer was sieht?

*Rolle von Manny*

-   Hat Manny in Spec 8 eine Rolle (z. B. Hinweise zur Community,
    Vorschlag, Freunde einzuladen, Meilenstein-Teilen), und wie weit
    reicht sein Wissen über Community-Inhalte? Spec 7 begrenzt Manny
    auf das Physio-Framework --- ein Zugriff auf Community-Beiträge
    wäre eine Erweiterung. --- Vorschlag: zunächst keine Manny-Rolle
    festlegen

*Datenschutz und Recht*

-   **DSGVO / Art. 9:** Gesundheitsdaten sind besondere Kategorien
    personenbezogener Daten. Rechtsgrundlage, Einwilligungstext,
    Verantwortlichkeiten für Community-Inhalte und Freigabe an Dritte
    sind mit Anwalt zu klären --- Vorschlag: vor Entwicklungsstart,
    wie das Datenschutz-Konzept in Spec 1

-   **Standard-Sichtbarkeit, Freigabe-Consent und Löschung:** Sind
    Daten standardmäßig nur für den Patienten sichtbar (Spec 1--7
    regeln das nicht ausdrücklich; Teilen per PDF/Share-Sheet gibt es
    bereits, Spec 5 und 6) und ist die Freigabe
    an Dritte ein eigener, dokumentierter (Timestamp + Version),
    widerrufbarer Consent analog Spec 1 Schritt 2? Was passiert bei
    Konto-Löschung oder Consent-Widerruf mit Community-Beiträgen und
    Freigaben (löschen, anonymisieren)? --- Vorschlag: ja, privat als
    Standard und eigener Consent; Löschregel offen

-   **Haftung:** Haftungs-Disclaimer für Community und Freigaben (analog
    Spec 4 / 7) --- Wortlaut offen

-   **Datenspeicherung:** Wo und wie lange werden Community-Inhalte und
    Freigaben gespeichert (Bezug: Die Rollback-Pläne von Spec 1 und
    Spec 4 nennen lokale Speicherung)? Community und Anbindung erfordern
    voraussichtlich serverseitige Speicherung --- Entscheidung offen

*Sonstiges*

-   **Name der Funktion** in der App (\"Health Social Media\" ist der
    Arbeitstitel)

-   **Messung des Erfolgs:** Woran wird gemessen, ob Community und
    Anbindung ihren Zweck erfüllen? (Keine Kennzahlen vom Auftraggeber
    vorgegeben)

**Aufwand**

**XL (Einschätzung)** --- Community-Funktionen (ggf. mit Moderation, siehe Offene
Fragen) + Einladungs- und Freigabe-System für Dritte +
Rechte-/Sichtbarkeitslogik auf bestehenden Reha-Daten +
voraussichtlich serverseitige Speicherung (Entscheidung offen) +
DSGVO-Konzept für Gesundheitsdaten. Die Einschätzung ist vorläufig und
hängt stark von den Entscheidungen in Offene Fragen ab (z. B. Form der
Community, Moderationsmodell).

**Abhängigkeiten**

-   Spec 1: Verletzungstyp als Zuordnung zur Community; Consent-Mechanik
    als mögliches Vorbild für eine Freigabe an Dritte (offen); Name/Datenschutz

-   Spec 3: Reha-Pfad und Streak als mögliche Inhalte der
    Freunde-/Familien-Ansicht; Ausschluss \"Live-Sharing\" entfällt

-   Spec 5: Fortschrittsdaten (Schmerzkurve, Sessions, Phase,
    Wochenzusammenfassung) als mögliche Inhalte der Freigabe;
    Ausschluss \"Vergleich mit anderen Nutzern\" entfällt bzw. wird
    angepasst

-   Spec 7: Abgrenzung der Manny-Rolle; DSGVO-Konzept für
    Gesprächs-Speicherung als Referenz

-   Datenschutz-Konzept (Anwalt) für Community und Freigabe von
    Gesundheitsdaten --- Vorschlag: vor Entwicklungsstart, als Blocker einzustufen

-   Entscheidung über Moderationsmodell (Vorschlag: als Blocker
    einstufen)

-   Chat Patient--Physio (nicht Teil von Spec 8, aber inhaltlich
    benachbart; eigene Spec oder Erweiterung einer bestehenden Spec,
    offen)

-   Texte der Specs 3 und 5 (Out of Scope) sind entsprechend Spec 8
    anzupassen --- nicht Teil dieser Spec-Datei

-   Voraussichtlich Backend mit serverseitiger Speicherung
    (Entscheidung offen; die Rollback-Pläne von Spec 1 und Spec 4
    nennen lokale Speicherung)

**Rollback-Plan**

Community-Zugang und Anbindung von Freunden/Familie sind
abschaltbar, ohne Reha-Pfad, Programm und Fortschritt (Specs 1--7) zu
beeinträchtigen. Der Patient kann angebundene Personen jederzeit
entfernen. Weitere Regeln zu Widerruf, Sichtbarkeit nach Entfernen und
Löschung von Community-Beiträgen: siehe Offene Fragen.
