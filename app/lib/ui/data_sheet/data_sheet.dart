// `DataSheet` „Deine Daten“ (Ergänzung 1, 3.2, Plan 4.4, 6.3; UI-46 bis 58):
// Profil ändern (Name, Verletzung, Datum) und alle Daten löschen. Ein Sheet
// (`CuraSheetRoute`, E2) mit festem Kopf, scrollendem Mittelteil und fester
// Fußleiste („Speichern“).
//
// - Dieselben Bausteine wie im Onboarding (UI-53, Code-Regel 6): `CuraTextField`,
//   `ChoiceCard`, `DateCard`; kein Manny, keine Mikrofon-Zeile.
// - „Speichern“ ist aktiv, wenn der Entwurf vom gespeicherten Stand abweicht, der
//   Name nach dem Trimmen nicht leer ist, ein Typ und ein Datum (nicht in der
//   Zukunft) gesetzt sind (`ProfileDraft.canSave`, UI-54).
// - Schließen mit ungespeicherten Änderungen (X, Zurück, Escape, Scrim,
//   Wegwischen auf dem Kopf): `PopScope(canPop: false)` fängt jeden Weg ab und
//   öffnet „Änderungen verwerfen?“ (UI-57). Ohne Änderungen schließt das Sheet
//   direkt.
// - Speichern: `AppController.updateProfile`; das Sheet schließt mit dem
//   Ergebnis, die Shell setzt die Folgen um (Tageswechsel). Rückmeldung nur als
//   Ansage („Gespeichert. Pfad neu berechnet.“): auf dem Pfad gibt es keine
//   Snackbar (K2). Streak, Freezes und Heute-Änderungen bleiben (Logik in
//   `lib/logic/profile.dart`); der Pfad wird neu berechnet und ohne Puls auf die
//   aktuelle Unit zentriert.
// - „Alle Daten löschen und neu starten“ öffnet den `DeleteDialog`.
// - Ganz unten steht der Link „Datenschutzerklärung“ (SK-1): er öffnet die
//   Platzhalterseite aus dem Onboarding über dem Sheet; der Entwurf bleibt.
// - Öffnen/Schließen und Fokusrückgabe an das Icon in der Pfad-Kopfzeile
//   übernimmt `HomeShellState.openDataSheet`.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/strings_de.dart';
import '../../logic/clock.dart';
import '../../logic/date_format.dart';
import '../../logic/injury_type.dart';
import '../../logic/profile.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/choice_card.dart';
import '../components/cura_label.dart';
import '../components/cura_text_field.dart';
import '../components/date_card.dart';
import '../components/info_note.dart';
import '../components/pill_button.dart';
import '../components/probe_keys.dart';
import '../components/sheet_title_bar.dart';
import '../onboarding/step4_date.dart' show DatePickerRange;
import '../routes/app_routes.dart';
import '../routes/cura_sheet_route.dart';
import '../components/cura_pressable.dart';
import '../routes/cura_date_picker.dart';
import '../routes/route_focus.dart';
import 'delete_dialog.dart';
import 'discard_dialog.dart';

class DataSheet extends StatefulWidget {
  const DataSheet({super.key});

  /// Die Sheet-Route; Ergebnis ist das [ProfileUpdateResult] nach „Speichern“,
  /// sonst `null`.
  static CuraSheetRoute<ProfileUpdateResult?> route(BuildContext context) {
    return CuraSheetRoute<ProfileUpdateResult?>(
      context: context,
      routeLabel: S.dataSheetTitle,
      builder: (BuildContext context) => const DataSheet(),
    );
  }

  @override
  State<DataSheet> createState() => _DataSheetState();
}

class _DataSheetState extends State<DataSheet> {
  late ProfileDraft _draft;
  late final TextEditingController _name;
  late final TextEditingController _other;
  final FocusNode _dateFocus = FocusNode(debugLabel: 'Datum');
  final FocusNode _deleteFocus = FocusNode(debugLabel: 'Alle Daten löschen');
  final FocusNode _privacyFocus = FocusNode(debugLabel: 'Datenschutzerklärung');
  bool _discardOpen = false;

  AppController get _controller =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;

  @override
  void initState() {
    super.initState();
    _draft = ProfileDraft.fromState(_controller.state);
    _name = TextEditingController(text: _draft.name);
    _other = TextEditingController(text: _draft.injuryOther);
  }

