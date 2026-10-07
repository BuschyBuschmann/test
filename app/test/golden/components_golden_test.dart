// Goldens der geteilten Bausteine (U2a, Plan 12.2 G): Typo-Tafel, Bausteine
// einzeln (Normal und Hoher Kontrast), Flächen mit Glow, Manny-Posen. Referenz
// ist ausschließlich diese Linux-Umgebung; Erzeugung mit `--update-goldens`,
// Sichtung durch den `ui-designer`, Freigabe durch den Nutzer (Plan 12.1).
@Tags(<String>['golden'])
library;

import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_typography.dart';
import 'package:curaone/ui/components/action_cluster.dart';
import 'package:curaone/ui/components/choice_card.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/cura_label.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/cura_text_field.dart';
import 'package:curaone/ui/components/date_card.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/glow_background.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/messages_button.dart';
import 'package:curaone/ui/components/mic_button.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/components/step_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

const Size _board = Size(390, 844);

Widget _withGlow(Widget content) => Stack(
  children: <Widget>[
    const Positioned.fill(child: GlowBackground()),
    content,
  ],
);

Future<void> _golden(
  WidgetTester tester,
  Widget board,
  String name, {
  bool hc = false,
  Size size = _board,
}) async {
  await pumpApp(tester, board, size: size, highContrast: hc);
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(Scaffold),
    matchesGoldenFile('goldens/$name.png'),
  );
}

Widget _gap() => const SizedBox(height: 12);

/// Bausteine einzeln: Tasten, Auswahl, Felder, Kreise, Fortschritt, Label.
Widget _controls() => _withGlow(
  SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const StepProgress(step: 2),
        _gap(),
        PillButton(
          label: 'Training starten',
          onPressed: () {},
          icon: Icons.play_arrow_rounded,
        ),
        _gap(),
        PillButton(
          label: 'Abbrechen',
          variant: PillButtonVariant.neutral,
          onPressed: () {},
        ),
        _gap(),
        PillButton(
          label: 'Ja, alles löschen',
          variant: PillButtonVariant.outline,
          icon: Icons.delete_outline_rounded,
          onPressed: () {},
        ),
        _gap(),
        const PillButton(
          label: 'Heute erledigt',
          onPressed: null,
          icon: Icons.check_rounded,
        ),
        _gap(),
        const CuraLabel('Verletzung'),
        _gap(),
        ChoiceCard(
          title: 'Kreuzbandriss (ACL)',
          selected: true,
          onPressed: () {},
        ),
        _gap(),
        ChoiceCard(
          title: 'Bänderriss Sprunggelenk',
          selected: false,
          onPressed: () {},
        ),
        _gap(),
        ChoiceCard(
          title: 'Anderes / selbst eingeben',
          selected: false,
          leadingIcon: Icons.edit_rounded,
          onPressed: () {},
        ),
        _gap(),
        CuraTextField(
          label: 'Dein Name',
          hintText: 'Wie heißt du?',
          controller: TextEditingController(text: 'Jakob'),
        ),
        _gap(),
        DateCard(valueText: '3. September 2026', onPressed: () {}),
        _gap(),
        DateCard(onPressed: () {}),
        _gap(),
        Row(
          children: <Widget>[
            MicButton(onPressed: () {}),
            const SizedBox(width: 8),
            HeaderIconButton(
              icon: Icons.person_outline_rounded,
              tooltip: 'Deine Daten',
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            MessagesButton(onPressed: () {}),
            const SizedBox(width: 8),
            MannyChatButton(onPressed: () {}),
          ],
        ),
      ],
    ),
  ),
);

/// Flächen: Glas-Karte, Snackbar, Sprechblasen, Dialog.
Widget _surfaces() => _withGlow(
  SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const GlassCard(
          child: Text('Glas-Karte (E1): kein Blur, innere Lichtkante.'),
        ),
        _gap(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const MannyPlaceholder(height: 80),
            const SizedBox(width: 4),
            Expanded(
              child: MannyBubble(
                text: "Moin Jakob, los geht's. Dein Weg beginnt hier.",
                onClose: () {},
              ),
            ),
          ],
        ),
        _gap(),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: MannyBubble(
            text: 'Stark, Jakob. Das war Tag 4.',
            arrow: BubbleArrow.down,
            onClose: () {},
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 40),
          child: MannyPlaceholder(height: 80, pose: MannyPose.feiernd),
        ),
        _gap(),
        CuraSnackbar(
          text: 'Eingetragen.',
          actionLabel: 'Rückgängig',
          onAction: () {},
        ),
        _gap(),
        const CuraSnackbar(text: 'Alle Daten sind gelöscht.'),
        _gap(),
        CuraDialog(
          icon: Icons.delete_outline_rounded,
          title: 'Alles löschen?',
          message:
              'Name, Verletzung, Pfad, Streak und deine Einwilligung werden von '
              'diesem Gerät gelöscht. Das lässt sich nicht rückgängig machen.',
          actions: <Widget>[
            PillButton(
              label: 'Abbrechen',
              variant: PillButtonVariant.neutral,
              onPressed: () {},
            ),
            PillButton(
              label: 'Ja, alles löschen',
              variant: PillButtonVariant.outline,
              icon: Icons.delete_outline_rounded,
              onPressed: () {},
            ),
          ],
        ),
      ],
    ),
  ),
);

