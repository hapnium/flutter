# Development Log

This document captures the logic, scripts, and commands used to build and maintain this fork of `phosphor_flutter`.

---

## Why This Fork Exists

The original `phosphor_flutter: ^2.1.0` on pub.dev is stale (last updated ~2 years ago). Flutter 3.44.6 made `IconData` a `final class`, which broke the package's class hierarchy:

- `PhosphorIconData extends IconData` — **illegal** (final class)
- `PhosphorFlatIconData extends IconData` — **illegal**
- `PhosphorDuotoneIconData extends IconData` — **illegal**

No update was available on pub.dev, so we forked and patched.

---

## Step 1: Fork the Core Package

We cloned the canonical source (not the stale pub.dev version):

```bash
git clone --depth 1 https://github.com/phosphor-icons/core.git /tmp/phosphor-core
```

Then copied the Flutter package out:

```bash
cp -r /tmp/phosphor-core/packages/phosphor_flutter /Users/mac/Documents/Hapnium/Packages/flutter/phosphor_flutter
```

---

## Step 2: Fix `IconData` for Flutter 3.44.6

`IconData` is now `final class`, so it cannot be extended or implemented.

### The Fix

Replace all class definitions with typedefs in `lib/src/phosphor_icon_data.dart`:

```dart
// BEFORE:
class PhosphorIconData extends IconData { ... }
class PhosphorFlatIconData extends IconData { ... }
class PhosphorDuotoneIconData extends IconData { ... }

// AFTER:
typedef PhosphorIconData = IconData;
typedef PhosphorFlatIconData = IconData;
typedef PhosphorDuotoneIconData = IconData;
```

### Transforming Icon Files

Each auto-generated icon file (e.g. `phosphor_icons_regular.dart`) uses the old constructors. A Dart script was used to transform them all:

```dart
// /tmp/transform_phosphor.dart
import 'dart:io';

void main() {
  final srcDir = Directory('/Users/mac/Documents/Hapnium/Packages/flutter/phosphor_flutter/lib/src');
  
  for (final file in srcDir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    if (file.path.endsWith('phosphor_icon_data.dart')) continue;
    if (file.path.endsWith('phosphor_icons.dart')) continue;
    if (file.path.endsWith('phosphor_icon.dart')) continue;
    
    var content = file.readAsStringSync();
    
    // Replace class constructors with IconData constructors
    content = content.replaceAllMapped(
      RegExp(r'const (Phosphor(?:Flat|Duotone|Regular|Thin|Light|Bold|Fill)?IconData)\((0x[0-9a-fA-F]+),\s*\'([^\']+)\'\)'),
      (match) {
        final className = match.group(1)!;
        final codePoint = match.group(2)!;
        
        String style;
        if (className.contains('Regular')) style = 'Regular';
        else if (className.contains('Thin')) style = 'Thin';
        else if (className.contains('Light')) style = 'Light';
        else if (className.contains('Bold')) style = 'Bold';
        else if (className.contains('Fill')) style = 'Fill';
        else if (className.contains('Duotone')) style = 'Duotone';
        else if (className.contains('Flat')) style = 'Regular';
        else style = 'Regular';
        
        return 'const IconData($codePoint, fontFamily: \'Phosphor$style\', fontPackage: \'phosphor_flutter\', matchTextDirection: true)';
      },
    );
    
    // Replace old import with new import
    content = content.replaceAll(
      "import 'phosphor_icon_data.dart';",
      "import 'package:flutter/widgets.dart';",
    );
    
    file.writeAsStringSync(content);
  }
}
```

Run with:

```bash
dart /tmp/transform_phosphor.dart
```

---

## Step 3: Update SVG Documentation References

The original SVG comments pointed to GitHub URLs at `phosphor-icons/core`. We updated them to point to our own repo so they're:
1. Owned by us
2. Hoverable in IDEs (raw GitHub URLs render as images in doc tooltips)

### The Script

