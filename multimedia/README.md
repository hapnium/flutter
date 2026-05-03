# multimedia

**High-level Flutter UI** for **camera capture** and **gallery browsing**, built on **`camera`**, **`file_picker`**, and the internal **`gallery`** package. Includes configuration models, album/grid/list views, and a **video-style progress slider**.

**Import:** `package:multimedia/multimedia.dart`  
This library **re-exports** `package:gallery/gallery.dart` so consumers can use **`Gallery`**, **`Album`**, **`Medium`**, and providers from one import if desired.

---

## Modules

### Configuration models (`src/models/`)

- **`MultimediaConfigurations`** — top-level entry for wiring camera + gallery settings.
- **`MultimediaGalleryConfiguration`**, **`MultimediaGalleryAlbumConfiguration`**, **`GalleryViewConfiguration`**, **`AlbumViewConfiguration`** — layout, filtering, and album behavior.
- **`MultimediaCameraConfiguration`** — resolution and camera behavior.
- **`MultimediaLayoutConfiguration`** — grid spacing, sizing, cross-axis count, etc.
- **`SelectedMedia`** — represents user-selected items.

### Widgets

- **`MultimediaGallery`** — full gallery experience with **`MultimediaGalleryState`**: grid/list toggles, album navigation, empty states (**`NotItemFound`** / `not_item_found.dart`). Typically driven by **`MultimediaConfigurations`** / **`MultimediaGalleryConfiguration`**.
- **`MultimediaGalleryAlbum`** — album-scoped UI with **`MultimediaGalleryAlbumState`**, **`AlbumGridView`**, **`AlbumListView`**, **`MediumImage`**, **`AlbumInformation`**; configured via **`MultimediaGalleryAlbumConfiguration`** / **`AlbumViewConfiguration`**.
- **`MultimediaCamera`** + **`MultimediaCameraState`** — live camera preview, **`RestorableCameraController`** for restoration flows; tune with **`MultimediaCameraConfiguration`**.
- **`GalleryListView`**, **`GalleryGridView`** — reusable media list/grid pieces under **`multimedia_gallery/widgets/`**.

### Progress slider

**`ProgressSlider`** (`progress_slider/`) — timing labels, bar cap shape, drag details; used for trim/preview-style UIs.

### Utilities

**`MultimediaUtils`** — permissions, formatting, and shared helpers.

### File reading

**`FileReader`** abstraction with **IO** and **stub** implementations for cross-platform file access patterns.

---

## Dependencies

- **`gallery`** (path) — native album/media access.
- Dev: **`tracing`**, **`smart`** for development/testing support in this repo.

---

## Installation (private monorepo)

```yaml
dependencies:
  multimedia:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: multimedia
```

Ensure your app declares any **camera** / **storage** permissions required by `camera`, `file_picker`, and `gallery`.

---

## License

See [LICENSE](LICENSE) in this package directory.
