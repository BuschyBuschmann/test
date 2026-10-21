// Manny aus den finalen PNGs (Brief-Ergänzung 1, 6.1 bis 6.6): Bildwahl nach
// Variante und Pose (V2-56), Label einmal je Darstellung (V2-71), Mindestgröße
// Kopf und Scheibe (V2-72), Dichte-Auswahl 1x/2x/3x und Größenobergrenzen
// (V2-73), Halo in Nacht und Kontur gegen den Untergrund (V2-69), statisch bei
// „Bewegung reduzieren“ und Look-Wechsel ohne Überblendung (V2-74), Hit-Fläche.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/manny_occasions.dart';
import 'package:curaone/logic/world_time.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/contrast.dart' show contrastRatio;
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controller_harness.dart';
import '../support/world_app.dart';

/// Kontur der Figur (Ergänzung 1, 6.1: gleichmäßig fast schwarz `#040F17`).
const Color _outline = Color(0xFF040F17);

Finder _images() => find.byType(Image);

Future<String> _assetName(WidgetTester tester, [int index = 0]) async {
  final Finder f = _images().at(index);
  final Image img = tester.widget<Image>(f);
  final ImageConfiguration cfg = createLocalImageConfiguration(
    tester.element(f),
  );
  final AssetBundleImageKey key =
      (await tester.runAsync(() => img.image.obtainKey(cfg)))!
          as AssetBundleImageKey;
  return key.name;
}

Future<double> _assetScale(WidgetTester tester) async {
  final Finder f = _images().first;
  final Image img = tester.widget<Image>(f);
  final ImageConfiguration cfg = createLocalImageConfiguration(
    tester.element(f),
  );
  final AssetBundleImageKey key =
      (await tester.runAsync(() => img.image.obtainKey(cfg)))!
          as AssetBundleImageKey;
  return key.scale;
}

/// Breite und Höhe eines PNG aus dem Dateikopf (IHDR).
Size _pngSize(File file) {
  final Uint8List bytes = file.readAsBytesSync();
  final ByteData d = ByteData.sublistView(bytes);
  expect(bytes.sublist(1, 4), <int>[0x50, 0x4E, 0x47], reason: file.path);
  return Size(d.getUint32(16).toDouble(), d.getUint32(20).toDouble());
}

