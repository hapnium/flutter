/// {@template multimedia_library}
/// # multimedia Library
///
/// A powerful and flexible Flutter library for handling multimedia selection,
/// gallery and camera integrations, and layout configurations.
///
/// ## Features
/// - Unified APIs for interacting with camera and gallery
/// - Rich UI components and layout customizations
/// - Media selection and preview support
/// - Configuration-driven design
///
/// ## Structure
/// - **Models**: Configuration models for customizing gallery, camera, and layouts
/// - **Utils**: Utility functions to support media operations
/// - **Widgets**: Core camera/gallery widgets and progress slider
///
/// {@endtemplate}
library;

/// {@template multimedia_typedefs_exports}
/// # Typedefs
/// Type definitions used across the multimedia library for cleaner, reusable function signatures.
/// {@endtemplate}
export 'src/typedefs.dart';

/// {@template multimedia_models_exports}
/// # Models
/// Configuration models and data structures for media operations.
///
/// - [album_view_configuration.dart]: Configuration for album views.
/// - [gallery_view_configuration.dart]: Layout and filter options for the media gallery.
/// - [selected_media.dart]: Represents selected media file(s).
/// - [multimedia_configurations.dart]: Core configuration entry point.
/// - [multimedia_layout_configuration.dart]: Controls grid, spacing, and sizing in views.
/// - [multimedia_gallery_configuration.dart]: Main config for the gallery UI.
/// - [multimedia_gallery_album_configuration.dart]: Album-specific config overrides.
/// - [multimedia_camera_configuration.dart]: Camera-specific controls like resolution.
/// {@endtemplate}
export 'src/models/album_view_configuration.dart';
export 'src/models/gallery_view_configuration.dart';
export 'src/models/selected_media.dart';
export 'src/models/multimedia_configurations.dart';
export 'src/models/multimedia_layout_configuration.dart';
export 'src/models/multimedia_gallery_configuration.dart';
export 'src/models/multimedia_gallery_album_configuration.dart';
export 'src/models/multimedia_camera_configuration.dart';

/// {@template multimedia_progress_slider_exports}
/// # Progress Slider
/// A reusable progress slider widget used in multimedia playback or trim editing interfaces.
/// {@endtemplate}
export 'src/progress_slider/progress_slider.dart';

/// {@template multimedia_utils_exports}
/// # Utilities
/// Helper functions for working with media sources, permissions, formatting, and validations.
/// {@endtemplate}
export 'src/utils/multimedia_utils.dart';

/// {@template multimedia_core_exports}
/// # Core Multimedia Widgets
///
/// Main interactive widgets that power media selection from gallery or capture via camera:
/// - [multimedia_gallery.dart]: Grid-based picker UI for photos/videos.
/// - [multimedia_camera.dart]: Camera interface to capture media with live preview.
/// {@endtemplate}
export 'src/multimedia_gallery/multimedia_gallery.dart';
export 'src/multimedia_camera/multimedia_camera.dart';

/// {@template multimedia_external_exports}
/// # External Dependencies
///
/// Re-exports types and functionality from the `gallery` package for internal use or extension.
/// {@endtemplate}
export 'package:gallery/gallery.dart';