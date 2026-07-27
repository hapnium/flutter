part of 'multimedia_camera.dart';

/// {@template multimedia_camera_state}
/// State for [MultimediaCamera] that manages the full camera lifecycle:
/// initialization, preview, photo capture, video recording, flash/exposure/focus
/// control, camera switching, pinch-to-zoom, and cleanup.
///
/// The state mixes in [WidgetsBindingObserver] to respond to app lifecycle
/// changes (backgrounding the app disposes the camera controller; returning
/// re-initializes it). It also mixes in [TickerProviderStateMixin] to provide
/// tickers for the animated control panels (flash, exposure, focus, flip),
/// and [RestorationMixin] to persist the camera controller across navigation
/// stack restorations via [_resController].
///
/// The camera is always initialized to the rear camera by default (index 1)
/// if no custom camera list is provided. If the caller supplies a camera
/// list via [MultimediaCameraConfiguration.cameras], that list is used
/// instead.
/// {@endtemplate}
class _MultimediaCameraState extends State<MultimediaCamera> with WidgetsBindingObserver, TickerProviderStateMixin, RestorationMixin {
  /// The underlying [CameraController] managing the native camera session.
  ///
  /// Initialized asynchronously in [_initializeCamera] and disposed in
  /// [_disposeCameraResources]. All camera operations (preview, capture,
  /// flash, zoom) are delegated to this controller.
  CameraController? _controller;

  /// The resolved [MultimediaCameraConfiguration] from the parent widget.
  ///
  /// Cached in [initState] and updated in [didUpdateWidget] when the parent
  /// provides a new configuration.
  late MultimediaCameraConfiguration parent;

  /// A [RestorableProperty] that persists the camera controller across
  /// navigation stack restorations.
  ///
  /// Registered in [restoreState] so that when Flutter rebuilds the route,
  /// the camera controller can be restored without re-initializing from
  /// scratch. In practice, the restored controller falls back to defaults
  /// because [CameraController] cannot be meaningfully serialized.
  final RestorableCameraController _resController = RestorableCameraController();

  /// The list of available cameras on the current device.
  ///
  /// Deduplicated in [_updateCameras] to prevent duplicate entries for the
  /// same camera (e.g., a camera appearing under both its name and lens
  /// direction). Updated when the camera list changes or when the app
  /// lifecycle triggers a re-scan.
  List<CameraDescription> _cameras = [];

  /// The current pinch-to-zoom scale factor.
  ///
  /// Updated in [_handleScaleUpdate] when the user performs a two-finger
  /// pinch gesture on the camera preview. Clamped between
  /// [_minAvailableZoom] and [_maxAvailableZoom]. Set back to the base
  /// scale when a new pinch gesture starts.
  double _currentScale = 1.0;

  /// The zoom scale at the start of a pinch gesture.
  ///
  /// Captured in [_handleScaleStart] so that subsequent [_handleScaleUpdate]
  /// events can compute a relative scale from the original pinch distance.
  double _baseScale = 1.0;

  /// The current flash mode applied to the camera.
  ///
  /// Toggled by [_setFlash] when the user taps a flash mode button. Defaults
  /// to [FlashMode.off]. Changing the flash mode updates the camera preview
  /// in real time.
  FlashMode _flashMode = FlashMode.off;

  /// The current exposure mode applied to the camera.
  ///
  /// Toggled between [ExposureMode.auto] and [ExposureMode.locked] via
  /// [_setExposureMode]. When locked, the camera maintains its current
  /// exposure value regardless of scene brightness changes.
  ExposureMode _exposure = ExposureMode.auto;

  /// The current exposure offset applied to the camera.
  ///
  /// Adjusted via [_setExposureOffset] when the user drags the exposure
  /// slider. The valid range is bounded by [_minAvailableExposureOffset]
  /// and [_maxAvailableExposureOffset]. Reset to 0.0 by
  /// [_handleExposureOffsetReset].
  double _currentExposureOffset = 0.0;

  /// The current focus mode applied to the camera.
  ///
  /// Toggled between [FocusMode.auto] and [FocusMode.locked] via
  /// [_setFocusMode]. When locked, the camera maintains its current focus
  /// distance regardless of scene changes.
  FocusMode _focus = FocusMode.auto;

  /// The currently active [CameraDescription].
  ///
  /// Updated in [_initializeCamera] and [_onNewCameraSelected] when the user
  /// switches cameras. Defaults to a front-facing camera with 270-degree
  /// sensor orientation. Used by [buildCamera] to display the camera lens
  /// direction indicator.
  CameraDescription _description = CameraDescription(
    name: "camera 0",
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 270
  );

  /// The minimum exposure offset supported by the current camera hardware.
  ///
  /// Queried from the [CameraController] during [_initializeCamera]. If the
  /// camera does not support exposure offsets, this and
  /// [_maxAvailableExposureOffset] will be equal, and the exposure offset
  /// slider will not be rendered.
  double _minAvailableExposureOffset = 0.0;

  /// The maximum exposure offset supported by the current camera hardware.
  ///
  /// Queried from the [CameraController] during [_initializeCamera]. The
  /// exposure slider's range is [_minAvailableExposureOffset] to this value.
  double _maxAvailableExposureOffset = 0.0;

  /// The minimum zoom level supported by the current camera hardware.
  ///
  /// Queried from the [CameraController] during [_initializeCamera]. Used
  /// to clamp the pinch-to-zoom value in [_handleScaleUpdate].
  double _minAvailableZoom = 1.0;

  /// The maximum zoom level supported by the current camera hardware.
  ///
  /// Queried from the [CameraController] during [_initializeCamera]. Used
  /// to clamp the pinch-to-zoom value in [_handleScaleUpdate].
  double _maxAvailableZoom = 1.0;

  /// Whether audio recording is enabled for video capture.
  ///
  /// Toggled by [_onAudioModeButtonPressed]. When `true`, the camera
  /// controller is re-initialized with `enableAudio: true` so that the
  /// microphone captures audio alongside video. Defaults to `false`.
  bool _enableAudio = false;

  /// Whether the capture orientation is currently locked.
  ///
  /// Toggled by [_onCaptureOrientationLockButtonPressed]. When locked, the
  /// camera maintains its current orientation regardless of device rotation.
  /// The lock/unlock state is reflected by the orientation lock button icon.
  bool _isCaptureOrientationLocked = false;

  /// Whether a video recording is currently in progress.
  ///
  /// Set to `true` in [_startRecording] when the user starts recording.
  /// Set to `false` in [_pauseRecording], [_stopRecording], and
  /// [_onCameraStateChanged] when recording stops or the controller reports
  /// the recording has ended. Controls which action buttons are shown in
  /// [recording] vs [paused] vs [onlyVideo].
  bool _isRecording = false;

  /// Whether a video recording is currently paused.
  ///
  /// Set to `true` in [_pauseRecording] when the user pauses the recording.
  /// Set to `false` in [_continueRecording] and [_stopRecording]. When
  /// paused, [buildCamera] renders the static preview via
  /// [CameraController.buildPreview] instead of the live camera feed.
  bool _isPausedRecording = false;

  /// Whether media is currently being processed (e.g., stopping a recording
  /// and encoding the video file).
  ///
  /// Set to `true` in [_stopRecording] while the controller is finalizing the
  /// video file. Set to `false` in the `whenComplete` callback after
  /// [_stopVideoRecording] finishes. While `true`, the UI can display a
  /// loading indicator to prevent further user interaction.
  bool _isFetching = false;

  /// The elapsed recording duration in seconds.
  ///
  /// Incremented by [_startTimer] every second via a periodic [Timer]. Reset
  /// to `0` in [_stopRecording]. Compared against
  /// [MultimediaCameraConfiguration.maxDuration] to auto-stop recording when
  /// the maximum duration is reached.
  int _recordDuration = 0;

  /// A human-readable display of the current recording duration.
  ///
  /// Formatted as `"MM : SS"` by [_startTimer]. Used by [recording] and
  /// [paused] to display the elapsed time next to the recording controls.
  String _videoDuration = "00:00";

