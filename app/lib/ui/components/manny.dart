// `MannyIllustration` und `MannyAvatar` (Design-Brief v2, Ergänzung 1, 6.1 bis
// 6.6): Manny aus den **finalen PNG-Grafiken** beider Varianten (`brille/`,
// `ohne/`; Posen `normal`, `freudig`, `traurig` und `kopf`). Es gibt keinen
// gezeichneten Platzhalter mehr. Die Figur wird nie umgefärbt, gedreht,
// gespiegelt oder verzerrt (`BoxFit.contain`, quadratische bzw. feste
// Seitenverhältnisse der Leinwand).
//
// Die Variante kommt aus dem Zustand (`AppState.mannyLook`) und gilt in jeder
// Pose und an jeder Stelle; ohne `AppScope` (Bausteintests, Vorschau) gilt die
// Vorbelegung „Mit Brille“. Anlass -> Bild steht zentral in
// `lib/logic/manny_occasions.dart` (`mannyImageFor`). Flutter wählt die
// Dichte-Variante (`2.0x/`, `3.0x/`) selbst; kein Bild wird größer als seine
// Leinwand in dp dargestellt (Körper 158 × 193 dp, Kopf 110 dp).
//
// Sichtbarkeit (6.4): Auf der Welt Nacht verschwindet die dunkle Kontur; dort
// steht hinter der Figur ein **Halo** (Weiß 28 %, 1,15 × Leinwandbreite). Der
// **Kopf** steht immer auf einer hellen Scheibe (`MannyAvatar`) und ist nie
// kleiner als 40 dp (6.5).
//
// Diese Datei enthält keine Animation (Regel 9): Hüpfen und Wippen gehören zu
// den Feier-Momenten und kommen mit ihnen; bei „Bewegung reduzieren“ ist Manny
// ohnehin statisch (V2-26, V2-74).
import 'package:flutter/widgets.dart';

import '../../l10n/strings_de.dart';
import '../../logic/manny_look.dart';
import '../../logic/manny_occasions.dart';
import '../../state/app_scope.dart';
import '../../state/world_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';

export '../../logic/manny_occasions.dart' show MannyPose;

enum MannyCrop { full, head }

/// Die Variante, die an [context] gilt: aus dem Zustand, sonst die
/// Vorbelegung.
MannyLook mannyLookOf(BuildContext context) =>
    AppScope.maybeOf(context)?.state.mannyLook ?? MannyLook.defaultLook;

class MannyIllustration extends StatelessWidget {
  const MannyIllustration({
    super.key,
    required this.height,
    this.pose = MannyPose.neutral,
    this.crop = MannyCrop.full,
    this.look,
    this.onTap,
    this.excludeSemantics = false,
    this.onWorld = false,
  }) : assert(height > 0),
       assert(
         crop == MannyCrop.full
             ? height <= CuraSize.mannyBodyHeight
             : height >= CuraSize.mannyHeadMin &&
                   height <= CuraSize.mannyHeadCanvas,
         'Manny: Körper höchstens 193 dp hoch, Kopf zwischen 40 und 110 dp.',
       );

  /// Höhe der Leinwand in dp (Pfad 88, Onboarding 120, Auswahlkarten bis 190);
  /// beim Kopf zugleich die Breite.
  final double height;
  final MannyPose pose;
  final MannyCrop crop;

  /// Variante; ohne Angabe die gewählte (`AppState.mannyLook`).
  final MannyLook? look;

  /// Nur auf dem Pfad gesetzt: Tipp auf die Figur (plus 8 dp Rand, mindestens
  /// 48 × 48 dp, unten an der Fußlinie) öffnet den Chat. Ohne Wert ist Manny
  /// nicht antippbar (`IgnorePointer`). Manny hat nie eine eigene Fokusstation.
  final VoidCallback? onTap;

  /// Bild-Label ausblenden (Knopf, Avatar und Zeile tragen ihr eigenes Label).
  final bool excludeSemantics;

  /// Manny steht direkt auf der Welt (Pfad): in der Welt Nacht mit Halo.
  final bool onWorld;

  /// Zusätzlicher Platz um die Figur, wenn Manny tippbar ist: links, rechts und
  /// oben der Trefferrand bzw. so viel, dass das Mindestquadrat Platz hat;
  /// unten nichts (Fußlinie). Der Besitzer rechnet damit beim Platzieren.
  static EdgeInsets tapInsets(
    Size size, {
    double margin = CuraSize.mannyHitMargin,
    double minSide = CuraSize.touchTarget,
  }) {
    final double x = margin > (minSide - size.width) / 2
        ? margin
        : (minSide - size.width) / 2;
    final double top = margin > minSide - size.height
        ? margin
        : minSide - size.height;
    return EdgeInsets.fromLTRB(x, top, x, 0);
  }

