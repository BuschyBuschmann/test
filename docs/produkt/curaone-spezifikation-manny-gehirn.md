# CuraOne – Spezifikation „Patienten-Framework und Manny als Gehirn“

Status: FREIGEGEBEN (2026-10-11) · Stand 2026-10-11 · Grundlage für KI-Plan v2 und Flutter-Plan der Ausschnitte 2 bis 4

## 1. Zielbild

Manny ist das Gehirn der App. Er kennt zu jedem Patienten ein **Patienten-Framework**. Darin stehen Behandler, Krankengeschichte, der Plan vom Physio mit den freigegebenen Übungen sowie Befinden und Verlauf. Aus diesem Framework hilft Manny motivierend und alltagsnah: im Chat, beim Zusammenstellen des Tagesprogramms, beim Begleiten einer Übung und mit persönlichen Texten auf dem Pfad. Medizinisch bewegt er sich nur innerhalb dessen, was der Physio freigegeben hat. Weitere Funktionen sollen später ebenfalls auf Manny aufbauen.

**Rahmen:** CuraOne ist ein **Prototyp zur Präsentation**. Er arbeitet nur mit Testdaten (vorbereitete Testpraxen und Testpatienten). Die Frage, ob die App ein Medizinprodukt ist (MDR), wird für den Prototyp bewusst nicht behandelt.

## 2. Rollen

| Rolle | Zugang | Darf |
|---|---|---|
| **Physio** | eigener Web-Zugang, schlank | Patienten anlegen und einladen, Plan aus Katalog und eigenen Übungen zusammenstellen, Grenzen setzen, Behandler und Krankengeschichte pflegen, Verlauf und Warnzeichen sehen |
| **Patient** | App, nur mit Einladung des Physios | eigenen Plan nutzen, Befinden melden, Termine und Dokumente ergänzen, mit Manny sprechen |
| **Arzt** | kein Zugang | erscheint nur als Behandler-Eintrag mit Kontakt und Terminen |
| **Manny (KI)** | – | nutzt das Framework, wählt und passt nur innerhalb der Physio-Freigabe an, leitet alles andere weiter |

## 3. Nutzerentscheidungen (2026-10-11)

1. Den Plan und die Übungen pflegt der **Physio über einen eigenen Zugang**. Der Patient ergänzt Befinden, Termine und Dokumente.
2. Manny wählt und passt **nur innerhalb der Freigabe** an, z. B. mit einer leichteren Variante bei Schmerz. Er erfindet keine Übungen. Alles andere geht als Frage an den Physio.
3. Daten im Framework: Plan und freigegebene Übungen, Behandler, Krankengeschichte, Befinden und Verlauf.
4. Manny hilft im Chat, beim Zusammenstellen von „Heute“, beim Begleiten einer Übung und mit den Texten auf dem Pfad.
5. Der Physio sieht Verlauf und Warnzeichen, **nicht** den Manny-Chat. Der Patient wird darüber informiert und stimmt zu.
6. Die App ist **nur mit Physio nutzbar**. Der Zugang läuft über eine Einladung.
7. Übungen kommen aus einem **CuraOne-Katalog** (geprüfte Beschreibung, später Video) und aus **eigenen Übungen des Physios**.
8. Verbindung: Der **Physio lädt ein** (legt den Patienten an, Code oder Link per QR, SMS oder Mail). Der Patient gibt den Code ein und landet in seinem Plan.
9. Ärzte erscheinen nur als Eintrag.
10. Umsetzung in drei Ausschnitten: **2 Fundament → 3 Manny-KI (Chat, Heute) → 4 Übung begleiten, KI-Texte auf dem Pfad**.
11. MDR wird vorerst ignoriert (Prototyp zur Präsentation).
12. Physio-Seite: **echt, aber schlank**, mit vorbereiteten Testpraxen und Testpatienten.
13. Technik (aus den KI-Entscheidungen): Supabase in der EU. Entwicklung direkt über die Claude API mit Testdaten. Echte Daten nur über eine EU-Region. Bis zum Datenschutz-Konzept nur Testdaten.

## 4. Ausschnitt 2 – Fundament (ohne KI)

### Nutzergeschichten und Akzeptanzkriterien

**P-1 Physio meldet sich an.** Als Physio möchte ich mich im Web-Zugang anmelden, damit ich meine Patienten betreuen kann.
- AK: Ein Test-Physio meldet sich an und sieht die Liste seiner Patienten. Patienten anderer Praxen sieht er nicht.
- AK: Mit falschen Zugangsdaten erscheint eine verständliche Fehlermeldung, und es gibt keinen Zugang.

