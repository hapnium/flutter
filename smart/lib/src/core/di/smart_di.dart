import 'package:smart/responsive.dart';

class SmartDI {
  static final _instances = <Type, dynamic>{};
  static ResponsiveConfig _responsiveSingleton = ResponsiveConfig();

  static ResponsiveConfig get responsive => _responsiveSingleton;

  static void registerResponsive(ResponsiveConfig responsive) {
    _responsiveSingleton = responsive;
  }

  static T put<T>(T instance) {
    _instances[T] = instance;
    return instance;
  }

  static T find<T>() {
    final instance = _instances[T];
    if (instance == null) {
      throw Exception('Dependency of type $T not found.');
    }

    return instance as T;
  }

  static bool isRegistered<T>() => _instances.containsKey(T);

  static void delete<T>() {
    _instances.remove(T);
  }

  static void deleteInstance<T>(T key) {
    _instances.remove(key);
  }
}