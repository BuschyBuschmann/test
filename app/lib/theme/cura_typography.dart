// Textstile als `ThemeExtension` (Design-Brief v1 3.3, Plan 8.1). Jeder Stil
// setzt `fontFamily`, `fontSize`, `height`, `fontWeight` **und**
// `fontVariations` (`wght`, `opsz`, bei Bricolage zusätzlich `wdth`).
// Stile tragen keine Farbe, außer `segment`/`segmentSelected` (A-23); die Farbe
// setzt die Komponente aus `CuraColors`.
import 'package:flutter/material.dart';

import 'cura_colors.dart';
import 'tokens.dart';

/// Optische Größe: `opsz = fontSize`, begrenzt auf die Achse der Schrift
/// (entspricht `font-optical-sizing: auto` im Web).
double opticalSizeFor(TypeSpec spec) {
  final bool bricolage = spec.family == TypeScale.bricolage;
  final double min = bricolage
      ? TypeScale.bricolageOpszMin
      : TypeScale.dmSansOpszMin;
  final double max = bricolage
      ? TypeScale.bricolageOpszMax
      : TypeScale.dmSansOpszMax;
  return spec.size.clamp(min, max).toDouble();
}

TextStyle textStyleFromSpec(TypeSpec spec, {Color? color}) {
  final bool bricolage = spec.family == TypeScale.bricolage;
  return TextStyle(
    fontFamily: spec.family,
    fontSize: spec.size,
    height: spec.lineHeight / spec.size,
    fontWeight: FontWeight.values.firstWhere(
      (FontWeight w) => w.value == spec.weight,
    ),
    letterSpacing: spec.letterSpacingEm == 0
        ? null
        : spec.letterSpacingEm * spec.size,
    color: color,
    fontVariations: <FontVariation>[
      FontVariation('wght', spec.weight.toDouble()),
      FontVariation('opsz', opticalSizeFor(spec)),
      if (bricolage) const FontVariation('wdth', TypeScale.bricolageWidth),
    ],
  );
}

@immutable
class CuraTypography extends ThemeExtension<CuraTypography> {
  const CuraTypography({
    required this.display,
    required this.title,
    required this.heading,
    required this.numeral,
    required this.numeralLarge,
    required this.button,
    required this.body,
    required this.bodyStrong,
    required this.secondary,
    required this.label,
    required this.caption,
    required this.bubble,
    required this.segment,
    required this.segmentSelected,
  });

  factory CuraTypography.from(CuraColors colors) {
    return CuraTypography(
      display: textStyleFromSpec(TypeScale.display),
      title: textStyleFromSpec(TypeScale.title),
      heading: textStyleFromSpec(TypeScale.heading),
      numeral: textStyleFromSpec(TypeScale.numeral),
      numeralLarge: textStyleFromSpec(TypeScale.numeralLarge),
      button: textStyleFromSpec(TypeScale.button),
      body: textStyleFromSpec(TypeScale.body),
      bodyStrong: textStyleFromSpec(TypeScale.bodyStrong),
      secondary: textStyleFromSpec(TypeScale.secondary),
      label: textStyleFromSpec(TypeScale.label),
      caption: textStyleFromSpec(TypeScale.caption),
      bubble: textStyleFromSpec(TypeScale.bubble),
      segment: textStyleFromSpec(TypeScale.segment, color: colors.text2),
      segmentSelected: textStyleFromSpec(
        TypeScale.segmentSelected,
        color: colors.text1,
      ),
    );
  }

  final TextStyle display;
  final TextStyle title;
  final TextStyle heading;
  final TextStyle numeral;

  /// Zahl 24/28 (z. B. Uhrzeit auf Karten).
  final TextStyle numeralLarge;
  final TextStyle button;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle secondary;

  /// Abschnittstitel; Großbuchstaben nur in der Darstellung (`CuraLabel`).
  final TextStyle label;
  final TextStyle caption;

  /// Sprechblase, 14,5 sp.
  final TextStyle bubble;
  final TextStyle segment;
  final TextStyle segmentSelected;

  /// Alle Stile mit Namen (für Typo-Tafel und Tests).
  Map<String, TextStyle> get all => <String, TextStyle>{
    'display': display,
    'title': title,
    'heading': heading,
    'numeral': numeral,
    'numeralLarge': numeralLarge,
    'button': button,
    'body': body,
    'bodyStrong': bodyStrong,
    'secondary': secondary,
    'label': label,
    'caption': caption,
    'bubble': bubble,
    'segment': segment,
    'segmentSelected': segmentSelected,
  };

  static final CuraTypography dark = CuraTypography.from(CuraColors.dark);
  static final CuraTypography darkHighContrast = CuraTypography.from(
    CuraColors.darkHighContrast,
  );

  static CuraTypography of(BuildContext context) {
    final CuraTypography? t = Theme.of(context).extension<CuraTypography>();
    assert(
      t != null,
      'CuraTypography fehlt im Theme (CuraTheme.build nutzen).',
    );
    return t!;
  }

  @override
  CuraTypography copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? heading,
    TextStyle? numeral,
    TextStyle? numeralLarge,
    TextStyle? button,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? secondary,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? bubble,
    TextStyle? segment,
    TextStyle? segmentSelected,
  }) {
    return CuraTypography(
      display: display ?? this.display,
      title: title ?? this.title,
      heading: heading ?? this.heading,
      numeral: numeral ?? this.numeral,
      numeralLarge: numeralLarge ?? this.numeralLarge,
      button: button ?? this.button,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      secondary: secondary ?? this.secondary,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      bubble: bubble ?? this.bubble,
      segment: segment ?? this.segment,
      segmentSelected: segmentSelected ?? this.segmentSelected,
    );
  }

  @override
  CuraTypography lerp(ThemeExtension<CuraTypography>? other, double t) {
    if (other is! CuraTypography) return this;
    return CuraTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      heading: TextStyle.lerp(heading, other.heading, t)!,
      numeral: TextStyle.lerp(numeral, other.numeral, t)!,
      numeralLarge: TextStyle.lerp(numeralLarge, other.numeralLarge, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      secondary: TextStyle.lerp(secondary, other.secondary, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      bubble: TextStyle.lerp(bubble, other.bubble, t)!,
      segment: TextStyle.lerp(segment, other.segment, t)!,
      segmentSelected: TextStyle.lerp(
        segmentSelected,
        other.segmentSelected,
        t,
      )!,
    );
  }
}
