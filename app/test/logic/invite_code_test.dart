// Einladungscode (Plan 6.5, N-7): Normalisierung, Format, Link.
import 'package:curaone/logic/invite_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Normalisierung', () {
    test('Großschreibung, Leerzeichen und Bindestriche entfernen', () {
      expect(normalizeInviteCode(' abcde-fghjk '), 'ABCDEFGHJK');
      expect(normalizeInviteCode('ab cd\te-fg\nhjk'), 'ABCDEFGHJK');
    });

    test('O → 0, I und L → 1', () {
      expect(normalizeInviteCode('OIL-oil'), '011011');
      expect(normalizeInviteCode('o0i1l1'), '001111');
    });

    test('entspricht der Datenbankfunktion (translate OIL → 011)', () {
      // app.normalize_invite_code: upper, [[:space:]-] entfernen, translate.
      expect(normalizeInviteCode('a-b c'), 'ABC');
      expect(normalizeInviteCode(''), '');
    });
  });

  group('Gültigkeit', () {
    test('10 Zeichen des Alphabets sind gültig', () {
      expect(isValidNormalizedInviteCode('0123456789'), isTrue);
      expect(isValidNormalizedInviteCode('ABCDEFGHJK'), isTrue);
      expect(isValidNormalizedInviteCode('MNPQRSTVWX'), isTrue);
      expect(isValidNormalizedInviteCode('YZ01234567'), isTrue);
    });

    test('I, L, O, U gehören nicht zum Alphabet (nach Normalisierung)', () {
      expect(kInviteAlphabet.length, 32);
      for (final String c in <String>['I', 'L', 'O', 'U']) {
        expect(kInviteAlphabet.contains(c), isFalse, reason: c);
      }
      // U wird nicht umgeschrieben und bleibt ungültig.
      expect(parseInviteCode('ABCDE-FGHJU'), isNull);
    });

    test('zu kurz, zu lang, Sonderzeichen', () {
      expect(parseInviteCode('ABCDE-FGHJ'), isNull);
      expect(parseInviteCode('ABCDE-FGHJKM'), isNull);
      expect(parseInviteCode('ABCDE-FGH!K'), isNull);
      expect(parseInviteCode(''), isNull);
    });

    test('O/I/L-Verwechslungen werden korrigiert und sind dann gültig', () {
      expect(parseInviteCode('abcde-fghjo'), 'ABCDEFGHJ0');
      expect(parseInviteCode('l1l1l-1l1l1'), '1111111111');
    });
  });

  group('Format', () {
    test('Anzeige XXXXX-XXXXX', () {
      expect(formatInviteCode('abcdefghjk'), 'ABCDE-FGHJK');
      expect(formatInviteCode('ABCDE FGHJK'), 'ABCDE-FGHJK');
      expect(formatInviteCode('zu kurz'), isNull);
    });

    test('Eingabehilfe während des Tippens', () {
      expect(formatInviteCodeInput('ab'), 'AB');
      expect(formatInviteCodeInput('abcde'), 'ABCDE');
      expect(formatInviteCodeInput('abcdef'), 'ABCDE-F');
      expect(formatInviteCodeInput('abcdefghjkmnp'), 'ABCDE-FGHJK');
      expect(formatInviteCodeInput('ab-cd e'), 'ABCDE');
    });
  });

  group('Link', () {
    test('https-Link mit einladung=', () {
      expect(
        inviteCodeFromLink(
          Uri.parse('https://app.example.org/?einladung=abcde-fghjk'),
        ),
        'ABCDEFGHJK',
      );
    });

    test('curaone://einladung?code=', () {
      expect(
        inviteCodeFromLink(Uri.parse('curaone://einladung?code=ABCDE-FGHJK')),
        'ABCDEFGHJK',
      );
    });

    test('ohne Parameter null; ungültiger Code wird trotzdem geliefert', () {
      expect(inviteCodeFromLink(Uri.parse('https://x.org/')), isNull);
      expect(
        inviteCodeFromLink(Uri.parse('https://x.org/?einladung=')),
        isNull,
      );
      expect(
        inviteCodeFromLink(Uri.parse('https://x.org/?einladung=ab')),
        'AB',
      );
    });
  });
}