  /// Whether the camera has finished initializing and is ready for preview.
  ///
  /// Set to `true` in [_initializeCamera] after the [CameraController]
  /// successfully initializes. Controls whether [buildCamera] renders
  /// the live preview or a placeholder loading color. Also gates the
  /// display of action buttons in [button].
  bool _isCameraInitialized = false;

  /// The number of touch pointers currently on the camera preview.
  ///
  /// Managed by the [Listener] wrapping [CameraPreview] in [buildCamera].
  /// Incremented on [onPointerDown] and decremented on [onPointerUp].
  /// [_handleScaleUpdate] only applies zoom when this value equals 2
  /// (exactly two fingers on screen).
  int _pointers = 0;

  /// The periodic timer driving the recording duration counter.
  ///
  /// Created by [_startTimer] and cancelled in [_stopRecording] and [dispose].
  /// Each tick increments [_recordDuration] by one second and updates
  /// [_videoDuration].
  Timer? _timer;

  /// Whether to show the video recording button.
  ///
  /// Determined in [initState] from the configuration flags:
  /// `true` if [MultimediaCameraConfiguration.showOnlyVideo] is `true`,
  /// or if neither `showOnlyVideo` nor `showOnlyPhoto` is `true` (both modes).
  late bool _showVideo;

  /// Whether to show the photo capture button.
  ///
  /// Determined in [initState] from the configuration flags:
  /// `true` if [MultimediaCameraConfiguration.showOnlyPhoto] is `true`,
  /// or if neither `showOnlyVideo` nor `showOnlyPhoto` is `true` (both modes).
  late bool _showPhoto;

  /// Animation controller for the flash mode control panel.
  ///
  /// Drives the [SizeTransition] that expands/collapses the flash mode
  /// buttons. Duration is 300ms with [Curves.easeInCubic].
  late final AnimationController _flashModeControlRowAnimationController;

  /// Curved animation for the flash mode control panel.
  ///
  /// Wraps [_flashModeControlRowAnimationController] with [Curves.easeInCubic]
  /// to provide a smooth ease-in effect for the flash panel expansion.
  late final CurvedAnimation _flashModeControlRowAnimation;

  /// Animation controller for the camera flip control panel.
  ///
  /// Drives the [SizeTransition] that expands/collapses the camera selection
  /// buttons. Duration is 300ms with [Curves.easeInCubic].
  late final AnimationController _flipCameraControlRowAnimationController;

  /// Curved animation for the camera flip control panel.
  ///
  /// Wraps [_flipCameraControlRowAnimationController] with [Curves.easeInCubic]
  /// to provide a smooth ease-in effect for the flip panel expansion.
  late final CurvedAnimation _flipCameraControlRowAnimation;

  /// Animation controller for the exposure mode control panel.
  ///
  /// Drives the [SizeTransition] that expands/collapses the exposure mode
  /// buttons and offset slider. Duration is 300ms with [Curves.easeInCubic].
  late final AnimationController _exposureModeControlRowAnimationController;

  /// Curved animation for the exposure mode control panel.
  ///
  /// Wraps [_exposureModeControlRowAnimationController] with [Curves.easeInCubic]
  /// to provide a smooth ease-in effect for the exposure panel expansion.
  late final CurvedAnimation _exposureModeControlRowAnimation;

  /// Animation controller for the focus mode control panel.
  ///
  /// Drives the [SizeTransition] that expands/collapses the focus mode
  /// buttons. Duration is 300ms with [Curves.easeInCubic].
  late final AnimationController _focusModeControlRowAnimationController;

  /// Curved animation for the focus mode control panel.
  ///
  /// Wraps [_focusModeControlRowAnimationController] with [Curves.easeInCubic]
  /// to provide a smooth ease-in effect for the focus panel expansion.
  late final CurvedAnimation _focusModeControlRowAnimation;

  /// The resolved [MultimediaLayoutConfiguration] from the parent widget.
  ///
  /// Falls back to a default [MultimediaLayoutConfiguration] when the parent
  /// does not provide one. Controls the overall scaffold layout (app bar,
  /// background color, safe area, loading indicators, etc.).
  @protected
  MultimediaLayoutConfiguration get layoutConfig => parent.layoutConfiguration ?? MultimediaLayoutConfiguration();

  /// The restoration ID used by [RestorationMixin] to persist this state.
  ///
  /// Set to `'multimedia_camera_state'`. When Flutter rebuilds the route
  /// (e.g., after the app is killed and restored), this ID is used to
  /// locate and restore the camera controller via [_resController].
  @override
  String? get restorationId => 'multimedia_camera_state';

  /// Whether the camera supports a non-zero exposure offset range.
  ///
  /// Returns `true` when the minimum and maximum available exposure offsets
  /// differ, meaning the camera hardware supports exposure adjustment. When
  /// `false`, the exposure offset slider is not rendered in the exposure
  /// control panel.
  @protected
  bool get hasOffset => _minAvailableExposureOffset.notEquals(_maxAvailableExposureOffset);

  /// The color used for inactive/stale UI elements (e.g., the loading placeholder
  /// when the camera is not initialized).
  ///
  /// Falls back to the theme's bottom app bar color if not configured.
  @protected
  Color? get staleColor => parent.staleColor ?? Theme.of(context).bottomAppBarTheme.color;

  /// The color used for the currently active/selected UI element.
  ///
  /// Used to highlight the active flash mode, active exposure/focus mode, and
  /// the currently selected camera lens. Defaults to [Colors.green].
  @protected
  Color get activeColor => parent.activeColor ?? Colors.green;

  /// The color used for inactive/unselected UI elements.
  ///
  /// Used to dim flash modes, exposure/focus modes, and camera lenses that
  /// are not currently active. Defaults to `Color(0xffF1F1F1)`.
  @protected
  Color get inActiveColor => parent.inActiveColor ?? Color(0xffF1F1F1);

  /// Returns [activeColor] when [value] is `true`, [inActiveColor] otherwise.
  ///
  /// Convenience method for toggling colors based on selection state in the
  /// flash, exposure, focus, and camera flip panels.
  @protected
  Color active(bool value) => value ? activeColor : inActiveColor;

  /// The color used for the camera control bar background and common UI
  /// elements (e.g., the back button container).
  ///
  /// Defaults to white (`Color(0xffFFFFFF)`).
  @protected
  Color get commonColor => parent.commonColor ?? Color(0xffFFFFFF);

  /// The color used for the active/selected flash mode icon.
  ///
  /// Defaults to orange (`Color(0xffFF9E53)`). The currently active flash
  /// mode icon is rendered in this color while inactive modes use
  /// [inActiveFlashColor].
  @protected
  Color get activeFlashColor => parent.activeFlashColor ?? Color(0xffFF9E53);

  /// The color used for inactive flash mode icons.
  ///
  /// Defaults to green (`Color(0xff06C270)`). Flash modes that are not
  /// currently selected are rendered in this color.
  @protected
  Color get inActiveFlashColor => parent.inActiveFlashColor ?? Color(0xff06C270);

  /// The color used for the pause button during recording.
  ///
  /// Defaults to red (`Color(0xffFF3B3B)`). Controls the icon color of
  /// the pause and stop buttons when recording is paused.
  @protected
  Color get pausedColor => parent.pausedColor ?? Color(0xffFF3B3B);

  /// The color used for the recording indicator and action buttons.
  ///
  /// Defaults to red (`Color(0xffFF3B3B)`). Controls the icon color of
  /// the pause, stop, and timer text during active recording.
  @protected
  Color get recordingColor => parent.recordingColor ?? Color(0xffFF3B3B);

  /// The background color of the circular progress indicator during recording.
  ///
  /// Defaults to the theme's unselected widget color. The progress ring's
  /// unfilled portion is rendered in this color.
  @protected
  Color get progressBackgroundColor => parent.progressBackgroundColor ?? Theme.of(context).unselectedWidgetColor;

  /// The animated value color of the circular progress indicator during recording.
  ///
  /// Defaults to red (`Color(0xffFF3B3B)`) wrapped in [AlwaysStoppedAnimation].
  /// The filled portion of the progress ring animates between this color as
  /// the recording progresses.
  @protected
  Animation<Color?> get progressValueColor => parent.progressValueColor ?? AlwaysStoppedAnimation<Color>(Color(0xffFF3B3B));