```dart
// /tmp/fix_doc_urls.dart
import 'dart:io';

void main() {
  final srcDir = Directory('/Users/mac/Documents/Hapnium/Packages/flutter/phosphor_flutter/lib/src');
  const baseUrl = 'https://raw.githubusercontent.com/Hapnium/flutter/main/phosphor_flutter/assets/icons';
  
  for (final file in srcDir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    if (file.path.endsWith('phosphor_icon_data.dart')) continue;
    if (file.path.endsWith('phosphor_icon.dart')) continue;
    if (file.path.endsWith('phosphor_icons.dart')) continue;
    
    var content = file.readAsStringSync();
    
    // Replace local SVG references with GitHub raw URLs
    content = content.replaceAllMapped(
      RegExp(r'!\[([^\]]+)\]\(assets/icons/(\w+)/([^\)]+)\)'),
      (match) {
        final style = match.group(2);
        final filename = match.group(3);
        return '![${match.group(1)}]($baseUrl/$style/$filename)';
      },
    );
    
    file.writeAsStringSync(content);
  }
}
```

Run with:

```bash
dart /tmp/fix_doc_urls.dart
```

---

## Step 4: Update `pubspec.yaml`

Key changes:

```yaml
name: phosphor_flutter
version: 2.1.1  # bumped from 2.1.0

environment:
  sdk: ">=3.11.0 <4.0.0"      # was >=2.17.0
  flutter: ">=3.44.0"          # was >=3.0.0

dependencies:
  flutter:
    sdk: flutter
  phosphor: ^2.1.1

flutter:
  fonts:
    - family: PhosphorRegular
      fonts:
        - asset: lib/fonts/Phosphor-Regular.ttf
    - family: PhosphorThin
      fonts:
        - asset: lib/fonts/Phosphor-Thin.ttf
    - family: PhosphorLight
      fonts:
        - asset: lib/fonts/Phosphor-Light.ttf
    - family: PhosphorBold
      fonts:
        - asset: lib/fonts/Phosphor-Bold.ttf
    - family: PhosphorFill
      fonts:
        - asset: lib/fonts/Phosphor-Fill.ttf
    - family: PhosphorDuotone
      fonts:
        - asset: lib/fonts/Phosphor-Duotone.ttf
  assets:
    - assets/icons/regular/
    - assets/icons/thin/
    - assets/icons/light/
    - assets/icons/bold/
    - assets/icons/fill/
    - assets/icons/duotone/
```

---

## Step 5: Simplify `PhosphorIcon` Widget

The original `phosphor_icon.dart` had duotone rendering logic that used the removed class hierarchy. Simplified to delegate to Flutter's built-in `Icon` widget:

```dart
class PhosphorIcon extends StatelessWidget {
  const PhosphorIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}
```

---

## Step 6: Commit and Push

```bash
cd /Users/mac/Documents/Hapnium/Packages/flutter
git add phosphor_flutter/
git commit -m "Fork phosphor_flutter: fix for Flutter 3.44.6, own SVGs"
git push origin main
```

---

## Step 7: Reference from App

In the consuming app's `pubspec.yaml`:

```yaml
dependencies:
  phosphor_flutter:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: phosphor_flutter
```

---

## Verification

```bash
# In phosphor_flutter/ — tests pass
flutter test  # 12/12 passing

# In app/ — no errors
flutter analyze lib/  # 0 errors
```

---

## Package Structure

```
phosphor_flutter/
├── assets/icons/          # 9,072 SVG icons (1,512 × 6 styles)
│   ├── regular/
│   ├── thin/
│   ├── light/
│   ├── bold/
│   ├── fill/
│   └── duotone/
├── lib/
│   ├── fonts/             # 6 TTF font files
│   ├── src/               # All Dart source
│   └── phosphor_flutter.dart
├── meta/                  # Screenshots and logo
├── example/               # Full example app
├── test/                  # 12 passing tests
├── pubspec.yaml           # Dart >=3.11.0, Flutter >=3.44.0
└── DEVELOPMENT.md         # This file
```