/// Nav und Button-Gruppe über scrollendem Inhalt (Blur, Ausblenden).
Widget _navBoard() => _withGlow(
  Stack(
    children: <Widget>[
      Positioned.fill(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            for (int i = 0; i < 12; i++) ...<Widget>[
              GlassCard(child: Text('Karte ${i + 1}')),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: FloatingNav(
          currentIndex: 1,
          onSelected: (_) {},
          items: const <NavItem>[
            NavItem(icon: Icons.route_rounded, label: 'Pfad'),
            NavItem(icon: Icons.event_available_rounded, label: 'Heute'),
          ],
        ),
      ),
      Positioned(
        right: 16,
        bottom: 22 + 64 + 16,
        child: ActionCluster(
          mode: ActionClusterMode.path,
          onOpenChat: () {},
          onOpenMessages: () {},
        ),
      ),
    ],
  ),
);

Widget _manny() => _withGlow(
  Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (final MannyPose p in MannyPose.values) ...<Widget>[
              MannyPlaceholder(height: 120, pose: p),
              const SizedBox(width: 16),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            for (final MannyPose p in MannyPose.values) ...<Widget>[
              MannyPlaceholder(height: 56, pose: p),
              const SizedBox(width: 16),
            ],
            for (final MannyPose p in MannyPose.values) ...<Widget>[
              MannyPlaceholder(height: 38, pose: p, crop: MannyCrop.head),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    ),
  ),
);

Widget _typoBoard() => Builder(
  builder: (BuildContext context) {
    final CuraColors c = CuraColors.of(context);
    final CuraTypography t = CuraTypography.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final MapEntry<String, TextStyle> e
              in t.all.entries) ...<Widget>[
            Text(
              '${e.key} · ${e.value.fontFamily} ${e.value.fontSize} '
              '${e.value.fontWeight?.value}',
              style: t.caption.copyWith(color: c.text3),
            ),
            Text(
              e.key == 'label' ? 'ABSCHNITTSTITEL' : 'Heute, Jakob 17:00',
              style: e.value.copyWith(color: e.value.color ?? c.text1),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  },
);

void main() {
  group('Typo-Tafel (alle Stile, opsz und wght je Stil)', () {
    testWidgets('typo_board', (WidgetTester tester) async {
      await _golden(
        tester,
        _typoBoard(),
        'typo_board',
        size: const Size(390, 1040),
      );
    });
  });

  group('Bausteine', () {
    testWidgets('controls', (WidgetTester tester) async {
      await _golden(
        tester,
        _controls(),
        'controls',
        size: const Size(390, 1180),
      );
    });

    testWidgets('controls_hc', (WidgetTester tester) async {
      await _golden(
        tester,
        _controls(),
        'controls_hc',
        hc: true,
        size: const Size(390, 1180),
      );
    });

    testWidgets('surfaces', (WidgetTester tester) async {
      await _golden(
        tester,
        _surfaces(),
        'surfaces',
        size: const Size(390, 1500),
      );
    });

    testWidgets('surfaces_hc', (WidgetTester tester) async {
      await _golden(
        tester,
        _surfaces(),
        'surfaces_hc',
        hc: true,
        size: const Size(390, 1500),
      );
    });

    testWidgets('nav_cluster', (WidgetTester tester) async {
      await _golden(tester, _navBoard(), 'nav_cluster');
    });

    testWidgets('nav_cluster_hc', (WidgetTester tester) async {
      await _golden(tester, _navBoard(), 'nav_cluster_hc', hc: true);
    });

    testWidgets('manny_poses', (WidgetTester tester) async {
      await _golden(
        tester,
        _manny(),
        'manny_poses',
        size: const Size(390, 300),
      );
    });

    testWidgets('glow', (WidgetTester tester) async {
      await _golden(tester, _withGlow(const SizedBox.expand()), 'glow');
    });
  });
}
