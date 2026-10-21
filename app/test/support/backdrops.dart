// Zählt Blur-Flächen: `CuraBlur` hält seinen Baum in jedem Zustand gleich und
// schaltet nur `BackdropFilter.enabled` um (L1K). Eine Blur-Fläche ist ein
// `BackdropFilter` mit `enabled == true`.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Alle wirksamen `BackdropFilter` (`enabled == true`).
Finder activeBackdrops() => find.byWidgetPredicate(
  (Widget w) => w is BackdropFilter && w.enabled,
  description: 'BackdropFilter (enabled)',
);