  /// An optional override color for the progress indicator's filled portion.
  ///
  /// When provided, overrides the default [progressValueColor] for the
  /// recording progress ring. When `null`, [progressValueColor] is used.
  @protected
  Color? get progressColor => parent.progressColor;

  /// An optional override for the progress indicator's stroke cap.
  ///
  /// When provided, sets the [StrokeCap] of the recording progress ring
  /// (e.g., [StrokeCap.round] for rounded ends). When `null`, defaults
  /// to the Flutter default ([StrokeCap.butt]).
  @protected
  StrokeCap? get progressStrokeCap => parent.progressStrokeCap;

  /// The stroke width of the circular progress indicator during recording.
  ///
  /// Defaults to `4.0`. Controls the thickness of the progress ring drawn
  /// around the recording action buttons.
  @protected
  double get progressStrokeWidth => parent.progressStrokeWidth ?? 4.0;

  /// The icon displayed for the photo capture button.
  ///
  /// Defaults to [Icons.photo_camera_rounded]. Used in [onlyPhoto] and
  /// [combined] to render the shutter button icon.
  @protected
  IconData get cameraIcon => parent.cameraIcon ?? Icons.photo_camera_rounded;

  /// The icon displayed for the video recording button.
  ///
  /// Defaults to [Icons.radio_button_on_rounded]. Used in [onlyVideo],
  /// [recording], [paused], and [combined] to render the record button icon.
  @protected
  IconData get videoIcon => parent.videoIcon ?? Icons.radio_button_on_rounded;

  /// The size of the primary action icons (photo/video buttons).
  ///
  /// Defaults to `Sizing.font(40)`. Controls the visual weight of the
  /// capture/record buttons in the bottom control area.
  @protected
  double get actionIconSize => parent.actionIconSize ?? Sizing.font(40);

  /// The [CameraDescription] of the currently active camera, or `null` if
  /// the camera controller is not yet initialized.
  ///
  /// Delegated to [CameraController.description]. Used by [buildCamera] to
  /// determine the active camera lens direction and by
  /// [_onCaptureOrientationLockButtonPressed] to read orientation state.
  @protected
  CameraDescription? get description => _controller?.description;

