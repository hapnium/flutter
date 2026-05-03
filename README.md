# Hapnium Flutter packages

Monorepo of Dart and Flutter libraries maintained by **Hapnium Inc.** for shared mobile (and partially web/desktop) functionality: core utilities, logging, networking, cryptography, device intelligence, local storage, notifications, media, and a large UI kit.

This directory is **not** the Flutter SDK. It is a **collection of packages**; there is **no root `pubspec.yaml`**. Each subfolder is an independent package. All packages use `publish_to: none` and are intended to be consumed via **path** or **git** dependencies (see [Consuming packages](#consuming-packages)).

---

## Repository layout

| Directory | Package name | SDK / runtime |
|-----------|--------------|---------------|
| `hapnium/` | `hapnium` | Dart `^3.7.0` (no Flutter SDK in `pubspec`) |
| `tracing/` | `tracing` | Dart `^3.0.0` |
| `zap/` | `zap` | Flutter + Dart `^3.0.0` |
| `secure/` | `secure` | Dart `^3.0.0` |
| `device/` | `device` | Dart `^3.0.0` |
| `sedat/` | `sedat` | Dart `^3.0.0` |
| `tappy/` | `tappy` | Flutter |
| `chime/` | `chime` | Flutter |
| `link_preview/` | `link_preview` | Flutter |
| `gallery/` | `gallery` | Flutter plugin (Android + iOS) |
| `multimedia/` | `multimedia` | Flutter |
| `smart/` | `smart` | Flutter |
| `gallery/example/` | `gallery_example` | Example app for `gallery` |

**Version numbers** live in each package’s `pubspec.yaml` (`version:` field).

---

## Architecture overview

Rough dependency flow (arrows mean “depends on”):

- **`tracing`** — used across the stack for structured logging; **no runtime package dependencies**.
- **`hapnium`** — pure Dart extensions, `Optional`, JSON/helpers, streams/collectors, statistics; depends only on `meta`. Consumed by **`smart`**, **`device`**, **`sedat`**, and (as a dev dependency) **`chime`**.
- **`gallery`** — native gallery access via platform channels; **`multimedia`** builds on it.
- **`zap`** — HTTP and sockets for apps; uses `web` for portable I/O; **`tracing`** is a **dev** dependency (tests/tooling), not required at runtime for library users.
- **`smart`** — umbrella UI and app utilities; depends on **`hapnium`** + **`tracing`**, re-exports both from `smart.dart` (with `tracing`’s `console` hidden to avoid name clashes).

**Notification stacks:** **`tappy`** and **`chime`** overlap in purpose (local + in-app notifications). **`tappy`** is oriented around `TappyApplication`, typed notification models (calls, trips, chat, etc.), and a documented public surface. **`chime`** exposes a **`Chime` registry** singleton, `ChimeApplication`, and pluggable controller / in-app / push handlers. Choose one per app unless you deliberately integrate both.

**CI note:** GitHub Actions release workflows (see below) include most packages but **do not** currently list **`chime`**. If you ship `chime` with the same tagging policy, consider adding it to the workflow matrix.

---

## Packages in detail

### `hapnium` — core Dart utilities

Foundation library for Hapnium Dart code:

- **`Optional<T>`** and **`HapniumException`**
- **Extensions** on primitives (`String`, `int`, `double`, `bool`, `num`), collections (`List`, `Map`, `Iterable`, `Set`), `DateTime`, `Duration`, `dynamic`, and generic **`T`**
- **Utilities:** `JsonUtils`, `InstanceUtils`, `RegexUtils`, helpers and typedefs
- **IO helpers:** `BaseStream` and typed stream specializations (`int`/`double`/generic)
- **Collectors** and **summary statistics** (`IntSummaryStatistics`, `DoubleSummaryStatistics`)

Entry: `package:hapnium/hapnium.dart`.

---

### `tracing` — structured logging

Logging with levels (`TRACE` … `FATAL`), pluggable **`TracingListener`**, **`LogPrinter`** implementations (simple, pretty, structured, hybrid, prefix, FMT, etc.), **`LogConfig`**, and a global **`console`** singleton (`Tracing` instance).

Other packages (e.g. **`device`**) import `package:tracing/tracing.dart` for `console` and diagnostics.

Entry: `package:tracing/tracing.dart`.

---

### `zap` — HTTP, sockets, Flux, Zync

Networking layer for Hapnium apps:

- **HTTP:** `ZapClient`, request/response types, redirects, multipart/form-data, GraphQL-oriented response types, status and header helpers, platform-specific IO/HTML/stub request paths, certificate loading, request **modifiers**, **`CancelToken`**
- **Sockets:** client abstraction with IO vs HTML implementations, status/type enums, **`SocketMessenger`**
- **Flux:** reactive stream-style client configuration
- **Zync:** real-time sync-style configuration and responses
- **Models:** `ApiResponse`, session responses, pagination (`ZapPage`), location payloads, **`ZapConfig`**, exceptions and **`ControllerAdvice`**

Entry: `package:zap/zap.dart`.

---

### `secure` — cryptography and secure messaging

Built on **PointyCastle**:

- **RSA and EC** key handling and **PEM** utilities
- **`SecureKey`** / **`SecureMessaging`** (including RSA and EC messaging implementations)
- Models for keys, messaging metadata, and responses; **`SecureException`**

Entry: `package:secure/secure.dart`.

---

### `device` — device model, runtime, and validation hooks

- **`Device`** and **`DeviceValidator`** models
- **`DeviceValidationManager`** / **`DeviceEngine`** for integrity checks (root/jailbreak, emulator, developer mode, mock location — via your **`DeviceValidationFactory`** implementations)
- **`DeviceRuntime`**: explicit **`RuntimePlatform`** initialization (important for **Web** vs native), structured device info via `device_info_plus`, optional **custom IP fetcher** (needed on Web for public IP), integration with **`tracing`** for debug logs

Also exports **`universal.dart`** / **`io.dart`** for conditional imports where applicable.

Entry: `package:device/device.dart`.

---

### `sedat` — Hive-backed secure local database

Repository pattern on **Hive CE**:

- **`AbstractSecureDatabaseConfigurer`**, **`Repository`**, **`BaseRepository`**, **`StreamableRepository`**, **`RepositoryService`**, mixins and configuration types
- **`SecureDatabaseException`**

Uses code generation in development (`hive_ce_generator`).

Entry: `package:sedat/sedat.dart`.

---

### `tappy` — notifications (feature-rich)

Wraps **flutter_local_notifications**, **fluttertoast**, **toastification**, **timezone**:

- **`TappyApplication`** root widget, **`Tappy`** controller, lifecycle and mixin APIs
- **Typed notification payloads** (call, trip, schedule, chat, transaction, nearby, blink, etc.), **`Notifier`**, remote and in-app config models
- Device and in-app notification builders and managers, platform engine, sounds and events

Entry: `package:tappy/tappy.dart`.

---

### `chime` — notifications (registry-centric)

Alternative/complementary stack:

- Global **`Chime`** registry with **`ChimeController`**, **`ChimeInAppNotification`**, **`ChimePushNotification`**
- **`ChimeApplication`**, configuration, events, notification manager, display helpers, sounds, streamable utilities
- Ships wrappers/re-exports for timezone and toast-related stacks under `lib/` (platform-specific entrypoints)

Entry: `package:chime/chime.dart`.

---

### `link_preview` — URL metadata and preview UI

- Fetch and parse previews (v1/v2 pipelines, HTML and site-specific parsers e.g. Open Graph, YouTube, Twitter, JSON-LD-style id parser)
- **`LinkPreviewData`** / **`LinkPreviewImage`**, **`CacheManager`**, extensions for URL, cache, UI, linkify, url_launcher
- Widgets: **`LinkPreview`**, linkify UI

Entry: `package:link_preview/link_preview.dart`.

---

### `gallery` — native gallery plugin

Flutter plugin (`com.hapnium.gallery` on Android, `GalleryPlugin` on iOS):

- List **albums** and **media** with pagination, **thumbnails**, delete and cache control
- **`MediumType`** for image vs video
- Image providers for photos, albums, thumbnails

Example app: `gallery/example/`.

Entry: `package:gallery/gallery.dart`.

---

### `multimedia` — camera + gallery UI

- **`MultimediaGallery`** and **`MultimediaCamera`** widgets, album/grid/list views, configurations for layout, gallery, album, and camera
- **`ProgressSlider`** and related enums for playback/trim-style UIs
- **`MultimediaUtils`**, **`SelectedMedia`**, file reader abstractions
- Depends on **`gallery`**; re-exports `package:gallery/gallery.dart`

Entry: `package:multimedia/multimedia.dart`.

---

### `smart` — UI kit, themes, routing, and app glue

Large Flutter layer (~230+ library files) including:

- **State:** `SmartController`, notifiers, DI (`smart_di`), lifecycle mixins, **`SmartView`** / builders, router types
- **UI:** avatars, buttons, dialogs (modal bottom sheet, preference selector, share), forms (PIN, OTP, phone, country picker, smart field), ratings, polls, loading/shimmer, text builder, stepping, comment thread widgets, many layouts (auth, consent, cookie, inactivity, permission), **pageable** list/grid/page/staggered views with controllers and builders
- **Cross-cutting:** animations, responsive config, theme factory and assets, country data, link utilities, extensions on `BuildContext`, colors, layouts, enums
- **Bundled assets and fonts** (declared in `pubspec.yaml`: images under `assets/`, **League Spartan**, **Nunito**, **Glow**)

`lib/smart.dart` re-exports **`hapnium`** and **`tracing`** (hiding `console` from the tracing export); prefer a single `import 'package:smart/smart.dart';` only when you want that umbrella behavior.

Entry: `package:smart/smart.dart`.

---

## CI and releases

Under `.github/workflows/`:

- **`check_release.yml`** (on pull requests to `main`): for each package in the matrix, if that folder changed, verifies that a Git tag named **`{package_dir}/{version}`** (from that package’s `pubspec.yaml`) does **not** already exist — enforcing version bumps for changed packages.
- **`publish_release.yml`** (on push to `main`): same matrix, creates the tag and a GitHub Release when the version is new.

**Matrix today:** `zap`, `tracing`, `secure`, `tappy`, `smart`, `gallery`, `hapnium`, `sedat`, `device`, `multimedia`, `link_preview`. **`chime` is not in the matrix.**

---

## Consuming packages

Because packages are `publish_to: none`, reference them from another repo with **path** (if this repo is vendored) or **git** with **`path`**:

```yaml
dependencies:
  smart:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: smart
  zap:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: zap
```

For local development, use relative paths:

```yaml
dependencies:
  smart:
    path: ../flutter/smart
```

Then run `flutter pub get` (or `dart pub get` for pure Dart packages) from your app/package root.

### Private GitHub access

If the repository is private, configure credentials (for example a **`~/.netrc`** entry for `github.com` with a personal access token with appropriate scopes). Restrict file permissions on `.netrc` (e.g. `chmod 600`).

---

## Prerequisites

- **Flutter** 3.x-compatible SDK (packages target Dart `^3.0.0` or higher; `hapnium` requires `^3.7.0`)
- **Dart** included with Flutter

---

## Contributing

1. Fork and branch from `main`.
2. Keep changes scoped to the package(s) you touch; bump **`version:`** in that package’s `pubspec.yaml` when you need a release (to satisfy tag checks).
3. Add or update tests where behavior changes (`hapnium`, `zap`, and others include `test/`).
4. Open a PR to `main`.

---

## License

Each package ships its own `LICENSE` file in its directory (for example `smart/LICENSE`, `zap/LICENSE`). Open the file for the package you use to confirm terms.

---

## Contact

- **Hapnium Inc.** — [developer@hapnium.com](mailto:developer@hapnium.com) · [www.hapnium.com](https://www.hapnium.com)
