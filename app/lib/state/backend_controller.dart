// Backend-Modus der Patienten-App (F2-4a, Plan 8.1, 8.2, 8.10, 8.11): hält die
// Verdrahtung (Warteschlange, Repositories, Löscher) und die Phase des
// Einstiegs: Start, Code, Neuanmeldungs-Hinweis, Einwilligung, Laden, bereit.
// Ohne `BackendController` läuft die App im Demo-Modus wie bisher.
//
// Der lokale Zustand (`AppState`) bleibt beim [AppController]; hier stehen nur
// die Abläufe, die das Backend brauchen.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../backend/backend_errors.dart';
import '../backend/outbox_sender.dart';
import '../backend/patient_backend.dart';
import '../data/account_deleter.dart';
import '../data/account_repository.dart';
import '../data/data_eraser.dart';
import '../data/framework_cache.dart';
import '../data/framework_repository.dart';
import '../data/key_value_store.dart';
import '../data/outbox_store.dart';
import '../data/record_repository.dart';
import '../logic/account.dart';
import '../logic/app_state.dart' show AccountState;
import '../logic/backend_failure.dart';
import '../logic/clock.dart';
import '../logic/code_start.dart';
import '../logic/manny_look.dart';
import '../logic/outbox.dart';
import 'app_controller.dart';

export '../logic/code_start.dart'
    show BindingLostKind, ConsentFailure, DeleteUiResult, RedeemFailure;

enum BackendPhase {
  /// Start läuft (Zustand lesen, unterbrochene Löschung prüfen).
  starting,

  /// Eine Löschung ist nicht abgeschlossen: „Löschen noch nicht abgeschlossen“.
  deletionPending,

  /// Look-Schritt und Zugang.
  codeStart,

  /// Hinweis „Du bist neu angemeldet“ (nach `ok_rebound`).
  rebindNotice,

  /// Einwilligung.
  consent,

  /// Framework wird geladen, kein Zwischenspeicher.
  loading,

  /// Inhalte stehen (aktuell oder aus dem Zwischenspeicher).
  ready,

  /// Laden ohne Zwischenspeicher gescheitert, oder der lokale Zustand ließ
  /// sich nicht lesen.
  loadError,

  /// Bindung gelöst (altes Gerät): Hinweis, danach Code-Start.
  bindingLostNotice,
}

class BackendController extends ChangeNotifier {
  BackendController._({
    required this.app,
    required this.backend,
    required this.sender,
    required this.accounts,
    required this.frameworks,
    required this.cache,
    required this.deleter,
    required this._clock,
    required List<DataEraser> localErasers,
    required this._newId,
  }) : _localErasers = List<DataEraser>.unmodifiable(localErasers) {
    app.onMannyLookChanged = _onLookChanged;
    _outboxSub = sender.changes.listen((_) => notifyListeners());
  }

  /// Verdrahtung aus einem Backend und einem Schlüssel-Speicher. Der Speicher
  /// hält Warteschlange, Zwischenspeicher und Merkzeichen. [localErasers] sind
  /// die lokalen Löscher (Zustand, Darstellung …); Zwischenspeicher und
  /// Warteschlange werden hier ergänzt.
  factory BackendController.wire({
    required PatientBackend backend,
    required AppController app,
    required KeyValueStore store,
    required Clock clock,
    List<DataEraser> localErasers = const <DataEraser>[],
    String Function()? newId,
  }) {
    late final BackendController controller;
    final OutboxSender sender = OutboxSender(
      store: StoreOutboxStore(store),
      backend: backend,
      onBindingLost: () => controller.handleBindingLost(),
    );
    final FrameworkCache cache = StoreFrameworkCache(store);
    final List<DataEraser> erasers = <DataEraser>[...localErasers, cache];
    controller = BackendController._(
      app: app,
      backend: backend,
      sender: sender,
      accounts: AccountRepository(
        backend: backend,
        sender: sender,
        clock: clock,
        newId: newId,
      ),
      frameworks: BackendFrameworkRepository(
        backend: backend,
        cache: cache,
        clock: clock,
      ),
      cache: cache,
      deleter: AccountDeleter(
        backend: backend,
        sender: sender,
        marker: StoreDeletionMarkerStore(store),
        localErasers: erasers,
      ),
      clock: clock,
      localErasers: erasers,
      newId: newId,
    );
    return controller;
  }

  final AppController app;
  final PatientBackend backend;
  final OutboxSender sender;
  final AccountRepository accounts;
  final FrameworkRepository frameworks;
  final FrameworkCache cache;
  final AccountDeleter deleter;
  final Clock _clock;
  final List<DataEraser> _localErasers;
  final String Function()? _newId;
  StreamSubscription<Outbox>? _outboxSub;