**P-2 Patient anlegen und einladen.** Als Physio möchte ich einen Patienten anlegen und ihm einen Code geben, damit er die App mit seinem Plan starten kann.
- AK: Nach dem Anlegen zeigt der Zugang einen Einladungscode, einen Link und einen QR-Code.
- AK: Ein Code lässt sich genau einem Patienten zuordnen. Ein bereits benutzter Code wird in der App mit Hinweis abgelehnt.

**P-3 Plan zusammenstellen.** Als Physio möchte ich aus dem Katalog und eigenen Übungen einen Plan mit Phasen und Grenzen erstellen, damit der Patient genau das trainiert, was ich freigebe.
- AK: Der Physio fügt Katalogübungen und eigene Übungen hinzu und setzt je Übung Wiederholungen, Sätze, Dauer, Belastungshinweis und die Phase.
- AK: Eine eigene Übung braucht mindestens Name und Beschreibung. Ohne sie ist Speichern nicht möglich, und das fehlende Feld wird genannt.
- AK: Nach dem Speichern sieht der Patient den geänderten Plan beim nächsten Öffnen von „Heute“.

**P-4 Akte pflegen.** Als Physio möchte ich Behandler und Krankengeschichte eintragen, damit Manny und ich den ganzen Verlauf kennen.
- AK: Behandler (Physio, Arzt) mit Rolle, Kontakt und Terminen, Verletzungen, OP, frühere Therapien, aktuelle Behandlungen und Behandlungsmöglichkeiten lassen sich anlegen, ändern und löschen.

**P-5 Verlauf und Warnzeichen sehen.** Als Physio möchte ich erledigte Übungen, gemeldetes Befinden und Warnzeichen sehen, damit ich rechtzeitig reagieren kann.
- AK: Die Patientenansicht zeigt je Tag die erledigten Übungen und das gemeldete Befinden.
- AK: Ein Warnzeichen erscheint in der Patientenliste sichtbar markiert. Welche Meldungen als Warnzeichen gelten, ist offene Frage O-2.
- AK: Inhalte des Manny-Chats sind für den Physio nirgends sichtbar.

**A-1 Start mit Einladung.** Als Patient möchte ich die App mit dem Code meines Physios starten, damit ich sofort meinen Plan habe.
- AK: Nach Eingabe eines gültigen Codes oder Öffnen des Links und der Einwilligung zeigt der Pfad den Plan des Physios statt des Beispielpfads.
- AK: Ohne gültigen Code kommt man nicht über den Startbildschirm hinaus. Der Bildschirm erklärt, dass der Zugang über den Physio kommt.
- AK: Die Einwilligung nennt ausdrücklich, dass der Physio Verlauf, Befinden und Warnzeichen sieht, aber nicht den Manny-Chat.

**A-2 Heute aus dem echten Plan.** Als Patient möchte ich in „Heute“ die Übungen meines Physios mit Beschreibung sehen, damit ich weiß, was und wie ich trainiere.
- AK: Jede Übung ist antippbar und zeigt Beschreibung und Grenzen des Physios.
- AK: Tauschen bietet nur Übungen an, die der Physio für die aktuelle Phase freigegeben hat.

**A-3 Befinden melden.** Als Patient möchte ich mein Befinden melden, damit mein Physio und Manny es berücksichtigen.
- AK: Der Patient kann Schmerz, Schwellung und Stimmung melden. Skalen und Häufigkeit sind offene Frage O-3. Die Meldung erscheint beim Physio in der Verlaufsansicht.

**A-4 Akte einsehen und ergänzen.** Als Patient möchte ich meine Behandler und Termine sehen und ergänzen, damit alles an einem Ort ist.
- AK: Der Patient sieht seine Behandler und Termine und kann eigene Termine hinzufügen. Was der Physio eingetragen hat, kann der Patient nicht ändern.
- AK: Dokumente hochladen ist in Ausschnitt 2 nur dann enthalten, wenn O-5 so entschieden wird.

**T-1 Testdaten für die Präsentation.** Als Präsentierender möchte ich vorbereitete Testpraxen und Testpatienten, damit ich alles live zeigen kann.
- AK: Ein Befehl legt die Testdaten neu an bzw. setzt sie zurück. Mindestens eine Praxis mit einem Physio und mehreren Patienten in unterschiedlichen Phasen. Die genaue Anzahl ist offene Frage O-6.

## 5. Ausschnitt 3 – Manny-KI: Chat und „Heute zusammenstellen“

