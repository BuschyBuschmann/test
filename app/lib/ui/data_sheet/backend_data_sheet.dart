// „Deine Daten“ im Backend-Modus (Brief-Ergänzung 2, A11): Name, Verletzung und
// Datum kommen vom Physio und sind nur lesbar; darunter „Alle Daten löschen“
// (Konto und Praxis-Zugang, [BackendDeleteDialog]) und die Datenschutzerklärung.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../logic/clock.dart';
import '../../logic/date_format.dart';
import '../../logic/framework.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../state/backend_controller.dart';
import '../../state/backend_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/cura_label.dart';
import '../components/cura_pressable.dart';
import '../components/glass_card.dart';
import '../components/info_note.dart';
import '../components/pill_button.dart';
import '../components/probe_keys.dart';
import '../components/sheet_title_bar.dart';
import '../routes/app_routes.dart';
import '../routes/cura_sheet_route.dart';
import '../routes/route_focus.dart';
import 'backend_delete_dialog.dart';

class BackendDataSheet extends StatefulWidget {
  const BackendDataSheet({super.key});

  @override
  State<BackendDataSheet> createState() => _BackendDataSheetState();
}

class _BackendDataSheetState extends State<BackendDataSheet> {
  final FocusNode _deleteFocus = FocusNode(debugLabel: 'Alle Daten löschen');
  final FocusNode _privacyFocus = FocusNode(debugLabel: 'Datenschutzerklärung');

  @override
  void dispose() {
    _deleteFocus.dispose();
    _privacyFocus.dispose();
    super.dispose();
  }

  Future<void> _openDelete() => pushReturningFocus<void>(
    Navigator.of(context),
    BackendDeleteDialog.route(context),
    trigger: _deleteFocus,
  );

  Future<void> _openPrivacy() => pushReturningFocus<void>(
    Navigator.of(context),
    AppRoutes.privacy(context),
    trigger: _privacyFocus,
  );

  Widget _field(BuildContext context, String label, String? value) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(label, style: type.secondary.copyWith(color: colors.text2)),
            const SizedBox(height: CuraSpace.s1),
            Text(
              (value == null || value.isEmpty) ? S.dataValueNone : value,
              style: type.body.copyWith(color: colors.text1),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppController app = AppScope.of(context);
    final BackendController? backend = BackendScope.maybeOf(context);
    final Framework? f = backend?.framework?.framework;
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final String name =
        (f?.patient.firstName ?? app.state.onboarding.firstName);
    final LocalDay? date = f?.injury?.referenceDate;
    final bool compact = CuraSheetScope.compactOf(context);
    return CuraSheetFrame(
      header: SheetTitleBar(
        title: S.dataSheetTitle,
        subtitle: compact ? null : S.dataSheetSubtitleBackend,
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: CuraSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (compact)
              Text(
                S.dataSheetSubtitleBackend,
                style: type.secondary.copyWith(color: colors.text2),
              ),
            const SizedBox(height: CuraSpace.s2),
            const CuraLabel(S.dataProfileLabel),
            const SizedBox(height: CuraSpace.s2),
            _field(context, S.nameLabel, name),
            const SizedBox(height: CuraSpace.s3),
            _field(context, S.dataInjuryLabel, f?.injury?.label),
            const SizedBox(height: CuraSpace.s3),
            _field(
              context,
              S.dataDateLabel,
              date == null ? null : formatDateFull(date),
            ),
            const SizedBox(height: CuraSpace.s3),
            const InfoNote(text: S.dataReadOnlyNote),
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
              S.dataDeleteTextBackend,
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
        label: S.done,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
