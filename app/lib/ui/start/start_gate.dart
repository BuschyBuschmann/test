// `StartGate` (Plan 4.1, 6.2): erste Route. Lädt den Zustand und wechselt per
// `pushReplacement` auf das Onboarding (am gespeicherten Schritt, UI-16) oder
// auf Home.
//
// - Unlesbare Daten (N-12): der Controller verwirft sie und setzt
//   [StartNotice.unreadable]; das Onboarding startet bei Schritt 1 mit Hinweis.
// - Plattformfehler oder Programmierfehler beim Lesen: Fehlerzustand im
//   Pfad-Layout mit „Nochmal versuchen“, die Daten bleiben erhalten (A-6).
// - Ladeansicht: statische Glas-Kreise, keine künstliche Verzögerung.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../logic/app_state.dart' show OnboardingState;
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../components/screen_frame.dart';
import '../path/path_error_view.dart';
import '../routes/app_routes.dart';
import 'start_loading_view.dart';

class StartGate extends StatefulWidget {
  const StartGate({super.key, this.startup});

  /// Start statt `controller.load()` (Prüfumgebung, Tests).
  final Future<void> Function(AppController controller)? startup;

  @override
  State<StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<StartGate> {
  bool _started = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final AppController controller = AppScope.of(context);
    // `load` benachrichtigt den Controller synchron; das darf nicht im
    // Bauen geschehen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start(controller);
    });
  }

  Future<void> _start(AppController controller) async {
    try {
      final Future<void> Function(AppController)? startup = widget.startup;
      await (startup == null ? controller.load() : startup(controller));
    } catch (e, stack) {
      // `load` fängt alles selbst ab; das hier sichert eigene Startfunktionen.
      debugPrint('Start fehlgeschlagen: $e\n$stack');
      if (mounted) setState(() => _failed = true);
      return;
    }
    _proceed(controller);
  }

  void _proceed(AppController controller) {
    if (!mounted) return;
    if (_failed || controller.loadStatus == LoadStatus.error) {
      setState(() => _failed = true);
      return;
    }
    final NavigatorState navigator = Navigator.of(context);
    final OnboardingState onboarding = controller.state.onboarding;
    final Route<void> next = onboarding.completed
        ? AppRoutes.home(context)
        : AppRoutes.onboarding(
            context,
            step: onboarding.step,
            notice: controller.startNotice,
          );
    navigator.pushReplacement<void, void>(next);
  }

  Future<void> _retry() async {
    final AppController controller = AppScope.of(context);
    setState(() => _failed = false);
    await controller.retryLoad();
    _proceed(controller);
  }

  @override
  Widget build(BuildContext context) {
    final bool error =
        _failed || AppScope.of(context).loadStatus == LoadStatus.error;
    return ScreenFrame(
      child: error
          ? PathErrorView(onRetry: _retry, message: S.startLoadError)
          : const StartLoadingView(),
    );
  }
}