  /// Größe in dp für eine Leinwandhöhe: Körper im Verhältnis 158 : 193, Kopf
  /// quadratisch.
  static Size sizeFor(MannyCrop crop, double height) => crop == MannyCrop.head
      ? Size(height, height)
      : Size(
          height * CuraSize.mannyBodyWidth / CuraSize.mannyBodyHeight,
          height,
        );

  /// Abstand der Fußlinie von der Oberkante der Leinwand (unten bleibt ein
  /// Rand von 8 dp bei 193 dp Leinwandhöhe).
  static double feetFromTop(double height) =>
      height *
      (CuraSize.mannyBodyHeight - CuraSize.mannyBottomMargin) /
      CuraSize.mannyBodyHeight;

  /// Bild der Anlass-Pose (Körper) bzw. der Kopf.
  MannyImage get image =>
      crop == MannyCrop.head ? MannyImage.kopf : mannyImageFor(pose);

  @override
  Widget build(BuildContext context) {
    final MannyLook variant = look ?? mannyLookOf(context);
    final Size size = sizeFor(crop, height);
    final bool tappable = onTap != null;
    // Tippbar: Die Fläche wird um [tapInsets] größer, damit der 8-dp-Rand und
    // das 48-dp-Mindestquadrat auch außerhalb der Figur (und der Bildgrenze)
    // Treffer liefern (Flutter trifft nur innerhalb der Box).
    final EdgeInsets insets = tappable ? tapInsets(size) : EdgeInsets.zero;
    Widget art = Image.asset(
      mannyAssetPath(variant, image),
      width: size.width,
      height: size.height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
    if (onWorld) art = _Halo(size: size, child: art);
    if (tappable) {
      art = ExcludeFocus(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: onTap,
          child: Padding(padding: insets, child: art),
        ),
      );
    } else {
      art = IgnorePointer(child: art);
    }
    if (excludeSemantics) return ExcludeSemantics(child: art);
    return Semantics(label: S.mannyImageLabel, image: true, child: art);
  }
}

/// Halo hinter der Figur (6.4): nur in der Welt Nacht, Kreis mit 1,15 × der
/// Leinwandbreite, Weiß 28 % mit weichem Auslauf am Rand; die Deckkraft folgt
/// `moonAmount` der Welt (in der Überblendung Abend/Nacht wächst er mit). Mit
/// „Transparenz reduzieren“/Hoher Kontrast opak (`card`).
class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double night = WorldScope.paletteOf(context).moonAmount;
    if (night <= 0) return child;
    final CuraColors colors = CuraColors.of(context);
    final double d = size.width * CuraSize.mannyHaloScale;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: OverflowBox(
            minWidth: 0,
            minHeight: 0,
            maxWidth: d,
            maxHeight: d,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: SizedBox.square(
                  key: const ValueKey<String>('manny-halo'),
                  dimension: d,
                  child: DecoratedBox(
                    decoration: colors.mannyHaloDecoration(night),
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Manny-Kopf auf heller Scheibe (6.4): Avatar in Chat-Liste, Chat-Kopf und
/// Nachrichten. Die Scheibe misst [size] (Durchmesser), der Kopf darin 86 %
/// (mindestens 40 dp, daher [size] ≥ 48). Scheibe `#FBF3E4` in Hell und
/// Dunkel gleich. Das Bild ist ausgeblendet: die Zeile oder der Kopf trägt das
/// Label (V2-71).
class MannyAvatar extends StatelessWidget {
  const MannyAvatar({super.key, required this.size, this.look})
    : assert(
        size * CuraSize.mannyDiscHeadFactor >= CuraSize.mannyHeadMin,
        'Manny-Kopf kleiner als 40 dp: Scheibe mindestens 48 dp.',
      );

  /// Durchmesser der Scheibe.
  final double size;
  final MannyLook? look;

  /// Kantenlänge des Kopfes in der Scheibe.
  static double headFor(double size) => size * CuraSize.mannyDiscHeadFactor;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.mannyDisc,
            border: colors.highContrast
                ? Border.all(
                    color: colors.lightSurfaceBorder,
                    width: CuraSize.controlBorder,
                  )
                : null,
          ),
          child: Center(
            child: MannyIllustration(
              height: headFor(size),
              crop: MannyCrop.head,
              look: look,
              excludeSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
