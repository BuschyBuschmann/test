// Semantische Farb-Tokens als `ThemeExtension` (Design-Brief v1 3.1, Errata
// E-1/E-2, Ergänzung 1 `scrim`). Benennung so, dass ein heller Modus nur neue
// Werte braucht. Komponenten lesen Farben ausschließlich über
// `CuraColors.of(context)`.
import 'package:flutter/material.dart';

import 'tokens.dart';

@immutable
class CuraColors extends ThemeExtension<CuraColors> {
  const CuraColors({
    required this.bg,
    required this.surfaceGlassTop,
    required this.surfaceGlassBottom,
    required this.surfaceFloat,
    required this.surfaceOpaque,
    required this.borderHair,
    required this.borderControl,
    required this.borderControlHc,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentHi,
    required this.accentSoft,
    required this.accentPressed,
    required this.onAccent,
    required this.focusRing,
    required this.catPhysio,
    required this.catArzt,
    required this.catUebung,
    required this.catFrist,
    required this.triGruen,
    required this.triGelb,
    required this.triOrange,
    required this.triRot,
    required this.statusError,
    required this.streakFreeze,
    required this.glowEmber,
    required this.scrim,
    required this.mannyBody,
    required this.mannyBelly,
    required this.mannyOutline,
    required this.cardFillTop,
    required this.cardFillBottom,
    required this.cardBorder,
    required this.floatFill,
    required this.controlBorder,
    required this.blurEnabled,
    required this.glowEnabled,
    required this.shadowsEnabled,
    required this.highContrast,
  });

  final Color bg;
  final Color surfaceGlassTop;
  final Color surfaceGlassBottom;
  final Color surfaceFloat;
  final Color surfaceOpaque;
  final Color borderHair;
  final Color borderControl;
  final Color borderControlHc;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color accent;
  final Color accentHi;
  final Color accentSoft;
  final Color accentPressed;
  final Color onAccent;
  final Color focusRing;
  final Color catPhysio;
  final Color catArzt;
  final Color catUebung;
  final Color catFrist;
  final Color triGruen;
  final Color triGelb;
  final Color triOrange;
  final Color triRot;
  final Color statusError;
  final Color streakFreeze;
  final Color glowEmber;
  final Color scrim;
  final Color mannyBody;
  final Color mannyBelly;
  final Color mannyOutline;

  /// Abgeleitete Rolle: Karten-/Glasfüllung oben (hoher Kontrast: opak).
  final Color cardFillTop;

  /// Karten-/Glasfüllung unten.
  final Color cardFillBottom;

  /// Kartenrand (Normal `borderHair`, hoher Kontrast `borderControlHc`).
  final Color cardBorder;

  /// Füllung schwebender Flächen (Nav, Blase, Sheet); hoher Kontrast opak.
  final Color floatFill;

  /// Rand bedienbarer Felder (`borderControl`, hoher Kontrast `borderControlHc`).
  final Color controlBorder;

  /// Blur erlaubt (hoher Kontrast: nein).
  final bool blurEnabled;

  /// Glow-Hintergrund gebaut (hoher Kontrast: nein).
  final bool glowEnabled;

  /// Schein/Schatten des Primärbuttons und der Nav (hoher Kontrast: nein). Die Schatten der Aktions-Buttons hängen nicht daran.
  final bool shadowsEnabled;

  /// Variante „Hoher Kontrast“.
  final bool highContrast;

