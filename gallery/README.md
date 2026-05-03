# gallery

**Flutter plugin** for reading the device **photo/video library** on **Android** and **iOS**. Uses a **`MethodChannel`** named **`smart_hap_gallery`** to talk to native code (`GalleryPlugin`).

**Import:** `package:gallery/gallery.dart`.

This package is **not** the same as the public `gallery` on pub.dev; it is maintained inside the Hapnium monorepo (`publish_to: none`).

---

## Platform setup

### iOS — `Info.plist`

Add photo library usage:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Describe why you need library access</string>
```

### Android — `AndroidManifest.xml`

Typical permissions (adjust for target SDK / policy):

```xml
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

---

## API overview

### `Gallery` — static methods (`src/gallery.dart`)

Channel: **`smart_hap_gallery`**.

| Method | Returns | Notes |
|--------|---------|--------|
| **`listAlbums({mediumType, newest, hideIfEmpty})`** | `Future<List<Album>>` | **`hideIfEmpty`**: iOS behavior for empty albums. |
| **`getMedium({mediumId, mediumType})`** | `Future<Medium>` | Metadata only. |
| **`getThumbnail({mediumId, mediumType, width, height, highQuality})`** | `Future<List<int>>` | Raw bytes; throws if native returns null. |
| **`getAlbumThumbnail({albumId, mediumType, newest, width, height, highQuality})`** | `Future<List<int>>` | Album cover bytes. |
| **`getFile({mediumId, mediumType, mimeType})`** | `Future<File>` | Local path from native. |
| **`deleteMedium({mediumId, mediumType})`** | `Future<void>` | Irreversible. |
| **`cleanCache()`** | `Future<void>` | Clears native cache (fire-and-forget invoke). |

**`Gallery._listMedia`** is private; use **`album.listMedia(...)`** on **`Album`**.

### `Album` / `Medium` / `MediaPage`

- **`Album.listMedia`** — paginated **`MediaPage`** (`skip`, `take`, **`lightWeight`**).
- **`MediaPage.nextPage`** — fetch next chunk when **`isLast`** is false.
- **`Medium.getFile`**, **`getThumbnail`** — instance methods wrapping `Gallery` statics.

### Image providers (Flutter)

- **`ThumbnailProvider`**, **`AlbumThumbnailProvider`**, **`PhotoProvider`** — `ImageProvider` subclasses for **`Image`**, **`FadeInImage`**, etc.

---

## Usage examples

### List albums and first page of media

```dart
import 'package:gallery/gallery.dart';

Future<void> load() async {
  final albums = await Gallery.listAlbums(mediumType: MediumType.image);
  if (albums.isEmpty) return;

  final page = await albums.first.listMedia(take: 24);
  for (final m in page.items) {
    // m.id, medium type, dates, etc.
  }

  if (!page.isLast) {
    final next = await page.nextPage();
    // ...
  }
}
```

### Thumbnail in a widget

```dart
Image(
  image: ThumbnailProvider(
    mediumId: id,
    mediumType: MediumType.image,
    width: 128,
    height: 128,
    highQuality: true,
  ),
  fit: BoxFit.cover,
)
```

---

## Example app

See **`example/`** (`gallery_example`) for a runnable demo.

---

## Installation (private monorepo)

```yaml
dependencies:
  gallery:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: gallery
```

---

## License

See [LICENSE](LICENSE) in this package directory.
