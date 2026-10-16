// Goldens der geteilten Bausteine (Plan 12.2 G; F2-R2): Typo-Tafel, Bausteine
// einzeln (Normal und Hoher Kontrast), Flächen auf der Welt, Manny-Posen je
// Variante und die Tafel aller Komponenten des Briefs v2 in einer Auswahl von
// vier Darstellungen (`showcase_*`: Mittag hell, Abend hell, Nacht dunkel, Nacht
// dunkel mit Hohem Kontrast). Referenz ist ausschließlich diese
// Linux-Umgebung; Erzeugung mit `--update-goldens`, Sichtung durch den
// `ui-designer`, Freigabe durch den Nutzer (Plan 12.1). Die Szenario-Goldens
// (`scenario_golden_test.dart`) bleiben für F2-R4.
@Tags(<String>['golden'])
library;

import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/world_time.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_typography.dart';
import 'package:curaone/ui/components/choice_card.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/cura_label.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/cura_text_field.dart';
import 'package:curaone/ui/components/date_card.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/world_background.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/mic_button.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/components/step_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/showcase.dart';
import '../support/world_app.dart';

const Size _board = Size(390, 844);

Widget _withWorld(Widget content) => Stack(
  children: <Widget>[
    const Positioned.fill(child: WorldBackground()),
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
  await precacheImages(tester);
  await expectLater(
    find.byType(Scaffold),
    matchesGoldenFile('goldens/$name.png'),
  );
}

Widget _gap() => const SizedBox(height: 12);

/// Bausteine einzeln: Tasten, Auswahl, Felder, Kreise, Fortschritt, Label.
Widget _controls() => _withWorld(
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
            const SizedBox(width: 8),
            MannyButton(onPressed: () {}),
          ],
        ),
      ],
    ),
  ),
);

/// Flächen: Glas-Karte, Snackbar, Sprechblasen, Dialog.
Widget _surfaces() => _withWorld(
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
            const MannyIllustration(height: 88),
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
          child: MannyIllustration(height: 88, pose: MannyPose.feiernd),
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

/// Leiste (Ruhe) und Button-Gruppe über scrollendem Inhalt (Blur, Schleier).
Widget _navBoard() => _withWorld(
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
          items: kShowcaseNav,
        ),
      ),
      Positioned(
        right: 18,
        bottom: 24 + 72 + 16,
        child: MannyButton(onPressed: () {}),
      ),
    ],
  ),
);

/// Die drei Posen und der Kopf einer Variante: auf der Welt Nacht mit Halo (Pfad)
/// und, darunter, Kopf auf heller Scheibe in 48, 56 und 80 dp.
Widget _manny(MannyLook look) => Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          for (final MannyPose p in const <MannyPose>[
            MannyPose.neutral,
            MannyPose.feiernd,
            MannyPose.troestend,
          ])
            MannyIllustration(height: 120, pose: p, look: look, onWorld: true),
        ],
      ),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          MannyAvatar(size: 48, look: look),
          const SizedBox(width: 16),
          MannyAvatar(size: 56, look: look),
          const SizedBox(width: 16),
          MannyAvatar(size: 80, look: look),
          const SizedBox(width: 16),
          MannyButton(onPressed: () {}),
        ],
      ),
    ],
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
              style: t.caption.copyWith(color: c.text2),
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

    for (final MannyLook look in MannyLook.values) {
      testWidgets('manny_poses_${look.name}', (WidgetTester tester) async {
        await pumpWorld(
          tester,
          _manny(look),
          phase: WorldPhase.night,
          brightness: Brightness.dark,
          size: const Size(390, 320),
        );
        await precacheImages(tester);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/manny_poses_${look.name}.png'),
        );
      });
    }
  });

  // Auswahl statt aller zehn Darstellungen (Design-Abnahme L1, Punkt 8): Mittag
  // hell (Referenz), Abend hell, Nacht dunkel und Nacht dunkel mit Hohem
  // Kontrast. Der Kontrast je Welt ist durch `contrast_world_test.dart` belegt.
  const Set<String> showcaseLooks = <String>{
    'midday_light',
    'night_dark_hc',
    'evening_light',
    'night_dark',
  };
  group('Tafel aller Komponenten (Auswahl der Welten)', () {
    for (final WorldLook l in allWorldLooks().where(
      (WorldLook l) => showcaseLooks.contains(l.name),
    )) {
      testWidgets('showcase_${l.name}', (WidgetTester tester) async {
        await pumpWorld(
          tester,
          v2Showcase(
            look: l.brightness == Brightness.dark
                ? MannyLook.ohne
                : MannyLook.brille,
          ),
          phase: l.phase,
          brightness: l.brightness,
          highContrast: l.highContrast,
          size: const Size(390, 2300),
        );
        await precacheImages(tester);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/showcase_${l.name}.png'),
        );
      });
    }
  });
}