  /// Verlauf der Glas-Karte (E1) von oben nach unten.
  LinearGradient get cardFill => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[cardFillTop, cardFillBottom],
  );

  static Color _white(double alpha) =>
      const Color(0xFFFFFFFF).withValues(alpha: alpha);

  static const Color _black = Color(0xFF000000);

  /// Dunkel (Normalfall).
  static final CuraColors dark = CuraColors(
    bg: Palette.bg,
    surfaceGlassTop: _white(Palette.glassTopWhiteAlpha),
    surfaceGlassBottom: _white(Palette.glassBottomWhiteAlpha),
    surfaceFloat: Palette.surfaceFloatRgb.withValues(
      alpha: Palette.surfaceFloatAlpha,
    ),
    surfaceOpaque: Palette.surfaceOpaque,
    borderHair: _white(Palette.borderHairAlpha),
    borderControl: _white(Palette.borderControlAlpha),
    borderControlHc: _white(Palette.borderControlHcAlpha),
    text1: Palette.text1,
    text2: Palette.text2,
    text3: Palette.text3,
    accent: Palette.accent,
    accentHi: Palette.accentHi,
    accentSoft: Palette.accent.withValues(alpha: Palette.accentSoftAlpha),
    accentPressed: Palette.accentPressed,
    onAccent: Palette.onAccent,
    focusRing: Palette.focusRing,
    catPhysio: Palette.catPhysio,
    catArzt: Palette.catArzt,
    catUebung: Palette.catUebung,
    catFrist: Palette.catFrist,
    triGruen: Palette.triGruen,
    triGelb: Palette.triGelb,
    triOrange: Palette.triOrange,
    triRot: Palette.triRot,
    statusError: Palette.statusError,
    streakFreeze: Palette.streakFreeze,
    glowEmber: Palette.glowEmber,
    scrim: _black.withValues(alpha: Palette.scrimAlpha),
    mannyBody: Palette.mannyBody,
    mannyBelly: Palette.mannyBelly,
    mannyOutline: _white(Palette.mannyOutlineAlpha),
    cardFillTop: _white(Palette.glassTopWhiteAlpha),
    cardFillBottom: _white(Palette.glassBottomWhiteAlpha),
    cardBorder: _white(Palette.borderHairAlpha),
    floatFill: Palette.surfaceFloatRgb.withValues(
      alpha: Palette.surfaceFloatAlpha,
    ),
    controlBorder: _white(Palette.borderControlAlpha),
    blurEnabled: true,
    glowEnabled: true,
    shadowsEnabled: true,
    highContrast: false,
  );

  /// Hoher Kontrast (Brief 3.5, Ergänzung 1 und 2, Plan 8.5): alle Flächen
  /// opak (`surface-opaque`), Ränder `border-control-hc`, kein Blur, kein
  /// Glow, keine Schatten/Scheine, `scrim` 72 %.
  static final CuraColors darkHighContrast = dark.copyWith(
    scrim: _black.withValues(alpha: Palette.scrimAlphaHighContrast),
    cardFillTop: Palette.surfaceOpaque,
    cardFillBottom: Palette.surfaceOpaque,
    cardBorder: _white(Palette.borderControlHcAlpha),
    floatFill: Palette.surfaceOpaque,
    controlBorder: _white(Palette.borderControlHcAlpha),
    blurEnabled: false,
    glowEnabled: false,
    shadowsEnabled: false,
    highContrast: true,
  );

  static CuraColors of(BuildContext context) {
    final CuraColors? colors = Theme.of(context).extension<CuraColors>();
    assert(
      colors != null,
      'CuraColors fehlt im Theme (CuraTheme.build nutzen).',
    );
    return colors!;
  }

  @override
  CuraColors copyWith({
    Color? bg,
    Color? surfaceGlassTop,
    Color? surfaceGlassBottom,
    Color? surfaceFloat,
    Color? surfaceOpaque,
    Color? borderHair,
    Color? borderControl,
    Color? borderControlHc,
    Color? text1,
    Color? text2,
    Color? text3,
    Color? accent,
    Color? accentHi,
    Color? accentSoft,
    Color? accentPressed,
    Color? onAccent,
    Color? focusRing,
    Color? catPhysio,
    Color? catArzt,
    Color? catUebung,
    Color? catFrist,
    Color? triGruen,
    Color? triGelb,
    Color? triOrange,
    Color? triRot,
    Color? statusError,
    Color? streakFreeze,
    Color? glowEmber,
    Color? scrim,
    Color? mannyBody,
    Color? mannyBelly,
    Color? mannyOutline,
    Color? cardFillTop,
    Color? cardFillBottom,
    Color? cardBorder,
    Color? floatFill,
    Color? controlBorder,
    bool? blurEnabled,
    bool? glowEnabled,
    bool? shadowsEnabled,
    bool? highContrast,
  }) {
    return CuraColors(
      bg: bg ?? this.bg,
      surfaceGlassTop: surfaceGlassTop ?? this.surfaceGlassTop,
      surfaceGlassBottom: surfaceGlassBottom ?? this.surfaceGlassBottom,
      surfaceFloat: surfaceFloat ?? this.surfaceFloat,
      surfaceOpaque: surfaceOpaque ?? this.surfaceOpaque,
      borderHair: borderHair ?? this.borderHair,
      borderControl: borderControl ?? this.borderControl,
      borderControlHc: borderControlHc ?? this.borderControlHc,
      text1: text1 ?? this.text1,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      accent: accent ?? this.accent,
      accentHi: accentHi ?? this.accentHi,
      accentSoft: accentSoft ?? this.accentSoft,
      accentPressed: accentPressed ?? this.accentPressed,
      onAccent: onAccent ?? this.onAccent,
      focusRing: focusRing ?? this.focusRing,
      catPhysio: catPhysio ?? this.catPhysio,
      catArzt: catArzt ?? this.catArzt,
      catUebung: catUebung ?? this.catUebung,
      catFrist: catFrist ?? this.catFrist,
      triGruen: triGruen ?? this.triGruen,
      triGelb: triGelb ?? this.triGelb,
      triOrange: triOrange ?? this.triOrange,
      triRot: triRot ?? this.triRot,
      statusError: statusError ?? this.statusError,
      streakFreeze: streakFreeze ?? this.streakFreeze,
      glowEmber: glowEmber ?? this.glowEmber,
      scrim: scrim ?? this.scrim,
      mannyBody: mannyBody ?? this.mannyBody,
      mannyBelly: mannyBelly ?? this.mannyBelly,
      mannyOutline: mannyOutline ?? this.mannyOutline,
      cardFillTop: cardFillTop ?? this.cardFillTop,
      cardFillBottom: cardFillBottom ?? this.cardFillBottom,
      cardBorder: cardBorder ?? this.cardBorder,
      floatFill: floatFill ?? this.floatFill,
      controlBorder: controlBorder ?? this.controlBorder,
      blurEnabled: blurEnabled ?? this.blurEnabled,
      glowEnabled: glowEnabled ?? this.glowEnabled,
      shadowsEnabled: shadowsEnabled ?? this.shadowsEnabled,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  /// Zwischenwerte werden nicht gemischt: Der Wechsel zwischen den Varianten
  /// ist ein Sofortwechsel (Mischen von Flächen und Schaltern wäre sinnlos).
  @override
  CuraColors lerp(ThemeExtension<CuraColors>? other, double t) {
    if (other is! CuraColors) return this;
    return t < 0.5 ? this : other;
  }
}
