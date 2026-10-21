// `DeleteDialog` „Alles löschen?“ (Ergänzung 1, 3.2, Plan 6.3, UI-49 bis 52).
//
// - Aufbau: Icon `delete_outline_rounded`, Titel, Text; „Abbrechen“ (Neutral
//   hell, Anfangsfokus) oben, „Ja, alles löschen“ (Umriss, Icon) darunter.
//   Opak, kein Blur; im Normalfall weder `accent` noch `status-error`.
// - Abbrechen, Zurück, Escape und Scrim brechen ab; es wird nichts gelöscht.
// - Ablauf: `await controller.deleteAll()`; bei Erfolg ersetzt
//   `AppRoutes.restartOnboarding` den gesamten Navigationsstapel (der
//   `OnboardingFlow` ruft `completeDeletion()` nach seinem ersten Frame, Plan
//   6.3). Ein Doppeltipp startet nur einen Vorgang (und der Controller reicht
//   einen laufenden Vorgang ohnehin weiter).
// - Laden: Solange der Vorgang läuft, sind Zurück, Escape, Scrim und „Abbrechen“
//   wirkungslos (`PopScope`, Barriere ignoriert) und „Ja, alles löschen“ ist
//   gesperrt. Erst nach mehr als 300 ms zeigt der Button den Fortschrittskreis
//   samt Statusansage „Wird gelöscht“ (`PillButton(busy)`, Erratum E-3).
// - Fehler: `DeleteErrorNotice` über den Buttons, der Button heißt „Nochmal
//   versuchen“; der Zustand im Speicher blieb unverändert (Controller).
import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_motion.dart';
import '../components/cura_dialog.dart';
import '../components/pill_button.dart';
import '../routes/app_routes.dart';
import '../routes/cura_dialog_route.dart';
import 'delete_error_notice.dart';

class DeleteDialog extends StatefulWidget {
  const DeleteDialog({super.key});

  static CuraDialogRoute<void> route(BuildContext context) {
    return CuraDialogRoute<void>(
      context: context,
      builder: (BuildContext context) => const DeleteDialog(),
    );
  }

  @override
  State<DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<DeleteDialog> {
  /// Ein Vorgang läuft (ab dem Tipp).
  bool _pending = false;

  /// Der Fortschrittskreis ist sichtbar (ab 300 ms).
  bool _busyVisible = false;
  bool _failed = false;

  /// Nach einem Fehler heißt der Button „Nochmal versuchen“, auch während des
  /// nächsten Versuchs.
  bool _everFailed = false;
  Timer? _busyTimer;

  @override
  void dispose() {
    _busyTimer?.cancel();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_pending) return;
    final NavigatorState navigator = Navigator.of(context);
    final AppController controller = context
        .getInheritedWidgetOfExactType<AppScope>()!
        .notifier!;
    setState(() {
      _pending = true;
      _failed = false;
    });
    _busyTimer = Timer(CuraMotion.busyDelay, () {
      if (mounted && _pending) setState(() => _busyVisible = true);
    });
    try {
      await controller.deleteAll();
    } catch (e) {
      debugPrint('Löschen fehlgeschlagen: $e');
      _busyTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _pending = false;
        _busyVisible = false;
        _failed = true;
        _everFailed = true;
      });
      return;
    }
    _busyTimer?.cancel();
    // Der Stapel wird ersetzt; was danach noch auf diesem Dialog steht, geht
    // mit der Route unter. Fehlt der Navigator, gibt es nichts zu ersetzen.
    if (!navigator.mounted) return;
    AppRoutes.restartOnboarding(navigator);
  }

  void _cancel() {
    if (_pending) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_pending,
      child: CuraDialog(
        icon: Icons.delete_outline_rounded,
        title: S.deleteTitle,
        message: S.deleteText,
        extra: _failed ? const DeleteErrorNotice() : null,
        actions: <Widget>[
          PillButton(
            label: S.cancel,
            variant: PillButtonVariant.neutral,
            autofocus: true,
            // Vor dem sichtbaren Fortschrittskreis bleibt die Fläche unverändert
            // (kein Flackern); die Handler ignorieren den Tipp während des
            // Vorgangs.
            onPressed: _busyVisible ? null : _cancel,
          ),
          PillButton(
            label: _everFailed ? S.retry : S.deleteConfirm,
            variant: PillButtonVariant.outline,
            icon: Icons.delete_outline_rounded,
            busy: _busyVisible,
            busyStatus: S.busyStatusDeleting,
            onPressed: _delete,
          ),
        ],
      ),
    );
  }
}
