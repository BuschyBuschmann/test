// Motion-Tokens (Design-Brief v1 3.6). Dauern und Kurve als Konstanten.
// `CuraMotion.of(context)` mit Erkennung „Bewegung reduzieren“ folgt mit den
// Bausteinen (U2a, Plan 8.1).
import 'package:flutter/animation.dart';

import 'tokens.dart';

abstract final class CuraMotion {
  static const Duration fast = MotionTokens.fast;
  static const Duration base = MotionTokens.base;
  static const Duration slow = MotionTokens.slow;
  static const Curve curve = MotionTokens.curve;
}
