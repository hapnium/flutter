# device

**Device identity**, **runtime detection**, and **integrity validation hooks** for Dart and Flutter. Uses **`device_info_plus`** and **`universal_io`**, and integrates with **`tracing`** for optional debug logging.

**Import:** `package:device/device.dart` (also `io.dart` / `universal.dart` where needed for conditional imports).

---

## Main pieces

### `Device` model

Structured fields (name, id, platform, OS version, IP, host, SDK int on Android, etc.) with **`Device.empty()`** and JSON helpers — used for telemetry or audit payloads.

### `DeviceValidator`

Result type for individual checks (e.g. jailbreak/root/emulator).

### `DeviceValidationManager` / `DeviceEngine`

Framework for **composing validations**: you subclass **`DeviceValidationFactory`** (see `device_validation_manager.dart`) and implement checks such as jailbreak, emulator, developer mode, mock location. The library provides **`checkRootedOrJailBroken`**-style helpers to normalize plugin results into **`DeviceValidator`**.

### `DeviceRuntime` (in `device.dart`)

**Explicit initialization** is required: call **`DeviceRuntime.initialize(RuntimePlatform.xxx, ...)`** once at startup.

**`initialize(platform, {debug, isWasm, ipAddressSupplier})`**

- **`platform`**: required **`RuntimePlatform`** (`web`, `android`, `ios`, `macos`, `windows`, `linux`, `unknown`). Use **`RuntimePlatform.fromOperatingSystem`**, **`fromCurrentPlatform`**, or set explicitly (recommended with **`kIsWeb`**).
- **`debug`**: when `true`, logs steps via **`tracing.console`**.
- **`isWasm`**: only meaningful on web; sets **`isWebWasm`**.
- **`ipAddressSupplier`**: optional **`Future<String> Function()`**; overrides default IP resolution (needed on web for public IP).

**After init — getters** (each calls **`_ensureInitialized()`**; throws **`StateError`** if **`initialize`** was not called):

| Getter | Meaning |
|--------|---------|
| **`isInitialized`** | Whether **`initialize`** ran. |
| **`platform`** | **`RuntimePlatform`** you passed in. |
| **`platformOS`** | Short label: `"Web"`, `"Android"`, … |
| **`isWebWasm`** | Your **`isWasm`** flag. |
| **`isWeb`**, **`isAndroid`**, **`isIOS`**, **`isMacOS`**, **`isWindows`**, **`isLinux`** | Booleans from **`platform`**. |
| **`isMobile`** | Android or iOS. |
| **`isDesktop`** | macOS, Windows, or Linux. |
| **`operatingSystem`** | Human-readable OS line (browser on web). |
| **`operatingSystemVersion`** | Version string (SDK int as string on Android, etc.). |
| **`deviceInfo`** | Summary (e.g. user agent on web). |
| **`ipAddress`** | Resolved or supplied IP; often `""` on web without supplier. |
| **`device`** | **`Device`** model for telemetry. |
| **`debug`** | Whether debug logging was enabled at init. |

Design goals (from implementation):

- **You choose the platform** so Web never accidentally calls mobile-only plugins.
- **Web:** default IP is empty unless **`ipAddressSupplier`** is set.
- **Native:** IP resolved via **`NetworkInterface.list`** when no custom supplier is set.

```dart
import 'package:device/device.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceRuntime.initialize(
    kIsWeb ? RuntimePlatform.web : RuntimePlatform.android,
    debug: kDebugMode,
    ipAddressSupplier: kIsWeb ? () async => fetchIpFromBackend() : null,
  );

  runApp(const MyApp());
}
```

---

## Dependencies

- **`tracing`** — `console` logging when `debug: true` on **`DeviceRuntime`**.
- **`hapnium`** — shared utilities used inside the package.

---

## Installation (private monorepo)

```yaml
dependencies:
  device:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: device
```

---

## License

See [LICENSE](LICENSE) in this package directory.