**M-1 Chat mit Manny.** Als Patient möchte ich Manny Fragen stellen, damit ich mich verstanden und begleitet fühle.
- AK: Manny antwortet mit Wissen aus dem Framework: Name, Phase, Plan, Behandler, Befinden der letzten Tage.
- AK: Fragen außerhalb der Freigabe (neue Übung, Medikament, Diagnose) beantwortet Manny nicht inhaltlich. Er verweist an den passenden Behandler aus der Akte.
- AK: Meldet der Patient ein Warnzeichen, zeigt die App einen festen Hinweis, und das Warnzeichen erscheint beim Physio (P-5).

**M-2 Heute zusammenstellen.** Als Patient möchte ich, dass Manny mein Tagesprogramm aus dem Plan zusammenstellt, damit es zu meiner Zeit und meinem Befinden passt.
- AK: Das vorgeschlagene Programm enthält ausschließlich Übungen der aktuellen Phase aus dem Plan des Physios, innerhalb seiner Grenzen. Das wird automatisch geprüft, und eine Abweichung zählt als Fehler.
- AK: Bei gemeldetem höherem Schmerz wählt Manny eine vom Physio freigegebene leichtere Variante oder weniger Umfang und sagt das dazu.
- AK: Der Patient sieht, warum Manny so zusammengestellt hat (ein kurzer Satz).

## 6. Ausschnitt 4 – Übung begleiten und KI-Texte auf dem Pfad

**M-3 Übung begleiten.** Als Patient möchte ich während der Übung angeleitet werden, damit ich sie richtig und sicher ausführe.
- AK: Manny führt Schritt für Schritt durch die Beschreibung des Physios und zählt Sätze und Wiederholungen mit.
- AK: Meldet der Patient während der Übung Schmerz, bietet Manny nur die freigegebene leichtere Variante oder einen Abbruch an.

**M-4 Persönliche Pfad-Texte.** Als Patient möchte ich persönliche Texte von Manny auf dem Pfad, damit die Motivation zu mir passt.
- AK: Begrüßung, Feier und Erinnerung beziehen sich auf den echten Verlauf. Fällt die KI aus, erscheinen die festen Texte aus Ausschnitt 1.

## 7. Folgen für den fertigen ersten Ausschnitt

- Das Onboarding beginnt mit dem Code des Physios. Name, Verletzung und Datum kommen aus der Akte statt aus Eigenangaben.
- Der Beispielpfad wird zum Rückfall für die Präsentation oder entfällt.
- Ein Hinweis aus der App-Prüfung löst sich damit: Andere Verletzungstypen zeigen bisher denselben Kreuzband-Pfad. Mit echten Plänen vom Physio entfällt das.
- „Deine Daten → Alles löschen“ muss Backend-Daten einschließen. Löschkonzept siehe KI-Plan v1.2, Abschnitt 9.

## 8. Bewusst nicht enthalten

Arzt-Zugang, Patient sucht Praxis selbst, Manny wählt Übungen außerhalb der Freigabe, Sprache, proaktive Nachrichten und Push, Chats mit Menschen (Direktnachrichten), Abrechnung, Mehrsprachigkeit, Zulassung als Medizinprodukt.

## 9. Risiken

- **Gewinnung der Physios:** Ohne Physio gibt es keinen Nutzer. Für die Präsentation lösen das Testpraxen. Für einen echten Einsatz ist es die zentrale Wachstumsfrage.
- **Zweite Oberfläche:** Der Web-Zugang für Physios ist eine zusätzliche Anwendung mit eigener Gestaltung. Technik dafür (Flutter Web oder anderes) entscheidet der Plan.
- **Katalog-Inhalte:** Ein „geprüfter“ Übungskatalog braucht fachliche Quellen. Für den Prototyp sind gekennzeichnete Beispielinhalte nötig (O-1).
- **Datenschutz:** Gesundheitsdaten mehrerer Personen. Bis zum Datenschutz-Konzept nur Testdaten.

## 10. Offene Fragen

- **O-1** Woher kommen die Katalogübungen für den Prototyp? Beispieltexte von uns, gekennzeichnet als Beispiel, oder Inhalte einer Fachperson?
- **O-2** Was gilt als Warnzeichen (Schwellen beim Befinden, Schlüsselwörter im Chat)? Bis zur Klärung: gekennzeichnete Startliste aus dem KI-Plan v1.2, Abschnitt 6.3.
- **O-3** Befinden: Welche Skalen (z. B. Schmerz 0 bis 10), wie oft wird gefragt?
- **O-4** Bleiben Streak, Freezes und Pfad-Darstellung aus Ausschnitt 1 so, und baut der Pfad auf den Phasen des Physio-Plans auf?
- **O-5** Dokumente hochladen: schon in Ausschnitt 2 oder später?
- **O-6** Umfang der Testdaten: wie viele Praxen, Patienten und Phasen?
- **O-7** Wie lange ist ein Einladungscode gültig?
