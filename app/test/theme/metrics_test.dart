// Maßkonstanten (Plan 14, U1a, MINOR-6): Ablage der Brief-Werte aus
// Design-Brief 3.4 und Ergänzung 2; keine neuen Design-Tokens.
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Raster 4 dp (Brief 3.4)', () {
    expect(
      <double>[
        CuraSpace.s1,
        CuraSpace.s2,
        CuraSpace.s3,
        CuraSpace.s4,
        CuraSpace.s5,
        CuraSpace.s6,
        CuraSpace.s8,
        CuraSpace.s10,
      ],
      <double>[4, 8, 12, 16, 20, 24, 32, 40],
    );
    expect(CuraSpace.pageMargin, 16);
  });

  test('Radien (Brief 3.4, Ergänzung 1, 2)', () {
    expect(CuraRadius.card, 24);
    expect(CuraRadius.pill, 999);
    expect(CuraRadius.chipInner, 12);
    expect(CuraRadius.sheet, 28);
    expect(CuraRadius.iconTile, 7);
    expect(CuraRadius.composer, 28); // Eingabeleiste
    expect(CuraRadius.notice, 16); // Hinweiskarte
    expect(CuraRadius.bubble, 20); // Blasen
    expect(CuraRadius.bubbleCorner, 6); // Ecke zur Absenderseite
    expect(CuraRadius.snackbar, 20);
    expect(CuraRadius.dialog, 24);
    expect(CuraRadius.nodeHint, 16);
  });

  test('Ergänzung 2: Button-Gruppe, Abstände, Ränder (MINOR-6)', () {
    expect(CuraSize.mannyChatButton, 56);
    expect(CuraSize.messagesButton, 48);
    expect(CuraSpace.clusterGap, 8);
    expect(CuraSpace.snackbarGap, 12);
    expect(CuraSpace.pageMargin, 16); // Rand
    expect(CuraSize.sendCircle, 40);
    expect(CuraSize.sendCircleHitArea, 48);
    expect(CuraSize.composerMinHeight, 56);
    expect(CuraSize.noticePaddingVertical, 10);
    expect(CuraSize.noticePaddingHorizontal, 14);
    expect(CuraSize.bubblePaddingVertical, 12);
    expect(CuraSize.bubblePaddingHorizontal, 16);
  });

  test('Ergänzung 2: Avatare, Embleme, Einzug, Längen, Zeilen', () {
    expect(CuraSize.avatar, 48);
    expect(CuraSize.avatarHeader, 36);
    expect(CuraSize.emblemMessage, 26);
    expect(CuraSize.emblemHeader, 34);
    expect(CuraSize.mannyHeadInButton, 38);
    expect(CuraSpace.mannyTextIndent, 36);
    expect(CuraSize.lineLengthMax, 560);
    expect(CuraSize.contactRowMin, 72);
    expect(CuraSpace.messageGap, 20);
    expect(CuraSpace.blockGap, 8);
  });

  test('Ergänzung 2: Schwellen, Manny-Hit-Rand, Routen-Schiebung', () {
    expect(CuraSize.bubbleWidthFactor, 0.80);
    expect(CuraSize.chatFooterMaxFraction, 0.40);
    expect(CuraSize.textScaleScrollAlong, 1.5);
    expect(CuraSize.mannyHitMargin, 8);
    expect(CuraSize.routeSlide, 24);
    expect(MotionTokens.routeSlide, 24);
  });

  test('Brief 3.4: Touch-Ziele, Nav, Buttons, Units', () {
    expect(CuraSize.touchTarget, 48);
    expect(CuraSize.minTargetGap, 8);
    expect(CuraSize.navHeight, 64);
    expect(CuraSize.navSideMargin, 16);
    expect(CuraSize.navBottomMargin, 22);
    expect(CuraSize.navActivePill, 48);
    expect(CuraSize.primaryButtonHeight, 56);
    expect(CuraSize.chipHeight, 48);
    expect(
      <double>[
        CuraSize.unitSmall,
        CuraSize.unitMedium,
        CuraSize.unitLarge,
        CuraSize.unitBoss,
      ],
      <double>[48, 60, 72, 92],
    );
  });

  test('Schatten (Brief 3.5, Ergänzung 2): Versatz, Weichzeichnung, Farbe', () {
    final BoxShadow action = CuraShadow.actionButton.single;
    expect(action.offset, const Offset(0, 6));
    expect(action.blurRadius, 16);
    expect(action.color.a, closeTo(0.40, 1e-9));
    expect(action.color.withValues(alpha: 1).toARGB32(), 0xFF000000);

    final BoxShadow floating = CuraShadow.floating.single;
    expect(floating.offset, const Offset(0, 10));
    expect(floating.blurRadius, 30);
    expect(floating.color.a, closeTo(0.45, 1e-9));

    final BoxShadow glow = CuraShadow.primaryGlow.single;
    expect(glow.offset, const Offset(0, 8));
    expect(glow.blurRadius, 28);
    expect(glow.color.a, closeTo(0.28, 1e-9));
    expect(glow.color.withValues(alpha: 1).toARGB32(), 0xFFD9622B);
  });

  test('Motion (Brief 3.6) und Blur', () {
    expect(MotionTokens.fast, const Duration(milliseconds: 120));
    expect(MotionTokens.base, const Duration(milliseconds: 200));
    expect(MotionTokens.slow, const Duration(milliseconds: 320));
    expect(MotionTokens.curve, Curves.easeOutCubic);
    expect(BlurTokens.sigma, 16);
    expect(SnackbarTokens.short, const Duration(seconds: 4));
    expect(SnackbarTokens.medium, const Duration(seconds: 5));
    expect(SnackbarTokens.long, const Duration(seconds: 8));
  });
}
