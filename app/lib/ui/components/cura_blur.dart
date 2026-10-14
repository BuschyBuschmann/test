// `CuraBlur` (Plan 8.3, Brief 3.5): einzige Stelle mit `BackdropFilter`
// (KONVENTIONEN Regel 2). Blur-Budget: höchstens [BlurTokens.maxPerScreen]
// (3) gleichzeitig gebaute `CuraBlur` je [BlurBudgetScope]; zulässig sind nur
// Leiste, Kopf-Karte und Manny-Knopf (Regel 3 der statischen Prüfung; während
// des Umbaus noch Blase und Sheet). Ein vierter Blur bekommt keinen Platz im
// Budget und bleibt unscharf (Fallback wie „Transparenz reduzieren“: Fläche
// des Kindes opak); wird ein Platz frei, rückt der nächste nach.
//
// Bei `blurEnabled == false` (Hoher Kontrast/Transparenz reduzieren) wird
// nichts weichgezeichnet und kein Platz belegt; die Fläche des Kindes ist
// dann opak.
import 'dart:ui' show ImageFilter;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../theme/cura_colors.dart';
import '../../theme/tokens.dart';

/// Zähler der belegten Blur-Plätze.
class BlurBudget {
  BlurBudget({this.capacity = BlurTokens.maxPerScreen});

  /// Obergrenze gleichzeitiger Blur-Flächen.
  final int capacity;

  int _used = 0;
  final List<VoidCallback> _waiters = <VoidCallback>[];

  /// Belegte Plätze.
  int get used => _used;

  bool tryAcquire() {
    if (_used >= capacity) return false;
    _used++;
    return true;
  }

  void release() {
    if (_used > 0) _used--;
    _notifyWaiters();
  }

  void addWaiter(VoidCallback retry) {
    if (!_waiters.contains(retry)) _waiters.add(retry);
  }

  void removeWaiter(VoidCallback retry) => _waiters.remove(retry);

  void _notifyWaiters() {
    if (_waiters.isEmpty) return;
    // Nicht während des Abbaus des Baums neu bauen: nach dem Frame.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      for (final VoidCallback retry in List<VoidCallback>.of(_waiters)) {
        retry();
      }
    });
  }
}

/// Stellt ein [BlurBudget] bereit. Ein Scope je Screen; die App legt einen
/// über alle Screens (Obergrenze 3 gleichzeitig gebaute Blur-Flächen).
class BlurBudgetScope extends StatefulWidget {
  const BlurBudgetScope({
    super.key,
    required this.child,
    this.capacity = BlurTokens.maxPerScreen,
  });

  final Widget child;
  final int capacity;

  /// Das Budget oberhalb von [context]; `null` ohne Scope (dann ist der Blur
  /// unbegrenzt, nur Tests von Einzelbausteinen).
  static BlurBudget? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BlurBudgetInherited>()?.budget;

  @override
  State<BlurBudgetScope> createState() => _BlurBudgetScopeState();
}

class _BlurBudgetScopeState extends State<BlurBudgetScope> {
  late final BlurBudget _budget = BlurBudget(capacity: widget.capacity);

  @override
  Widget build(BuildContext context) =>
      _BlurBudgetInherited(budget: _budget, child: widget.child);
}

class _BlurBudgetInherited extends InheritedWidget {
  const _BlurBudgetInherited({required this.budget, required super.child});

  final BlurBudget budget;

  @override
  bool updateShouldNotify(_BlurBudgetInherited oldWidget) =>
      oldWidget.budget != budget;
}

class CuraBlur extends StatefulWidget {
  const CuraBlur({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.sigma = BlurTokens.sigma,
  });

  final Widget child;

  /// Zuschnitt des weichgezeichneten Bereichs (Form der schwebenden Fläche).
  final BorderRadius borderRadius;

  /// Stärke der Weichzeichnung (Leiste `BlurTokens.navSigma`, Kopf-Karte
  /// `BlurTokens.headerSigma`).
  final double sigma;

  @override
  State<CuraBlur> createState() => _CuraBlurState();
}

class _CuraBlurState extends State<CuraBlur> {
  BlurBudget? _budget;
  bool _holds = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final BlurBudget? next = BlurBudgetScope.maybeOf(context);
    if (next != _budget) {
      _giveBack();
      _budget = next;
    }
    // Hoher Kontrast an/aus ändert das Theme und kommt hier an.
    if (_wanted) {
      _acquire();
    } else {
      _giveBack();
    }
  }

  bool get _wanted => CuraColors.of(context).blurEnabled;

  void _acquire() {
    final BlurBudget? budget = _budget;
    if (budget == null || _holds) return;
    if (!_wanted) return;
    if (budget.tryAcquire()) {
      _holds = true;
      budget.removeWaiter(_retry);
    } else {
      budget.addWaiter(_retry);
    }
  }

  void _giveBack() {
    final BlurBudget? budget = _budget;
    if (budget == null) return;
    budget.removeWaiter(_retry);
    if (_holds) {
      _holds = false;
      budget.release();
    }
  }

  void _retry() {
    if (!mounted || _holds) return;
    final BlurBudget? budget = _budget;
    if (budget != null && budget.tryAcquire()) {
      budget.removeWaiter(_retry);
      setState(() => _holds = true);
    }
  }

  @override
  void dispose() {
    _giveBack();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_wanted) return widget.child;
    if (_budget != null && !_holds) return widget.child;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.sigma, sigmaY: widget.sigma),
        child: widget.child,
      ),
    );
  }
}
