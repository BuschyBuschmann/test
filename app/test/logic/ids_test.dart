import 'dart:math';

import 'package:curaone/logic/ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('newUuid: UUID v4, eindeutig', () {
    final Random r = Random(1);
    final Set<String> seen = <String>{};
    for (int i = 0; i < 200; i++) {
      final String id = newUuid(r);
      expect(isUuid(id), isTrue, reason: id);
      expect(id[14], '4');
      expect('89ab'.contains(id[19]), isTrue);
      seen.add(id);
    }
    expect(seen.length, 200);
    expect(isUuid(newUuid()), isTrue);
  });

  test('uuidFromSeed: gleichbleibend, UUID-Form, Version 8', () {
    final String a = uuidFromSeed('result|p|2026-10-07|item1');
    expect(a, uuidFromSeed('result|p|2026-10-07|item1'));
    expect(isUuid(a), isTrue);
    expect(a[14], '8');
    expect('89ab'.contains(a[19]), isTrue);
  });

  test('uuidFromSeed: unterschiedliche Texte ergeben unterschiedliche IDs', () {
    final Set<String> ids = <String>{
      for (int d = 1; d <= 28; d++)
        for (int i = 0; i < 20; i++) uuidFromSeed('result|p|2026-10-$d|item$i'),
    };
    expect(ids.length, 28 * 20);
    expect(uuidFromSeed('a'), isNot(uuidFromSeed('b')));
    expect(
      uuidFromSeed('session|p1|2026-10-07'),
      isNot(uuidFromSeed('session|p2|2026-10-07')),
    );
  });

  test('isUuid lehnt Fremdes ab', () {
    expect(isUuid('nein'), isFalse);
    expect(isUuid('ZZZZZZZZ-ZZZZ-4ZZZ-8ZZZ-ZZZZZZZZZZZZ'), isFalse);
  });
}
