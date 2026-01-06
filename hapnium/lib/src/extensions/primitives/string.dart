// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:convert' show json;

import '../../utils/regex_utils.dart';
import 'iterable.dart';
import 'map.dart';
import 'int.dart';
import 'list.dart';

/// credits to "ReCase" package.
final RegExp _upperAlphaRegex = RegExp(r'[A-Z]');

final Set<String> _symbolSet = {' ', '.', '/', '_', '\\', '-'};

List<String> _groupIntoWords(String text) {
  StringBuffer sb = StringBuffer();
  List<String> words = <String>[];
  bool isAllCaps = text.toUpperCase() == text;

  for (int i = 0; i < text.length; i++) {
    String char = text[i];
    String? nextChar = i + 1 == text.length ? null : text[i + 1];
    if (_symbolSet.contains(char)) {
      continue;
    }

    sb.write(char);
    bool isEndOfWord = nextChar == null || (_upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) || _symbolSet.contains(nextChar);

    if (isEndOfWord) {
      words.add('$sb');
      sb.clear();
    }
  }

  return words;
}

extension StringExtensions on String {
  /// Case-insensitive equality check.
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();

  /// Case-insensitive in-equality check.
  bool notEqualsIgnoreCase(String other) => toLowerCase() != other.toLowerCase();

  /// Case equality check.
  bool equals(String other) => this == other;

  /// Case equality check.
  bool isEqualTo(String other) => equals(other);

  /// Case in-equality check.
  bool notEquals(String other) => this != other;

  /// Case in-equality check.
  bool isNotEqualTo(String other) => notEquals(other);

  /// Checks if string equals any item in the list
  /// 
  /// Adds extra value checkers like `lowercase`, `uppercase`, `ignorecase`
  bool equalsAny(List<String> values, {bool isLowerCase = false, bool isUpperCase = false, bool isIgnoreCase = false}) {
    if(isUpperCase) {
      return values.any((v) => v.toUpperCase().equals(toUpperCase()));
    }

    return values.any((v) => equalsIgnoreCase(v));
  }

  /// Checks if string does not equals any item in the list
  /// 
  /// Adds extra value checkers like `lowercase`, `uppercase`, `ignorecase`
  bool notEqualsAny(List<String> values, {bool isLowerCase = false, bool isUpperCase = false, bool isIgnoreCase = false}) {
    if(isUpperCase) {
      return !values.any((v) => v.toUpperCase().equals(toUpperCase()));
    }

    return !values.any((v) => equalsIgnoreCase(v));
  }

  /// Checks if string equals all items in the list
  /// 
  /// Adds extra value checkers like `lowercase`, `uppercase`, `ignorecase`
  bool equalsAll(List<String> values, {bool isLowerCase = false, bool isUpperCase = false, bool isIgnoreCase = false}) {
    if(isUpperCase) {
      return values.all((v) => v.toUpperCase().equals(toUpperCase()));
    }

    return values.all((v) => equalsIgnoreCase(v));
  }

  /// Checks if string does not equals all items in the list
  /// 
  /// Adds extra value checkers like `lowercase`, `uppercase`, `ignorecase`
  bool notEqualsAll(List<String> values, {bool isLowerCase = false, bool isUpperCase = false, bool isIgnoreCase = false}) {
    if(isUpperCase) {
      return !values.all((v) => v.toUpperCase().equals(toUpperCase()));
    }

    return !values.all((v) => equalsIgnoreCase(v));
  }

  /// Contains [value] with case-insensitive
  bool containsIgnoreCase(String value) => toLowerCase().contains(value.toLowerCase());

  /// Checks if string is a number type of `double` or `int`
  bool get isNumeric => (isNotEmpty && (double.tryParse(this) != null || int.tryParse(this) != null)) || RegexUtils.numeric.hasMatch(this);

  /// Returns "an" before the string if it starts with a vowel, otherwise "a".
  String get withAorAn => startsWith(RegExp('[aeiouAEIOU]')) ? "an ${toLowerCase()}" : "a ${toLowerCase()}";

  /// Capitalizes the first letter of the string.
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalizes the first letter of each word in the string.
  String get capitalizeEach {
    if (isEmpty) return this;

    return split(' ').map((String word) {
      return word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : word;
    }).join(' ');
  }

  /// Capitalizes the first letter of each word in the string.
  @Deprecated('Use `capitalizeEach` instead')
  String get capitalize => capitalizeEach;

  /// Checks if the string contains any emojis.
  bool get hasEmojis {
    RegExp emojiRegExp = RegExp(
      r'[\u{1F600}-\u{1F64F}' // Emoticons
      r'\u{1F300}-\u{1F5FF}' // Miscellaneous Symbols and Pictographs
      r'\u{1F680}-\u{1F6FF}' // Transport and Map Symbols
      r'\u{2600}-\u{26FF}' // Miscellaneous Symbols
      r'\u{2700}-\u{27BF}' // Dingbats
      r'\u{1F900}-\u{1F9FF}' // Supplemental Symbols and Pictographs
      r'\u{1F1E0}-\u{1F1FF}' // Flags (iOS flags are represented by two characters)
      ']+',
      unicode: true,
    );

    return emojiRegExp.hasMatch(this);
  }

