import 'dart:io';

import 'package:flutter/services.dart';

/// Familien wie in `pubspec.yaml`.
const String kBricolageFamily = 'BricolageGrotesque';
const String kDmSansFamily = 'DMSans';

const Map<String, String> _kFontFiles = <String, String>{
  kBricolageFamily: 'assets/fonts/BricolageGrotesque[opsz,wdth,wght].ttf',
  kDmSansFamily: 'assets/fonts/DMSans[opsz,wght].ttf',
};

bool _loaded = false;

Future<ByteData> _bytes(String path) async {
  final Uint8List data = await File(path).readAsBytes();
  return ByteData.sublistView(data);
}

/// Lädt die gebündelten Fonts und die Material-Icons für Widget- und
/// Golden-Tests (die Test-Engine lädt sonst nur die Ahem-Ersatzschrift).
/// Erwartet das Paketverzeichnis als Arbeitsverzeichnis (so startet
/// `flutter test`). Mehrfachaufruf ist wirkungslos.
Future<void> loadTestFonts() async {
  if (_loaded) return;
  _loaded = true;

  for (final MapEntry<String, String> entry in _kFontFiles.entries) {
    final FontLoader loader = FontLoader(entry.key)
      ..addFont(_bytes(entry.value));
    await loader.load();
  }

  // Material-Icons liegen im Flutter-SDK, nicht im Projekt.
  final String flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final File icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final FontLoader loader = FontLoader('MaterialIcons')
      ..addFont(_bytes(icons.path));
    await loader.load();
  }
}
