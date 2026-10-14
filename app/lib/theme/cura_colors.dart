// Semantische Farb-Tokens als `ThemeExtension` (Design-Brief v2 3.2: Inhalts-
// flächen in Hell und Dunkel, unabhängig von der Welt). Komponenten lesen
// Farben ausschließlich über `CuraColors.of(context)`; die Welt (Himmel,
// Kopf-Karte, Leiste) steht in `world_tokens.dart`.
//
// Vier Varianten: [light], [dark] und je eine Variante „Hoher Kontrast“
// ([lightHighContrast], [darkHighContrast]); sie gilt auch für den App-Schalter
// „Transparenz reduzieren“ (Brief 3.5): alle Glasflächen opak, kein Blur, Welt
// ohne Körnung/Dunst/Sterne/Sonne/Mond, Ränder mit hohem Kontrast.
import 'package:flutter/material.dart';

import 'tokens.dart';

@immutable
class CuraColors extends ThemeExtension<CuraColors> {
  const CuraColors({
    required this.brightness,
    required this.bg,
    required this.card,
    required this.surfaceOpaque,
    required this.borderHair,
    required this.borderControl,
    required this.borderControlHc,
    required this.text1,
    required this.text2,
    required this.accent,
    required this.accentTop,
    required this.accentSoft,
    required this.accentPressed,
    required this.onAccent,
    required this.accentText,
    required this.successText,
    required this.focusRing,
    required this.focusRingOuter,
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
    required this.gold,
    required this.onGold,
    required this.chipNeutralFill,
    required this.chipSuccessFill,
    required this.chipSuccessText,
    required this.chipWarnFill,
    required this.chipWarnText,
    required this.scrim,
    required this.cardFillTop,
    required this.cardFillBottom,
    required this.cardBorder,
    required this.floatFill,
    required this.controlBorder,
    required this.blurEnabled,
    required this.worldDecorEnabled,
    required this.shadowsEnabled,
    required this.highContrast,
  });

  /// Helles oder dunkles Thema der Inhaltsflächen.
  final Brightness brightness;

  /// Grund unter der Welt (Scaffold, `world-floor` des Themas).
  final Color bg;

  /// `card`: Weiß 92 % (Hell) bzw. `#241D18` 92 % (Dunkel); Hoher Kontrast 100 %.
  final Color card;

  /// `card` zu 100 %: Sheet, Dialog, Eingabefelder (opak, kein Blur).
  final Color surfaceOpaque;
  final Color borderHair;
  final Color borderControl;
  final Color borderControlHc;

  /// `ink-1` (Hell) bzw. `text-1` (Dunkel).
  final Color text1;

  /// `ink-2` (Hell) bzw. `text-2` (Dunkel).
  final Color text2;

  /// Mandarine, nur Füllung (nie Text, V2-32).
  final Color accent;

  /// Oberer Ton des Akzentverlaufs `#FFA063` → `#FF7A2E`.
  final Color accentTop;
  final Color accentSoft;
  final Color accentPressed;
  final Color onAccent;

  /// Orange als Text: nur dieser dunkle Ton (Hell `#A83F0B`, Dunkel `#FF9A62`).
  final Color accentText;
  final Color successText;
  final Color focusRing;

  /// Außenrand des Fokusrings (2 dp), Gegenfarbe zu [focusRing].
  final Color focusRingOuter;
  final Color catPhysio;
  final Color catArzt;
  final Color catUebung;
  final Color catFrist;
  final Color triGruen;
  final Color triGelb;
  final Color triOrange;
  final Color triRot;

  /// `error-text` / `status-error`.
  final Color statusError;
  final Color streakFreeze;

  /// `gold` (Fortschritt, Ziel) und Symbole darauf.
  final Color gold;
  final Color onGold;
  final Color chipNeutralFill;
  final Color chipSuccessFill;
  final Color chipSuccessText;
  final Color chipWarnFill;
  final Color chipWarnText;
  final Color scrim;

  /// Karten-Füllung oben/unten (v2: beide `card`, flache Fläche; Hoher
  /// Kontrast: opak).
  final Color cardFillTop;
  final Color cardFillBottom;

  /// Kartenrand (Normal `borderHair`, hoher Kontrast `borderControlHc`).
  final Color cardBorder;

  /// Füllung schwebender Flächen (Nav, Blase, Sheet); hoher Kontrast opak.
  final Color floatFill;

