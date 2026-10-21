// Löschdialog im Backend-Modus (Brief-Ergänzung 2, A3 „Nicht einverstanden“,
// A11, V2-99, V2-100). Zwei Varianten: „Alles löschen?“ (Profil) und „Ohne
// Einwilligung geht es nicht“ (Zugang löschen). Opak, neutral, „Abbrechen“ (bzw.
// „Zurück“) zuerst und fokussiert, kein Mandarine-Knopf.
//
// Ausgänge von [BackendController.deleteAccount]:
// - sicher gelöscht: der Einstieg wechselt zum Code-Start (BackendRoot räumt die
//   Routen ab), die Snackbar „Alle Daten sind gelöscht.“ folgt dort;
// - offline / abgelehnt: nichts gelöscht, Meldung, „Nochmal versuchen“;
// - unklar: Meldung, „Nochmal versuchen“ (wiederholt, idempotent), Merkzeichen
//   bleibt;
// - lokaler Fehler: Server gelöscht, „Nochmal versuchen“ wiederholt nur das
//   lokale Aufräumen.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../state/backend_controller.dart';
import '../../state/backend_scope.dart';
import '../../theme/cura_motion.dart';
import '../components/cura_dialog.dart';
import '../components/notice_card.dart';
import '../components/pill_button.dart';
import '../routes/cura_dialog_route.dart';

enum DeleteVariant { everything, decline }

class BackendDeleteDialog extends StatefulWidget {
  const BackendDeleteDialog({super.key, required this.variant});

  final DeleteVariant variant;

  static CuraDialogRoute<void> route(
    BuildContext context, {
    DeleteVariant variant = DeleteVariant.everything,
  }) => CuraDialogRoute<void>(
    context: context,
    builder: (BuildContext context) => BackendDeleteDialog(variant: variant),
  );

  @override
  State<BackendDeleteDialog> createState() => _BackendDeleteDialogState();
}

class _BackendDeleteDialogState extends State<BackendDeleteDialog> {
  bool _pending = false;
  bool _busyVisible = false;
  bool _sendingFirst = false;
  DeleteUiResult? _result;
  Timer? _busyTimer;

  @override
  void dispose() {
    _busyTimer?.cancel();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_pending) return;
    final BackendController backend = BackendScope.readOf(context)!;
    setState(() {
      _pending = true;
      _result = null;
      _sendingFirst = backend.hasPendingEntries;
    });
    _busyTimer = Timer(CuraMotion.busyDelay, () {
      if (mounted && _pending) setState(() => _busyVisible = true);
    });
    final DeleteUiResult result = await backend.deleteAccount();
    _busyTimer?.cancel();
    if (!mounted) return;
    // Bei `done` baut BackendRoot den Navigationsstapel ab.
    setState(() {
      _pending = false;
      _busyVisible = false;
      _sendingFirst = false;
      _result = result == DeleteUiResult.done ? null : result;
    });
  }

  void _cancel() {
    if (_pending) return;
    Navigator.of(context).pop();
  }

  String? _errorText(DeleteUiResult? r) => switch (r) {
    null || DeleteUiResult.done => null,
    DeleteUiResult.notDeletedOffline => S.deleteOffline,
    DeleteUiResult.notDeletedRejected => S.deleteRejected,
    DeleteUiResult.unclear => S.deleteUnclear,
    DeleteUiResult.localFailure => S.deleteLocalFailure,
  };

  @override
  Widget build(BuildContext context) {
    final bool decline = widget.variant == DeleteVariant.decline;
    final String? error = _errorText(_result);
    final bool failed = _result != null;
    Widget? extra;
    if (error != null) {
      extra = NoticeCard(kind: NoticeKind.error, text: error, live: true);
    } else if (_busyVisible && _sendingFirst) {
      extra = const NoticeCard(
        kind: NoticeKind.info,
        text: S.deleteSendingPending,
        live: true,
      );
    }
    return PopScope(
      canPop: !_pending,
      child: CuraDialog(
        icon: Icons.delete_outline_rounded,
        title: decline ? S.declineTitle : S.deleteTitle,
        message: decline ? S.declineText : S.deleteBackendText,
        extra: extra,
        actions: <Widget>[
          PillButton(
            label: failed ? S.deleteClose : (decline ? S.back : S.cancel),
            variant: PillButtonVariant.neutral,
            autofocus: true,
            onPressed: _busyVisible ? null : _cancel,
          ),
          PillButton(
            label: failed
                ? S.retry
                : (decline ? S.declineDelete : S.deleteConfirm),
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
