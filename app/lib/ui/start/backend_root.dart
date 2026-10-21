// `BackendRoot` (F2-4a, Plan 8.1, 8.2): erste Route im Backend-Modus. Zeigt je
// Phase des [BackendController] den Code-Start, die Hinweise, die
// Einwilligung, das Laden oder die Home-Route. Verlässt der Controller die
// Phase `ready` (gelöste Bindung, Löschen), werden alle darüberliegenden Routen
// abgeräumt. Der Wechsel zurück in die App aus dem Hintergrund stößt das
// Abarbeiten der Warteschlange und das Neuladen an.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../state/backend_controller.dart';
import '../../state/backend_scope.dart';
import '../components/screen_frame.dart';
import '../home/home_shell.dart';
import 'code_start_flow.dart';
import 'consent_view.dart';
import 'notice_views.dart';
import 'start_loading_view.dart';

class BackendRoot extends StatefulWidget {
  const BackendRoot({super.key, this.startup, this.initialCode});

  /// Start statt `controller.load()` (Prüfumgebung, Tests).
  final Future<void> Function(AppController controller)? startup;

  /// Code aus einem Einladungslink.
  final String? initialCode;

  @override
  State<BackendRoot> createState() => _BackendRootState();
}

class _BackendRootState extends State<BackendRoot> {
  bool _started = false;
  BackendController? _backend;
  AppLifecycleListener? _lifecycle;
  BackendPhase? _lastPhase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final BackendController backend = BackendScope.readOf(context)!;
    final AppController app = AppScope.of(context);
    _backend = backend;
    backend.addListener(_onBackend);
    _lifecycle = AppLifecycleListener(onResume: backend.didResume);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final Future<void> Function(AppController)? startup = widget.startup;
      backend.start(loadApp: startup == null ? null : () => startup(app));
    });
  }

  void _onBackend() {
    final BackendPhase phase = _backend!.phase;
    final BackendPhase? last = _lastPhase;
    _lastPhase = phase;
    if (phase == BackendPhase.ready || last != BackendPhase.ready) return;
    // Die Inhalte sind weg: darüberliegende Routen (Sheets, Chat, Dialoge)
    // schließen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _backend?.removeListener(_onBackend);
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BackendController backend = BackendScope.maybeOf(context)!;
    final AppController app = AppScope.of(context);
    _lastPhase ??= backend.phase;
    return switch (backend.phase) {
      BackendPhase.starting => const ScreenFrame(child: StartLoadingView()),
      BackendPhase.deletionPending => const DeletionPendingView(),
      BackendPhase.codeStart => CodeStartFlow(
        key: const ValueKey<String>('code-start'),
        initialCode: widget.initialCode,
      ),
      BackendPhase.rebindNotice => const ReboundNoticeView(),
      BackendPhase.consent => const ConsentView(),
      BackendPhase.loading => const BackendLoadingView(),
      BackendPhase.loadError => BackendErrorView(
        message: app.loadStatus == LoadStatus.error
            ? S.startLoadError
            : S.backendLoadError,
        onRetry: app.loadStatus == LoadStatus.error
            ? backend.retryStart
            : backend.refresh,
      ),
      BackendPhase.bindingLostNotice => const BindingLostView(),
      BackendPhase.ready => const HomeShell(),
    };
  }
}