  /// Rand bedienbarer Felder (`borderControl`, hoher Kontrast `borderControlHc`).
  final Color controlBorder;

  /// Blur erlaubt (hoher Kontrast/Transparenz reduzieren: nein).
  final bool blurEnabled;

  /// Körnung, Dunst, Sterne, Sonne/Mond der Welt (hoher Kontrast: nein).
  final bool worldDecorEnabled;

  /// Schein/Schatten des Primärbuttons und der Nav (hoher Kontrast: nein). Die Schatten der Aktions-Buttons hängen nicht daran.
  final bool shadowsEnabled;

  /// Variante „Hoher Kontrast“ bzw. „Transparenz reduzieren“.
  final bool highContrast;

  /// Flache Karten-Fläche als Verlauf (beide Enden gleich).
  LinearGradient get cardFill => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[cardFillTop, cardFillBottom],
  );

  /// Akzentfüllung: Verlauf `#FFA063` → `#FF7A2E`.
  LinearGradient get accentFill => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[accentTop, accent],
  );

  bool get isDark => brightness == Brightness.dark;

  static Color _a(Color base, double alpha) => base.withValues(alpha: alpha);

  /// Baut eine Variante aus den Paletten.
  static CuraColors build({
    required Brightness brightness,
    bool highContrast = false,
  }) {
    final bool dark = brightness == Brightness.dark;
    final Color cardBase = dark ? Palette.cardDark : Palette.cardLight;
    final Color text1 = dark ? Palette.text1Dark : Palette.text1Light;
    final Color text2 = dark ? Palette.text2Dark : Palette.text2Light;
    final Color cardTint = _a(cardBase, Palette.cardAlpha);
    final Color cardFill = highContrast ? cardBase : cardTint;
    final Color borderControl = _a(
      text1,
      dark ? Palette.borderControlDarkAlpha : Palette.borderControlLightAlpha,
    );
    final Color borderControlHc = _a(text1, Palette.borderControlHcAlpha);
    final Color borderHair = _a(
      text1,
      dark ? Palette.borderHairDarkAlpha : Palette.borderHairLightAlpha,
    );
    final Color accent = Palette.accent;
    return CuraColors(
      brightness: brightness,
      bg: dark ? Palette.bgDark : Palette.bgLight,
      card: cardTint,
      surfaceOpaque: cardBase,
      borderHair: borderHair,
      borderControl: borderControl,
      borderControlHc: borderControlHc,
      text1: text1,
      text2: text2,
      accent: accent,
      accentTop: Palette.accentTop,
      accentSoft: _a(accent, Palette.accentSoftAlpha),
      accentPressed: Palette.accentPressed,
      onAccent: Palette.onAccent,
      accentText: dark ? Palette.accentTextDark : Palette.accentTextLight,
      successText: dark ? Palette.successTextDark : Palette.successTextLight,
      focusRing: text1,
      focusRingOuter: dark
          ? Palette.focusRingOuterDark
          : Palette.focusRingOuterLight,
      catPhysio: dark ? Palette.catPhysioDark : Palette.catPhysioLight,
      catArzt: dark ? Palette.catArztDark : Palette.catArztLight,
      catUebung: dark ? Palette.catUebungDark : Palette.catUebungLight,
      catFrist: dark ? Palette.catFristDark : Palette.catFristLight,
      triGruen: dark ? Palette.triGruenDark : Palette.triGruenLight,
      triGelb: dark ? Palette.triGelbDark : Palette.triGelbLight,
      triOrange: dark ? Palette.triOrangeDark : Palette.triOrangeLight,
      triRot: dark ? Palette.triRotDark : Palette.triRotLight,
      statusError: dark ? Palette.errorDark : Palette.errorLight,
      streakFreeze: dark ? Palette.streakFreezeDark : Palette.streakFreezeLight,
      gold: Palette.gold,
      onGold: Palette.onGold,
      chipNeutralFill: _a(
        dark ? Palette.cardLight : Palette.text1Light,
        dark ? Palette.chipNeutralDarkAlpha : Palette.chipNeutralLightAlpha,
      ),
      chipSuccessFill: dark
          ? Palette.chipSuccessFillDark
          : Palette.chipSuccessFillLight,
      chipSuccessText: dark
          ? Palette.chipSuccessTextDark
          : Palette.chipSuccessTextLight,
      chipWarnFill: dark ? Palette.chipWarnFillDark : Palette.chipWarnFillLight,
      chipWarnText: dark ? Palette.chipWarnTextDark : Palette.chipWarnTextLight,
      scrim: _a(
        Palette.scrimBase,
        highContrast ? Palette.scrimAlphaHighContrast : Palette.scrimAlpha,
      ),
      cardFillTop: cardFill,
      cardFillBottom: cardFill,
      cardBorder: highContrast ? borderControlHc : borderHair,
      floatFill: highContrast ? cardBase : _a(cardBase, Palette.floatAlpha),
      controlBorder: highContrast ? borderControlHc : borderControl,
      blurEnabled: !highContrast,
      worldDecorEnabled: !highContrast,
      shadowsEnabled: !highContrast,
      highContrast: highContrast,
    );
  }

  static final CuraColors light = build(brightness: Brightness.light);
  static final CuraColors dark = build(brightness: Brightness.dark);

  /// Hoher Kontrast bzw. „Transparenz reduzieren“ (Brief 3.5): alle
  /// Flächen opak (`card` 100 %), Ränder `border-control-hc`, kein Blur, Welt
  /// ohne Dekor, keine Schatten/Scheine.
  static final CuraColors lightHighContrast = build(
    brightness: Brightness.light,
    highContrast: true,
  );
  static final CuraColors darkHighContrast = build(
    brightness: Brightness.dark,
    highContrast: true,
  );

  /// Variante nach Thema und Kontrast.
  static CuraColors variant(
    Brightness brightness, {
    bool highContrast = false,
  }) {
    if (brightness == Brightness.dark) {
      return highContrast ? darkHighContrast : dark;
    }
    return highContrast ? lightHighContrast : light;
  }

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
    Brightness? brightness,
    Color? bg,
    Color? card,
    Color? surfaceOpaque,
    Color? borderHair,
    Color? borderControl,
    Color? borderControlHc,
    Color? text1,
    Color? text2,
    Color? accent,
    Color? accentTop,
    Color? accentSoft,
    Color? accentPressed,
    Color? onAccent,
    Color? accentText,
    Color? successText,
    Color? focusRing,
    Color? focusRingOuter,
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
    Color? gold,
    Color? onGold,
    Color? chipNeutralFill,
    Color? chipSuccessFill,
    Color? chipSuccessText,
    Color? chipWarnFill,
    Color? chipWarnText,
    Color? scrim,
    Color? cardFillTop,
    Color? cardFillBottom,
    Color? cardBorder,
    Color? floatFill,
    Color? controlBorder,
    bool? blurEnabled,
    bool? worldDecorEnabled,
    bool? shadowsEnabled,
    bool? highContrast,
  }) {
    return CuraColors(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      card: card ?? this.card,
      surfaceOpaque: surfaceOpaque ?? this.surfaceOpaque,
      borderHair: borderHair ?? this.borderHair,
      borderControl: borderControl ?? this.borderControl,
      borderControlHc: borderControlHc ?? this.borderControlHc,
      text1: text1 ?? this.text1,
      text2: text2 ?? this.text2,
      accent: accent ?? this.accent,
      accentTop: accentTop ?? this.accentTop,
      accentSoft: accentSoft ?? this.accentSoft,
      accentPressed: accentPressed ?? this.accentPressed,
      onAccent: onAccent ?? this.onAccent,
      accentText: accentText ?? this.accentText,
      successText: successText ?? this.successText,
      focusRing: focusRing ?? this.focusRing,
      focusRingOuter: focusRingOuter ?? this.focusRingOuter,
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
      gold: gold ?? this.gold,
      onGold: onGold ?? this.onGold,
      chipNeutralFill: chipNeutralFill ?? this.chipNeutralFill,
      chipSuccessFill: chipSuccessFill ?? this.chipSuccessFill,
      chipSuccessText: chipSuccessText ?? this.chipSuccessText,
      chipWarnFill: chipWarnFill ?? this.chipWarnFill,
      chipWarnText: chipWarnText ?? this.chipWarnText,
      scrim: scrim ?? this.scrim,
      cardFillTop: cardFillTop ?? this.cardFillTop,
      cardFillBottom: cardFillBottom ?? this.cardFillBottom,
      cardBorder: cardBorder ?? this.cardBorder,
      floatFill: floatFill ?? this.floatFill,
      controlBorder: controlBorder ?? this.controlBorder,
      blurEnabled: blurEnabled ?? this.blurEnabled,
      worldDecorEnabled: worldDecorEnabled ?? this.worldDecorEnabled,
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
