import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/day_program.dart';
import 'package:curaone/logic/manny_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/injury_type.dart';
import 'package:curaone/logic/streak.dart';

/// Standard-Heute der Tests (Plan 6.4): Mittwoch.
const LocalDay kToday = LocalDay(2026, 10, 7);

/// Zustand nach abgeschlossenem Onboarding: Name Jakob, ACL, Verletzung vor
/// 4 Wochen + 2 Tagen (also Woche 5 am [kToday]).
AppState onboardedState({
  LocalDay? today,
  String name = 'Jakob',
  InjuryType type = InjuryType.acl,
  LocalDay? injuryDate,
  StreakState streak = const StreakState(),
}) {
  final LocalDay t = today ?? kToday;
  return AppState.initial(t).copyWith(
    onboarding: OnboardingState(
      completed: true,
      step: 3,
      name: name,
      injuryType: type,
      injuryDate: injuryDate ?? t.addDays(-30),
    ),
    consent: ConsentState(
      acceptedAt: DateTime.utc(2026, 9, 1, 8),
      version: ConsentState.kVersion,
    ),
    streak: streak,
  );
}

/// Erwarteter Zustand zum Fixture `state_v1.json`.
AppState expectedV1() => AppState(
  onboarding: const OnboardingState(
    completed: true,
    step: 3,
    name: 'Jakob ',
    injuryType: InjuryType.other,
    injuryOther: 'Schulter',
    injuryDate: LocalDay(2026, 9, 7),
  ),
  consent: ConsentState(
    acceptedAt: DateTime.utc(2026, 9, 8, 8, 12, 30, 123),
    version: 'prototype-0',
  ),
  streak: const StreakState(
    count: 12,
    freezes: 1,
    lastTrainingDay: LocalDay(2026, 10, 5),
    evaluatedThrough: LocalDay(2026, 10, 6),
    coveredInGap: 1,
  ),
  path: const PathState(
    completedUnitIds: <String>['w5-d1', 'w5-d2'],
    pulsePending: 'w5-d2',
  ),
  day: const DayProgramState(
    dayKey: LocalDay(2026, 10, 7),
    removed: <String>['ex-wade'],
    swaps: <String, int>{'ex-kniebeuge': 2},
    custom: <CustomExercise>[
      CustomExercise(id: 'custom-1', name: 'Plank', reps: '3 × 10', minutes: 5),
    ],
    done: true,
  ),
  prefs: const PrefsState(timeChoice: 30),
  manny: const MannyState(
    lastShown: <MannyOccasion, LocalDay>{
      MannyOccasion.greeting: LocalDay(2026, 10, 6),
      MannyOccasion.fact: LocalDay(2026, 10, 7),
    },
  ),
  celebration: const CelebrationState(
    day: LocalDay(2026, 10, 7),
    unitId: 'w5-d2',
  ),
);