  /// Checks if the string contains only emojis.
  bool get containsOnlyEmojis {
    String textWithoutEmojis = replaceAll(RegexUtils.emoji, '');
    return textWithoutEmojis.isEmpty;
  }

  /// Checks if the string contains only one emoji.
  bool get containsOnlyOneEmoji {
    String textWithoutEmojis = replaceAll(RegexUtils.singleEmoji, '');
    return textWithoutEmojis.isEmpty && RegexUtils.emoji.allMatches(this).length == 1;
  }

  /// {@macro string_emoji_extensions}
  ///
  /// Returns `true` if this string contains at least one emoji character.
  ///
  /// Example:
  /// ```dart
  /// final text = "I love 🍕!";
  /// print(text.containsEmoji); // true
  /// ```
  bool get containsEmoji => RegexUtils.targetedEmoji.hasMatch(this);

  /// {@macro string_emoji_extensions}
  ///
  /// Returns a new string with all emojis removed, including any
  /// **leading or trailing whitespace** around the emojis, to avoid
  /// leftover gaps in the text.
  ///
  /// Example:
  /// ```dart
  /// final text = "I ❤️ Dart 🌟";
  /// print(text.removeEmojis); // "I Dart"
  /// ```
  /// Remove emojis while preserving layout and box-drawing characters.
  ///
  /// Options:
  /// - [collapseSpaces] (default true): collapse runs of 2+ whitespace into a single space (but preserve leading indentation).
  /// - [replacement] (default ''): replace emojis with this string instead of removing. If you want fixed width marker, set e.g. '⍰'.
  ///
  /// Behavior details:
  /// - Operates per-line (split on `\n`) so box drawing lines are preserved.
  /// - Preserves leading whitespace (indentation) for each line.
  /// - Trims trailing whitespace from each line (to avoid visible gaps).
  /// - Collapses multiple internal spaces to a single space (configurable).
  String removeEmojis({bool collapseSpaces = true, String replacement = '', RegExp? regex}) {
    final emojiRegex = regex ?? RegexUtils.targetedEmoji;
    if (!emojiRegex.hasMatch(this)) return this;

    final lines = split('\n');
    final buffer = StringBuffer();

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];

      // 1) Replace emoji sequences with replacement
      var replaced = line.replaceAll(emojiRegex, replacement);

      // 2) Trim trailing whitespace (we don't want trailing gaps)
      replaced = replaced.replaceFirst(RegExp(r'\s+$'), '');

      // 3) Detect a prefix to preserve:
      //    If the line begins with a non-alphanumeric "prefix" (common in boxed logs),
      //    preserve up to and including the first whitespace after that prefix.
      //    Examples preserved: "│ ", "┌── ", "> ", "- "
      final prefixMatch = RegExp(r'^([^A-Za-z0-9][^\S\r\n]*[^A-Za-z0-9]?[\s])').firstMatch(replaced);
      String prefix = '';
      String core = replaced;
      if (prefixMatch != null) {
        prefix = prefixMatch.group(0) ?? '';
        core = replaced.substring(prefix.length);
      } else {
        // Fall back: preserve leading whitespace (indentation)
        final leadingWs = RegExp(r'^\s*').firstMatch(replaced)?.group(0) ?? '';
        prefix = leadingWs;
        core = replaced.substring(prefix.length);
      }

      // 4) Collapse internal multiple spaces if requested
      final coreCollapsed = collapseSpaces ? core.replaceAll(RegExp(r'\s{2,}'), ' ') : core;

