// Nicht persistierter UI-Zustand (Plan 5): Rückgängig-Fenster, offene Blase,
// offener Hinweis. Ein App-Neustart beendet alles (A-5).
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logic/manny_occasions.dart';
import '../logic/undo.dart';
import '../theme/tokens.dart';

/// Was das Rückgängig-Fenster gerade zurücknehmen würde.
sealed class UndoEntry {
  const UndoEntry();
}

class TrainingUndo extends UndoEntry {
  const TrainingUndo(this.snapshot);

  final TrainingSnapshot snapshot;
}

class RemovalUndo extends UndoEntry {
  const RemovalUndo(this.token);

  final RemovalToken token;
}

/// Fenster, Timer und Schnappschuss-Halter des Rückgängig liegen
/// ausschließlich hier. Es gibt genau **eine** Methode, die das Fenster
/// beendet: [endUndoWindow] (Tabwechsel, Tageswechsel, neue Snackbar, Öffnen
/// von Chat/Nachrichten rufen sie gleichermaßen auf).
class TransientUi extends ChangeNotifier {
  TransientUi({Duration? undoDuration})
    : _undoDuration = undoDuration ?? SnackbarTokens.long;

  final Duration _undoDuration;
  UndoEntry? _undo;
  Timer? _timer;
  BubbleDecision? _bubble;
  String? _hintUnitId;
  bool _disposed = false;

  UndoEntry? get undo => _undo;

  bool get undoWindowOpen => _undo != null;

  /// Öffnet das Fenster (8 s wie die Snackbar, UI-39); ein laufendes Fenster
  /// endet dabei (nur eine Snackbar gleichzeitig).
  void startUndoWindow(UndoEntry entry) {
    _timer?.cancel();
    _undo = entry;
    _timer = Timer(_undoDuration, endUndoWindow);
    notifyListeners();
  }

  /// Das offene Fenster läuft ab jetzt ohne eigenen Zeitgeber weiter: sein
  /// Besitzer, die sichtbare Snackbar mit „Rückgängig“, entscheidet über das
  /// Ende (Ablauf mit Pause bei Fokus/Zeiger, kein Ablauf bei Screenreader,
  /// Ergänzung 1, 3.3) und ruft dann [endUndoWindow]. Ohne offenes Fenster
  /// wirkungslos.
  void holdUndoWindow() {
    _timer?.cancel();
    _timer = null;
  }

  /// Beendet das Fenster; der Eintrag bleibt bestehen, es gibt nur kein
  /// „Rückgängig“ mehr.
  void endUndoWindow() {
    _timer?.cancel();
    _timer = null;
    if (_undo == null) return;
    _undo = null;
    if (!_disposed) notifyListeners();
  }

  /// Sichtbare Manny-Blase (Pfad).
  BubbleDecision? get visibleBubble => _bubble;

  void showBubble(BubbleDecision decision) {
    _bubble = decision;
    notifyListeners();
  }

  void dismissBubble() {
    if (_bubble == null) return;
    _bubble = null;
    notifyListeners();
  }

  /// Unit, an der gerade ein `NodeHint` steht.
  String? get hintUnitId => _hintUnitId;

  void showHint(String unitId) {
    _hintUnitId = unitId;
    notifyListeners();
  }

  void dismissHint() {
    if (_hintUnitId == null) return;
    _hintUnitId = null;
    notifyListeners();
  }

  /// Verwirft alles (z. B. nach „Alles löschen“).
  void reset() {
    _timer?.cancel();
    _timer = null;
    _undo = null;
    _bubble = null;
    _hintUnitId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
