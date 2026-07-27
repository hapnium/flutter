import 'package:chime/chime.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

void main() {
  group('ChimeInAppStyle', () {
    test('has 5 values', () {
      expect(ChimeInAppStyle.values.length, 5);
    });

    test('minimal maps to ToastificationStyle.minimal', () {
      expect(ChimeInAppStyle.minimal.toast, ToastificationStyle.minimal);
    });

    test('fillColored maps to ToastificationStyle.fillColored', () {
      expect(ChimeInAppStyle.fillColored.toast, ToastificationStyle.fillColored);
    });

    test('flatColored maps to ToastificationStyle.flatColored', () {
      expect(ChimeInAppStyle.flatColored.toast, ToastificationStyle.flatColored);
    });

    test('flat maps to ToastificationStyle.flat', () {
      expect(ChimeInAppStyle.flat.toast, ToastificationStyle.flat);
    });

    test('simple maps to ToastificationStyle.simple', () {
      expect(ChimeInAppStyle.simple.toast, ToastificationStyle.simple);
    });
  });

  group('ChimeInAppState', () {
    test('has 4 values', () {
      expect(ChimeInAppState.values.length, 4);
    });

    test('info has correct properties', () {
      expect(ChimeInAppState.info.type, ToastificationType.info);
      expect(ChimeInAppState.info.icon, Icons.info);
      expect(ChimeInAppState.info.color, Colors.blue);
    });

    test('warning has correct properties', () {
      expect(ChimeInAppState.warning.type, ToastificationType.warning);
      expect(ChimeInAppState.warning.icon, Icons.warning_amber_outlined);
      expect(ChimeInAppState.warning.color, Colors.yellow);
    });

    test('success has correct properties', () {
      expect(ChimeInAppState.success.type, ToastificationType.success);
      expect(ChimeInAppState.success.icon, Icons.check_circle);
      expect(ChimeInAppState.success.color, Colors.green);
    });

    test('error has correct properties', () {
      expect(ChimeInAppState.error.type, ToastificationType.error);
      expect(ChimeInAppState.error.icon, Icons.error);
      expect(ChimeInAppState.error.color, Colors.red);
    });

    test('each state has a unique type', () {
      final types = ChimeInAppState.values.map((s) => s.type).toSet();
      expect(types.length, 4);
    });

    test('each state has a unique icon', () {
      final icons = ChimeInAppState.values.map((s) => s.icon).toSet();
      expect(icons.length, 4);
    });

    test('each state has a unique color', () {
      final colors = ChimeInAppState.values.map((s) => s.color).toSet();
      expect(colors.length, 4);
    });
  });

  group('ChimePlatform', () {
    test('has 3 values', () {
      expect(ChimePlatform.values.length, 3);
    });

    test('contains ANDROID', () {
      expect(ChimePlatform.values, contains(ChimePlatform.ANDROID));
    });

    test('contains IOS', () {
      expect(ChimePlatform.values, contains(ChimePlatform.IOS));
    });

    test('contains WEB', () {
      expect(ChimePlatform.values, contains(ChimePlatform.WEB));
    });
  });
}