  @override
  void dispose() {
    _name.dispose();
    _other.dispose();
    _dateFocus.dispose();
    _deleteFocus.dispose();
    _privacyFocus.dispose();
    super.dispose();
  }

  void _update(ProfileDraft draft) => setState(() => _draft = draft);

  Future<void> _pickDate() async {
    final AppController c = _controller;
    final DatePickerRange range = DatePickerRange.from(
      today: c.today,
      saved: _draft.injuryDate,
    );
    final DateTime? picked = await showCuraDatePicker(
      context: context,
      initialDate: range.initial,
      firstDate: range.first,
      lastDate: range.last,
    );
    if (!mounted) return;
    if (picked != null) {
      _update(_draft.copyWith(injuryDate: LocalDay.from(picked)));
    }
    _dateFocus.requestFocus();
  }

  /// Schließversuch mit ungespeicherten Änderungen: „Änderungen verwerfen?“.
  Future<void> _confirmDiscard() async {
    if (_discardOpen) return;
    _discardOpen = true;
    final NavigatorState navigator = Navigator.of(context);
    final bool? discard = await navigator.push<bool>(
      DiscardDialog.route(context),
    );
    _discardOpen = false;
    // Verwerfen schließt das Sheet; die Felder gehen mit ihm unter (nichts
    // wurde gespeichert).
    if (discard == true && mounted) navigator.pop();
  }

