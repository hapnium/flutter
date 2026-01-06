import 'dart:convert';

import './typedefs.dart';
import '../extensions/others/t.dart';

/// {@template json_utils}
/// A generic codec class for encoding and decoding data using JSON.
///
/// This class provides methods for encoding data of type `T` into a JSON string
/// and decoding a JSON string back into an object of type `T`.
/// 
/// {@endtemplate}
class JsonUtils<T> {
  /// {@macro json_utils}
  JsonUtils._();
  static JsonUtils instance = JsonUtils._();

  /// {@macro json_utils}
  JsonUtils();

  final Map<Type, JsonUtilsDecoder<dynamic>> _adapters = {};

  /// Registers a type adapter for the specified type `T`.
  JsonUtils<T> registerAdapter(JsonUtilsDecoder<T> decoder) {
    _adapters[T] = decoder;

    return this;
  }

  /// Finds and applies the registered adapter for the given type `T`.
  T? _decodeWithAdapter(Map<String, dynamic> json) {
    JsonUtilsDecoder? adapter = _adapters[T] as JsonUtilsDecoder<T>?;
    if (adapter.isNotNull) {
      return adapter!(json);
    }

    return null;
  }

  /// Encodes the given data object into a JSON string.
  String encode(T data) => jsonEncode(data);

  /// Decodes the given JSON string into an object of type `T`.
  T decode(String data) {
    try {
      return jsonDecode(data) as T;
    } catch (_) {
      JsonMap value = JsonMap.from(jsonDecode(data));

      T? result = _decodeWithAdapter(value);
      if (result.isNotNull) {
        return result!;
      } else {
        return value as T;
      }
    }
  }
}