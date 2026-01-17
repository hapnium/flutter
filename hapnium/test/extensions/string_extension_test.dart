import 'package:hapnium/hapnium.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('StringExtensions Tests', () {
    test('equalsIgnoreCase and notEqualsIgnoreCase', () {
      expect('Hello'.equalsIgnoreCase('hello'), isTrue);
      expect('Hello'.notEqualsIgnoreCase('hello'), isFalse);
    });

    test('equals and notEquals', () {
      expect('Hello'.equals('Hello'), isTrue);
      expect('Hello'.notEquals('HELLO'), isTrue);
    });

    test('equalsAny', () {
      expect('Test'.equalsAny(['test', 'Test'], isIgnoreCase: true), isTrue);
      expect('Test'.equalsAny(['testing', 'example']), isFalse);
    });

    test('notEqualsAny', () {
      expect('Test'.notEqualsAny(['test'], isIgnoreCase: true), isFalse);
      expect('Test'.notEqualsAny(['testing', 'example']), isTrue);
    });

    test('equalsAll', () {
      expect('yes'.equalsAll(['YES', 'yes'], isIgnoreCase: true), isTrue);
      expect('yes'.equalsAll(['YES', 'no'], isIgnoreCase: true), isFalse);
    });

    test('containsIgnoreCase', () {
      expect('DartLang'.containsIgnoreCase('lang'), isTrue);
      expect('DartLang'.containsIgnoreCase('LANG'), isTrue);
    });

    test('capitalizeFirst', () {
      expect('hello world'.capitalizeFirst, equals('Hello world'));
    });

    test('capitalizeEach', () {
      expect('hello world'.capitalizeEach, equals('Hello World'));
    });

    test('withAorAn', () {
      expect('apple'.withAorAn, equals('an apple'));
      expect('banana'.withAorAn, equals('a banana'));
    });

    test('isNumeric and isNum', () {
      expect('123'.isNumeric, isTrue);
      expect('123.45'.isNumeric, isTrue);
      expect('abc'.isNumeric, isFalse);
      expect('123'.isNum, isTrue);
    });

    test('hasEmojis', () {
      expect('Hi 👋'.hasEmojis, isTrue);
      expect('Just text'.hasEmojis, isFalse);
    });

    test('containsOnlyEmojis', () {
      expect('🎉🎈'.containsOnlyEmojis, isTrue);
      expect('🎉 text'.containsOnlyEmojis, isFalse);
    });

    test('isBool', () {
      expect('true'.isBool, isTrue);
      expect('FALSE'.isBool, isTrue);
      expect('maybe'.isBool, isFalse);
    });

    test('isImage', () {
      expect('photo.jpg'.isImage, isTrue);
      expect('video.mp4'.isImage, isFalse);
    });

    test('isPDF', () {
      expect('file.pdf'.isPDF, isTrue);
    });

    test('isVideo', () {
      expect('movie.mp4'.isVideo, isTrue);
    });

    test('isUsername', () {
      expect('user_name123'.isUsername, isTrue);
      expect('_invalidUsername'.isUsername, isFalse);
    });

    test('isURL', () {
      expect('https://example.com'.isURL, isTrue);
      expect('not a url'.isURL, isFalse);
    });

    test('isAlpha and isAlphanumeric', () {
      expect('abc'.isAlphabetic, isTrue);
      expect('abc123'.isAlphanumeric, isTrue);
      expect('abc-123'.isAlphanumeric, isFalse);
    });

    test('isBase64', () {
      expect('SGVsbG8gV29ybGQ='.isBase64, isTrue);
    });

    test('isInt and isFloat', () {
      expect('123'.isInt, isTrue);
      expect('123.45'.isFloat, isTrue);
    });

    test('isDivisibleBy', () {
      expect('10'.isDivisibleBy(2), isTrue);
      expect('10'.isDivisibleBy('5'), isTrue);
      expect('10'.isDivisibleBy('3'), isFalse);
    });

    test('isLowercase and isUppercase', () {
      expect('abc'.isLowercase, isTrue);
      expect('ABC'.isUppercase, isTrue);
    });
  });

  group('Extended String Extension', () {
    test('isLength handles surrogate pairs correctly', () {
      expect('a'.isLength(1), isTrue);
      expect('💖'.isLength(1), isTrue); // emoji is a surrogate pair
      expect('💖'.isLength(2), isFalse);
    });

    test('isByteLength', () {
      expect('abc'.isByteLength(3), isTrue);
      expect('abc'.isByteLength(2), isTrue);
      expect('abc'.isByteLength(4), isFalse);
    });

    test('isUUID', () {
      expect('550e8400-e29b-41d4-a716-446655440000'.isUUID(), isTrue);
      expect('550e8400-e29b-41d4-a716-446655440000'.isUUID(4), isTrue);
      expect('invalid-uuid'.isUUID(), isFalse);
    });

    test('isDate', () {
      expect('2023-01-01'.isDate, isTrue);
      expect('invalid'.isDate, isFalse);
    });

    test('isAfter and isBefore', () {
      final now = DateTime.now();
      final past = now.subtract(Duration(days: 1)).toIso8601String();
      final future = now.add(Duration(days: 1)).toIso8601String();

      expect(future.isAfter(), isTrue);
      expect(past.isBefore(), isTrue);
    });

    test('isIn', () {
      expect('a'.isIn(['a', 'b']), isTrue);
      expect('c'.isIn(['a', 'b']), isFalse);
      expect('a'.isIn('abc'), isTrue);
    });

    test('isCreditCard', () {
      expect('4111 1111 1111 1111'.isCreditCard, isTrue);
      expect('1234 5678 9012 3456'.isCreditCard, isFalse);
    });

    test('isISBN', () {
      expect('0-306-40615-2'.isISBN(), isTrue);
      expect('978-3-16-148410-0'.isISBN(), isTrue);
    });

    test('isJson', () {
      expect('{"name":"value"}'.isJson, isTrue);
      expect('not json'.isJson, isFalse);
    });

    test('isMultibyte & isAscii', () {
      expect('こんにちは'.isMultibyte, isTrue);
      expect('hello'.isAscii, isTrue);
    });

    test('isPalindrome', () {
      expect('A man a plan a canal Panama'.isPalindrome, isTrue);
      expect('Hello'.isPalindrome, isFalse);
    });

    test('isEmail', () {
      expect('test@example.com'.isEmail, isTrue);
      expect('not-an-email'.isEmail, isFalse);
    });

    test('isPhoneNumber', () {
      expect('+1 234 567 8901'.isPhoneNumber, isTrue);
      expect('123'.isPhoneNumber, isFalse);
    });

    test('isIPv4 & isIPv6', () {
      expect('192.168.1.1'.isIPv4, isTrue);
      expect('::1'.isIPv6, isTrue);
    });

    test('isMD5', () {
      expect('d41d8cd98f00b204e9800998ecf8427e'.isMD5, isTrue);
    });

    test('isSSN', () {
      expect('123-45-6789'.isSSN, isTrue);
      expect('000-00-0000'.isSSN, isFalse);
    });

    test('isCpf and isCnpj', () {
      expect('52998224725'.isCpf, isTrue);
      expect('00000000000'.isCpf, isFalse);
      expect('11222333000181'.isCnpj, isTrue);
      expect('00000000000000'.isCnpj, isFalse);
    });

    test('camelCase and snakeCase and paramCase', () {
      expect('hello world'.camelCase, 'helloWorld');
      expect('HelloWorld'.snakeCase(), 'hello_world');
      expect('HelloWorld'.paramCase, 'hello-world');
    });

    test('numericOnly', () {
      expect('OTP 12312 27/04/2020'.numericOnly(), '1231227042020');
      expect('OTP 12312 27/04/2020'.numericOnly(firstWordOnly: true), '12312');
    });

    test('capitalizeAllWordsFirstLetter', () {
      expect('hello world'.capitalizeAllWordsFirstLetter, 'Hello World');
    });

    test('removeAllWhitespace', () {
      expect('a b c'.removeAllWhitespace, 'abc');
    });

    test('isPassport', () {
      expect('A1234567'.isPassport, isTrue);
      expect('0000000'.isPassport, isFalse);
    });

    test('isCurrency', () {
      expect('\$1,234.56'.isCurrency, isTrue);
      expect('1234.56'.isCurrency, isTrue);
    });
  });
}