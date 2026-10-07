import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/injury_type.dart';
import 'package:curaone/logic/manny_occasions.dart';
import 'package:curaone/logic/path_generator.dart';
import 'package:curaone/logic/profile.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/logic/training.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

/// Zustand mit Fortschritt, Streak, Feier, Puls und erledigtem Tag.
AppState progressed() {
  final AppState s = onboardedState(
    streak: StreakState(
      count: 12,
      freezes: 1,
      lastTrainingDay: kToday.addDays(-1),
    ),
  );
  return applyTraining(
    s,
    kToday,
  ).state.copyWith(prefs: const PrefsState(timeChoice: 30));
}

void main() {
  final AppState base = progressed();
  final ProfileDraft same = ProfileDraft.fromState(base);

  group('isDirty / canSave', () {
    test('unverändert: nicht dirty, nicht speicherbar', () {
      expect(same.isDirty(base), isFalse);
      expect(same.canSave(base, kToday), isFalse);
    });

    test('Name nach trim: nur Leerzeichen zählt nicht als Änderung', () {
      expect(same.copyWith(name: '  Jakob  ').isDirty(base), isFalse);
      expect(same.copyWith(name: 'Jakob2').isDirty(base), isTrue);
    });

    test('Name leer: nicht speicherbar', () {
      final ProfileDraft d = same.copyWith(name: '   ');
      expect(d.isDirty(base), isTrue);
      expect(d.canSave(base, kToday), isFalse);
    });

    test('Datum in der Zukunft: nicht speicherbar; heute: speicherbar', () {
      expect(
        same.copyWith(injuryDate: kToday.addDays(1)).canSave(base, kToday),
        isFalse,
      );
      expect(same.copyWith(injuryDate: kToday).canSave(base, kToday), isTrue);
    });

    test('„Anderes“-Freitext zählt nur bei Typ „Anderes“', () {
      expect(same.copyWith(injuryOther: 'egal').isDirty(base), isFalse);
      final AppState other = base.copyWith(
        onboarding: base.onboarding.copyWith(
          injuryType: InjuryType.other,
          injuryOther: 'Schulter',
        ),
      );
      final ProfileDraft d = ProfileDraft.fromState(other);
      expect(d.isDirty(other), isFalse);
      expect(d.copyWith(injuryOther: 'Schulter ').isDirty(other), isFalse);
      expect(d.copyWith(injuryOther: 'Knie').isDirty(other), isTrue);
    });
  });

  group('apply', () {
    test('nur Name geändert: nichts wird neu berechnet (A-12, n3)', () {
      final ProfileUpdate u = applyProfile(
        base,
        same.copyWith(name: 'Lena'),
        kToday,
      );
      expect(u.nameChanged, isTrue);
      expect(u.pathRecomputed, isFalse);
      expect(u.state.onboarding.name, 'Lena');
      expect(u.state.path, base.path);
      expect(u.state.celebration, base.celebration);
      expect(u.state.streak, base.streak);
      expect(u.state.day, base.day);
      expect(u.state.prefs, base.prefs);
    });

    test('nur „Anderes“-Freitext geändert: keine Neuberechnung', () {
      final AppState other = base.copyWith(
        onboarding: base.onboarding.copyWith(
          injuryType: InjuryType.other,
          injuryOther: 'Schulter',
        ),
      );
      final ProfileUpdate u = applyProfile(
        other,
        ProfileDraft.fromState(other).copyWith(injuryOther: 'Knie'),
        kToday,
      );
      expect(u.nameChanged, isFalse);
      expect(u.pathRecomputed, isFalse);
      expect(u.state.onboarding.injuryOther, 'Knie');
      expect(u.state.path, other.path);
    });

    test('Typ geändert: Pfad neu, Fortschritt/Puls leer, Feier gestrichen', () {
      expect(base.path.completedUnitIds, isNotEmpty);
      expect(base.path.pulsePending, isNotNull);
      expect(base.celebration, isNotNull);
      final ProfileUpdate u = applyProfile(
        base,
        same.copyWith(injuryType: InjuryType.ankle),
        kToday,
      );
      expect(u.pathRecomputed, isTrue);
      expect(u.nameChanged, isFalse);
      expect(u.state.path.completedUnitIds, isEmpty);
      expect(u.state.path.pulsePending, isNull);
      expect(u.state.celebration, isNull); // w5-d1 im neuen Pfad nicht erledigt
    });

    test(
      'Datum geändert: Feier bleibt, wenn ihre Unit im neuen Pfad erledigt ist',
      () {
        // Neues Datum vor 60 Tagen → Woche 9: w5-d1 ist per Datum erledigt.
        final ProfileUpdate u = applyProfile(
          base,
          same.copyWith(injuryDate: kToday.addDays(-60)),
          kToday,
        );
        expect(u.pathRecomputed, isTrue);
        expect(u.state.path.completedUnitIds, isEmpty);
        expect(u.state.path.pulsePending, isNull);
        expect(u.state.celebration, base.celebration);
        final PathProgress p = computePathProgress(
          injuryDate: u.state.onboarding.injuryDate,
          today: kToday,
          completedUnitIds: u.state.path.completedUnitIds,
        );
        expect(p.week, 9);
        expect(p.current!.id, 'w9-d1');
      },
    );

    test('Streak, Freezes, day.* inkl. done und Zeitwahl bleiben (N-7)', () {
      final ProfileUpdate u = applyProfile(
        base,
        same.copyWith(
          name: 'Lena',
          injuryType: InjuryType.muscle,
          injuryDate: kToday.addDays(-10),
        ),
        kToday,
      );
      expect(u.state.streak, base.streak);
      expect(u.state.day, base.day);
      expect(u.state.day.done, isTrue);
      expect(u.state.prefs.timeChoice, 30);
      expect(u.state.manny, base.manny);
      expect(u.state.consent, base.consent);
      expect(u.state.onboarding.completed, isTrue);
    });

    test('Typ weg von „Anderes“ löscht den Freitext', () {
      final AppState other = base.copyWith(
        onboarding: base.onboarding.copyWith(
          injuryType: InjuryType.other,
          injuryOther: 'Schulter',
        ),
      );
      final ProfileUpdate u = applyProfile(
        other,
        ProfileDraft.fromState(other).copyWith(injuryType: InjuryType.acl),
        kToday,
      );
      expect(u.state.onboarding.injuryOther, '');
    });

    test('Entwurf ohne Änderung: Zustand identisch, keine Flags', () {
      final ProfileUpdate u = applyProfile(base, same, kToday);
      expect(identical(u.state, base), isTrue);
      expect(u.nameChanged, isFalse);
      expect(u.pathRecomputed, isFalse);
    });

    test('Name wird ungetrimmt gespeichert (Plan 6.1), Vorname getrimmt', () {
      final ProfileUpdate u = applyProfile(
        base,
        same.copyWith(name: ' Lena '),
        kToday,
      );
      expect(u.state.onboarding.name, ' Lena ');
      expect(u.state.onboarding.firstName, 'Lena');
    });
  });

  test('Datumstyp: ProfileDraft kennt LocalDay', () {
    expect(same.injuryDate, isA<LocalDay>());
  });

  test('MAJOR-1 (T1): behaltene Feier löst nach Profiländerung keinen Ring-Puls aus', () {
    final ProfileUpdate u = applyProfile(
      base,
      same.copyWith(injuryDate: kToday.addDays(-60)),
      kToday,
    );
    expect(u.state.path.pulsePending, isNull);
    expect(u.state.celebration, isNotNull);
    final BubbleDecision d = nextBubble(u.state, DateTime(2026, 10, 7, 12))!;
    expect(d.occasion, MannyOccasion.celebration);
    expect(d.pulseUnitId, isNull);
    // Ohne Profiländerung bleibt der Puls.
    expect(nextBubble(base, DateTime(2026, 10, 7, 12))!.pulseUnitId, 'w5-d1');
  });
}
