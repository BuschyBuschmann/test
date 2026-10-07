import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/test_fonts.dart';

/// Gilt für alle Tests unter `test/`: echte Fonts und Material-Icons laden.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadTestFonts();
  await testMain();
}
