// `CustomExerciseDialog` (Brief 6.3, Plan 9 B-4, N-16): Dialog „Eigene
// Übung“ im `CuraDialog`-Rahmen mit drei `CuraTextField`s: Name (Pflicht,
// getrimmt), Wiederholungen (vorbefüllt „3 × 10“) und Dauer in Minuten
// (vorbefüllt „5“). Ein geleertes Feld fällt beim Hinzufügen auf die Vorgabe
// zurück (der Controller wendet das an), damit jede Karte Name, Wiederholungen
// und Dauer zeigt (UI-27). Buttons gestapelt: „Hinzufügen“ (Primär, deaktiviert
// bei leerem Namen) und „Abbrechen“ (Umriss). Der Dialog ist kein Warnkontext:
// der Akzent-Button ist zulässig.
//
// Ergebnis der Route: [CustomExerciseInput] oder `null` (Abbrechen, Scrim,
// Zurück, Tageswechsel). Hinzugefügt wird erst nach dem Schließen, damit ein
// Tageswechsel den halb ausgefüllten Dialog verwirft, ohne einen Eintrag auf
// den falschen Tag zu schreiben (Ergänzung 1, 3.4).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../components/cura_dialog.dart';
import '../components/cura_text_field.dart';
import '../components/pill_button.dart';
import '../../theme/cura_metrics.dart';
import '../routes/cura_dialog_route.dart';

class CustomExerciseInput {
  const CustomExerciseInput({
    required this.name,
    required this.reps,
    required this.minutes,
  });

  final String name;
  final String reps;
  final String minutes;
}

class CustomExerciseDialog extends StatefulWidget {
  const CustomExerciseDialog({super.key});

  /// Die Dialog-Route (Scrim, Einblenden `dur-base`).
  static CuraDialogRoute<CustomExerciseInput?> route(BuildContext context) {
    return CuraDialogRoute<CustomExerciseInput?>(
      context: context,
      builder: (BuildContext context) => const CustomExerciseDialog(),
    );
  }

  @override
  State<CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<CustomExerciseDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _reps = TextEditingController(
    text: S.customDefaultReps,
  );
  final TextEditingController _minutes = TextEditingController(
    text: '${S.customDefaultMinutes}',
  );

  @override
  void initState() {
    super.initState();
    _name.addListener(_onName);
  }

  @override
  void dispose() {
    _name.dispose();
    _reps.dispose();
    _minutes.dispose();
    super.dispose();
  }

  bool _canAdd = false;

  void _onName() {
    final bool can = _name.text.trim().isNotEmpty;
    if (can != _canAdd) setState(() => _canAdd = can);
  }

  void _add() {
    if (!_canAdd) return;
    Navigator.of(context).pop(
      CustomExerciseInput(
        name: _name.text.trim(),
        reps: _reps.text,
        minutes: _minutes.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CuraDialog(
      title: S.customDialogTitle,
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CuraTextField(
            label: S.customNameLabel,
            controller: _name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: CuraSpace.s3),
          CuraTextField(
            label: S.customRepsLabel,
            controller: _reps,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: CuraSpace.s3),
          CuraTextField(
            label: S.customMinutesLabel,
            controller: _minutes,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
          ),
        ],
      ),
      actions: <Widget>[
        PillButton(label: S.customAddButton, onPressed: _canAdd ? _add : null),
        PillButton(
          label: S.cancel,
          variant: PillButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
