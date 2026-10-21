// Malt die Welt (Design-Brief v2, 3.1 und 4 „WorldBackground“): Himmelsverlauf,
// Licht (Sonne/Mond), Sterne, drei Hügelebenen mit Dunstbändern und Körnung.
// Statisch: das Bild hängt nur von Palette und Größe ab und liegt hinter einer
// `RepaintBoundary`, es wird nicht pro Frame neu gemalt. **Keine harten
// Konturen** zwischen den Ebenen: jede Ebene läuft nach unten in Transparenz
// aus, hinten ist der Kamm stärker weichgezeichnet (Maskenfilter, einmalig
// durch die Zwischenspeicherung der Ebene), dazwischen liegt Dunst.
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'world_tokens.dart';

/// Welt hinter dem Inhalt. [decor] = Hügelebenen, Körnung, Dunst, Sterne und
/// Sonne/Mond (entfällt bei „Transparenz reduzieren“/Hoher Kontrast); [calm] = ruhige
/// Welt des Physio-Bereichs (Ebenen 50 %, ohne Sonne/Mond/Sterne/Körnung).
class WorldPainter extends CustomPainter {
  const WorldPainter({
    required this.palette,
    this.decor = true,
    this.calm = false,
  });

  final WorldPalette palette;
  final bool decor;
  final bool calm;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.sky,
          stops: kSkyGrid,
        ).createShader(rect),
    );

    final bool sky = decor && !calm;
    if (sky) {
      _paintLight(canvas, size);
      _paintStars(canvas, size);
    }

    // Hoher Kontrast/Transparenz reduzieren: nur der ruhige Verlauf, keine
    // Hügelebenen, kein Dunst (Brief v2, N1).
    if (decor) {
      final double hillAlpha = calm ? WorldGeometry.calmHillAlpha : 1;
      _paintHill(
        canvas,
        size,
        palette.hillFar,
        hillAlpha,
        crest: WorldGeometry.farCrest,
        amplitude: WorldGeometry.farAmplitude,
        wavelength: WorldGeometry.farWavelength,
        phase: WorldGeometry.farPhase,
        fadeEnd: WorldGeometry.farFadeEnd,
        blur: WorldGeometry.farBlur,
      );
      _paintMist(canvas, size, 0);
      _paintHill(
        canvas,
        size,
        palette.hillMid,
        hillAlpha,
        crest: WorldGeometry.midCrest,
        amplitude: WorldGeometry.midAmplitude,
        wavelength: WorldGeometry.midWavelength,
        phase: WorldGeometry.midPhase,
        fadeEnd: WorldGeometry.midFadeEnd,
        blur: WorldGeometry.midBlur,
      );
      _paintMist(canvas, size, 1);
      _paintHill(
        canvas,
        size,
        palette.hillNear,
        hillAlpha,
        crest: WorldGeometry.nearCrest,
        amplitude: WorldGeometry.nearAmplitude,
        wavelength: WorldGeometry.nearWavelength,
        phase: WorldGeometry.nearPhase,
        fadeEnd: WorldGeometry.nearFadeEnd,
        blur: WorldGeometry.nearBlur,
      );
      _paintMist(canvas, size, 2);
    }

    if (sky) _paintGrain(canvas, size);
  }

  void _paintLight(Canvas canvas, Size size) {
    final Offset center = Offset(
      palette.lightX * size.width,
      palette.lightY * size.height,
    );
    final double moon = palette.moonAmount;
    final double glow =
        lerpDouble(
          WorldGeometry.sunGlowRadius,
          WorldGeometry.moonGlowRadius,
          moon,
        )! *
        size.width;
    final double disc =
        lerpDouble(
          WorldGeometry.sunDiscRadius,
          WorldGeometry.moonDiscRadius,
          moon,
        )! *
        size.width;
    final Color c = palette.lightColor;
    final double peak = WorldGeometry.lightGlowAlpha * (1 - 0.5 * moon);
    canvas.drawCircle(
      center,
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            c.withValues(alpha: peak),
            c.withValues(alpha: peak * 0.35),
            c.withValues(alpha: 0),
          ],
          stops: <double>[0, disc / glow, 1],
        ).createShader(Rect.fromCircle(center: center, radius: glow)),
    );
    // Scheibe mit weichem Rand (keine harte Kontur).
    final double softDisc = disc * WorldGeometry.lightDiscSoftness;
    canvas.drawCircle(
      center,
      softDisc,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[c, c, c.withValues(alpha: 0)],
          stops: <double>[0, disc / softDisc, 1],
        ).createShader(Rect.fromCircle(center: center, radius: softDisc)),
    );
  }

  void _paintStars(Canvas canvas, Size size) {
    final double amount = palette.starAmount;
    if (amount <= 0) return;
    final math.Random random = math.Random(WorldGeometry.starSeed);
    final Paint paint = Paint();
    for (int i = 0; i < WorldPalette.nightStarCount; i++) {
      final double x = random.nextDouble() * size.width;
      final double y =
          random.nextDouble() * size.height * WorldGeometry.starRegionHeight;
      final double r =
          WorldGeometry.starMinRadius +
          random.nextDouble() *
              (WorldGeometry.starMaxRadius - WorldGeometry.starMinRadius);
      final double a =
          WorldGeometry.starMinAlpha +
          random.nextDouble() * (1 - WorldGeometry.starMinAlpha);
      paint.color = palette.lightColor.withValues(alpha: a * amount);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _paintHill(
    Canvas canvas,
    Size size,
    Color color,
    double alpha, {
    required double crest,
    required double amplitude,
    required double wavelength,
    required double phase,
    required double fadeEnd,
    required double blur,
  }) {
    final double w = size.width;
    final double h = size.height;
    // Über den Rand hinaus, damit der Weichzeichner keine Kante an den
    // Seiten setzt.
    final double margin = blur * 3;
    const int segments = 48;
    final Path path = Path()..moveTo(-margin, h + margin);
    for (int i = 0; i <= segments; i++) {
      final double x = -margin + (w + 2 * margin) * i / segments;
      final double y =
          h * crest +
          h *
              amplitude *
              math.sin((x / (w * wavelength)) * 2 * math.pi + phase);
      path.lineTo(x, y);
    }
    path
      ..lineTo(w + margin, h + margin)
      ..close();

    final double top = h * (crest - amplitude);
    final Rect shaderRect = Rect.fromLTRB(0, top, w, h * fadeEnd);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.18, 1],
        ).createShader(shaderRect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  void _paintMist(Canvas canvas, Size size, int index) {
    final double centre = WorldGeometry.mistCenters[index] * size.height;
    final double half = WorldGeometry.mistHeight * size.height / 2;
    final Rect band = Rect.fromLTRB(
      0,
      centre - half,
      size.width,
      centre + half,
    );
    final Color m = palette.mist;
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[m.withValues(alpha: 0), m, m.withValues(alpha: 0)],
        ).createShader(band),
    );
  }

  void _paintGrain(Canvas canvas, Size size) {
    final int count =
        (size.width * size.height / 10000 * WorldGeometry.grainPerTenThousand)
            .round();
    final math.Random random = math.Random(WorldGeometry.grainSeed);
    final List<Offset> points = <Offset>[
      for (int i = 0; i < count; i++)
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
    ];
    // Tag: dunkle Körnung (multiply), Nacht: helle (screen).
    final Color tone = Color.lerp(
      const Color(0xFF000000),
      const Color(0xFFFFFFFF),
      palette.starAmount,
    )!;
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = tone.withValues(alpha: WorldGeometry.grainAlpha)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(WorldPainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.decor != decor ||
      oldDelegate.calm != calm;
}