  BackendPhase _phase = BackendPhase.starting;
  FrameworkLoad? _framework;
  bool _refreshing = false;
  RecordRepository? _records;

  int _codeStartTotal = 2;
  bool _redeeming = false;
  RedeemFailure? _redeemFailure;
  MannyLook? _reboundLookNote;
  bool _consentBusy = false;
  ConsentFailure? _consentFailure;
  bool _deleting = false;
  bool _pendingBusy = false;
  bool _pendingOffline = false;
  BindingLostKind _lostKind = BindingLostKind.otherDevice;
  bool _lookSyncPending = false;
  bool _applyingLook = false;
  final Set<String> _dismissedDeferred = <String>{};

  BackendPhase get phase => _phase;

  /// Letzter geladener oder zwischengespeicherter Stand.
  FrameworkLoad? get framework => _framework;

  /// Ein Laden im Hintergrund läuft (Zwischenspeicher steht schon).
  bool get isRefreshing => _refreshing;

  /// Schreibwege (Abhaken, Termine); erst mit Bindung.
  RecordRepository? get records => _records;

  /// Anzahl der Schritte des Code-Starts (2 oder 3, für „Schritt N von M“ der
  /// Einwilligung); gesetzt beim Einlösen.
  int get codeStartTotal => _codeStartTotal;

  bool get isRedeeming => _redeeming;
  RedeemFailure? get redeemFailure => _redeemFailure;

  /// Konto-Look, der bei der Neubindung übernommen wurde und vom zuvor
  /// gewählten abweicht (Satz im Neuanmeldungs-Hinweis).
  MannyLook? get reboundLookNote => _reboundLookNote;

  bool get isConsentBusy => _consentBusy;
  ConsentFailure? get consentFailure => _consentFailure;
  bool get isDeleting => _deleting;
  bool get isPendingBusy => _pendingBusy;
  bool get pendingOffline => _pendingOffline;
  BindingLostKind get lostKind => _lostKind;

  /// Zurückgestellte Einträge (NIT-2).
  int get deferredCount => sender.deferredCount;

  /// Hinweis „Ein Eintrag konnte nicht gesendet werden“ sichtbar?
  bool get deferredNoticeVisible => showDeferredNotice(
    deferredIds: <String>[
      for (final OutboxEntry e in sender.outbox.deferred) e.id,
    ],
    dismissedIds: _dismissedDeferred,
  );

  /// Es gibt Einträge, die noch nicht gesendet wurden.
  bool get hasPendingEntries => !sender.outbox.isEmpty;

