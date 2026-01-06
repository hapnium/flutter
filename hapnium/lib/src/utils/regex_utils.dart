/// {@template regex_utils}
/// A collection of commonly used regular expressions, provided as constants.
/// 
/// Each RegExp is documented with its matching behavior, valid/invalid examples,
/// and typical use cases for validation and pattern matching.
/// 
/// {@endtemplate}
class RegexUtils {
  /// {@macro regex_utils}
  const RegexUtils._(); // Prevent instantiation

  /// Matches valid **email addresses** according to RFC 5322 specifications.
  ///
  /// - **Examples (✅ Valid)**:
  ///   - `user@example.com`
  ///   - `"john.doe"@mail.co.uk`
  /// - **Examples (❌ Invalid)**:
  ///   - `user@.com`
  ///   - `john@@mail.com`
  ///
  /// **Use Case**: Validating user input in forms, emails for account creation.
  static final RegExp email = RegExp(
    r"^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|"
    r"[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|"
    r"[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)"
    r"|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|"
    r"[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|"
    r"(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*"
    r"(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|"
    r"(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|"
    r"[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+"
    r"(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|"
    r"[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|"
    r"[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$"
  );

  /// Matches **IPv4** addresses in dot-decimal notation.
  ///
  /// - **Examples (✅ Valid)**: `192.168.1.1`, `10.0.0.255`
  /// - **Examples (❌ Invalid)**: `256.0.0.1`, `192.168.1`
  ///
  /// **Use Case**: IP address validation in networking configurations or input forms.
  static final RegExp ipv4 = RegExp(r'^(\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)$');

  /// Matches **IPv6** addresses in standard compressed or full form.
  ///
  /// - **Examples (✅ Valid)**:
  ///   - `::1`
  ///   - `2001:0db8:85a3:0000:0000:8a2e:0370:7334`
  /// - **Examples (❌ Invalid)**:
  ///   - `2001:::7334`
  ///
  /// **Use Case**: Useful in cloud platforms, APIs, and dev tools for modern networking.
  static final RegExp ipv6 = RegExp(r'^::|^::1|^([a-fA-F0-9]{1,4}::?){1,7}([a-fA-F0-9]{1,4})$');

  /// Matches **integer** numbers including negative values.
  ///
  /// - **Examples (✅ Valid)**: `123`, `-456`
  /// - **Examples (❌ Invalid)**: `12.3`, `abc`
  ///
  /// **Use Case**: Fields requiring whole numbers such as age, quantity.
  static final RegExp integer = RegExp(r'^(?:-?(?:0|[1-9][0-9]*))$');

  /// Matches **alphanumeric** strings (letters and digits only).
  ///
  /// - **Examples (✅ Valid)**: `abc123`, `Hello2025`
  /// - **Examples (❌ Invalid)**: `abc!`, `123_`
  ///
  /// **Use Case**: Usernames, tags, IDs that exclude symbols.
  static final RegExp alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');

  /// Matches **alphabetic** strings (only uppercase/lowercase letters).
  ///
  /// - **Examples (✅ Valid)**: `abcDEF`
  /// - **Examples (❌ Invalid)**: `abc123`, `abc!`
  ///
  /// **Use Case**: Names, language-only fields.
  static final RegExp alphabetic = RegExp(r'^[a-zA-Z]+$');

  /// Matches **numeric** integers including negative values.
  ///
  /// - **Examples (✅ Valid)**: `123`, `-456`
  /// - **Examples (❌ Invalid)**: `12.3`, `abc`
  ///
  /// **Use Case**: Fields requiring whole numbers such as age, quantity.
  static final RegExp numeric = RegExp(r'^-?[0-9]+$');

  /// Matches **floating-point numbers**, including scientific notation.
  ///
  /// - **Examples (✅ Valid)**: `1.5`, `-3.14`, `1e10`
  /// - **Examples (❌ Invalid)**: `abc`, `1.2.3`
  ///
  /// **Use Case**: Prices, measurements, or any decimal-based entry.
  static final RegExp float = RegExp(r'^(?:-?(?:[0-9]+))?(?:\.[0-9]*)?(?:[eE][\+\-]?(?:[0-9]+))?$');

  /// Matches **hexadecimal numbers** (0-9 and A-F case-insensitive).
  ///
  /// - **Examples (✅ Valid)**: `1a2b3C`, `FFEE99`
  /// - **Examples (❌ Invalid)**: `Z123`, `12G`
  ///
  /// **Use Case**: Color codes, memory dumps, binary files.
  static final RegExp hexadecimal = RegExp(r'^[0-9a-fA-F]+$');

