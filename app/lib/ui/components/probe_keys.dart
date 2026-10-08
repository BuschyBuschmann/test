// Marker-Schlüssel für die Prüfungen (Matrix, Web-Screenshots): Screens und
// Bausteine setzen sie an die Elemente, die die Prüfungen brauchen. Die
// Schlüssel liegen hier (nicht in `lib/dev/`), weil `lib/ui/` nichts aus
// `lib/dev/` importieren darf; `PreviewKeys` in `lib/dev/scenarios.dart`
// verweist auf dieselben Werte.
//
// Namen mit Präfix `overlay:` zählen als Overlay (schwebt über dem Inhalt),
// `probe:` als Messpunkt für die Pipette. Fehlt ein Marker, entfällt die
// jeweilige Prüfung (bei gesetztem Szenario-Flag ist das ein harter Befund).
import 'package:flutter/widgets.dart';

abstract final class ProbeKeys {
  static const ValueKey<String> nav = ValueKey<String>('overlay:nav');
  static const ValueKey<String> cluster = ValueKey<String>('overlay:cluster');
  static const ValueKey<String> primaryRow = ValueKey<String>(
    'overlay:primary-row',
  );
  static const ValueKey<String> bubble = ValueKey<String>('overlay:bubble');
  static const ValueKey<String> hint = ValueKey<String>('overlay:hint');
  static const ValueKey<String> chatFooter = ValueKey<String>(
    'overlay:chat-footer',
  );
  static const ValueKey<String> keyboard = ValueKey<String>('overlay:keyboard');
  static const ValueKey<String> header = ValueKey<String>('header');

  /// Kopf, der in der Scrollfläche mitläuft (Onboarding bei großer Schrift
  /// oder geringer Höhe): kein fester Kopf, darum **nicht** `header`.
  static const ValueKey<String> scrollHeader = ValueKey<String>(
    'scroll-header',
  );
  static const ValueKey<String> scroll = ValueKey<String>('scroll');
  static const ValueKey<String> primary = ValueKey<String>('primary');
  static const ValueKey<String> probeBackground = ValueKey<String>('probe:bg');
  static const ValueKey<String> probePrimary = ValueKey<String>(
    'probe:primary',
  );
  static const ValueKey<String> probeTitle = ValueKey<String>('probe:title');
}
