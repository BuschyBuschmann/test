import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/day_program.dart';
import 'package:curaone/logic/manny_context.dart';
import 'package:curaone/logic/manny_occasions.dart';
import 'package:curaone/logic/manny_text_source.dart';
import 'package:curaone/logic/placeholder_pools.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/text_checks.dart';

void main() {
  group('Übungspool', () {
    int sum(int choice) => kBaseExercises[choice]!.fold(
      0,
      (int s, ExerciseFamily f) => s + f.base.minutes,
    );

    test('Summe der Basis-Dauern ist genau 10/20/30 Minuten', () {
      expect(sum(10), 10);
      expect(sum(20), 20);
      expect(sum(30), 30);
    });

    test('Basis 10 ⊂ 20 ⊂ 30 mit gleichen IDs', () {
      Set<String> ids(int c) =>
          kBaseExercises[c]!.map((ExerciseFamily f) => f.base.id).toSet();
      expect(ids(20).containsAll(ids(10)), isTrue);
      expect(ids(30).containsAll(ids(20)), isTrue);
      expect(ids(10).length, lessThan(ids(20).length));
      expect(ids(20).length, lessThan(ids(30).length));
    });

    test('Alternativen: gleiche ID und Dauer, zyklisches Tauschen (A-15)', () {
      for (final List<ExerciseFamily> list in kBaseExercises.values) {
        for (final ExerciseFamily f in list) {
          expect(f.alternatives, isNotEmpty);
          for (final ExerciseDef a in f.alternatives) {
            expect(a.id, f.base.id);
            expect(a.minutes, f.base.minutes);
          }
          final int n = f.alternatives.length + 1;
          expect(f.atSwapSteps(0), f.base);
          expect(f.atSwapSteps(1), f.alternatives.first);
          expect(f.atSwapSteps(n), f.base);
          expect(f.atSwapSteps(n + 1), f.alternatives.first);
        }
      }
    });

    test('Mockup-Übungen sind enthalten', () {
      final List<DisplayedExercise> l = deriveExercises(
        DayProgramState.fresh(kToday),
        20,
      );
      final DisplayedExercise squat = l.firstWhere(
        (e) => e.name == 'Kniebeuge am Stuhl',
      );
      expect((squat.reps, squat.minutes), ('3 × 12 Wdh.', 6));
      final DisplayedExercise bridge = l.firstWhere(
        (e) => e.name == 'Brücke mit Fersendruck',
      );
      expect((bridge.reps, bridge.minutes), ('3 × 15 Wdh.', 7));
    });
  });

  group('Termine (N-14)', () {
    test('Mo–Do: Physio 17:00', () {
      for (int i = 0; i < 4; i++) {
        final LocalDay day = const LocalDay(2026, 10, 5).addDays(i); // Mo..Do
        final List<Appointment> a = appointmentsFor(day);
        expect(a, hasLength(1), reason: '$day');
        expect(a.single.category, AppointmentCategory.physio);
        expect(a.single.timeText, '17:00');
        expect(a.single.title, 'Physiotherapie, Praxis Müller');
        expect(a.single.meta, 'Köln-Ehrenfeld · Beispiel');
      }
    });

    test('Freitag: Arzt 09:30 vor Physio 17:00 (nach Uhrzeit)', () {
      final List<Appointment> a = appointmentsFor(const LocalDay(2026, 10, 9));
      expect(a.map((e) => e.timeText), <String>['09:30', '17:00']);
      expect(a.first.category, AppointmentCategory.doctor);
      expect(a.first.title, 'Kontrolltermin Orthopädie');
      expect(a.first.meta, endsWith('· Beispiel'));
    });

    test('Samstag/Sonntag: keine Termine', () {
      expect(appointmentsFor(const LocalDay(2026, 10, 10)), isEmpty);
      expect(appointmentsFor(const LocalDay(2026, 10, 11)), isEmpty);
    });

    test('Screenreader-Label (A-16)', () {
      expect(
        appointmentsFor(kToday).single.semanticsLabel,
        'Beispieltermin, Physio, Physiotherapie, Praxis Müller, 17:00 Uhr',
      );
      expect(
        appointmentsFor(const LocalDay(2026, 10, 9)).first.semanticsLabel,
        'Beispieltermin, Arzt, Kontrolltermin Orthopädie, 09:30 Uhr',
      );
    });
  });

  group('Fakten (KS-2)', () {
    test('IDs eindeutig und stabil, Text unverändert', () {
      expect(
        kAllFacts.map((FactRef f) => f.id).toSet(),
        hasLength(kAllFacts.length),
      );
      expect(kExampleFact.id, 'fact-gewebe-umbau');
      expect(
        kExampleFact.text,
        'Dein Gewebe baut sich gerade aktiv um. Heute zählt.',
      );
    });
  });

  group('Manny-Texte', () {
    final MannyContext ctx = MannyContext.from(
      onboardedState().copyWith(
        streak: onboardedState().streak.copyWith(count: 12),
      ),
      kToday,
    );
    const PlaceholderMannyTextSource source = PlaceholderMannyTextSource();

    test('Onboarding-Sätze je Schritt (Brief 6.1)', () {
      expect(
        onboardingMannyText(0, ''),
        'Moin, ich bin Manny und begleite dich durch deine Reha. Wie heißt du?',
      );
      expect(
        onboardingMannyText(1, '  Jakob '),
        'Kurz und ehrlich, Jakob: Das passiert mit deinen Daten.',
      );
      expect(onboardingMannyText(2, 'Jakob'), "Was hat's erwischt, Jakob?");
      expect(
        onboardingMannyText(3, 'Jakob'),
        'Wann war die Verletzung oder OP?',
      );
      expect(kMicHint, 'Das kann ich bald, heute noch nicht.');
    });

    test('Platzhalterquelle liefert für jeden Anlass die bisherigen Texte', () {
      expect(
        source.bubbleText(MannyOccasion.greeting, ctx),
        "Moin Jakob, los geht's. Dein Weg beginnt hier.",
      );
      expect(
        source.bubbleText(MannyOccasion.streakDanger, ctx),
        'Dein Streak von 12 Tagen wartet auf dich. Heute noch eine Runde?',
      );
      expect(
        source.bubbleText(MannyOccasion.celebration, ctx),
        'Stark, Jakob. Das war Tag 12.',
      );
      expect(
        source.bubbleText(MannyOccasion.restart, ctx),
        'Neuer Anlauf, Jakob. Dein Pfad bleibt, der Streak startet heute neu.',
      );
      expect(
        source.bubbleText(MannyOccasion.fact, ctx),
        'Dein Gewebe baut sich gerade aktiv um. Heute zählt.',
      );
      expect(source.fact(ctx), kExampleFact);
    });

    test('Plural in der Streak-Gefahr-Blase: „1 Tag“', () {
      final MannyContext one = MannyContext.from(
        onboardedState().copyWith(
          streak: onboardedState().streak.copyWith(count: 1),
        ),
        kToday,
      );
      expect(
        source.bubbleText(MannyOccasion.streakDanger, one),
        'Dein Streak von 1 Tag wartet auf dich. Heute noch eine Runde?',
      );
    });

    test('alle Blasen- und Onboarding-Texte ≤ 2 Sätze', () {
      for (final MannyOccasion o in MannyOccasion.values) {
        expect(
          countSentences(source.bubbleText(o, ctx)),
          lessThanOrEqualTo(2),
          reason: '$o',
        );
      }
      for (int step = 0; step < 4; step++) {
        expect(
          countSentences(onboardingMannyText(step, 'Jakob')),
          lessThanOrEqualTo(2),
        );
      }
      expect(countSentences(kMicHint), lessThanOrEqualTo(2));
    });

    test('Satzzählung: Abkürzungen zählen nicht', () {
      expect(countSentences('Übungen · ca. 20 Min. Los.'), 2);
      expect(
        countSentences('Z. B. so. Und so.'.replaceAll('Z. B.', 'z. B.')),
        2,
      );
      expect(countSentences('Eins. Zwei. Drei.'), 3);
      expect(countSentences('Wirklich? Ja!'), 2);
    });

    test(
      'Sonderfall: Strings enthalten kein Sie/Ihr (Regel 10 Stichprobe)',
      () {
        expect(S.micHint.contains('Sie '), isFalse);
      },
    );
  });
}
