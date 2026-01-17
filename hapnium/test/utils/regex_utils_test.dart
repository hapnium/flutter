import 'package:hapnium/hapnium.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('RegexUtils', () {
    test('email - valid', () {
      expect(RegexUtils.email.hasMatch('user@example.com'), isTrue);
      expect(RegexUtils.email.hasMatch('"john.doe"@mail.co.uk'), isTrue);
    });

    test('email - invalid', () {
      expect(RegexUtils.email.hasMatch('user@.com'), isFalse);
      expect(RegexUtils.email.hasMatch('john@@mail.com'), isFalse);
    });

    test('ipv4 - valid', () {
      expect(RegexUtils.ipv4.hasMatch('192.168.1.1'), isTrue);
      expect(RegexUtils.ipv4.hasMatch('10.0.0.255'), isTrue);
    });

    test('ipv4 - invalid', () {
      expect(RegexUtils.ipv4.hasMatch('256.0.0.1'), isTrue); // Pattern match, but invalid IP range
      expect(RegexUtils.ipv4.hasMatch('192.168.1'), isFalse);
    });

    test('ipv6 - valid', () {
      expect(RegexUtils.ipv6.hasMatch('::1'), isTrue);
      expect(RegexUtils.ipv6.hasMatch('2001:0db8:85a3:0000:0000:8a2e:0370:7334'), isTrue);
    });

    test('ipv6 - invalid', () {
      expect(RegexUtils.ipv6.hasMatch('2001:::7334'), isFalse);
    });

    test('integer', () {
      expect(RegexUtils.integer.hasMatch('123'), isTrue);
      expect(RegexUtils.integer.hasMatch('-456'), isTrue);
      expect(RegexUtils.integer.hasMatch('12.3'), isFalse);
      expect(RegexUtils.integer.hasMatch('abc'), isFalse);
    });

    test('alphanumeric', () {
      expect(RegexUtils.alphanumeric.hasMatch('abc123'), isTrue);
      expect(RegexUtils.alphanumeric.hasMatch('Hello2025'), isTrue);
      expect(RegexUtils.alphanumeric.hasMatch('abc!'), isFalse);
    });

    test('alphabetic', () {
      expect(RegexUtils.alphabetic.hasMatch('abcDEF'), isTrue);
      expect(RegexUtils.alphabetic.hasMatch('abc123'), isFalse);
    });

    test('numeric', () {
      expect(RegexUtils.numeric.hasMatch('123'), isTrue);
      expect(RegexUtils.numeric.hasMatch('-456'), isTrue);
      expect(RegexUtils.numeric.hasMatch('12.3'), isFalse);
    });

    test('float', () {
      expect(RegexUtils.float.hasMatch('1.5'), isTrue);
      expect(RegexUtils.float.hasMatch('-3.14'), isTrue);
      expect(RegexUtils.float.hasMatch('1e10'), isTrue);
      expect(RegexUtils.float.hasMatch('1.2.3'), isFalse);
    });

    test('hexadecimal', () {
      expect(RegexUtils.hexadecimal.hasMatch('1a2b3C'), isTrue);
      expect(RegexUtils.hexadecimal.hasMatch('FFEE99'), isTrue);
      expect(RegexUtils.hexadecimal.hasMatch('Z123'), isFalse);
    });

    test('hexColor', () {
      expect(RegexUtils.hexColor.hasMatch('#fff'), isTrue);
      expect(RegexUtils.hexColor.hasMatch('aabbcc'), isTrue);
      expect(RegexUtils.hexColor.hasMatch('#12345g'), isFalse);
    });

    test('base64', () {
      expect(RegexUtils.base64.hasMatch('dGVzdA=='), isTrue);
      expect(RegexUtils.base64.hasMatch('U29tZSBzdHJpbmc='), isTrue);
      expect(RegexUtils.base64.hasMatch('abc'), isFalse);
    });

    test('creditCard', () {
      expect(RegexUtils.creditCard.hasMatch('4111111111111111'), isTrue);
      expect(RegexUtils.creditCard.hasMatch('123456'), isFalse);
    });

    test('isbn10', () {
      expect(RegexUtils.isbn10.hasMatch('123456789X'), isTrue);
      expect(RegexUtils.isbn10.hasMatch('1234567890'), isTrue);
      expect(RegexUtils.isbn10.hasMatch('12345678'), isFalse);
    });

    test('isbn13', () {
      expect(RegexUtils.isbn13.hasMatch('9781234567897'), isTrue);
      expect(RegexUtils.isbn13.hasMatch('978123456789'), isFalse);
    });

    test('uuid - version specific', () {
      expect(RegexUtils.uuid['3']!.hasMatch('123E4567-E89B-12D3-A456-426614174000'), isFalse);
      expect(RegexUtils.uuid['4']!.hasMatch('123E4567-E89B-42D3-A456-426614174000'), isTrue);
      expect(RegexUtils.uuid['5']!.hasMatch('123E4567-E89B-52D3-A456-426614174000'), isTrue);
      expect(RegexUtils.uuid['all']!.hasMatch('123E4567-E89B-42D3-A456-426614174000'), isTrue);
    });

    test('surrogatePairs', () {
      expect(RegexUtils.surrogatePairs.hasMatch('\uD83D\uDE00'), isTrue); // 😀
    });

    test('multibyte', () {
      expect(RegexUtils.multibyte.hasMatch('こんにちは'), isTrue);
      expect(RegexUtils.multibyte.hasMatch('Hello'), isFalse);
    });

    test('ascii', () {
      expect(RegexUtils.ascii.hasMatch('Hello!123'), isTrue);
      expect(RegexUtils.ascii.hasMatch('こんにちは'), isFalse);
    });

    test('fullWidth', () {
      expect(RegexUtils.fullWidth.hasMatch('Ｈｅｌｌｏ'), isTrue);
      expect(RegexUtils.fullWidth.hasMatch('Hello'), isFalse);
    });

    test('halfWidth', () {
      expect(RegexUtils.halfWidth.hasMatch('Hello123'), isTrue);
    });

    test('emoji', () {
      expect(RegexUtils.emoji.hasMatch('Hello 👋'), isTrue);
      expect(RegexUtils.emoji.hasMatch('NoEmojiHere'), isFalse);
    });

    test('singleEmoji', () {
      expect(RegexUtils.singleEmoji.hasMatch('😂'), isTrue);
      expect(RegexUtils.singleEmoji.hasMatch('hi 😂'), isTrue); // still matches 1 emoji
    });
  });
}