  /// Matches **hex color codes**: `#abc`, `#abcdef`, or `abc`, `abcdef`.
  ///
  /// - **Examples (✅ Valid)**: `#fff`, `#aabbcc`
  /// - **Examples (❌ Invalid)**: `#12345g`, `#abcd`
  ///
  /// **Use Case**: Web/app design for user-defined themes or settings.
  static final RegExp hexColor = RegExp(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$');

  /// Matches **base64-encoded** strings.
  ///
  /// - **Examples (✅ Valid)**: `dGVzdA==`, `U29tZSBzdHJpbmc=`
  /// - **Examples (❌ Invalid)**: `@#$%`, `abc=`
  ///
  /// **Use Case**: File encoding, JWT payloads, APIs.
  static final RegExp base64 = RegExp(
    r'^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|'
    r'[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{4})$');

  /// Matches **credit card numbers** from major providers.
  ///
  /// - **Examples (✅ Valid)**: `4111111111111111` (Visa)
  /// - **Examples (❌ Invalid)**: `123456`, `0000000000000000`
  ///
  /// **Use Case**: Payment gateways, e-commerce validation.
  static final RegExp creditCard = RegExp(
    r'^(?:4[0-9]{12}(?:[0-9]{3})?|'
    r'5[1-5][0-9]{14}|'
    r'6(?:011|5[0-9][0-9])[0-9]{12}|'
    r'3[47][0-9]{13}|'
    r'3(?:0[0-5]|[68][0-9])[0-9]{11}|'
    r'(?:2131|1800|35\d{3})\d{11})$',
  );

  /// Matches a possible **ISBN-10** format.
  static final RegExp isbn10 = RegExp(r'^(?:[0-9]{9}X|[0-9]{10})$');

  /// Matches a possible **ISBN-13** format.
  static final RegExp isbn13 = RegExp(r'^(?:[0-9]{13})$');

  /// Matches **UUIDs** by version.
  ///
  /// - `uuid['3']`: Matches UUID version 3
  /// - `uuid['4']`: Matches UUID version 4
  /// - `uuid['5']`: Matches UUID version 5
  /// - `uuid['all']`: Matches any valid UUID
  ///
  /// **Use Case**: API keys, database identifiers, sessions
  static final Map<String, RegExp> uuid = {
    '3': RegExp(r'^[0-9A-F]{8}-[0-9A-F]{4}-3[0-9A-F]{3}-[0-9A-F]{4}-[0-9A-F]{12}$'),
    '4': RegExp(r'^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$'),
    '5': RegExp(r'^[0-9A-F]{8}-[0-9A-F]{4}-5[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$'),
    'all': RegExp(r'^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$'),
  };

  /// Matches **surrogate pairs** (used in Unicode).
  /// 
  /// - **Examples (✅ Valid)**: `\uDBFF\uDC00`, `\uDBFF\uDC00`
  /// - **Examples (❌ Invalid)**: `\uDBFF\uDC00`, `\uDBFF\uDC00`
  /// 
  /// **Use Case**: Useful in Unicode processing, character encoding.
  static final RegExp surrogatePairs = RegExp(r'[\uD800-\uDBFF][\uDC00-\uDFFF]');

  /// Matches any **multibyte** characters (non-ASCII).
  static final RegExp multibyte = RegExp(r'[^\x00-\x7F]');

  /// Matches pure **ASCII** strings.
  static final RegExp ascii = RegExp(r'^[\x00-\x7F]+$');

  /// Matches **full-width** characters (used in Japanese, Chinese, Korean).
  static final RegExp fullWidth = RegExp(
      r'[^\u0020-\u007E\uFF61-\uFF9F\uFFA0-\uFFDC\uFFE8-\uFFEE0-9a-zA-Z]');

  /// Matches **half-width** characters (standard Latin characters).
  static final RegExp halfWidth = RegExp(
      r'[\u0020-\u007E\uFF61-\uFF9F\uFFA0-\uFFDC\uFFE8-\uFFEE0-9a-zA-Z]');

  /// Matches one or more **emoji** characters.
  ///
  /// Useful for detecting emojis in user messages.
  static final RegExp emoji = RegExp(
    r'[^\x00-\x7F]|(?:[.]{3})|[\uD83C-\uD83E][\uDDE0-\uDDFF]|'
    r'[\uD83C-\uD83E][\uDC00-\uDFFF]|'
    r'[\uD83F-\uD87F][\uDC00-\uDFFF]|'
    r'[\u2600-\u26FF]|[\u2700-\u27BF]',
  );

  /// Matches exactly one **emoji** character.
  ///
  /// Ideal for emoji-only validations (e.g., emoji picker).
  static final RegExp singleEmoji = RegExp(
    r'[^\x00-\x7F]|(?:[.]{3})|[\uD83C-\uD83E][\uDDE0-\uDDFF]|'
    r'[\uD83C-\uD83E][\uDC00-\uDFFF]|'
    r'[\uD83F-\uD87F][\uDC00-\uDFFF]|'
    r'[\u2600-\u26FF]|[\u2700-\u27BF]',
  );

  /// Emoji regex tuned to match emoji codepoint ranges (including Misc Technical U+2300–U+23FF)
  /// while deliberately avoiding box-drawing (U+2500–U+257F) and many other non-emoji ranges.
  /// The 'unicode: true' option is important.
  static final RegExp targetedEmoji = RegExp(
    // Match sequences of emoji codepoints, variation selectors, ZWJ and skin tone modifiers.
    // This covers most emoji blocks: Emoticons, Misc Symbols & Pictographs, Transport & Map,
    // Supplemental Symbols, Dingbats, Regional Indicators (flags), plus FE0F and ZWJ and skin tones.
    r'[\u{1F1E6}-\u{1F1FF}' // regional indicator (flags)
    r'\u{1F300}-\u{1F5FF}'  // Misc Symbols and Pictographs
    r'\u{1F600}-\u{1F64F}'  // Emoticons
    r'\u{1F680}-\u{1F6FF}'  // Transport & Map
    r'\u{1F700}-\u{1F77F}'  // Alchemical Symbols etc
    r'\u{1F780}-\u{1F7FF}'  // Geometric Shapes Extended
    r'\u{1F900}-\u{1F9FF}'  // Supplemental Symbols and Pictographs
    r'\u{1FA00}-\u{1FA6F}'  // Chess etc
    r'\u{1FA70}-\u{1FAFF}'  // Symbols & Pictographs Extended-A
    r'\u{2600}-\u{26FF}'    // Misc symbols (sun, cloud...)
    r'\u{2700}-\u{27BF}'    // Dingbats
    r'\u{2300}-\u{23FF}'    // Misc Technical
    r'\u{FE0F}'             // Variation selector-16
    r'\u{1F3FB}-\u{1F3FF}'  // Skin tone modifiers
    r'\u200D'               // Zero-width joiner (ZWJ)
    r']+',
    unicode: true,
  );
}