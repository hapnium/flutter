import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  group('PhosphorIconData typedef', () {
    test('PhosphorIconData is IconData', () {
      const icon = PhosphorIconsRegular.acorn;
      expect(icon, isA<IconData>());
    });

    test('PhosphorIconsRegular icons are IconData', () {
      const icon = PhosphorIconsRegular.addressBook;
      expect(icon, isA<IconData>());
      expect(icon.codePoint, 0xe6f8);
      expect(icon.fontFamily, 'PhosphorRegular');
      expect(icon.fontPackage, 'phosphor_flutter');
      expect(icon.matchTextDirection, true);
    });

    test('PhosphorIconsFill icons are IconData', () {
      const icon = PhosphorIconsFill.airplane;
      expect(icon, isA<IconData>());
      expect(icon.codePoint, 0xe002);
      expect(icon.fontFamily, 'PhosphorFill');
    });

    test('PhosphorIconsBold icons are IconData', () {
      const icon = PhosphorIconsBold.check;
      expect(icon, isA<IconData>());
      expect(icon.fontFamily, 'PhosphorBold');
    });

    test('PhosphorIconsThin icons are IconData', () {
      const icon = PhosphorIconsThin.warning;
      expect(icon, isA<IconData>());
      expect(icon.fontFamily, 'PhosphorThin');
    });

    test('PhosphorIconsLight icons are IconData', () {
      const icon = PhosphorIconsLight.heart;
      expect(icon, isA<IconData>());
      expect(icon.fontFamily, 'PhosphorLight');
    });

    test('PhosphorIconsDuotone icons are IconData', () {
      const icon = PhosphorIconsDuotone.star;
      expect(icon, isA<IconData>());
      expect(icon.fontFamily, 'PhosphorDuotone');
    });
  });

  group('PhosphorIcons convenience accessor', () {
    test('returns correct style via enum', () {
      final regular = PhosphorIcons.acorn();
      final fill = PhosphorIcons.acorn(PhosphorIconsStyle.fill);
      final bold = PhosphorIcons.acorn(PhosphorIconsStyle.bold);
      final thin = PhosphorIcons.acorn(PhosphorIconsStyle.thin);
      final light = PhosphorIcons.acorn(PhosphorIconsStyle.light);
      final duotone = PhosphorIcons.acorn(PhosphorIconsStyle.duotone);

      expect(regular.fontFamily, 'PhosphorRegular');
      expect(fill.fontFamily, 'PhosphorFill');
      expect(bold.fontFamily, 'PhosphorBold');
      expect(thin.fontFamily, 'PhosphorThin');
      expect(light.fontFamily, 'PhosphorLight');
      expect(duotone.fontFamily, 'PhosphorDuotone');
    });
  });

  group('Icon widget compatibility', () {
    test('PhosphorIcons can be used with Icon widget', () {
      final icon = Icon(PhosphorIconsRegular.check);
      expect(icon.icon, isA<IconData>());
    });

    test('PhosphorIconsFill can be used with Icon widget', () {
      const icon = Icon(PhosphorIconsFill.house);
      expect(icon.icon, isA<IconData>());
    });

    test('PhosphorIconsDuotone can be used with Icon widget', () {
      const icon = Icon(PhosphorIconsDuotone.envelopeSimple);
      expect(icon.icon, isA<IconData>());
    });
  });

  group('PhosphorIcon widget', () {
    test('PhosphorIcon accepts IconData', () {
      const icon = PhosphorIcon(
        PhosphorIconsRegular.pencil,
        size: 24.0,
        color: Color(0xFF000000),
      );
      expect(icon.icon, PhosphorIconsRegular.pencil);
      expect(icon.size, 24.0);
    });
  });
}
