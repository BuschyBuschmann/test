// Die Welt der App (Design-Brief v2, 3.1 „Zeitregel“): [WorldHost] hält die
// aktuelle Mischung (fester Look oder Zeitregel) und die daraus gebildete
// Palette, rechnet beim Start, bei Rückkehr in den Vordergrund, bei Änderung
// der Einstellung und per Minuten-Timer neu und stellt sie als [WorldScope]
// bereit. Die Welt wird nie animiert: Jede Neuberechnung ersetzt die Palette
// in einem Schritt (bei „Bewegung reduzieren“ gibt es keinen Timer, die Welt
// springt nur beim Öffnen eines Screens, Brief 3.1).
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../logic/world_time.dart';
import '../theme/cura_motion.dart';
import '../theme/tokens.dart';
import '../theme/world_tokens.dart';
import 'display_controller.dart';
import 'display_scope.dart';

class WorldScope extends InheritedWidget {
  const WorldScope({
    super.key,
    required this.mix,
    required this.palette,
    required this.refresh,
    required super.child,
  });

  final WorldMix mix;
  final WorldPalette palette;

  /// Rechnet die Welt jetzt neu (z. B. beim Öffnen eines Screens).
  final VoidCallback refresh;

  static WorldScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorldScope>();

  /// Palette ohne Scope: reiner Mittag (deterministisch für Bausteintests).
  static WorldPalette paletteOf(BuildContext context) =>
      maybeOf(context)?.palette ?? WorldPalette.midday;

  @override
  bool updateShouldNotify(WorldScope oldWidget) =>
      oldWidget.mix != mix || oldWidget.palette != palette;
}

class WorldHost extends StatefulWidget {
  const WorldHost({super.key, required this.child});

  final Widget child;

  @override
  State<WorldHost> createState() => _WorldHostState();
}

class _WorldHostState extends State<WorldHost> with WidgetsBindingObserver {
  DisplayController? _display;
  Timer? _timer;
  bool _reduced = false;
  WorldMix _mix = const WorldMix.pure(WorldPhase.midday);
  WorldPalette _palette = WorldPalette.midday;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final DisplayController? next = DisplayScope.maybeOf(context);
    if (next != _display) {
      _display?.removeListener(_onSettings);
      _display = next;
      _display?.addListener(_onSettings);
    }
    _reduced = CuraMotion.of(context).reduced;
    _compute();
    _syncTimer();
  }

  void _onSettings() {
    _refresh();
    _syncTimer();
  }

  WorldMix _currentMix() =>
      _display?.worldNow() ?? const WorldMix.pure(WorldPhase.midday);

  void _compute() {
    final WorldMix mix = _currentMix();
    if (mix == _mix) return;
    _mix = mix;
    _palette = WorldPalette.forMix(mix);
  }

  void _refresh() {
    if (!mounted) return;
    final WorldMix mix = _currentMix();
    if (mix == _mix) return;
    setState(() {
      _mix = mix;
      _palette = WorldPalette.forMix(mix);
    });
  }

  /// Minuten-Timer nur bei „Automatisch“ und ohne reduzierte Bewegung.
  void _syncTimer() {
    final bool needed =
        !_reduced && _display?.settings.world == WorldChoice.automatic;
    if (!needed) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(MotionTokens.worldTick, (_) => _refresh());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _display?.removeListener(_onSettings);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorldScope(
      mix: _mix,
      palette: _palette,
      refresh: _refresh,
      child: widget.child,
    );
  }
}