  void _set(BackendPhase next) {
    _phase = next;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Start
  // -------------------------------------------------------------------------

  /// Startet: Warteschlange lesen, unterbrochene Löschung abschließen,
  /// Zustand laden, dann je nach Konto weiter (Plan 8.2, 8.10).
  Future<void> start({Future<void> Function()? loadApp}) async {
    _set(BackendPhase.starting);
    await sender.load();
    final DeletionResume resume = await deleter.resumeOnStart();
    switch (resume) {
      case DeletionResume.none:
        break;
      case DeletionResume.completed:
        sender.resume();
        await _loadApp(loadApp);
        app.setStartNotice(StartNotice.deleted);
        _enterCodeStart();
        return;
      case DeletionResume.localFailure:
      case DeletionResume.accountStillExists:
      case DeletionResume.unknown:
        _pendingOffline = resume == DeletionResume.unknown;
        _set(BackendPhase.deletionPending);
        return;
    }
    await _loadApp(loadApp);
    if (app.loadStatus == LoadStatus.error) {
      _set(BackendPhase.loadError);
      return;
    }
    await _route();
  }

  Future<void> _loadApp(Future<void> Function()? loadApp) =>
      loadApp == null ? app.load() : loadApp();

  Future<void> _route() async {
    final AccountState? account = app.state.account;
    if (account == null) {
      _enterCodeStart();
      return;
    }
    _records = _recordsFor(account);
    if (app.state.consent == null) {
      _set(BackendPhase.consent);
      return;
    }
    unawaited(sender.drain(retryDeferred: true));
    await loadFramework();
  }

  RecordRepository _recordsFor(AccountState account) => RecordRepository(
    sender: sender,
    clock: _clock,
    patientId: account.patientId,
    newId: _newId,
  );

  void _enterCodeStart() {
    _framework = null;
    _records = null;
    _redeemFailure = null;
    _set(BackendPhase.codeStart);
  }

  /// „Nochmal versuchen“ nach einem Fehler beim Start.
  Future<void> retryStart() => start();

  // -------------------------------------------------------------------------
  // Framework laden (Plan 8.2)
  // -------------------------------------------------------------------------

  /// Lädt das Framework. Steht ein Zwischenspeicher dieses Patienten bereit,
  /// ist sofort alles da (Phase `ready`, `stale`), und das Laden läuft im
  /// Hintergrund weiter. Ohne Zwischenspeicher: Phase `loading`.
  Future<void> loadFramework() async {
    final AccountState? account = app.state.account;
    if (account == null || _refreshing) return;
    if (_framework == null) {
      final CachedFramework? cached = await cache.read();
      if (cached != null && cached.framework.patient.id == account.patientId) {
        _framework = FrameworkLoad(
          framework: cached.framework,
          loadedAt: cached.savedAt,
          stale: true,
        );
        app.adoptFramework(cached.framework);
        _set(BackendPhase.ready);
      } else {
        _set(BackendPhase.loading);
      }
    }
    _refreshing = true;
    notifyListeners();
    try {
      final FrameworkLoad load = await frameworks.load(
        expectedPatientId: account.patientId,
      );
      _framework = load;
      app.adoptFramework(load.framework);
      _set(BackendPhase.ready);
      await _retryLookSync();
    } on BindingLostException catch (e) {
      _refreshing = false;
      await handleBindingLost(e);
      return;
    } on FrameworkLoadException {
      if (_framework == null) _set(BackendPhase.loadError);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  /// „Aktualisieren“ bzw. „Nochmal versuchen“.
  Future<void> refresh() async {
    if (_phase == BackendPhase.loadError) _set(BackendPhase.loading);
    await loadFramework();
  }

  /// App kommt aus dem Hintergrund zurück: Warteschlange abarbeiten, neu laden.
  Future<void> didResume() async {
    if (_phase != BackendPhase.ready) return;
    unawaited(sender.drain(retryDeferred: true));
    await loadFramework();
  }

  // -------------------------------------------------------------------------
  // Code einlösen (A2)
  // -------------------------------------------------------------------------

  /// Löst [rawCode] ein. Der Aufrufer liest das Ergebnis aus [phase] und
  /// [redeemFailure].
  Future<void> redeem(String rawCode, {int totalSteps = 2}) async {
    if (_redeeming) return;
    _codeStartTotal = totalSteps;
    _redeeming = true;
    _redeemFailure = null;
    notifyListeners();
    try {
      final MannyLook localLook = app.state.mannyLook;
      final BindOutcome outcome = await accounts.redeem(
        rawCode: rawCode,
        localLook: localLook,
      );
      final AccountState? account = outcome.account;
      if (account == null) {
        _redeemFailure = RedeemFailure.of(outcome.result);
        return;
      }
      final LookSyncDecision? look = outcome.look;
      final MannyLook? adopted = look is AdoptAccountLook ? look.look : null;
      _lookSyncPending = look is LookSyncUndecided;
      _applyingLook = true;
      app.bindAccount(account, adoptedLook: adopted);
      _applyingLook = false;
      _records = _recordsFor(account);
      if (outcome.result == RedeemResult.okRebound) {
        _reboundLookNote = (adopted != null && adopted != localLook)
            ? adopted
            : null;
        if (await _serverHasConsent()) {
          app.applyConsent(kConsentVersion);
        }
        _set(BackendPhase.rebindNotice);
      } else {
        _reboundLookNote = null;
        _set(BackendPhase.consent);
      }
    } on BackendFailure {
      _redeemFailure = RedeemFailure.network;
    } on BindingLostException {
      _redeemFailure = RedeemFailure.notAllowed;
    } finally {
      _applyingLook = false;
      _redeeming = false;
      notifyListeners();
    }
  }

  Future<bool> _serverHasConsent() async {
    try {
      return await withSessionRefresh<bool>(
        backend,
        () => backend.hasConsent(kConsentKind, kConsentVersion),
      );
    } on Object {
      return false;
    }
  }

  /// „Verstanden“ im Neuanmeldungs-Hinweis.
  Future<void> acknowledgeRebound() async {
    _reboundLookNote = null;
    if (app.state.consent == null) {
      _set(BackendPhase.consent);
    } else {
      unawaited(sender.drain(retryDeferred: true));
      await loadFramework();
    }
  }

  // -------------------------------------------------------------------------
  // Einwilligung (A3)
  // -------------------------------------------------------------------------

  Future<void> acceptConsent() async {
    if (_consentBusy) return;
    _consentBusy = true;
    _consentFailure = null;
    notifyListeners();
    try {
      await accounts.acceptConsent(kConsentKind, kConsentVersion);
      app.applyConsent(kConsentVersion);
      _consentBusy = false;
      notifyListeners();
      unawaited(sender.drain(retryDeferred: true));
      await loadFramework();
    } on BackendFailure catch (f) {
      _consentFailure = f.kind == FailureKind.unreachable
          ? ConsentFailure.offline
          : ConsentFailure.failed;
    } on BindingLostException catch (e) {
      _consentBusy = false;
      await handleBindingLost(e);
    } finally {
      _consentBusy = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Bindung gelöst (A4, altes Gerät)
  // -------------------------------------------------------------------------

  /// Lokale Daten löschen, Hinweis zeigen (Plan 8.2, B-11).
  Future<void> handleBindingLost([BindingLostException? e]) async {
    if (_deleting || _phase == BackendPhase.bindingLostNotice) return;
    _lostKind = e?.reason == 'access_deleted'
        ? BindingLostKind.accessDeleted
        : BindingLostKind.otherDevice;
    try {
      await sender.discardAll();
      for (final DataEraser eraser in _localErasers) {
        await eraser.eraseAll();
      }
    } on Object catch (err) {
      debugPrint('Lokales Aufräumen nach gelöster Bindung: $err');
    }
    app.resetStateLocally();
    _framework = null;
    _records = null;
    _set(BackendPhase.bindingLostNotice);
  }

  /// „Weiter“ im Hinweis des alten Geräts.
  void acknowledgeBindingLost() => _enterCodeStart();

  // -------------------------------------------------------------------------
  // Löschen (A11)
  // -------------------------------------------------------------------------

  /// „Alles löschen“ bzw. „Zugang löschen“ (Plan 8.10).
  Future<DeleteUiResult> deleteAccount() async {
    if (_deleting) return DeleteUiResult.unclear;
    _deleting = true;
    notifyListeners();
    try {
      await app.lockForExternalDelete();
      final DeletionOutcome outcome = await deleter.run();
      switch (outcome) {
        case DeletionOutcome.done:
          // Der Sender blieb nach dem Löschen pausiert (F2-3R MINOR-2).
          sender.resume();
          _dismissedDeferred.clear();
          app.resetAfterExternalDelete();
          _enterCodeStart();
          return DeleteUiResult.done;
        case DeletionOutcome.notDeleted:
          app.unlockAfterFailedExternalDelete();
          return deleter.lastFailure?.kind == FailureKind.unreachable
              ? DeleteUiResult.notDeletedOffline
              : DeleteUiResult.notDeletedRejected;
        case DeletionOutcome.unclear:
          app.unlockAfterFailedExternalDelete();
          return DeleteUiResult.unclear;
        case DeletionOutcome.localFailure:
          return DeleteUiResult.localFailure;
      }
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }

  /// „Nochmal versuchen“ auf dem Bildschirm „Löschen noch nicht abgeschlossen“.
  Future<void> retryPendingDeletion() async {
    if (_pendingBusy) return;
    _pendingBusy = true;
    notifyListeners();
    try {
      final DeletionOutcome outcome = await deleter.run();
      if (outcome == DeletionOutcome.done) {
        sender.resume();
        await app.load();
        app.setStartNotice(StartNotice.deleted);
        _enterCodeStart();
        return;
      }
      _pendingOffline =
          outcome == DeletionOutcome.notDeleted &&
          deleter.lastFailure?.kind == FailureKind.unreachable;
    } finally {
      _pendingBusy = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Manny-Look im Konto (O-41)
  // -------------------------------------------------------------------------

  void _onLookChanged(MannyLook look) {
    if (_applyingLook || app.state.account == null) return;
    unawaited(accounts.setMannyLook(look));
  }

  /// Ließ sich der Konto-Wert bei der Neubindung nicht lesen, wird der
  /// Abgleich nach dem ersten erfolgreichen Laden wiederholt.
  Future<void> _retryLookSync() async {
    if (!_lookSyncPending) return;
    _lookSyncPending = false;
    final LookSyncDecision d = await accounts.syncLookAfterBinding(
      result: RedeemResult.okRebound,
      localLook: app.state.mannyLook,
    );
    if (d is LookSyncUndecided) {
      _lookSyncPending = true;
    } else if (d is AdoptAccountLook && d.look != app.state.mannyLook) {
      _applyingLook = true;
      app.setMannyLook(d.look);
      _applyingLook = false;
    }
  }

  // -------------------------------------------------------------------------
  // Zurückgestellte Einträge (NIT-2, A10)
  // -------------------------------------------------------------------------

  /// „Nochmal senden“: sofort ein neuer Versuch.
  Future<void> resendDeferred() async {
    await sender.drain(retryDeferred: true);
    notifyListeners();
  }

  /// X am Hinweis: nur lokal ausblenden; ein neuer zurückgestellter Eintrag
  /// bringt ihn zurück.
  void dismissDeferredNotice() {
    _dismissedDeferred.addAll(<String>[
      for (final OutboxEntry e in sender.outbox.deferred) e.id,
    ]);
    notifyListeners();
  }

  @override
  void dispose() {
    app.onMannyLookChanged = null;
    unawaited(_outboxSub?.cancel());
    super.dispose();
  }
}
