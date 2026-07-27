import 'dart:collection';

import '../../definitions.dart';

/// {@template header_value}
/// Parses and represents an HTTP header value with optional parameters.
///
/// This class handles the parsing of header values like
/// `'text/html; charset=utf-8'` into a structured format with the main
/// value and associated parameters.
///
/// ## Features
/// - Full HTTP header value parsing with parameters
/// - Support for quoted parameter values
/// - Backslash preservation option
/// - Unmodifiable parameter map
/// - Case-insensitive parameter names
///
/// ## Example
/// ```dart
/// final headerValue = HeaderValue.parse('text/html; charset=utf-8');
/// print(headerValue.value); // 'text/html'
/// print(headerValue.parameters); // {'charset': 'utf-8'}
/// ```
///
/// ## Edge cases
/// - Quoted values with escaped characters are handled correctly.
/// - Backslash preservation mode keeps backslashes before non-quote characters.
/// - Charset parameters are automatically lowercased.
/// {@endtemplate}
class HeaderValue {
  /// The raw value of the header.
  String _value;

  /// The parameters of the header value.
  Map<String, String?>? _parameters;

  /// The unmodifiable parameters of the header value.
  Map<String, String?>? _unmodifiableParameters;

  /// Creates a [HeaderValue] with the given value and parameters.
  ///
  /// ## Parameters
  /// - [value]: The header value (default: empty string).
  /// - [parameters]: Optional map of parameters.
  ///
  /// ## Example
  /// ```dart
  /// final hv = HeaderValue('text/html', {'charset': 'utf-8'});
  /// ```
  /// 
  /// {@macro header_value}
  HeaderValue([this._value = '', Headers? parameters]) {
    if (parameters != null) {
      _parameters = HashMap<String, String>.from(parameters);
    }
  }

  /// Parse a header value string into a [HeaderValue].
  ///
  /// This method parses header values like `'text/html; charset=utf-8'`
  /// into structured components.
  ///
  /// ## Parameters
  /// - [value]: The header value string to parse.
  /// - [parameterSeparator]: The separator between parameters (default: `;`).
  /// - [valueSeparator]: Optional separator between values.
  /// - [preserveBackslash]: When `true`, backslashes are preserved in quoted values.
  ///
  /// ## Returns
  /// A parsed [HeaderValue] instance.
  ///
  /// ## Throws
  /// [StateError] if the header value format is invalid.
  ///
  /// ## Example
  /// ```dart
  /// final hv = HeaderValue.parse('text/html; charset=utf-8');
  /// print(hv.value); // 'text/html'
  /// print(hv.parameters); // {'charset': 'utf-8'}
  /// ```
  /// 
  /// {@macro header_value}
  static HeaderValue parse(String value, {
    String parameterSeparator = ';',
    String? valueSeparator,
    bool preserveBackslash = false,
  }) {
    var result = HeaderValue();
    result._parse(value, parameterSeparator, valueSeparator, preserveBackslash);
    return result;
  }

  /// The main value of the header (without parameters).
  ///
  /// ## Example
  /// ```dart
  /// final hv = HeaderValue.parse('text/html; charset=utf-8');
  /// print(hv.value); // 'text/html'
  /// ```
  String get value => _value;

  /// Ensures the parameters map is initialized.
  void _ensureParameters() {
    _parameters ??= HashMap<String, String>();
  }

  /// The parameters of the header value.
  ///
  /// Returns an unmodifiable view of the parameters map.
  /// Parameter names are lowercase.
  ///
  /// ## Example
  /// ```dart
  /// final hv = HeaderValue.parse('text/html; charset=utf-8');
  /// print(hv.parameters); // {'charset': 'utf-8'}
  /// ```
  Map<String, String?>? get parameters {
    _ensureParameters();
    _unmodifiableParameters ??= UnmodifiableMapView(_parameters!);
    return _unmodifiableParameters;
  }

  /// Convert this [HeaderValue] to a string.
  ///
  /// The format is: `value; param1=value1; param2=value2`
  ///
  /// ## Returns
  /// The string representation of the header value.
  ///
  /// ## Example
  /// ```dart
  /// final hv = HeaderValue.parse('text/html; charset=utf-8');
  /// print(hv.toString()); // 'text/html; charset=utf-8'
  /// ```
  @override
  String toString() {
    var stringBuffer = StringBuffer();
    stringBuffer.write(_value);
    if (parameters != null && parameters!.isNotEmpty) {
      _parameters!.forEach((name, value) {
        stringBuffer
          ..write('; ')
          ..write(name)
          ..write('=')
          ..write(value);
      });
    }
    return stringBuffer.toString();
  }

  /// Parse the header value string.
  ///
  /// ## Parameters
  /// - [value]: The header value string to parse.
  /// - [parameterSeparator]: The separator between parameters.
  /// - [valueSeparator]: Optional separator between values.
  /// - [preserveBackslash]: When `true`, backslashes are preserved in quoted values.
  ///
  /// ## Throws
  /// [StateError] if the header value format is invalid.
  void _parse(String value, String parameterSeparator, String? valueSeparator, bool preserveBackslash) {
    var index = 0;

    bool done() => index == value.length;

    void bump() {
      while (!done()) {
        if (value[index] != ' ' && value[index] != '\t') return;
        index++;
      }
    }

    String parseValue() {
      var start = index;
      while (!done()) {
        if (value[index] == ' ' ||
            value[index] == '\t' ||
            value[index] == valueSeparator ||
            value[index] == parameterSeparator) {
          break;
        }
        index++;
      }
      return value.substring(start, index);
    }

    void expect(String expected) {
      if (done() || value[index] != expected) {
        throw StateError('Failed to parse header value');
      }
      index++;
    }

    void maybeExpect(String expected) {
      if (value[index] == expected) index++;
    }

    void parseParameters() {
      var parameters = HashMap<String, String?>();
      _parameters = UnmodifiableMapView(parameters);

      String parseParameterName() {
        var start = index;
        while (!done()) {
          if (value[index] == ' ' ||
              value[index] == '\t' ||
              value[index] == '=' ||
              value[index] == parameterSeparator ||
              value[index] == valueSeparator) {
            break;
          }
          index++;
        }
        return value.substring(start, index).toLowerCase();
      }

      String? parseParameterValue() {
        if (!done() && value[index] == '"') {
          var stringBuffer = StringBuffer();
          index++;
          while (!done()) {
            if (value[index] == '\\') {
              if (index + 1 == value.length) {
                throw StateError('Failed to parse header value');
              }
              if (preserveBackslash && value[index + 1] != '"') {
                stringBuffer.write(value[index]);
              }
              index++;
            } else if (value[index] == '"') {
              index++;
              break;
            }
            stringBuffer.write(value[index]);
            index++;
          }
          return stringBuffer.toString();
        } else {
          var val = parseValue();
          return val == '' ? null : val;
        }
      }

      while (!done()) {
        bump();
        if (done()) return;
        var name = parseParameterName();
        bump();
        if (done()) {
          parameters[name] = null;
          return;
        }
        maybeExpect('=');
        bump();
        if (done()) {
          parameters[name] = null;
          return;
        }
        var valueParameter = parseParameterValue();
        if (name == 'charset' && valueParameter != null) {
          valueParameter = valueParameter.toLowerCase();
        }
        parameters[name] = valueParameter;
        bump();
        if (done()) return;
        if (value[index] == valueSeparator) return;
        expect(parameterSeparator);
      }
    }

    bump();
    _value = parseValue();
    bump();
    if (done()) return;
    maybeExpect(parameterSeparator);
    parseParameters();
  }
}