void main() {
  group('Assets (V2-73)', () {
    const List<(String, int)> densities = <(String, int)>[
      ('', 1),
      ('2.0x/', 2),
      ('3.0x/', 3),
    ];

    test(
      'alle 24 Dateien liegen vor, Körper 158 × 193, Kopf 110 (× 1/2/3)',
      () {
        int count = 0;
        for (final MannyLook look in MannyLook.values) {
          for (final MannyImage image in MannyImage.values) {
            for (final (String dir, int factor) in densities) {
              final File f = File(
                'assets/manny/${look.name}/$dir${image.fileName}',
              );
              expect(f.existsSync(), isTrue, reason: f.path);
              final Size expected = image == MannyImage.kopf
                  ? const Size.square(CuraSize.mannyHeadCanvas)
                  : const Size(
                      CuraSize.mannyBodyWidth,
                      CuraSize.mannyBodyHeight,
                    );
              expect(_pngSize(f), expected * factor.toDouble(), reason: f.path);
              count++;
            }
          }
        }
        expect(count, 24);
      },
    );

    test('pubspec.yaml deklariert beide Verzeichnisse', () {
      final String yaml = File('pubspec.yaml').readAsStringSync();
      expect(yaml, contains('- assets/manny/brille/'));
      expect(yaml, contains('- assets/manny/ohne/'));
    });

    test('Asset-Pfade: Variante gilt in jeder Pose, Kopf ist kein Anlass', () {
      for (final MannyLook look in MannyLook.values) {
        for (final MannyPose pose in MannyPose.values) {
          final String path = mannyAssetPath(look, mannyImageFor(pose));
          expect(path, startsWith('assets/manny/${look.name}/'));
          expect(
            path,
            isNot(contains('kopf')),
            reason: 'Körperposen nutzen nie den Kopf',
          );
        }
      }
      expect(
        mannyAssetPath(MannyLook.ohne, MannyImage.kopf),
        'assets/manny/ohne/kopf.png',
      );
    });

    testWidgets('Dichte-Auswahl bei devicePixelRatio 1, 2 und 3', (
      WidgetTester tester,
    ) async {
      for (final (String dir, int factor) in densities) {
        await pumpWorld(
          tester,
          const Center(
            child: MannyIllustration(height: 88, look: MannyLook.brille),
          ),
          dpr: factor.toDouble(),
          background: false,
        );
        expect(
          await _assetName(tester),
          'assets/manny/brille/${dir}normal.png',
          reason: 'devicePixelRatio $factor',
        );
        expect(await _assetScale(tester), factor.toDouble());
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('Bildwahl (V2-56)', () {
    testWidgets('Variante × Pose liefert die erwartete Datei', (
      WidgetTester tester,
    ) async {
      const Map<MannyPose, String> expected = <MannyPose, String>{
        MannyPose.neutral: 'normal',
        MannyPose.gruessend: 'freudig',
        MannyPose.feiernd: 'freudig',
        MannyPose.ziel: 'normal',
        MannyPose.motiviert: 'normal',
        MannyPose.training: 'normal',
        MannyPose.troestend: 'traurig',
        MannyPose.denkend: 'normal',
        MannyPose.schlafend: 'normal',
      };
      for (final MannyLook look in MannyLook.values) {
        for (final MapEntry<MannyPose, String> e in expected.entries) {
          await pumpWorld(
            tester,
            Center(
              child: MannyIllustration(height: 88, pose: e.key, look: look),
            ),
            background: false,
          );
          expect(
            await _assetName(tester),
            'assets/manny/${look.name}/${e.value}.png',
            reason: '${look.name} ${e.key.name}',
          );
        }
      }
    });

    testWidgets('Kopf zeigt kopf.png beider Varianten', (
      WidgetTester tester,
    ) async {
      for (final MannyLook look in MannyLook.values) {
        await pumpWorld(
          tester,
          Center(
            child: MannyIllustration(
              height: 56,
              crop: MannyCrop.head,
              pose: MannyPose.feiernd,
              look: look,
            ),
          ),
          background: false,
        );
        expect(await _assetName(tester), 'assets/manny/${look.name}/kopf.png');
      }
    });

    testWidgets('ohne Angabe gilt die gewählte Variante aus dem Zustand', (
      WidgetTester tester,
    ) async {
      final Harness h = await Harness.onboarded();
      addTearDown(h.dispose);
      await pumpWorld(
        tester,
        const Center(child: MannyIllustration(height: 88)),
        controller: h.controller,
        background: false,
      );
      expect(await _assetName(tester), 'assets/manny/brille/normal.png');
      h.controller.setMannyLook(MannyLook.ohne);
      await tester.pump();
      expect(await _assetName(tester), 'assets/manny/ohne/normal.png');
    });

    testWidgets('ohne Zustand gilt die Vorbelegung „Mit Brille“', (
      WidgetTester tester,
    ) async {
      await pumpWorld(
        tester,
        const Center(child: MannyIllustration(height: 88)),
        background: false,
      );
      expect(await _assetName(tester), 'assets/manny/brille/normal.png');
    });
  });

  group('Größen (V2-72, V2-73)', () {
    testWidgets('Körper im Verhältnis 158 : 193, nie über der Leinwand', (
      WidgetTester tester,
    ) async {
      for (final double h in <double>[
        CuraSize.mannyPathHeight,
        CuraSize.mannyOnboardingStep1Height,
        CuraSize.mannyChoiceMaxHeight,
        CuraSize.mannyBodyHeight,
      ]) {
        await pumpWorld(
          tester,
          Center(child: MannyIllustration(height: h)),
          background: false,
        );
        final Size s = tester.getSize(_images().first);
        expect(s.height, h);
        expect(s.width, closeTo(h * 158 / 193, 0.001));
        expect(s.width, lessThanOrEqualTo(CuraSize.mannyBodyWidth));
        expect(s.height, lessThanOrEqualTo(CuraSize.mannyBodyHeight));
      }
    });

    testWidgets('Kopf quadratisch, höchstens 110 dp', (
      WidgetTester tester,
    ) async {
      await pumpWorld(
        tester,
        const Center(
          child: MannyIllustration(
            height: CuraSize.mannyHeadCanvas,
            crop: MannyCrop.head,
          ),
        ),
        background: false,
      );
      expect(tester.getSize(_images().first), const Size(110, 110));
    });

    test('Darstellungsgrößen aus 6.2', () {
      expect(CuraSize.mannyPathHeight, 88);
      expect(CuraSize.mannyOnboardingStep1Height, 120);
      expect(CuraSize.mannyChoiceMaxHeight, 190);
      expect(CuraSize.emblemHeader, 56);
      expect(CuraSize.mannyChatButton, 56);
    });

    test('kein Manny-Kopf unter 40 dp: alle Scheiben tragen ≥ 40 dp Kopf', () {
      expect(CuraSize.mannyHeadMin, 40);
      for (final double disc in <double>[
        CuraSize.emblemMessage,
        CuraSize.emblemHeader,
        CuraSize.mannyChatButton,
        CuraSize.avatar,
      ]) {
        expect(
          MannyAvatar.headFor(disc),
          greaterThanOrEqualTo(CuraSize.mannyHeadMin),
          reason: 'Scheibe $disc dp',
        );
      }
      // Eine Scheibe von 40 dp (Kopf 34 dp) ist ausgeschlossen.
      expect(
        () => MannyAvatar(size: 40),
        throwsA(isA<AssertionError>()),
        reason: 'Mindestgröße Kopf 40 dp',
      );
      expect(
        () => MannyIllustration(height: 32, crop: MannyCrop.head),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('Avatar: helle Scheibe in Hell und Dunkel gleich, Kopf 86 %', (
      WidgetTester tester,
    ) async {
      final List<Color?> discs = <Color?>[];
      for (final Brightness b in Brightness.values) {
        await pumpWorld(
          tester,
          const Center(child: MannyAvatar(size: 56)),
          brightness: b,
          background: false,
        );
        final DecoratedBox disc = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(MannyAvatar),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        discs.add((disc.decoration as BoxDecoration).color);
        expect(
          tester.getSize(_images().first).width,
          closeTo(56 * CuraSize.mannyDiscHeadFactor, 0.001),
        );
        expect(tester.getSize(find.byType(MannyAvatar)), const Size(56, 56));
      }
      expect(discs[0], const Color(0xFFFBF3E4));
      expect(discs[1], discs[0]);
    });
  });

  group('Label (V2-71)', () {
    testWidgets('„Manny, dein Begleiter“ genau einmal je Darstellung', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpWorld(
        tester,
        const Center(child: MannyIllustration(height: 88)),
        background: false,
      );
      expect(find.bySemanticsLabel(S.mannyImageLabel), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
      'ausgeblendet neben Blase/Knopf/Zeile; Avatar trägt kein Label',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpWorld(
          tester,
          const Column(
            children: <Widget>[
              MannyIllustration(height: 88, excludeSemantics: true),
              MannyAvatar(size: 56),
              MannyIllustration(
                height: 56,
                crop: MannyCrop.head,
                excludeSemantics: true,
              ),
            ],
          ),
          background: false,
        );
        expect(find.bySemanticsLabel(S.mannyImageLabel), findsNothing);
        handle.dispose();
      },
    );

    testWidgets('Strahlen und Träne haben kein eigenes Label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpWorld(
        tester,
        const Row(
          children: <Widget>[
            MannyIllustration(height: 88, pose: MannyPose.feiernd),
            MannyIllustration(height: 88, pose: MannyPose.troestend),
          ],
        ),
        background: false,
      );
      // Zwei Darstellungen, je genau ein Label, sonst kein Bild-Knoten.
      expect(find.bySemanticsLabel(S.mannyImageLabel), findsNWidgets(2));
      final Iterable<Image> images = tester.widgetList<Image>(_images());
      for (final Image i in images) {
        expect(i.excludeFromSemantics, isTrue);
      }
      handle.dispose();
    });
  });

  group('Halo (V2-69)', () {
    Widget onWorld() => const Align(
      alignment: Alignment(0, 0.6),
      child: MannyIllustration(height: 88, onWorld: true),
    );

    testWidgets('nur in der Welt Nacht', (WidgetTester tester) async {
      for (final WorldPhase p in kWorlds) {
        await pumpWorld(tester, onWorld(), phase: p);
        expect(
          find.byKey(const ValueKey<String>('manny-halo')),
          p == WorldPhase.night ? findsOneWidget : findsNothing,
          reason: p.name,
        );
      }
    });

    testWidgets('ohne onWorld nie (Karte, Sheet)', (WidgetTester tester) async {
      await pumpWorld(
        tester,
        const Center(child: MannyIllustration(height: 88)),
        phase: WorldPhase.night,
      );
      expect(find.byKey(const ValueKey<String>('manny-halo')), findsNothing);
    });

    test(
      'Durchmesser 1,15 × Leinwandbreite, Weiß 28 %, opak bei Hohem Kontrast',
      () {
        expect(CuraSize.mannyHaloScale, 1.15);
        expect(
          CuraColors.light.mannyHalo,
          const Color(0xFFFFFFFF).withValues(alpha: 0.28),
        );
        expect(CuraColors.dark.mannyHalo.a, closeTo(0.28, 0.001));
        expect(CuraColors.lightHighContrast.mannyHalo.a, 1);
        expect(CuraColors.darkHighContrast.mannyHalo.a, 1);
      },
    );

    testWidgets('Halo-Fläche misst 1,15 × Leinwandbreite', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, onWorld(), phase: WorldPhase.night);
      final Size canvas = tester.getSize(_images().first);
      final Size halo = tester.getSize(
        find.byKey(const ValueKey<String>('manny-halo')),
      );
      expect(halo.width, closeTo(canvas.width * 1.15, 0.01));
    });

    testWidgets(
      'Kontur gegen den Untergrund hinter der Figur ≥ 3:1 (Renderprobe)',
      (WidgetTester tester) async {
        // Alpha des PNG (3x) bestimmt, wo hinter der Figur der Untergrund frei
        // liegt: dort wird gemessen.
        final ui.Image art = (await tester.runAsync(() async {
          final ui.Codec codec = await ui.instantiateImageCodec(
            File('assets/manny/brille/3.0x/normal.png').readAsBytesSync(),
          );
          return (await codec.getNextFrame()).image;
        }))!;
        final ByteData alpha = (await tester.runAsync<ByteData?>(
          () => art.toByteData(),
        ))!;
        final GlobalKey key = GlobalKey();
        for (final bool hc in <bool>[false, true]) {
          await pumpWorld(
            tester,
            const Align(
              alignment: Alignment(0, 0.6),
              child: MannyIllustration(height: 88, onWorld: true),
            ),
            phase: WorldPhase.night,
            highContrast: hc,
            boundaryKey: key,
          );
          await tester.runAsync(() async {
            for (final Element e in find.byType(Image).evaluate()) {
              await precacheImage((e.widget as Image).image, e);
            }
          });
          await tester.pumpAndSettle();
          final ui.Image shot = (await tester.runAsync(
            () => tester
                .renderObject<RenderRepaintBoundary>(find.byKey(key))
                .toImage(),
          ))!;
          final ByteData px = (await tester.runAsync<ByteData?>(
            () => shot.toByteData(),
          ))!;

          // Ein Punkt der Leinwand, an dem das PNG durchsichtig ist, im voll
          // gedeckten Kern des Halos (Radius < 0,72 × Halo-Radius).
          final Rect canvas = tester.getRect(_images().first);
          final double haloR = canvas.width * CuraSize.mannyHaloScale / 2;
          Offset? pick;
          for (double r = 0.65; r > 0.15 && pick == null; r -= 0.05) {
            for (int deg = 0; deg < 360 && pick == null; deg += 10) {
              final double rad = deg * math.pi / 180;
              final Offset p =
                  canvas.center +
                  Offset(haloR * r * math.cos(rad), haloR * r * math.sin(rad));
              if (!canvas.contains(p)) continue;
              final int ax = ((p.dx - canvas.left) / canvas.width * art.width)
                  .floor()
                  .clamp(0, art.width - 1);
              final int ay = ((p.dy - canvas.top) / canvas.height * art.height)
                  .floor()
                  .clamp(0, art.height - 1);
              if (alpha.getUint8((ay * art.width + ax) * 4 + 3) == 0) pick = p;
            }
          }
          expect(pick, isNotNull, reason: 'durchsichtiger Punkt im Halo');
          final int i = (pick!.dy.floor() * shot.width + pick.dx.floor()) * 4;
          final Color behind = Color.fromARGB(
            255,
            px.getUint8(i),
            px.getUint8(i + 1),
            px.getUint8(i + 2),
          );
          expect(
            contrastRatio(_outline, behind),
            greaterThanOrEqualTo(3.0),
            reason:
                'Kontur gegen ${behind.toARGB32().toRadixString(16)} (HC $hc)',
          );
        }
      },
    );
  });

  group('Bewegung (V2-74)', () {
    testWidgets('statisch: kein Ticker, Look-Wechsel im selben Frame', (
      WidgetTester tester,
    ) async {
      final Harness h = await Harness.onboarded();
      addTearDown(h.dispose);
      await pumpWorld(
        tester,
        const Center(child: MannyIllustration(height: 88)),
        controller: h.controller,
        background: false,
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(await _assetName(tester), 'assets/manny/brille/normal.png');
      h.controller.setMannyLook(MannyLook.ohne);
      await tester.pump();
      // Kein Überblenden: nach genau einem Frame steht die neue Variante.
      expect(await _assetName(tester), 'assets/manny/ohne/normal.png');
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('Trefferfläche', () {
    testWidgets(
      'Leinwand plus 8 dp Rand, mindestens 48 × 48 dp, Tipp ruft onTap',
      (WidgetTester tester) async {
        int taps = 0;
        await pumpWorld(
          tester,
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(100),
              child: MannyIllustration(height: 88, onTap: () => taps++),
            ),
          ),
          background: false,
        );
        final Rect art = tester.getRect(_images().first);
        final EdgeInsets ins = MannyIllustration.tapInsets(art.size);
        final Rect hit = tester.getRect(find.byType(MannyIllustration));
        expect(hit.left, art.left - ins.left);
        expect(hit.top, art.top - ins.top);
        expect(hit.right, art.right + ins.right);
        expect(hit.bottom, art.bottom, reason: 'unten an der Leinwand');
        expect(ins.left, greaterThanOrEqualTo(CuraSize.mannyHitMargin));
        expect(hit.width, greaterThanOrEqualTo(CuraSize.touchTarget));
        expect(hit.height, greaterThanOrEqualTo(CuraSize.touchTarget));
        await tester.tapAt(art.center);
        await tester.tapAt(art.topLeft - const Offset(6, 6));
        expect(taps, 2);
        await tester.tapAt(art.topLeft - const Offset(14, 0));
        expect(taps, 2, reason: '14 dp daneben');
      },
    );

    testWidgets('ohne onTap nicht antippbar', (WidgetTester tester) async {
      await pumpWorld(
        tester,
        const Center(child: MannyIllustration(height: 88)),
        background: false,
      );
      expect(
        find.descendant(
          of: find.byType(MannyIllustration),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    testWidgets('Fußlinie: 8 dp Rand unten bei 193 dp Leinwand', (
      WidgetTester tester,
    ) async {
      expect(
        MannyIllustration.feetFromTop(193),
        closeTo(193 - CuraSize.mannyBottomMargin, 0.001),
      );
    });
  });
}
