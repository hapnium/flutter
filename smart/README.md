# smart

**Flutter UI kit**, **themes**, **layouts**, **forms**, **pagination**, **state helpers**, and **app glue** for Hapnium mobile apps. Depends on **`hapnium`** and **`tracing`**, bundles **fonts** (League Spartan, Nunito, Glow) and a large **asset** set (see `pubspec.yaml`).

**Import:** `package:smart/smart.dart` — umbrella export (also `ui.dart`, `extensions.dart`, etc.).

---

## What `smart.dart` does

The main library re-exports:

- **`assets.dart`** — asset path helpers.
- **`extensions.dart`**, **`enums.dart`**, **`utilities.dart`**, **`exceptions.dart`**, **`styles.dart`**, **`responsive.dart`**, **`flutter.dart`**, **`ui.dart`**.
- **`package:hapnium/hapnium.dart`** in full.
- **`package:tracing/tracing.dart`** with **`console` hidden** (to avoid naming conflicts). Import `tracing` directly if you need `console`.

---

## UI surface (from `src/ui/export.dart`)

Representative modules:

- **Animations** — expandable, heartbeat, poll animator, swiper, open container, wave, timer, etc.
- **Avatars** — `SmartAvatar`, stacked avatars.
- **Buttons** — interactive / smart / sized buttons, dynamic button models, update log views.
- **Common** — dividers, line headers, spacing, biometrics icon, social connect tiles.
- **Dialogs** — modal bottom sheet (+ indicator), preference selector, share dialogs and configs.
- **Forms** — PIN, OTP, phone, country picker, password/smart/fake fields, field controllers and decoration configs.
- **Rating** — icon and bar ratings, indicators.
- **Loading** — loading + shimmer.
- **Poll** — `SmartPoll` and option metadata.
- **Layouts** — auth, consent, view layout, cookie consent, inactivity, permission consent (+ models).
- **Pageable** — `PageableController`, list/grid/page/**staggered** views, builders, listeners, `PageableSeparatorStrategy`, page models and status.

Also: **text** builder, **stepping** wizard, **smart comment thread** tree, **floating** config models, and more under `lib/src/ui/`.

---

## Core / architecture (non-UI)

Under `lib/src/core/`:

- **`SmartController`**, **`ListNotifier`**, state mixins, **`SmartView`**, **`SmartRoute`** / decoder, **DI** (`smart_di`), **`FlutterEngine`**, **`SmartManagement`**, animation registry, lifecycle mixins.

Use these when you want Hapnium conventions for controllers and screens alongside the widget set.

### `SmartController` (typical responsibilities)

Hold mutable UI or domain state, notify listeners, and integrate with **`SmartView`**. Pair with **`ListNotifier`** / mixins (**`SmartLifecycle`**, **`StateMixin`**, **`SmartFullLifeCycle`**, etc.) for consistent **`initState`** / dispose behavior. See **`smart_controller.dart`** and **`smart_view.dart`**.

### Routing

**`SmartRoute`**, **`SmartRouteDecoder`** — encode/deep-link style route data; use with your app navigator.

### Dependency injection

**`smart_di.dart`** — lightweight service location / injection patterns used across the package (open file for registration API).

### Responsive

**`responsive.dart`** exports **`ResponsiveConfig`**, screen size enums/extensions — breakpoint helpers for layout.

---

## Assets and fonts

`pubspec.yaml` declares many **`packages/smart/assets/...`** entries and three font families. Consuming apps must not duplicate asset paths unless they fork the package.

---

## Dependencies

- **`tracing`**, **`hapnium`**, **`collection`**, **`meta`**.

---

## Installation (private monorepo)

```yaml
dependencies:
  smart:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: smart
```

Ensure **Material** is available (`uses-material-design: true` is set in this package).

---

## License

See [LICENSE](LICENSE) in this package directory.
