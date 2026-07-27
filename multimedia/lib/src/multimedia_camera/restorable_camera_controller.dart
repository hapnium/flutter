import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

/// {@template restorable_camera_controller}
/// A [RestorableProperty] that persists and restores a [CameraController]
/// across navigation routes and platform lifecycle changes.
///
/// This class implements [RestorableValue] to serialize the camera controller's
/// state when the navigation stack is saved (e.g., during a push/pop transition)
/// and restore it when the stack is rebuilt. The restoration is handled by
/// Flutter's [RestorationMixin] — the parent state registers this property in
/// [restoreState] and provides a [restorationId].
///
/// **Serialization strategy:**
/// - [toPrimitives] returns the current [CameraController] instance directly.
///   In a production setting, this would serialize the camera name, resolution,
///   and audio preference to a [Map], but the current implementation stores the
///   controller reference itself.
/// - [fromPrimitives] ignores the serialized data and returns a fresh
///   [CameraController] via [createDefaultValue]. This ensures the restored
///   controller is in a known-good state rather than attempting to deserialize
///   an opaque object.
///
/// ### Example usage:
/// ```dart
/// class _MyCameraState extends State<MyCamera> with RestorationMixin {
///   final RestorableCameraController _camera = RestorableCameraController();
///
///   @override
///   String? get restorationId => 'my_camera';
///
///   @override
///   void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
///     registerForRestoration(_camera, 'camera_controller');
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return CameraPreview(_camera.value);
///   }
/// }
/// ```
/// {@endtemplate}
class RestorableCameraController extends RestorableValue<CameraController> {
  /// {@macro restorable_camera_controller}
  RestorableCameraController();

  /// Creates a default [CameraController] used as the initial value
  /// and as the restored value when deserialization is not possible.
  ///
  /// The default controller targets a front-facing camera with:
  /// - Name: `'camera_0'`
  /// - Lens direction: [CameraLensDirection.front]
  /// - Sensor orientation: 270 degrees
  /// - Resolution: [ResolutionPreset.high]
  /// - Audio: disabled
  ///
  /// These defaults match the most common camera configuration on mobile
  /// devices. Callers can override by providing their own controller
  /// after restoration completes.
  @override
  CameraController createDefaultValue() {
    return CameraController(
      CameraDescription(
        name: 'camera_0',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 270,
      ),
      ResolutionPreset.high,
      enableAudio: false,
    );
  }

  /// Restores a [CameraController] from serialized primitives.
  ///
  /// Currently ignores [data] and returns [createDefaultValue] instead of
  /// attempting to deserialize the controller. This is intentional — a
  /// [CameraController] cannot be meaningfully serialized to primitives
  /// without losing its internal state (texture ID, native session).
  /// The restored controller must be re-initialized by the caller.
  @override
  CameraController fromPrimitives(Object? data) {
    return createDefaultValue();
  }

  /// Serializes the current [CameraController] to a storable primitive.
  ///
  /// Returns the controller instance directly. In a production
  /// implementation, this would return a [Map] containing the camera
  /// name, lens direction, resolution preset, and audio preference.
  @override
  Object toPrimitives() {
    return value;
  }

  /// Called when the underlying [CameraController] value changes.
  ///
  /// No-op in the current implementation. Override this to perform
  /// side effects when the controller is swapped (e.g., re-attaching
  /// a preview widget).
  @override
  void didUpdateValue(CameraController? oldValue) {
  }
}