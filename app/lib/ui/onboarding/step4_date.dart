// Schritt 4: Zeitpunkt (Brief 6.1, UI-15, A-27). Die `DateCard` öffnet die
// Datumsauswahl der Plattform im Dark-Theme: `lastDate` = heute,
// `firstDate` = früher von (heute − 2 Jahre, gespeichertes Datum),
// `initialDate` = gespeichertes Datum oder heute, immer innerhalb der Grenzen.
// Keine Phasen-Auswahl. „Weiter“ ist bis zur Auswahl deaktiviert.
import 'package:flutter/material.dart';

import '../../logic/clock.dart';
import '../../logic/date_format.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_metrics.dart';
import '../components/date_card.dart';

/// Grenzen der Datumsauswahl (A-27), als reine Funktion testbar.
class DatePickerRange {
  const DatePickerRange({
    required this.first,
    required this.last,
    required this.initial,
  });

  factory DatePickerRange.from({required LocalDay today, LocalDay? saved}) {
    final DateTime last = DateTime(today.year, today.month, today.day);
    final DateTime twoYears = DateTime(last.year - 2, last.month, last.day);
    final DateTime? savedDate = saved == null
        ? null
        : DateTime(saved.year, saved.month, saved.day);
    final DateTime first = savedDate != null && savedDate.isBefore(twoYears)
        ? savedDate
        : twoYears;
    DateTime initial = savedDate ?? last;
    if (initial.isAfter(last)) initial = last;
    if (initial.isBefore(first)) initial = first;
    return DatePickerRange(first: first, last: last, initial: initial);
  }

  final DateTime first;
  final DateTime last;
  final DateTime initial;
}

class Step4Date extends StatefulWidget {
  const Step4Date({super.key, required this.prompt});

  final Widget prompt;

  @override
  State<Step4Date> createState() => _Step4DateState();
}

class _Step4DateState extends State<Step4Date> {
  final FocusNode _cardFocus = FocusNode();

  @override
  void dispose() {
    _cardFocus.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final AppController c = AppScope.of(context);
    final DatePickerRange range = DatePickerRange.from(
      today: c.today,
      saved: c.state.onboarding.injuryDate,
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: range.initial,
      firstDate: range.first,
      lastDate: range.last,
    );
    if (picked != null) c.setInjuryDate(LocalDay.from(picked));
    if (mounted) _cardFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final LocalDay? date = AppScope.of(context).state.onboarding.injuryDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        widget.prompt,
        const SizedBox(height: CuraSpace.s6),
        DateCard(
          valueText: date == null ? null : formatDateFull(date),
          focusNode: _cardFocus,
          onPressed: _pick,
        ),
      ],
    );
  }
}