      // 5) Reattach prefix and write line
      buffer.writeln(prefix + coreCollapsed);
    }

    // Trim final newline added by writeln to match original line count
    var result = buffer.toString();
    if (result.endsWith('\n')) result = result.substring(0, result.length - 1);
    return result;
  }

  /// Checks if string is int or double.
  bool get isNum {
    if (isEmpty) {
      return false;
    }

    return num.tryParse(this) is num;
  }

  /// Checks if string consist only numeric.
  /// Numeric only doesn't accepting "." which double data type have
  bool get isNumericOnly => matchesRegex(r'^\d+$');

  /// Checks if string consist only Alphabet. (No Whitespace)
  bool get isAlphabetOnly => matchesRegex(r'^[a-zA-Z]+$');

  /// Checks if string contains at least one Capital Letter
  bool get hasCapitalLetter => matchesRegex(r'[A-Z]');

  /// Checks if string is boolean.
  bool get isBool {
    if (isEmpty) {
      return false;
    }

    return (equalsIgnoreCase('true') || equalsIgnoreCase('false'));
  }

  /// Checks if string is an video file.
  bool get isVideo {
    String ext = toLowerCase();

    return ext.endsWith(".mp4") ||
        ext.endsWith(".avi") ||
        ext.endsWith(".wmv") ||
        ext.endsWith(".rmvb") ||
        ext.endsWith(".mpg") ||
        ext.endsWith(".mpeg") ||
        ext.endsWith(".3gp");
  }

  /// Checks if string is an image file.
  bool get isImage {
    String ext = toLowerCase();

    return ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg") ||
        ext.endsWith(".png") ||
        ext.endsWith(".gif") ||
        ext.endsWith(".bmp");
  }

  /// Checks if string is an audio file.
  bool get isAudio {
    String ext = toLowerCase();

    return ext.endsWith(".mp3") ||
        ext.endsWith(".wav") ||
        ext.endsWith(".wma") ||
        ext.endsWith(".amr") ||
        ext.endsWith(".ogg");
  }

  /// Checks if string is an powerpoint file.
  bool get isPPT {
    String ext = toLowerCase();

    return ext.endsWith(".ppt") || ext.endsWith(".pptx");
  }

  /// Checks if string is an word file.
  bool get isWord {
    String ext = toLowerCase();

    return ext.endsWith(".doc") || ext.endsWith(".docx");
  }

  /// Checks if string is an excel file.
  bool get isExcel {
    String ext = toLowerCase();

    return ext.endsWith(".xls") || ext.endsWith(".xlsx");
  }

  /// Checks if string is an apk file.
  bool get isAPK => toLowerCase().endsWith(".apk");

  /// Checks if string is an pdf file.
  bool get isPDF => toLowerCase().endsWith(".pdf");

  /// Checks if string is an txt file.
  bool get isTxt => toLowerCase().endsWith(".txt");

  /// Checks if string is an chm file.
  bool get isChm => toLowerCase().endsWith(".chm");

  /// Checks if string is a vector file.
  bool get isVector => toLowerCase().endsWith(".svg");

  /// Checks if string is an html file.
  bool get isHTML => toLowerCase().endsWith(".html");

  /// Checks if string is a valid username.
  bool get isUsername => matchesRegex(r'^[a-zA-Z0-9][a-zA-Z0-9_.]+[a-zA-Z0-9]$');

  /// Checks if string is URL.
  bool get isURL => matchesRegex(r"^((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://)?(www.|[a-zA-Z0-9].)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,7}(\:[0-9]{1,5})*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&amp;%\$#\=~_\-]+))*$");

  /// Check if the string is a URL
  ///
  /// `options` is a `Map` which defaults to
  /// `{ 'protocols': ['http','https','ftp'], 'require_tld': true,
  /// 'require_protocol': false, 'allow_underscores': false }`.
  bool isUrl([Map<String, Object>? options]) {
    var str = this;
    if (str.isEmpty || str.length > 2083 || str.indexOf('mailto:') == 0) {
      return false;
    }

    final defaultUrlOptions = {
      'protocols': ['http', 'https', 'ftp'],
      'require_tld': true,
      'require_protocol': false,
      'allow_underscores': false,
    };

    options = options?.merge(defaultUrlOptions) ?? defaultUrlOptions;

    // check protocol
    var split = str.split('://');
    if (split.length > 1) {
      final protocol = split.shift();
      final protocols = options['protocols'] as List<String>;
      if (!protocols.contains(protocol)) {
        return false;
      }
    } else if (options['require_protocol'] == true) {
      return false;
    }
    str = split.join('://');

    // check hash
    split = str.split('#');
    str = split.shift() ?? "";
    final hash = split.join('#');
    if (hash.isNotEmpty && RegExp(r'\s').hasMatch(hash)) {
      return false;
    }

    // check query params
    split = str.isNotEmpty ? str.split('?') : [];
    str = split.shift() ?? "";
    final query = split.join('?');
    if (query != "" && RegExp(r'\s').hasMatch(query)) {
      return false;
    }

    // check path
    split = str.isNotEmpty ? str.split('/') : [];
    str = split.shift() ?? "";
    final path = split.join('/');
    if (path != "" && RegExp(r'\s').hasMatch(path)) {
      return false;
    }

    // check auth type urls
    split = str.isNotEmpty ? str.split('@') : [];
    if (split.length > 1) {
      final auth = split.shift();
      if (auth != null && auth.contains(':')) {
        // final auth = auth.split(':');
        final parts = auth.split(':');
        final user = parts.shift();
        if (user == null || !RegExp(r'^\S+$').hasMatch(user)) {
          return false;
        }
        final pass = parts.join(':');
        if (!RegExp(r'^\S*$').hasMatch(pass)) {
          return false;
        }
      }
    }

    // check hostname
    final hostname = split.join('@');
    split = hostname.split(':');
    final host = split.shift();
    if (split.isNotEmpty) {
      final portStr = split.join(':');
      final port = int.tryParse(portStr, radix: 10);
      if (!RegExp(r'^[0-9]+$').hasMatch(portStr) || port == null || port <= 0 || port > 65535) {
        return false;
      }
    }

    if (host == null || !host.isIP() && !host.isFQDN(options) && host != 'localhost') {
      return false;
    }

    return true;
  }

  /// Check if the string is an IP (version 4 or 6)
  ///
  /// `version` is a String or an `int`.
  bool isIP([Object? version]) {
    final String str = this;

    assert(version == null || version is String || version is int);
    version = version.toString();
    if (version == 'null') {
      return str.isIP(4) || isIP(6);
    } else if (version == '4') {
      if (!RegexUtils.ipv4.hasMatch(str)) {
        return false;
      }
      var parts = str.split('.');
      parts.sort((a, b) => int.parse(a) - int.parse(b));
      return int.parse(parts[3]) <= 255;
    }
    return version == '6' && RegexUtils.ipv6.hasMatch(str);
  }

  /// Check if the string is a fully qualified domain name (e.g. domain.com).
  ///
  /// `options` is a `Map` which defaults to `{ 'require_tld': true, 'allow_underscores': false }`.
  bool isFQDN([Map<String, Object>? options]) {
    var str = this;

    final defaultFqdnOptions = {'require_tld': true, 'allow_underscores': false};

    options = options?.merge(defaultFqdnOptions) ?? defaultFqdnOptions;
    final parts = str.split('.');
    if (options['require_tld'] as bool) {
      var tld = parts.removeLast();
      if (parts.isEmpty || !RegExp(r'^[a-z]{2,}$').hasMatch(tld)) {
        return false;
      }
    }

    for (final part in parts) {
      if (options['allow_underscores'] as bool) {
        if (part.contains('__')) {
          return false;
        }
      }
      if (!RegExp(r'^[a-z\\u00a1-\\uffff0-9-]+$').hasMatch(part)) {
        return false;
      }
      if (part[0] == '-' ||
          part[part.length - 1] == '-' ||
          part.contains('---')) {
        return false;
      }
    }
    return true;
  }

  /// Check if the string contains only letters (a-zA-Z).
  bool get isAlphabetic => RegexUtils.alphabetic.hasMatch(this);

  /// Check if the string contains only letters and numbers
  bool get isAlphanumeric => RegexUtils.alphanumeric.hasMatch(this);

  /// Check if a string is base64 encoded
  bool get isBase64 => RegexUtils.base64.hasMatch(this);

  /// Check if the string is an integer
  bool get isInt => RegexUtils.integer.hasMatch(this);

  /// Check if the string is a float
  bool get isFloat => RegexUtils.float.hasMatch(this);

  /// Check if the string is a hexadecimal number
  ///
  /// Example: HexColor => #12F
  bool get isHexadecimal => RegexUtils.hexadecimal.hasMatch(this) || matchesRegex(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$');

  /// Check if the string is a hexadecimal color
  bool get isHexColor => RegexUtils.hexColor.hasMatch(this);

  /// Check if the string is lowercase
  bool get isLowercase => this == toLowerCase();

  /// Check if the string is uppercase
  bool get isUppercase => this == toUpperCase();

  /// Check if the string is a number that's divisible by another
  ///
  /// [n] is a String or an int.
  bool isDivisibleBy(Object n) {
    assert(n is String || n is int);
    final int? number;
    if (n is int) {
      number = n;
    } else if (n is String) {
      number = int.tryParse(n);
    } else {
      return false;
    }
    if (number == null) return false;
    try {
      return double.parse(this) % number == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if the string's length falls in a range
  /// If no max is given then any length above min is ok.
  ///
  /// Note: this function takes into account surrogate pairs.
  bool isLength(int min, [int? max]) {
    var str = this;

    final surrogatePairs = RegexUtils.surrogatePairs.allMatches(str).toList();
    int len = str.length - surrogatePairs.length;
    return len >= min && (max == null || len <= max);
  }

  /// Check if the string's length (in bytes) falls in a range.
  bool isByteLength(int min, [int? max]) => length >= min && (max == null || length <= max);

  /// Check if the string is a UUID (version 3, 4 or 5).
  bool isUUID([Object? version]) {
    if (version == null) {
      version = 'all';
    } else {
      version = version.toString();
    }

    RegExp? pat = RegexUtils.uuid[version];
    return (pat != null && pat.hasMatch(toUpperCase()));
  }

  /// Check if the string is a date
  bool get isDate => DateTime.tryParse(this) != null;

  /// Check if the string is a date that's after the specified date
  ///
  /// If `date` is not passed, it defaults to now.
  bool isAfter([String? date]) {
    DateTime referenceDate;
    if (date == null) {
      referenceDate = DateTime.now();
    } else if (date.isDate) {
      referenceDate = DateTime.parse(date);
    } else {
      return false;
    }

    final strDate = DateTime.tryParse(this);
    if (strDate == null) return false;

    return strDate.isAfter(referenceDate);
  }

  /// Check if the string is a date that's before the specified date
  ///
  /// If `date` is not passed, it defaults to now.
  bool isBefore([String? date]) {
    DateTime referenceDate;
    if (date == null) {
      referenceDate = DateTime.now();
    } else if (date.isDate) {
      referenceDate = DateTime.parse(date);
    } else {
      return false;
    }

    final strDate = DateTime.tryParse(this);
    if (strDate == null) return false;

    return strDate.isBefore(referenceDate);
  }

  /// Check if the string is in an array of allowed values
  bool isIn(Object? values) {
    var str = this;

    if (values == null) return false;
    if (values is String) {
      return values.contains(str);
    }
    if (values is! Iterable) return false;
    for (Object? value in values) {
      if (value.toString() == str) return true;
    }
    return false;
  }

  /// Check if the string is a credit card
  bool get isCreditCard {
    var str = this;

    String sanitized = str.replaceAll(RegExp(r'[^0-9]+'), '');
    if (!RegexUtils.creditCard.hasMatch(sanitized)) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    String digit;
    bool shouldDouble = false;

    for (int i = sanitized.length - 1; i >= 0; i--) {
      digit = sanitized.substring(i, (i + 1));
      int tmpNum = int.parse(digit);

      if (shouldDouble == true) {
        tmpNum *= 2;
        if (tmpNum >= 10) {
          sum += ((tmpNum % 10) + 1);
        } else {
          sum += tmpNum;
        }
      } else {
        sum += tmpNum;
      }
      shouldDouble = !shouldDouble;
    }

    return (sum % 10 == 0);
  }

  /// Check if the string is an ISBN (version 10 or 13)
  bool isISBN([Object? version]) {
    var str = this;

    if (version == null) {
      return str.isISBN('10') || str.isISBN('13');
    }

    version = version.toString();

    String sanitized = str.replaceAll(RegExp(r'[\s-]+'), '');
    int checksum = 0;

    if (version == '10') {
      if (!RegexUtils.isbn10.hasMatch(sanitized)) {
        return false;
      }
      for (int i = 0; i < 9; i++) {
        checksum += (i + 1) * int.parse(sanitized[i]);
      }
      if (sanitized[9] == 'X') {
        checksum += 10 * 10;
      } else {
        checksum += 10 * int.parse(sanitized[9]);
      }
      return (checksum % 11 == 0);
    } else if (version == '13') {
      if (!RegexUtils.isbn13.hasMatch(sanitized)) {
        return false;
      }
      var factor = [1, 3];
      for (int i = 0; i < 12; i++) {
        checksum += factor[i % 2] * int.parse(sanitized[i]);
      }
      return (int.parse(sanitized[12]) - ((10 - (checksum % 10)) % 10) == 0);
    }

    return false;
  }

  /// Check if the string is valid JSON
  bool get isJson {
    try {
      json.decode(this);
    } catch (e) {
      return false;
    }
    return true;
  }

  /// Check if the string contains one or more multibyte chars
  bool get isMultibyte => RegexUtils.multibyte.hasMatch(this);

  /// Check if the string contains ASCII chars only
  bool get isAscii => RegexUtils.ascii.hasMatch(this);

  /// Check if the string contains any full-width chars
  bool get isFullWidth => RegexUtils.fullWidth.hasMatch(this);

  /// Check if the string contains any half-width chars
  bool get isHalfWidth => RegexUtils.halfWidth.hasMatch(this);

  /// Check if the string contains a mixture of full and half-width chars
  bool get isVariableWidth => isFullWidth && isHalfWidth;

  /// Check if the string contains any surrogate pairs chars
  bool get isSurrogatePair => RegexUtils.surrogatePairs.hasMatch(this);

  /// Check if the string is a valid hex-encoded representation of a MongoDB ObjectId
  bool get isMongoId => (isHexadecimal && length == 24);

  /// Checks if string is email.
  bool get isEmail => matchesRegex(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

  /// Checks if string is phone number.
  bool get isPhoneNumber {
    if (length > 16 || length < 9) {
      return false;
    }

    return matchesRegex(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
  }

  /// Checks if string is DateTime (UTC or Iso8601).
  bool get isDateTime => matchesRegex(r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}.\d{3}Z?$');

  /// Checks if string is MD5 hash.
  bool get isMD5 => matchesRegex(r'^[a-f0-9]{32}$');

  /// Checks if string is SHA1 hash.
  bool get isSHA1 => matchesRegex(r'(([A-Fa-f0-9]{2}\:){19}[A-Fa-f0-9]{2}|[A-Fa-f0-9]{40})');

  /// Checks if string is SHA256 hash.
  bool get isSHA256 => matchesRegex(r'([A-Fa-f0-9]{2}\:){31}[A-Fa-f0-9]{2}|[A-Fa-f0-9]{64}');

  /// Checks if string is SSN (Social Security Number).
  bool get isSSN => matchesRegex(r'^(?!0{3}|6{3}|9[0-9]{2})[0-9]{3}-?(?!0{2})[0-9]{2}-?(?!0{4})[0-9]{4}$');

  /// Checks if string is binary.
  bool get isBinary => matchesRegex(r'^[0-1]+$');

  /// Checks if string is IPv4.
  bool get isIPv4 => matchesRegex(r'^(?:(?:^|\.)(?:2(?:5[0-5]|[0-4]\d)|1?\d?\d)){4}$');

  /// Checks if string is IPv6.
  bool get isIPv6 => matchesRegex(r'^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-Fa-f]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})|(::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:))$');

  /// Checks if string is Palindrome.
  bool get isPalindrome {
    String cleanString = toLowerCase()
        .replaceAll(RegExp(r"\s+"), '')
        .replaceAll(RegExp(r"[^0-9a-zA-Z]+"), "");

    for (int i = 0; i < cleanString.length; i++) {
      if (cleanString[i] != cleanString[cleanString.length - i - 1]) {
        return false;
      }
    }

    return true;
  }

  /// Checks if string is Passport No.
  bool get isPassport => matchesRegex(r'^(?!^0+$)[a-zA-Z0-9]{6,9}$');

  /// Checks if string is Currency.
  bool get isCurrency => matchesRegex(r'^(S?\$|\₩|Rp|\¥|\€|\₹|\₽|fr|R\$|R)?[ ]?[-]?([0-9]{1,3}[,.]([0-9]{3}[,.])*[0-9]{3}|[0-9]+)([,.][0-9]{1,2})?( ?(USD?|AUD|NZD|CAD|CHF|GBP|CNY|EUR|JPY|IDR|MXN|NOK|KRW|TRY|INR|RUB|BRL|ZAR|SGD|MYR))?$');

  /// Checks if a contains b (Treating or interpreting upper- and lowercase
  /// letters as being the same).
  bool isCaseInsensitiveContains(String b) => toLowerCase().contains(b.toLowerCase());

  /// Checks if a contains b or b contains a (Treating or
  /// interpreting upper- and lowercase letters as being the same).
  bool isCaseInsensitiveContainsAny(String b) {
    String lowA = toLowerCase();
    String lowB = b.toLowerCase();

    return lowA.contains(lowB) || lowB.contains(lowA);
  }

  // Checks if num is a cnpj
  bool get isCnpj {
    // Get only the numbers from the CNPJ
    String numbers = replaceAll(RegExp(r'[^0-9]'), '');

    // Test if the CNPJ has 14 digits
    if (numbers.length != 14) {
      return false;
    }

    // Test if all digits of the CNPJ are the same
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return false;
    }

    // Divide digits
    List<int> digits = numbers.split('').map(int.parse).toList();

    // Calculate the first check digit
    int calcDv1 = 0;
    int j = 0;
    for (int i in Iterable<int>.generate(12, (int i) => i < 4 ? 5 - i : 13 - i)) {
      calcDv1 += digits[j++] * i;
    }
    calcDv1 %= 11;
    int dv1 = calcDv1 < 2 ? 0 : 11 - calcDv1;

    // Test the first check digit
    if (digits[12] != dv1) {
      return false;
    }

    // Calculate the second check digit
    int calcDv2 = 0;
    j = 0;
    for (int i in Iterable<int>.generate(13, (int i) => i < 5 ? 6 - i : 14 - i)) {
      calcDv2 += digits[j++] * i;
    }
    calcDv2 %= 11;
    int dv2 = calcDv2 < 2 ? 0 : 11 - calcDv2;

    // Test the second check digit
    if (digits[13] != dv2) {
      return false;
    }

    return true;
  }

  /// Checks if the cpf is valid.
  bool get isCpf {
    // get only the numbers
    String numbers = replaceAll(RegExp(r'[^0-9]'), '');
    // Test if the CPF has 11 digits
    if (numbers.length != 11) {
      return false;
    }

    // Test if all CPF digits are the same
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return false;
    }

    // split the digits
    List<int> digits = numbers.split('').map(int.parse).toList();

    // Calculate the first verifier digit
    int calcDv1 = 0;
    for (int i in Iterable<int>.generate(9, (int i) => 10 - i)) {
      calcDv1 += digits[10 - i] * i;
    }
    calcDv1 %= 11;

    int dv1 = calcDv1 < 2 ? 0 : 11 - calcDv1;

    // Tests the first verifier digit
    if (digits[9] != dv1) {
      return false;
    }

    // Calculate the second verifier digit
    int calcDv2 = 0;
    for (int i in Iterable<int>.generate(10, (int i) => 11 - i)) {
      calcDv2 += digits[11 - i] * i;
    }
    calcDv2 %= 11;

    int dv2 = calcDv2 < 2 ? 0 : 11 - calcDv2;

    // Test the second verifier digit
    if (digits[10] != dv2) {
      return false;
    }

    return true;
  }

  /// Remove all whitespace inside string
  String get removeAllWhitespace => replaceAll(' ', '');

  /// camelCase string
  /// Example: your name => yourName
  String? get camelCase {
    if (isEmpty) {
      return null;
    }

    List<String> separatedWords = split(RegExp(r'[!@#<>?":`~;[\]\\|=+)(*&^%-\s_]+'));
    String newString = '';

    for (String word in separatedWords) {
      newString += word[0].toUpperCase() + word.substring(1).toLowerCase();
    }

    return newString[0].toLowerCase() + newString.substring(1);
  }

  /// snake_case
  /// 
  /// Turns a word into snake case design. username = user_name
  String snakeCase({String separator = '_'}) {
    if (isEmpty) {
      return "";
    }

    return _groupIntoWords(this).map((String word) => word.toLowerCase()).join(separator);
  }

  /// param-case
  String get paramCase => snakeCase(separator: '-');

  /// Extract numeric value of string
  /// Example: OTP 12312 27/04/2020 => 1231227042020ß
  /// If firstWordOnly is true, then the example return is "12312"
  /// (first found numeric word)
  String numericOnly({bool firstWordOnly = false}) {
    String numericOnlyStr = '';

    for (int i = 0; i < length; i++) {
      if (this[i].isNumericOnly) {
        numericOnlyStr += this[i];
      }
      if (firstWordOnly && numericOnlyStr.isNotEmpty && this[i] == " ") {
        break;
      }
    }

    return numericOnlyStr;
  }

  /// Capitalize only the first letter of each word in a string
  String get capitalizeAllWordsFirstLetter {
    String lowerCasedString = toLowerCase();
    String stringWithoutExtraSpaces = lowerCasedString.trim();

    if (stringWithoutExtraSpaces.isEmpty) {
      return "";
    }
    if (stringWithoutExtraSpaces.length == 1) {
      return stringWithoutExtraSpaces.toUpperCase();
    }

    List<String> stringWordsList = stringWithoutExtraSpaces.split(" ");
    List<String> capitalizedWordsFirstLetter = stringWordsList.map((String word) {
      if (word.trim().isEmpty) {
        return "";
      }
      return word.trim();
    }).where((String word) => word != "").map((String word) {
      if (word.startsWith(RegExp(r'[\n\t\r]'))) {
        return word;
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    String finalResult = capitalizedWordsFirstLetter.join(" ");
    return finalResult;
  }

  bool matchesRegex(String pattern) => RegExp(pattern).hasMatch(this);

  /// Create a path with the given segments.
  String createPath([Iterable? segments]) {
    if (segments == null || segments.isEmpty) {
      return this;
    }

    Iterable<String> list = segments.map((dynamic e) => '/$e');
    return this + list.join();
  }

  /// Checks if all data have same value.
  bool get isOneAKind {
    if(isEmpty) {
      return false;
    } else {
      String first = this[0];
      int len = length;

      for (int i = 0; i < len; i++) {
        if (this[i] != first) {
          return false;
        }
      }

      return true;
    }
  }

  /// Replaces all occurrences of the given pattern with the specified replacement
  /// and returns the result as a String.
  String replaceAllWithOriginalCase(Pattern pattern, String replace) {
    return replaceAll(pattern, replace);
  }

  /// Replaces all occurrences of the given pattern with the specified replacement
  /// and returns the result in lowercase.
  String replaceAllToLowerCase(Pattern pattern, String replace) {
    return replaceAll(pattern, replace).toLowerCase();
  }

  /// Replaces all occurrences of the given pattern with the specified replacement
  /// and returns the result in uppercase.
  String replaceAllToUpperCase(Pattern pattern, String replace) {
    return replaceAll(pattern, replace).toUpperCase();
  }

  /// Replaces the first occurrence of the given pattern with the specified replacement
  /// and returns the result as a String.
  String replaceWithOriginalCase(Pattern pattern, String replace) {
    return replaceFirst(pattern, replace);
  }

  /// Replaces the first occurrence of the given pattern with the specified replacement
  /// and returns the result in lowercase.
  String replaceToLowerCase(Pattern pattern, String replace) {
    return replaceFirst(pattern, replace).toLowerCase();
  }

  /// Replaces the first occurrence of the given pattern with the specified replacement
  /// and returns the result in uppercase.
  String replaceToUpperCase(Pattern pattern, String replace) {
    return replaceFirst(pattern, replace).toUpperCase();
  }

  /// Determines the MIME type of the file based on its extension.
  /// 
  /// This extension method analyzes the file extension of the given string 
  /// and returns the corresponding MIME type. 
  /// 
  /// **Returns:**
  /// 
  /// The MIME type of the file. 
  /// 
  /// Returns 'application/octet-stream' if the extension is not recognized.
  String get mimeType {
    final extension = split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm': 
        return 'video/webm'; 
      case '3gp': 
        return 'video/3gpp'; 
      case 'wmv': 
        return 'video/x-ms-wmv'; 
      case 'flv': 
        return 'video/x-flv'; 
      case 'mpeg': 
        return 'video/mpeg'; 
      case 'mpg': 
        return 'video/mpeg'; 
      case 'm4v': 
        return 'video/mp4'; 
      case 'ts': 
        return 'video/mp2t'; 
      case '3g2': 
        return 'video/3gpp2'; 
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
        return 'audio/m4a';
      case 'amr':
        return 'audio/amr';
      default:
        return 'application/octet-stream';
    }
  }

  /// Checks if the string represents a local file path.
  bool get isLocalFile => startsWith('/');

  /// Checks if the string represents a base64 encoded image.
  bool get isMemoryImage => startsWith('data:image');

  /// Extracts the file name from a path, URL, or asset.
  ///
  /// If [withMimeType] is `true`, it returns the name with the MIME type.
  /// If [appendMimeType] is `true`, it will return the name with .mimeType
  String getFileName({bool withMimeType = false, bool appendMimeType = true}) {
    // Extract file name from path or URL
    String fileName = split('/').last.split('\\').last;

    if (withMimeType) {
      // Determine MIME type
      String mimeType = fileName.mimeType;
      return appendMimeType ? "$fileName.$mimeType" : "$fileName ($mimeType)";
    }

    return fileName;
  }

  /// Returns the first [count] characters of the string.
  /// If [count] exceeds the string length, it returns the whole string.
  /// If the string is empty or null, it returns an empty string.
  String first([int count = 1]) {
    if (isEmpty || count.isLtOrEt(0)) return '';

    return length.isLtOrEt(count) ? this : substring(0, count);
  }

  /// Converts the string to a [DateTime] object. Returns null if parsing fails.
  DateTime? toDate() => DateTime.tryParse(this);

  /// Converts the string to a [double]. Returns NaN if parsing fails.
  double toFloat() => double.tryParse(this) ?? double.nan;

  /// Converts the string to a [double]. Returns NaN if parsing fails.
  double toDouble() => toFloat();

  /// Converts the string to a [num]. [radix] is the base for integer parsing.
  num toInt({int radix = 10}) => int.tryParse(this, radix: radix) ?? double.tryParse(this)?.toInt() ?? double.nan;

  /// Converts the string to a [bool]. [strict] mode only allows '1' and 'true' to return true.
  bool toBool([bool strict = false]) => strict == true ? this == '1' || this == 'true' : this != '0' && this != 'false' && isNotEmpty;

  /// Trims characters from the left side of the string.
  String leftTrim([String? chars]) => (chars != null)
      ? replaceAll(RegExp('^[$chars]+'), '')
      : replaceAll(RegExp(r'^\s+'), '');

  /// Trims characters from the right side of the string.
  String rightTrim([String? chars]) => (chars != null)
      ? replaceAll(RegExp('[$chars]+\$'), '')
      : replaceAll(RegExp(r'\s+$'), '');

  /// Removes characters that do not appear in the whitelist.
  String whitelist(String chars) => replaceAll(RegExp('[^$chars]+'), '');

  /// Removes characters that appear in the blacklist.
  String blacklist(String chars) => replaceAll(RegExp('[$chars]+'), '');

  /// Removes characters with a numerical value less than 32 and 127.
  /// If [keepNewLines] is true, newline characters are preserved (\n and \r, hex 0xA and 0xD).
  String stripLow([bool keepNewLines = false]) {
    final chars = keepNewLines == true
        ? '\x00-\x09\x0B\x0C\x0E-\x1F\x7F'
        : '\x00-\x1F\x7F';
    return blacklist(chars);
  }

  /// Replaces HTML entities <, >, &, ', and " with their respective HTML entities.
  String escape() => replaceAll(RegExp(r'&'), '&amp;')
      .replaceAll(RegExp(r'"'), '&quot;')
      .replaceAll(RegExp(r"'"), '&#x27;')
      .replaceAll(RegExp(r'<'), '&lt;')
      .replaceAll(RegExp(r'>'), '&gt;');

  /// Canonicalizes an email address. Options include lowercase and specific provider rules.
  String normalizeEmail([Map<String, Object>? options]) {
    Map<String, Object> defaultNormalizeEmailOptions = {'lowercase': true};
    options = options?.merge(defaultNormalizeEmailOptions) ?? defaultNormalizeEmailOptions;
    if (isEmail == false) {
      return '';
    }

    final parts = split('@');
    parts[1] = parts[1].toLowerCase();

    if (options['lowercase'] == true) {
      parts[0] = parts[0].toLowerCase();
    }

    if (parts[1] == 'gmail.com' || parts[1] == 'googlemail.com') {
      if (options['lowercase'] == false) {
        parts[0] = parts[0].toLowerCase();
      }
      parts[0] = parts[0].replaceAll('.', '').split('+')[0];
      parts[1] = 'gmail.com';
    }
    return parts.join('@');
  }

  /// Formats the string with the given arguments.
  /// 
  /// Supports `%s`, `%d`, `%f`, and `%n` placeholders using either:
  /// - Positional arguments (e.g. `formatted("Alice", 42)`)
  /// - A single list of arguments (e.g. `formatted(["Alice", 42])`)
  ///
  /// Example:
  /// ```dart
  /// 'Hello, %s. You have %d new messages.%n'.formatted('Alice', 5);
  /// ```
  /// Outputs:
  /// ```
  /// Hello, Alice. You have 5 new messages.
  /// ```
  ///
  /// Supports usage like:
  /// ```dart
  /// '%s %d %f %n'.formatted('hi', 2, 3.14);
  /// '%s %s'.formatted(['a', 'b']);
  /// ```
  String formatted([Object? arg1, Object? arg2, Object? arg3, Object? arg4, Object? arg5, Object? arg6, Object? arg7, Object? arg8]) {
    final args = _normalizeArgs([arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8]);
    final parts = split(RegExp(r'(%[sdfn])'));
    final buffer = StringBuffer();
    var argIndex = 0;

    for (var part in parts) {
      if (_isPlaceholder(part)) {
        if (argIndex < args.length) {
          buffer.write(_formatPlaceholder(part, args[argIndex]));
          argIndex++;
        } else {
          buffer.write(part); // Leave placeholder as-is
        }
      } else {
        buffer.write(part);
      }
    }

    return buffer.toString();
  }

  /// Normalizes args: if the first arg is a List and others are null, treat it as list input.
  List<Object?> _normalizeArgs(List<Object?> args) {
    final trimmed = args.where((e) => e != null).toList();
    if (trimmed.length == 1 && trimmed.first is List) {
      return List<Object?>.from(trimmed.first as List);
    }
    return trimmed;
  }

  bool _isPlaceholder(String s) => s == '%s' || s == '%d' || s == '%f' || s == '%n';

  String _formatPlaceholder(String placeholder, Object? arg) {
    switch (placeholder) {
      case '%s':
        return arg.toString();
      case '%d':
        return (arg is num) ? arg.toInt().toString() : arg.toString();
      case '%f':
        return (arg is num) ? arg.toDouble().toStringAsFixed(2) : arg.toString();
      case '%n':
        return '\n';
      default:
        return placeholder;
    }
  }
}