  void _save() {
    final AppController c = _controller;
    final ProfileUpdateResult result = c.updateProfile(_draft);
    if (!result.saved) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      result.pathRecomputed ? S.dataSavedRecomputed : S.dataSaved,
      Directionality.of(context),
    );
    Navigator.of(context).pop(result);
  }

  Future<void> _openDelete() {
    return pushReturningFocus<void>(
      Navigator.of(context),
      DeleteDialog.route(context),
      trigger: _deleteFocus,
    );
  }

  /// Öffnet die Datenschutz-Platzhalterseite aus dem Onboarding. Das Sheet
  /// bleibt darunter offen, der Entwurf bleibt erhalten; der Fokus kehrt an den
  /// Eintrag zurück.
  Future<void> _openPrivacy() {
    return pushReturningFocus<void>(
      Navigator.of(context),
      AppRoutes.privacy(context),
      trigger: _privacyFocus,
    );
  }

  Widget _injuryCard(InjuryType type, String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CuraSpace.s3),
      child: ChoiceCard(
        title: title,
        selected: _draft.injuryType == type,
        leadingIcon: icon,
        onPressed: () => _update(_draft.copyWith(injuryType: type)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppController c = AppScope.of(context);
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final bool dirty = _draft.isDirty(c.state);
    final bool canSave = _draft.canSave(c.state, c.today);
    final LocalDay? date = _draft.injuryDate;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return PopScope(
      // Jeder Weg des Schließens läuft über `maybePop` (Zurück, Escape, Scrim,
      // Wischen) und landet hier.
      canPop: !dirty,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _confirmDiscard();
      },
      child: Builder(
        builder: (BuildContext context) {
          // Große Schrift oder wenig Platz: der Untertitel läuft im Scrollbereich
          // mit (bei wenig Platz der ganze Kopf, siehe `CuraSheetFrame`).
          final bool largeText =
              scaler.scale(CuraSize.textScaleUnit) >=
              CuraSize.textScaleScrollAlong;
          final bool compact = largeText || CuraSheetScope.compactOf(context);
          // Wenig Platz und Tastatur sichtbar (kleines Gerät, große Schrift): der
          // Abschnitt „Daten löschen“ entfällt, solange die Tastatur steht. Der
          // lange Löschen-Button (vier Zeilen) bliebe sonst höher als der
          // Scrollbereich, und beim Schreiben tippt ihn niemand. Mit der
          // Tastatur verschwindet auch diese Einschränkung.
          final bool showDelete =
              !(CuraSheetScope.compactOf(context) &&
                  CuraSheetScope.keyboardVisibleOf(context));
          final Widget subtitle = Text(
            S.dataSheetSubtitle,
            style: type.secondary.copyWith(color: colors.text2),
          );
          return CuraSheetFrame(
            header: SheetTitleBar(
              title: S.dataSheetTitle,
              subtitle: compact ? null : S.dataSheetSubtitle,
            ),
            body: Padding(
              padding: const EdgeInsets.only(bottom: CuraSpace.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Feste Kindpositionen (der Fokus eines Feldes übersteht den
                  // Wechsel zwischen normal und kompakt).
                  if (compact) subtitle else const SizedBox.shrink(),
                  SizedBox(height: compact ? CuraSpace.s4 : CuraSpace.s2),
                  const CuraLabel(S.dataProfileLabel),
                  const SizedBox(height: CuraSpace.s2),
                  CuraTextField(
                    label: S.nameLabel,
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.givenName],
                    onChanged: (String v) => _update(_draft.copyWith(name: v)),
                  ),
                  const SizedBox(height: CuraSpace.s6),
                  const CuraLabel(S.dataInjuryLabel),
                  const SizedBox(height: CuraSpace.s2),
                  _injuryCard(InjuryType.acl, S.injuryAcl),
                  _injuryCard(InjuryType.ankle, S.injuryAnkle),
                  _injuryCard(InjuryType.muscle, S.injuryMuscle),
                  _injuryCard(
                    InjuryType.other,
                    S.injuryOther,
                    icon: Icons.edit_rounded,
                  ),
                  if (_draft.injuryType == InjuryType.other)
                    CuraTextField(
                      label: S.injuryOtherLabel,
                      controller: _other,
                      textInputAction: TextInputAction.done,
                      onChanged: (String v) =>
                          _update(_draft.copyWith(injuryOther: v)),
                    ),
                  if (_draft.injuryType != null &&
                      _draft.injuryType != InjuryType.acl) ...<Widget>[
                    const SizedBox(height: CuraSpace.s2),
                    InfoNote(
                      text: S.injuryNoOwnPath,
                      // Nur ansagen, wenn der Typ im Entwurf gerade geändert
                      // wurde, nicht beim Öffnen mit gespeichertem Typ.
                      announce:
                          _draft.injuryType !=
                          _controller.state.onboarding.injuryType,
                    ),
                  ],
                  const SizedBox(height: CuraSpace.s6),
                  const CuraLabel(S.dataDateLabel),
                  const SizedBox(height: CuraSpace.s2),
                  DateCard(
                    valueText: date == null ? null : formatDateFull(date),
                    focusNode: _dateFocus,
                    onPressed: _pickDate,
                  ),
                  const SizedBox(height: CuraSpace.s4),
                  MergeSemantics(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: CuraSpace.s1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: CuraSize.hintIcon,
                            color: colors.text2,
                          ),
                        ),
                        const SizedBox(width: CuraSpace.s2),
                        Expanded(
                          child: Text(
                            S.dataRecomputeNote,
                            style: type.secondary.copyWith(color: colors.text2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // `Offstage` statt `if`: die Struktur bleibt gleich, die Felder
                  // darüber behalten Element, Fokus und Eingabeverbindung, wenn
                  // die Tastatur erscheint. Ausgeblendet nimmt der Abschnitt
                  // weder Platz, noch Fokus, noch Semantik.
                  Offstage(
                    offstage: !showDelete,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: CuraSpace.s6),
                        Divider(
                          height: CuraSize.hairline,
                          thickness: CuraSize.hairline,
                          color: colors.borderHair,
                        ),
                        const SizedBox(height: CuraSpace.s6),
                        const CuraLabel(S.dataDeleteLabel),
                        const SizedBox(height: CuraSpace.s2),
                        Text(
                          S.dataDeleteText,
                          style: type.body.copyWith(color: colors.text2),
                        ),
                        const SizedBox(height: CuraSpace.s3),
                        PillButton(
                          label: S.dataDeleteButton,
                          variant: PillButtonVariant.outline,
                          icon: Icons.delete_outline_rounded,
                          focusNode: _deleteFocus,
                          onPressed: _openDelete,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CuraSpace.s4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CuraPressable(
                      onPressed: _openPrivacy,
                      semanticLabel: S.dataPrivacyEntry,
                      focusNode: _privacyFocus,
                      ringRadius: CuraRadius.chipInner,
                      builder: (BuildContext context, bool pressed) {
                        final Color color = pressed
                            ? colors.text1
                            : colors.accentText;
                        return ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: CuraSize.touchTarget,
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              S.dataPrivacyEntry,
                              style: type.bodyStrong.copyWith(
                                color: color,
                                decoration: TextDecoration.underline,
                                decorationColor: color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            footer: PillButton(
              key: ProbeKeys.primary,
              label: S.dataSave,
              onPressed: canSave ? _save : null,
            ),
          );
        },
      ),
    );
  }
}