  /// Whether the camera controller has finished initializing and is ready
  /// for preview, capture, and recording operations.
  ///
  /// Delegated to [CameraController.value.isInitialized]. When `false`,
  /// [buildCamera] renders a placeholder color instead of the live preview.
  @protected
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Restores the camera controller state when Flutter rebuilds the route.
  ///
  /// Registers [_resController] for restoration if the camera controller
  /// is not `null`. This is called by [RestorationMixin] when the
  /// restoration bucket changes or during initial restoration.
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if(_controller.isNotNull) {
      registerForRestoration(_resController, 'camera_controller');
    }
  }

  /// Initializes the camera state, animation controllers, and begins
  /// the camera setup process.
  ///
  /// Called once when the widget is inserted into the tree. Resolves the
  /// [parent] configuration, determines whether to show video/photo buttons,
  /// initializes all animation controllers for the control panels, and
  /// starts the camera initialization process.
  @override
  void initState() {
    parent = widget.configuration;
    _showVideo = parent.showOnlyVideo || (!parent.showOnlyVideo && !parent.showOnlyPhoto);
    _showPhoto = parent.showOnlyPhoto || (!parent.showOnlyVideo && !parent.showOnlyPhoto);

    _initControllers();
    _initCamera();
    _controller?.addListener(_onCameraStateChanged);

    super.initState();
  }

  /// Initializes all animation controllers for the flash, flip, exposure,
  /// and focus control panels.
  ///
  /// Each controller uses a 300ms duration with [Curves.easeInCubic] for
  /// smooth expand/collapse transitions. Also registers this state as a
  /// [WidgetsBindingObserver] to receive app lifecycle notifications.
  void _initControllers() {
    WidgetsBinding.instance.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    _flipCameraControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flipCameraControlRowAnimation = CurvedAnimation(
      parent: _flipCameraControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _focusModeControlRowAnimation = CurvedAnimation(
      parent: _focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
  }

  /// Discovers available cameras and initializes the default camera.
  ///
  /// If the parent provided a non-empty [MultimediaCameraConfiguration.cameras]
  /// list, those cameras are used directly via [_updateCameras]. Otherwise,
  /// calls [availableCameras] to discover all cameras on the device.
  /// In both cases, the camera at index 1 (rear camera, if present) is
  /// initialized as the default. Errors are routed to [_handleCameraException]
  /// or [_error].
  void _initCamera() async {
    if(parent.cameras.isNotEmpty) {
      _updateCameras(parent.cameras);

      _initializeCamera(_cameras[1]);
    } else {
      await availableCameras().then((cameras) {
        _updateCameras(cameras);

        _initializeCamera(_cameras[1]);
      }).catchError((e) {
        if(e is CameraException) {
          _handleCameraException(e);
        } else {
          _error("Couldn't access your camera. Try again.", useTip: false);
        }
      });
    }
  }

  /// Deduplicates the camera list and notifies the parent of the update.
  ///
  /// Iterates through [cameras] and adds each camera to a [Set] only if no
  /// existing entry shares the same name or lens direction. This prevents
  /// duplicate entries that some platforms return. After deduplication,
  /// calls [MultimediaCameraConfiguration.cameraDescriptionUpdated] if
  /// provided, passing the cleaned list.
  void _updateCameras(List<CameraDescription> cameras) {
    Set<CameraDescription> descriptions = {};
    for (CameraDescription camera in cameras) {
      if(!descriptions.any((cam) => cam.name.equals(camera.name) || cam.lensDirection.equals(camera.lensDirection))) {
        descriptions.add(camera);
      }
    }

    setState(() {
      _cameras = descriptions.toList();
    });

    if(parent.cameraDescriptionUpdated.isNotNull) {
      parent.cameraDescriptionUpdated!(descriptions.toList());
    }
  }

  /// Initializes the camera controller for the given [description].
  ///
  /// Creates a [CameraController] with resolution preset [ResolutionPreset.high]
  /// (or [ResolutionPreset.max] on web), enables audio only if [_showVideo]
  /// is `true`, and uses JPEG format. After initialization, queries the
  /// hardware for available zoom levels and exposure offset ranges. On web,
  /// exposure offset queries are included (the comment in the source is
  /// misleading — the `if(parent.isWeb)` block actually runs exposure queries
  /// only on web, where exposure mode is not supported).
  ///
  /// If a [CameraException] occurs during initialization or hardware
  /// queries, it is routed to [_handleCameraException].
  void _initializeCamera(CameraDescription description) async {
    setState(() {
      _description = description;
    });

    if(_cameras.isNotEmpty) {
      final CameraController cameraController = CameraController(
        description,
        parent.isWeb ? ResolutionPreset.max : ResolutionPreset.high,
        enableAudio: _showVideo,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = cameraController;
      try {
        await _controller?.initialize();
        setState(() {
          _isCameraInitialized = true;
        });

        await Future.wait(<Future<Object?>>[
          // The exposure mode is currently not supported on the web.
          if(parent.isWeb) ...[
            cameraController.getMinExposureOffset().then((double value) {
              setState(() {
                _minAvailableExposureOffset = value;
              });
              
              return value;
            }),
            cameraController.getMaxExposureOffset().then((double value) {
              setState(() {
                _maxAvailableExposureOffset = value;
              });

              return value;
            })
          ],
          cameraController.getMaxZoomLevel().then((double value) {
            setState(() {
              _maxAvailableZoom = value;
            });

            return value;
          }),
          cameraController.getMinZoomLevel().then((double value) {
            setState(() {
              _minAvailableZoom = value;
            });

            return value;
          }),
        ]);
      } on CameraException catch (e) {
        _handleCameraException(e);
      }
    }

    setState(() {

    });
  }

  /// Translates a [CameraException] into a user-friendly error message.
  ///
  /// Maps each known error code to a specific message:
  /// - `CameraAccessDenied`: Camera permission not granted
  /// - `AudioAccessDenied`: Microphone permission not granted
  /// - `CameraAccessDeniedWithoutPrompt`: iOS-only, camera denied without prompt
  /// - `CameraAccessRestricted`: iOS-only, camera restricted by parental controls
  /// - `AudioAccessDeniedWithoutPrompt`: iOS-only, audio denied without prompt
  /// - `AudioAccessRestricted`: iOS-only, audio restricted by parental controls
  /// - Default: generic camera access denied message
  ///
  /// The resolved message is forwarded to [_error] for delivery to the
  /// [MultimediaCameraConfiguration.onErrorReceived] callback.
  void _handleCameraException(CameraException e) {
    String error = "An error occurred with camera settings";
    switch (e.code) {
      case 'CameraAccessDenied':
        error = e.description ?? "Camera access is denied";
        break;
      case 'AudioAccessDenied':
        error = e.description ?? "Audio access is denied";
        break;
      case 'CameraAccessDeniedWithoutPrompt':
        // iOS only
        error = 'Please go to Settings app to enable camera access.';
      case 'CameraAccessRestricted':
        // iOS only
        error = 'Camera access is restricted.';
      case 'AudioAccessDeniedWithoutPrompt':
        // iOS only
        error = 'Please go to Settings app to enable audio access.';
      case 'AudioAccessRestricted':
        // iOS only
        error = 'Audio access is restricted.';
      default:
        error = e.description ?? "Camera access is denied";
        break;
    }

    _error(error);
  }

  /// Delivers an error message to the parent via the configured callback.
  ///
  /// If [MultimediaCameraConfiguration.onErrorReceived] is provided, the
  /// [message] is forwarded to it along with [useTip] which indicates
  /// whether the UI should display a tip alongside the error. If no
  /// callback is configured, the error is silently discarded.
  void _error(String message, {bool useTip = true}) {
    if(parent.onErrorReceived.isNotNull) {
      parent.onErrorReceived!(message, useTip);
    }
  }

  /// Listener attached to the [CameraController] that detects when a
  /// video recording ends externally (e.g., the system stops recording
  /// due to a memory limit).
  ///
  /// When the controller reports that recording has stopped, resets
  /// [_isRecording] and [_isPausedRecording] to `false` so the UI
  /// returns to the idle state.
  void _onCameraStateChanged() {
    if(_controller.isNotNull && _controller!.value.isRecordingVideo.isFalse) {
      setState(() {
        _isRecording = false;
        _isPausedRecording = false;
      });
    }
  }


  /// Responds to app lifecycle state changes by managing the camera controller.
  ///
  /// - [AppLifecycleState.inactive]: The app is transitioning. The camera
  ///   controller is disposed to release native resources.
  /// - [AppLifecycleState.hidden] / [AppLifecycleState.paused]: The app is
  ///   in the background. No action is taken (the controller remains alive).
  /// - [AppLifecycleState.resumed] / other: The app returns to the foreground.
  ///   The camera list is re-scanned via [_updateCameras] and the camera
  ///   is re-initialized via [_initializeCamera].
  ///
  /// If the controller is `null` or not yet initialized, this method is a
  /// no-op.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;

    // App state changed before we got the chance to initialize.
    if (controller.isNull || controller!.value.isInitialized.isFalse) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if(state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      ///
    } else {
      _updateCameras([..._cameras, controller.description]);
      _initializeCamera(description ?? controller.description);
    }

    super.didChangeAppLifecycleState(state);
  }

  /// Releases all camera-related resources: the controller listener, the
  /// controller itself, the widgets binding observer, and all animation
  /// controllers.
  ///
  /// Called by [dispose] and by [_stopRecording] after a video is finalized.
  /// Each resource is disposed independently to prevent partial cleanup if
  /// an error occurs during disposal.
  void _disposeCameraResources() {
    _controller?.removeListener(_onCameraStateChanged);
    _controller?.dispose();

    WidgetsBinding.instance.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _flashModeControlRowAnimation.dispose();
    _flipCameraControlRowAnimationController.dispose();
    _flipCameraControlRowAnimation.dispose();
    _exposureModeControlRowAnimationController.dispose();
    _exposureModeControlRowAnimation.dispose();
    _focusModeControlRowAnimationController.dispose();
    _focusModeControlRowAnimation.dispose();
  }

  /// Cleans up all resources when the widget is removed from the tree.
  ///
  /// Cancels the recording timer and disposes all camera resources via
  /// [_disposeCameraResources]. Must be called to prevent memory leaks,
  /// especially the periodic timer and native camera session.
  @override
  void dispose() {
    _timer?.cancel();
    _disposeCameraResources();

    super.dispose();
  }

  /// Resumes a paused video recording.
  ///
  /// Restarts the recording duration timer via [_startTimer] and calls
  /// [CameraController.resumeVideoRecording]. Updates [_isRecording] to
  /// `true` and [_isPausedRecording] to `false` so the UI switches from
  /// [paused] back to [recording].
  void _continueRecording() async {
    _startTimer();

    await _controller?.resumeVideoRecording();

    setState(() {
      _isRecording = true;
      _isPausedRecording = false;
    });
  }

  /// Pauses the current video recording.
  ///
  /// Cancels the recording duration timer and calls
  /// [CameraController.pauseVideoRecording]. Updates [_isRecording] to
  /// `false` and [_isPausedRecording] to `true` so the UI switches from
  /// [recording] to [paused], showing the static preview and resume/stop
  /// buttons.
  void _pauseRecording() async {
    _timer?.cancel();

    await _controller?.pauseVideoRecording();
    
    setState(() {
      _isRecording = false;
      _isPausedRecording = true;
    });
  }

  /// Dispatches the appropriate video recording action based on current state.
  ///
  /// - If currently recording and not paused: pauses via [_pauseRecording].
  /// - If paused and not recording: resumes via [_continueRecording].
  /// - Otherwise (idle): starts a new recording via [_startRecording].
  ///
  /// This is the main entry point called by the video recording button in
  /// [onlyVideo] and [combined].
  void _recordVideo() async {
    if(_isRecording && !_isPausedRecording) {
      _pauseRecording();
    } else if(_isPausedRecording && !_isRecording) {
      _continueRecording();
    } else {
      _startRecording();
    }
  }

  /// Sets the camera flash mode and updates the UI.
  ///
  /// Calls [CameraController.setFlashMode] with the given [mode] and,
  /// on success, updates [_flashMode] so the flash panel highlights the
  /// active mode. If the flash mode cannot be set (e.g., the camera is
  /// not initialized), the error is routed to [_handleCameraException]
  /// and re-thrown.
  void _setFlash(FlashMode mode) async {
    try {
      await _controller?.setFlashMode(mode).then((_) {
        setState(() {
          _flashMode = mode;
        });
      });
    } on CameraException catch (e) {
      _handleCameraException(e);
      rethrow;
    }
  }

  /// Starts the periodic timer that increments the recording duration.
  ///
  /// Creates a [Timer.periodic] that fires every second. Each tick
  /// increments [_recordDuration] by one and formats the duration as
  /// `"MM : SS"` into [_videoDuration]. When [_recordDuration] reaches
  /// [MultimediaCameraConfiguration.maxDuration], the recording is
  /// automatically stopped via [_stopRecording].
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _recordDuration = _recordDuration++;
      });

      String minutes = (_recordDuration ~/ 60).toTimeUnit();
      String seconds = (_recordDuration % 60).toTimeUnit();

      setState(() {
        _videoDuration = "$minutes : $seconds";
      });

      if(_recordDuration.equals(parent.maxDuration)) {
        _stopRecording();
      }
    });
  }

  /// Starts a new video recording.
  ///
  /// Calls [CameraController.startVideoRecording], starts the duration
  /// timer via [_startTimer], and sets [_isRecording] to `true`. The UI
  /// transitions to the [recording] view showing pause/stop buttons and
  /// the elapsed time.
  void _startRecording() async {
    await _controller?.startVideoRecording();
    _startTimer();

    setState(() {
      _isRecording = true;
    });
  }

  /// Stops the video recording and returns the recorded file as a
  /// [SelectedMedia].
  ///
  /// Calls [CameraController.stopVideoRecording] to finalize the recording
  /// and returns a [SelectedMedia] containing the file path, size, type
  /// ([MediaType.video]), and raw bytes. If the file is `null` (recording
  /// was interrupted), returns `null`. On [CameraException], routes the
  /// error to [_error] and returns `null`.
  Future<SelectedMedia?> _stopVideoRecording() async {
    try{
      XFile? file = await _controller?.stopVideoRecording();
      if(file.isNotNull) {
        final size = (await file?.length())?.toFileSize;

        return SelectedMedia(
          path: file!.path,
          size: size ?? "",
          media: MediaType.video,
          data: await file.readAsBytes()
        );
      }
    } on CameraException catch (e) {
      _error(e.description ?? "Couldn't capture. Try again");
    }

    return null;
  }

  /// Finalizes the video recording and delivers the result.
  ///
  /// First validates that the recording duration meets
  /// [MultimediaCameraConfiguration.minDuration]. If not, shows an error.
  /// Otherwise, cancels the timer, resets the recording state, and calls
  /// [_stopVideoRecording]. After the file is processed, the camera
  /// resources are disposed and the result is delivered either via
  /// [MultimediaCameraConfiguration.onRecordingCompleted] or by popping
  /// the navigation stack with the [SelectedMedia] as the result.
  void _stopRecording() async {
    if(parent.minDuration > _recordDuration) {
      _error("Cannot stop video recording until it exceeds min duration");
      return;
    }

    _timer?.cancel();

    setState(() {
      _recordDuration = 0;
      _isRecording = false;
      _isPausedRecording = false;
      _isFetching = true;
    });

    SelectedMedia?  result = await _stopVideoRecording().whenComplete(() {
      setState(() {
        _isFetching = false;
      });
    });

    if(result.isNotNull && _isFetching.isFalse) {
      result = result!.copyWith(duration: _videoDuration, isCamera: true);
      _disposeCameraResources();
      
      if(parent.onRecordingCompleted.isNotNull) {
        parent.onRecordingCompleted!(result);
      } else {
        Navigator.pop(context, result);
      }
    }
  }

  /// Captures a single photo and returns it as a [SelectedMedia].
  ///
  /// Validates that the controller is initialized and not already taking
  /// a picture. Calls [CameraController.takePicture] and returns a
  /// [SelectedMedia] containing the file path, size, type
  /// ([MediaType.photo]), and raw bytes. On [CameraException], routes
  /// the error to [_error] and returns `null`.
  Future<SelectedMedia?> _takePicture() async {
    try{
      if (_controller.isNull || !_controller!.value.isInitialized) {
        _error('Camera is not initialized. Try again');
        return null;
      }

      if (_controller!.value.isTakingPicture) {
        // A capture is already pending, do nothing.
        return null;
      }

      XFile? file = await _controller?.takePicture();
      if(file.isNotNull) {
        final size = (await file?.length())?.toFileSize;

        return SelectedMedia(
          path: file!.path,
          size: size ?? "",
          media: MediaType.photo,
          data: await file.readAsBytes(),
          isCamera: true
        );
      }
    } on CameraException catch (e) {
      _error(e.description ?? "Couldn't capture. Try again");
    }

    return null;
  }

  /// Captures a photo and delivers the result.
  ///
  /// Calls [_takePicture] to capture the image, then resets the flash
  /// to [FlashMode.off] via [_setFlash]. If the capture succeeds, the
  /// [SelectedMedia] is delivered either via
  /// [MultimediaCameraConfiguration.onImageTaken] or by popping the
  /// navigation stack. If the capture fails, an error is shown via [_error].
  void _takePhoto() async {
    final result = await _takePicture();

    _setFlash(FlashMode.off);

    if(result.isNotNull) {
      if(parent.onImageTaken.isNotNull) {
        parent.onImageTaken!(result!);
      } else {
        Navigator.pop(context, result);
      }
    } else {
      _error("Couldn't capture. Try again");
    }
  }

  /// Delivers an informational message to the parent.
  ///
  /// If [MultimediaCameraConfiguration.onInfoReceived] is provided, the
  /// [message] is forwarded to it. Used by orientation lock toggle,
  /// exposure/focus mode changes, and point resets to inform the user
  /// of the action taken.
  void _inform(String message) {
    if(parent.onInfoReceived.isNotNull) {
      parent.onInfoReceived!(message);
    }
  }

  /// Toggles the flash mode control panel open/closed.
  ///
  /// If the flash panel is fully open (value == 1), reverses it. Otherwise,
  /// forwards it and reverses all other panels (exposure, focus, flip) so
  /// only one panel is open at a time.
  void _onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value.equals(1)) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
      _flipCameraControlRowAnimationController.reverse();
    }
  }

  /// Toggles the exposure mode control panel open/closed.
  ///
  /// If the exposure panel is fully open (value == 1), reverses it. Otherwise,
  /// forwards it and reverses all other panels (flash, focus, flip) so
  /// only one panel is open at a time.
  void _onExposureModeButtonPressed() {
    if (_exposureModeControlRowAnimationController.value.equals(1)) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
      _flipCameraControlRowAnimationController.reverse();
    }
  }

  /// Toggles the focus mode control panel open/closed.
  ///
  /// If the focus panel is fully open (value == 1), reverses it. Otherwise,
  /// forwards it and reverses all other panels (flash, exposure, flip) so
  /// only one panel is open at a time.
  void _onFocusModeButtonPressed() {
    if (_focusModeControlRowAnimationController.value.equals(1)) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
      _flipCameraControlRowAnimationController.reverse();
    }
  }

  /// Toggles the camera flip control panel open/closed.
  ///
  /// If the flip panel is fully open (value == 1), reverses it. Otherwise,
  /// forwards it and reverses all other panels (flash, focus, exposure) so
  /// only one panel is open at a time.
  void _onFlipCameraButtonPressed() {
    if (_flipCameraControlRowAnimationController.value.equals(1)) {
      _flipCameraControlRowAnimationController.reverse();
    } else {
      _flipCameraControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
    }
  }

  /// Toggles audio recording on/off and re-initializes the camera.
  ///
  /// Flips [_enableAudio] and re-initializes the camera controller via
  /// [_onNewCameraSelected] so that the new audio preference takes effect.
  /// This triggers a brief preview interruption as the camera session is
  /// recreated.
  void _onAudioModeButtonPressed() {
    setState(() {
      _enableAudio = !_enableAudio;
    });

    if (_controller.isNotNull) {
      _onNewCameraSelected(_controller!.description);
    }
  }

  /// Switches to the specified camera.
  ///
  /// Validates that [description] is not `null`, then delegates to
  /// [_onNewCameraSelected] which either updates the existing controller's
  /// description or creates a new controller. Called by the camera flip
  /// panel when the user selects a different camera lens.
  void _onCameraChanged(CameraDescription? description) {
    if (description.isNull) {
      return;
    }

    _onNewCameraSelected(description!);
  }

  /// Updates the active camera to the given [description].
  ///
  /// If a controller already exists, updates its description via
  /// [CameraController.setDescription] (which may or may not be supported
  /// by the platform). If no controller exists, initializes a new one via
  /// [_initializeCamera]. Also updates the camera list via [_updateCameras]
  /// to include the new description.
  Future<void> _onNewCameraSelected(CameraDescription description) async {
    if (_controller.isNotNull) {
      setState(() {
        _description = description;
      });

      return _controller!.setDescription(description);
    } else {
      _updateCameras([..._cameras, description]);

      return _initializeCamera(description);
    }
  }

  /// Toggles the capture orientation lock on/off.
  ///
  /// When locked, the camera maintains its current orientation regardless
  /// of device rotation. When unlocked, the camera follows the device
  /// orientation. After toggling, an informational message is sent via
  /// [_inform] with the current orientation state. On [CameraException],
  /// the error is routed to [_handleCameraException].
  Future<void> _onCaptureOrientationLockButtonPressed() async {
    try {
      if (_controller.isNotNull) {
        setState(() {
          _isCaptureOrientationLocked = !_isCaptureOrientationLocked;
        });

        if (_controller!.value.isCaptureOrientationLocked) {
          await _controller!.unlockCaptureOrientation();
          _inform('Capture orientation unlocked');
        } else {
          await _controller!.lockCaptureOrientation();
          _inform('Capture orientation locked to ${_controller!.value.lockedCaptureOrientation.toString().split('.').last}');
        }
      }
    } on CameraException catch (e) {
      _handleCameraException(e);
    }
  }

  /// Sets the exposure mode and informs the user.
  ///
  /// Delegates to [_setExposureMode] and, on success, sends an info
  /// message via [_inform] with the new mode name.
  void _onSetExposureModeButtonPressed(ExposureMode mode) {
    _setExposureMode(mode).then((_) {
      _inform('Exposure mode set to ${mode.toString().split('.').last}');
    });
  }

  /// Applies the given exposure [mode] to the camera controller.
  ///
  /// If the controller is `null`, returns immediately. Calls
  /// [CameraController.setExposureMode] and updates [_exposure]. On
  /// [CameraException], routes the error to [_handleCameraException]
  /// and re-throws.
  Future<void> _setExposureMode(ExposureMode mode) async {
    if (_controller.isNull) {
      return;
    }

    try {
      await _controller!.setExposureMode(mode);
      setState(() {
        _exposure = mode;
      });
    } on CameraException catch (e) {
      _handleCameraException(e);
      rethrow;
    }
  }

  /// Resets the exposure point to the camera's default.
  ///
  /// Calls [CameraController.setExposurePoint] with `null` and informs
  /// the user via [_inform] that the exposure point has been reset.
  void _handleExposurePointReset() {
    if (_controller.isNotNull) {
      _controller!.setExposurePoint(null);
    }
    _inform('Resetting exposure point');
  }

  /// Sets the focus mode and informs the user.
  ///
  /// Delegates to [_setFocusMode] and, on success, sends an info
  /// message via [_inform] with the new mode name.
  void _onSetFocusModeButtonPressed(FocusMode mode) {
    _setFocusMode(mode).then((_) {
      _inform('Focus mode set to ${mode.toString().split('.').last}');
    });
  }

  /// Applies the given focus [mode] to the camera controller.
  ///
  /// If the controller is `null`, returns immediately. Calls
  /// [CameraController.setFocusMode] and updates [_focus]. On
  /// [CameraException], routes the error to [_handleCameraException]
  /// and re-throws.
  Future<void> _setFocusMode(FocusMode mode) async {
    if (_controller.isNull) {
      return;
    }

    try {
      await _controller!.setFocusMode(mode);
      setState(() {
        _focus = mode;
      });
    } on CameraException catch (e) {
      _handleCameraException(e);
      rethrow;
    }
  }

  /// Resets the focus point to the camera's default.
  ///
  /// Calls [CameraController.setFocusPoint] with `null` and informs
  /// the user via [_inform] that the focus point has been reset.
  void _handleFocusPointReset() {
    if (_controller.isNotNull) {
      _controller!.setFocusPoint(null);
    }
    _inform('Resetting focus point');
  }

  /// Handles changes to the exposure offset slider value.
  ///
  /// If the camera does not support exposure offset (min equals max),
  /// returns immediately. Otherwise, delegates to [_setExposureOffset]
  /// to apply the new offset to the camera controller.
  void _handleExposureOffsetChanged(double value) {
    if(_minAvailableExposureOffset.equals(_maxAvailableExposureOffset)) {
      return;
    } else {
      _setExposureOffset(value);
    }
  }

  /// Applies the given exposure [offset] to the camera controller.
  ///
  /// Updates [_currentExposureOffset] and calls
  /// [CameraController.setExposureOffset]. On [CameraException], routes
  /// the error to [_handleCameraException] and re-throws.
  Future<void> _setExposureOffset(double offset) async {
    if (_controller.isNull) {
      return;
    }

    setState(() {
      _currentExposureOffset = offset;
    });
    try {
      offset = await _controller!.setExposureOffset(offset);
    } on CameraException catch (e) {
      _handleCameraException(e);
      rethrow;
    }
  }

  /// Resets the exposure offset to zero.
  ///
  /// Calls [CameraController.setExposureOffset] with `0.0` and informs
  /// the user via [_inform] that the offset has been reset. The slider
  /// in the exposure panel will return to its center position.
  void _handleExposureOffsetReset() {
    if (_controller.isNotNull) {
      _controller!.setExposureOffset(0.0);
    }
    _inform('Resetting exposure offset');
  }

  /// Toggles the camera preview between paused and resumed states.
  ///
  /// If the controller is `null` or not initialized, shows an error. If
  /// the preview is currently paused, resumes it. Otherwise, pauses it.
  /// This does not affect video recording — only the live preview feed.
  Future<void> onPausePreviewButtonPressed() async {
    if (_controller.isNull || _controller!.value.isInitialized.isFalse) {
      _error('Camera is not initialized. Try again');
      return;
    }

    if (_controller!.value.isPreviewPaused) {
      await _controller!.resumePreview();
    } else {
      await _controller!.pausePreview();
    }
  }

  /// Captures the base zoom scale when a pinch gesture starts.
  ///
  /// Stores the current [_currentScale] as [_baseScale] so that subsequent
  /// [_handleScaleUpdate] events can compute a relative scale from the
  /// original pinch distance rather than applying an absolute scale.
  void _handleScaleStart(ScaleStartDetails details) {
    setState(() {
      _baseScale = _currentScale;
    });
  }

  /// Applies pinch-to-zoom based on the two-finger scale gesture.
  ///
  /// Only activates when exactly 2 fingers are on the screen (tracked by
  /// [_pointers]). Computes the new scale as `[_baseScale] * details.scale`
  /// clamped between [_minAvailableZoom] and [_maxAvailableZoom], then
  /// applies it to the camera controller via [CameraController.setZoomLevel].
  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (_controller.isNull || _pointers.notEquals(2)) {
      return;
    }

    setState(() {
      _currentScale = (_baseScale * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);
    });

    await _controller!.setZoomLevel(_currentScale);
  }

  /// Handles taps on the camera preview to set exposure and focus points.
  ///
  /// Converts the tap position from local coordinates to normalized
  /// coordinates (0.0–1.0) relative to the preview size, then passes
  /// the offset to both [CameraController.setExposurePoint] and
  /// [CameraController.setFocusPoint]. This allows the user to tap
  /// on a specific area of the scene to meter exposure and focus on
  /// that region.
  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller.isNull) {
      return;
    }

    final CameraController cameraController = _controller!;

    final Offset offset = Offset(
      details.localPosition.dx.divideBy(constraints.maxWidth),
      details.localPosition.dy.divideBy(constraints.maxHeight),
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  /// Builds the main camera screen layout.
  ///
  /// Wraps the content in a [ViewLayout] with the resolved layout
  /// configuration. When the camera is initialized, transparent system
  /// bars are configured. The content is a [Stack] with the camera
  /// preview filling the screen and a back button positioned at the top
  /// left. The back button can be overridden via
  /// [MultimediaCameraConfiguration.backButton].
  @override
  @protected
  Widget build(BuildContext context) {
    return ViewLayout(
      config: layoutConfig.config ?? (_isCameraInitialized ? UiConfig(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ) : null),
      needSafeArea: layoutConfig.needSafeArea,
      floaterPosition: parent.floatingPosition ?? 10,
      floater: Material(color: Colors.transparent, child: button()),
      extendBehindAppbar: layoutConfig.extendBehindAppbar,
      extendBody: layoutConfig.extendBody,
      goDark: layoutConfig.goDark,
      theme: layoutConfig.theme,
      shouldWillPop: layoutConfig.shouldWillPop,
      shouldOverride: layoutConfig.shouldOverride,
      floatingButton: layoutConfig.floatingButton,
      floaterWidth: layoutConfig.floaterWidth,
      floatingLocation: layoutConfig.floatingLocation,
      drawer: layoutConfig.drawer,
      endDrawer: layoutConfig.endDrawer,
      useFloaterWidth: layoutConfig.useFloaterWidth,
      withActivity: layoutConfig.withActivity,
      onInactivity: layoutConfig.onInactivity,
      onActivity: layoutConfig.onActivity,
      inactivityDuration: layoutConfig.inactivityDuration,
      isLoading: layoutConfig.isLoading,
      loadingHeight: layoutConfig.loadingHeight,
      loadingPosition: layoutConfig.loadingPosition,
      loadingWidth: layoutConfig.loadingWidth,
      loadingColor: layoutConfig.loadingColor,
      loadingBackgroundColor: layoutConfig.loadingBackgroundColor,
      floatFit: layoutConfig.floatFit,
      loadingFit: layoutConfig.loadingFit,
      bottomNavbar: layoutConfig.bottomNavbar,
      bottomSheet: layoutConfig.bottomSheet,
      barColor: layoutConfig.barColor,
      navigationColor: layoutConfig.navigationColor,
      darkBackgroundColor: layoutConfig.darkBackgroundColor,
      onWillPop: layoutConfig.onWillPop,
      backgroundColor: layoutConfig.backgroundColor,
      child: Stack(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height,
            child: buildCamera(),
          ),
          parent.backButton ?? Positioned(
            top: 6,
            left: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24)
              ),
              child: InfoButton(
                onPressed: parent.onGoingBack,
                icon: Icon(Icons.arrow_back, color: commonColor)
              ),
            )
          )
        ],
      )
    );
  }

  /// Builds the camera preview area.
  ///
  /// When the camera is initialized and the controller is ready:
  /// - If recording is paused ([_isPausedRecording]), renders the static
  ///   preview via [CameraController.buildPreview] so the user sees the
  ///   last frame without the live feed.
  /// - Otherwise, renders a live [CameraPreview] wrapped in a [Listener]
  ///   (for pointer counting) and a [GestureDetector] (for pinch-to-zoom
  ///   and tap-to-focus).
  ///
  /// When the camera is not initialized, renders a placeholder container
  /// with [staleColor] as the background.
  @protected
  Widget buildCamera() {
    if(_isCameraInitialized && _controller.isNotNull && isInitialized) {
      if(_isPausedRecording) {
        return _controller!.buildPreview();
      } else {
        return Listener(
          onPointerDown: (_) => _pointers++,
          onPointerUp: (_) => _pointers--,
          child: CameraPreview(
            _controller!,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onTapDown: (TapDownDetails details) => _onViewFinderTap(details, constraints),
                );
              }
            ),
          )
        );
      }
    } else {
      return Container(color: staleColor);
    }
  }

  /// Builds the bottom control area with action buttons.
  ///
  /// When the camera is initialized, renders a [Column] containing:
  /// 1. [control] — the top toolbar with flash, exposure, focus, audio,
  ///    orientation lock, and flip buttons.
  /// 2. One of:
  ///    - [combined] — when both photo and video are enabled
  ///    - [recording] — when video-only and currently recording
  ///    - [paused] — when video-only and recording is paused
  ///    - [onlyVideo] — when video-only and idle
  ///    - [onlyPhoto] — when photo-only
  ///
  /// When the camera is not initialized, renders an empty [SizedBox].
  @protected
  Widget button() {
    if(_isCameraInitialized) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            control(),
            if(_showVideo && _showPhoto) ...[
              combined()
            ] else if(_showVideo) ...[
              if(_isRecording) ...[
                recording()
              ] else if(_isPausedRecording) ...[
                paused()
              ] else ...[
                onlyVideo()
              ]
            ] else ...[
              onlyPhoto()
            ]
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  /// Builds the top toolbar with camera control buttons.
  ///
  /// Renders a row of [InfoButton] icons inside a rounded container:
  /// - Flash toggle (always shown)
  /// - Exposure mode (web excluded)
  /// - Focus mode (web excluded)
  /// - Audio toggle (video modes only)
  /// - Orientation lock (always shown)
  /// - Camera flip (always shown)
  ///
  /// Below the toolbar, the expandable panels are rendered: [flash],
  /// [flip], [focus], and [exposure]. Only one panel can be open at a
  /// time — opening one closes the others.
  @protected
  Widget control() {
    return Container(
      padding: EdgeInsets.all(2),
      margin: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24)
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InfoButton(
                icon: Icon(Icons.flash_on, color: commonColor),
                onPressed: _onFlashModeButtonPressed,
              ),
              // The exposure and focus mode are currently not supported on the web.
              if(parent.isWeb.isFalse) ...[
                InfoButton(
                  icon: Icon(Icons.exposure, color: commonColor),
                  onPressed: _onExposureModeButtonPressed,
                ),
                InfoButton(
                  icon: Icon(Icons.filter_center_focus, color: commonColor),
                  onPressed: _onFocusModeButtonPressed,
                ),
              ],
              if(_showVideo) ...[
                InfoButton(
                  icon: Icon(
                    _enableAudio ? Icons.volume_up : Icons.volume_mute,
                    color: commonColor
                  ),
                  onPressed: _onAudioModeButtonPressed,
                )
              ],
              InfoButton(
                icon: Icon(
                  _isCaptureOrientationLocked ? Icons.screen_lock_rotation : Icons.screen_rotation,
                  color: commonColor
                ),
                onPressed: _onCaptureOrientationLockButtonPressed,
              ),
              InfoButton(
                icon: Icon(Icons.flip_camera_android, color: commonColor),
                onPressed: _onFlipCameraButtonPressed,
              ),
            ],
          ),
          flash(),
          flip(),
          focus(),
          exposure(),
        ],
      )
    );
  }

  /// Builds the exposure mode control panel.
  ///
  /// Renders a [SizeTransition] that expands/collapses the exposure
  /// options. Contains:
  /// - An "Exposure Mode" label
  /// - AUTO and LOCKED buttons with the active mode highlighted
  /// - A RESET OFFSET button (only shown when [_hasOffset] is `true`)
  /// - An exposure offset slider (only shown when [_hasOffset] is `true`)
  ///   with min/max labels and a [Slider] for adjusting the offset
  ///
  /// Long-pressing the AUTO button resets the exposure point via
  /// [_handleExposurePointReset].
  @protected
  Widget exposure() {
    final ButtonStyle styleAuto = TextButton.styleFrom(foregroundColor: active(_exposure == ExposureMode.auto));
    final ButtonStyle styleLocked = TextButton.styleFrom(foregroundColor: active(_exposure == ExposureMode.locked));

    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: Column(
        children: <Widget>[
          Center(
            child: TextBuilder(
              text: 'Exposure Mode',
              color: commonColor
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
                style: styleAuto,
                onPressed: () => _onSetExposureModeButtonPressed(ExposureMode.auto),
                onLongPress: _handleExposurePointReset,
                child: const Text('AUTO'),
              ),
              TextButton(
                style: styleLocked,
                onPressed: () => _onSetExposureModeButtonPressed(ExposureMode.locked),
                child: const Text('LOCKED'),
              ),
              if(hasOffset) ...[
                TextButton(
                  style: styleLocked,
                  onPressed: _handleExposureOffsetReset,
                  child: const Text('RESET OFFSET'),
                ),
              ]
            ],
          ),
          if(hasOffset) ...[
            Spacing.vertical(20),
            Center(
              child: TextBuilder(
                text: 'Exposure Offset',
                color: commonColor
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextBuilder(
                  text: _minAvailableExposureOffset.toString(),
                  color: commonColor
                ),
                Slider(
                  value: _currentExposureOffset,
                  min: _minAvailableExposureOffset,
                  max: _maxAvailableExposureOffset,
                  label: _currentExposureOffset.toString(),
                  onChanged: _handleExposureOffsetChanged,
                ),
                TextBuilder(
                  text: _maxAvailableExposureOffset.toString(),
                  color: commonColor
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  /// Builds the flash mode control panel.
  ///
  /// Renders a [SizeTransition] containing a row of [IconButton]s for
  /// each [FlashMode] value (off, always, auto, torch). The currently
  /// active flash mode is highlighted with [activeFlashColor]; inactive
  /// modes use [inActiveFlashColor]. Tapping a mode calls [_setFlash]
  /// to apply it.
  @protected
  Widget flash() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: FlashMode.values.map((mode) {
            IconData icon;
            switch(mode) {
              case FlashMode.off:
                icon = Icons.flash_off;
                break;
              case FlashMode.always:
                icon = Icons.flash_on;
                break;
              case FlashMode.auto:
                icon = Icons.flash_auto;
                break;
              case FlashMode.torch:
                icon = Icons.highlight;
                break;
            }

            return IconButton(
              icon: Icon(icon),
              color: _flashMode == mode ? activeFlashColor : inActiveFlashColor,
              onPressed: () => _setFlash(mode),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Builds the camera flip control panel.
  ///
  /// Renders a [SizeTransition] containing a row of [InfoButton]s for
  /// each available camera in [_cameras]. Each button shows the camera
  /// lens icon (front/rear/external) and a label. The currently active
  /// camera is highlighted with [activeColor]. If no cameras are
  /// available, a "No camera found" message is displayed. Tapping a
  /// camera calls [_onCameraChanged] to switch to it.
  @protected
  Widget flip() {
    if (_cameras.isEmpty) {
      return Center(
        child: TextBuilder(
          text: "No camera found",
          color: commonColor
        )
      );
    } else {
      return SizeTransition(
        sizeFactor: _flipCameraControlRowAnimation,
        child: ClipRect(
          child: Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _cameras.map((camera) {
              IconData getCameraLensIcon(CameraLensDirection direction) {
                switch (direction) {
                  case CameraLensDirection.back:
                    return Icons.camera_rear;
                  case CameraLensDirection.front:
                    return Icons.camera_front;
                  case CameraLensDirection.external:
                    return Icons.camera;
                }
                // This enum is from a different package, so a new value could be added at
                // any time. The example should keep working if that happens.
                // ignore: dead_code
                return Icons.camera;
              }

              CameraDescription current = _description;
              bool isCurrent = camera.lensDirection == current.lensDirection;

              return InfoButton(
                icon: Column(
                  children: [
                    Icon(
                      getCameraLensIcon(camera.lensDirection),
                      color: active(isCurrent)
                    ),
                    TextBuilder(
                      text: "${camera.lensDirection.name.capitalizeEach} Camera",
                      color: active(isCurrent)
                    )
                  ],
                ),
                onPressed: () => _onCameraChanged(camera),
              );
            }).toList()
          )
        ),
      );
    }
  }

  /// Builds the focus mode control panel.
  ///
  /// Renders a [SizeTransition] containing AUTO and LOCKED buttons for
  /// [FocusMode]. The active mode is highlighted with [activeColor].
  /// Long-pressing the AUTO button resets the focus point via
  /// [_handleFocusPointReset].
  @protected
  Widget focus() {
    final ButtonStyle styleAuto = TextButton.styleFrom(foregroundColor: active(_focus == FocusMode.auto));
    final ButtonStyle styleLocked = TextButton.styleFrom(foregroundColor: active(_focus == FocusMode.locked));

    return SizeTransition(
      sizeFactor: _focusModeControlRowAnimation,
      child: Column(
        children: <Widget>[
          Center(
            child: TextBuilder(
              text: 'Focus Mode',
              color: commonColor
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
                style: styleAuto,
                onPressed: () => _onSetFocusModeButtonPressed(FocusMode.auto),
                onLongPress: _handleFocusPointReset,
                child: const Text('AUTO'),
              ),
              TextButton(
                style: styleLocked,
                onPressed: () => _onSetFocusModeButtonPressed(FocusMode.locked),
                child: const Text('LOCKED'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the photo-only capture button.
  ///
  /// Renders a single circular button with [cameraIcon] that calls
  /// [_takePhoto] on press. Used when [MultimediaCameraConfiguration.showOnlyPhoto]
  /// is `true`.
  @protected
  Widget onlyPhoto() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          margin: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            shape: BoxShape.circle
          ),
          child: InfoButton(
            onPressed: _takePhoto,
            icon: Icon(
              cameraIcon,
              size: actionIconSize,
              color: commonColor
            )
          ),
        )
      ],
    );
  }

  /// Builds the video-only recording button (idle state).
  ///
  /// Renders a single circular button with [videoIcon] that calls
  /// [_recordVideo] on press. Used when video-only mode is active and
  /// no recording is in progress.
  @protected
  Widget onlyVideo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          margin: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            shape: BoxShape.circle
          ),
          child: IconButton(
            onPressed: _recordVideo,
            icon: Icon(
              videoIcon,
              size: actionIconSize,
              color: commonColor
            )
          ),
        )
      ],
    );
  }

  /// Builds the combined photo + video button row (idle state).
  ///
  /// Renders two side-by-side buttons in a rounded container: one for
  /// photo capture ([_takePhoto]) and one for video recording
  /// ([_recordVideo]). Used when both photo and video modes are enabled
  /// (the default).
  @protected
  Widget combined() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(4),
          margin: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(24)
          ),
          child: Row(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _takePhoto,
                icon: Icon(
                  cameraIcon,
                  size: actionIconSize,
                  color: commonColor
                )
              ),
              IconButton(
                onPressed: _recordVideo,
                icon: Icon(
                  videoIcon,
                  size: actionIconSize,
                  color: commonColor
                )
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the paused recording view.
  ///
  /// Renders three sections in a row:
  /// 1. A [CircularProgressIndicator] showing the elapsed time as a
  ///    fraction of [MultimediaCameraConfiguration.maxDuration].
  /// 2. Resume ([_continueRecording]) and stop ([_stopRecording]) buttons
  ///    colored with [pausedColor].
  /// 3. A [HeartBeating] animation around the elapsed time text
  ///    ([_videoDuration]) in [pausedColor].
  ///
  /// Shown when video-only mode is active and the recording is paused.
  Widget paused() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          backgroundColor: progressBackgroundColor,
          valueColor: progressValueColor,
          value: _recordDuration.divideBy(parent.maxDuration),
          color: progressColor,
          strokeCap: progressStrokeCap,
          strokeWidth: progressStrokeWidth,
        ),
        Row(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _continueRecording,
              icon: Icon(
                Icons.videocam_rounded,
                size: actionIconSize,
                color: pausedColor
              )
            ),
            IconButton(
              onPressed: _stopRecording,
              icon: Icon(
                Icons.stop_circle_rounded,
                size: actionIconSize,
                color: pausedColor
              )
            ),
          ],
        ),
        HeartBeating(
          child: TextBuilder(
            text: _videoDuration,
            size: Sizing.font(16),
            color: pausedColor
          ),
        )
      ],
    );
  }

  /// Builds the active recording view.
  ///
  /// Renders three sections in a row:
  /// 1. A [CircularProgressIndicator] showing the elapsed time as a
  ///    fraction of [MultimediaCameraConfiguration.maxDuration].
  /// 2. Pause ([_pauseRecording]) and stop ([_stopRecording]) buttons
  ///    colored with [recordingColor].
  /// 3. A [HeartBeating] animation around the elapsed time text
  ///    ([_videoDuration]) in [recordingColor].
  ///
  /// Shown when video-only mode is active and recording is in progress.
  @protected
  Widget recording() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          backgroundColor: progressBackgroundColor,
          valueColor: progressValueColor,
          value: _recordDuration.divideBy(parent.maxDuration),
          color: progressColor,
          strokeCap: progressStrokeCap,
          strokeWidth: progressStrokeWidth,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _pauseRecording,
              icon: Icon(
                Icons.pause,
                size: actionIconSize,
                color: recordingColor
              )
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: _stopRecording,
              icon: Icon(
                Icons.stop_circle_rounded,
                size: actionIconSize,
                color: recordingColor
              )
            ),
          ],
        ),
        HeartBeating(
          child: TextBuilder(
            text: _videoDuration,
            size: Sizing.font(16),
            color: recordingColor
          ),
        )
      ],
    );
  }
}