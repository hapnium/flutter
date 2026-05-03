# link_preview

**Fetch, cache, and render URL previews** in Flutter: HTTP fetch, HTML/OG/Twitter/YouTube/JSON-LD-style parsing, **`LinkPreviewData`** models, **`CacheManager`**, and widgets for **linkified** text.

**Import:** `package:link_preview/link_preview.dart`.

---

## Entry points

### `LinkPreviewInterface` / `LinkPreview` singleton

**`LinkPreview`** is a **`LinkPreviewInterface`** instance (default impl **`_LinkPreviewImpl`**).

**`Future<LinkPreviewData?> get(String link, {proxy, cacheDuration, requestTimeout, userAgent})`**

1. Runs **v1** pipeline (`runV1` / `core_v1.dart`).
2. If `null` and **`LinkPreview.isValidLink(link)`**, normalizes `www.` and runs **v2** (`core_v2.dart` + parsers).
3. **`proxy`**: optional CORS proxy prefix (Flutter Web).
4. **`cacheDuration`**: TTL for in-memory cache.
5. **`requestTimeout`**: applies to v1 HTTP fetch.
6. **`userAgent`**: override request user-agent.

Helper **`LinkPreview.isValidLink`** — URL validation used before v2.

**Usage:**

```dart
final data = await LinkPreview.get(
  'https://example.com',
  proxy: 'https://your-cors-proxy/', // optional; useful on Web
  cacheDuration: const Duration(minutes: 5),
  requestTimeout: const Duration(seconds: 5),
  userAgent: 'MyBot/1.0',
);
```

**Algorithm:** tries **v1** (`runV1`) first; if that yields no result and the string is a valid link, falls back to **v2** with richer parsing (`core_v2.dart` and `v2/parsers/*`).

### Widgets and extensions

- **`LinkPreviewBuilder`** (see `src/ui/link_preview_builder.dart`) — compose preview cards.
- **`linkify.dart`** — linkify text widget; package re-exports selected **`linkify`** types (`LinkifyOptions`, `LinkifyElement`, …).
- **Extensions:** `cache_extension`, `url_extension`, `ui_extension`, `linkifier_extension`, `url_launcher_extension` — ergonomic chaining on strings, URIs, and widgets.

### Caching

**`CacheManager`** (`cache_manager.dart`, `cache.dart`) — pluggable cache for preview metadata; extensions add cache-aware helpers.

### Models

- **`LinkPreviewData`** — title, description, image(s), site name, etc.; flags like **`hasAllMetadata`** / **`hasAnyData`** (see model).
- **`LinkPreviewImage`** — image URL and dimensions for cards.

---

## Dependencies

- **`html`**, **`http`**, **`xml`**, **`linkify`**, **`url_launcher`**, **`meta`**, **`tracing`**.

---

## Installation (private monorepo)

```yaml
dependencies:
  link_preview:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: link_preview
```

---

## License

See [LICENSE](LICENSE) in this package directory.
