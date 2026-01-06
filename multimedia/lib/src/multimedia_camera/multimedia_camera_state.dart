part of 'multimedia_camera.dart';

class _MultimediaCameraState extends State<MultimediaCamera> with WidgetsBindingObserver, TickerProviderStateMixin, RestorationMixin {
  CameraController? _controller;
  late MultimediaCameraConfiguration parent;

  final RestorableCameraController _resController = RestorableCameraController();
  
  /// List of cameras
  List<CameraDescription> _cameras = [];

  ///
  double _currentScale = 1.0;

  ///
  double _baseScale = 1.0;

  /// Tell the current flash mode
  FlashMode _flashMode = FlashMode.off;

  /// Exposure mode
  ExposureMode _exposure = ExposureMode.auto;

  /// Exposure offset
  double _currentExposureOffset = 0.0;

  /// Focus mode
  FocusMode _focus = FocusMode.auto;

  /// Current camera description
  CameraDescription _description = CameraDescription(
    name: "camera 0",
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 270
  );

  double _minAvailableExposureOffset = 0.0;

  double _maxAvailableExposureOffset = 0.0;

  double _minAvailableZoom = 1.0;

  double _maxAvailableZoom = 1.0;

  /// Enable audio
  bool _enableAudio = false;

  /// Orientation lock
  bool _isCaptureOrientationLocked = false;

  /// Tell whether the user is recording a video
  bool _isRecording = false;

  /// Tell whether the video recording was paused
  bool _isPausedRecording = false;

  bool _isFetching = false;

  /// Video recording duration
  int _recordDuration = 0;

  /// Video time in minutes and seconds
  String _videoDuration = "00:00";

  /// Tell if the camera is initialized
  bool _isCameraInitialized = false;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  ///
  Timer? _timer;

  /// Whether to show video
  late bool _showVideo;

  /// Whether to showPhoto
  late bool _showPhoto;

  late final AnimationController _flashModeControlRowAnimationController;
  late final CurvedAnimation _flashModeControlRowAnimation;
  late final AnimationController _flipCameraControlRowAnimationController;
  late final CurvedAnimation _flipCameraControlRowAnimation;
  late final AnimationController _exposureModeControlRowAnimationController;
  late final CurvedAnimation _exposureModeControlRowAnimation;
  late final AnimationController _focusModeControlRowAnimationController;
  late final CurvedAnimation _focusModeControlRowAnimation;

  @protected
  MultimediaLayoutConfiguration get layoutConfig => parent.layoutConfiguration ?? MultimediaLayoutConfiguration();
  
  @override
  String? get restorationId => 'multimedia_camera_state';

  @protected
  bool get hasOffset => _minAvailableExposureOffset.notEquals(_maxAvailableExposureOffset);

  @protected
  Color? get staleColor => parent.staleColor ?? Theme.of(context).bottomAppBarTheme.color;

  @protected
  Color get activeColor => parent.activeColor ?? Colors.green;

  @protected
  Color get inActiveColor => parent.inActiveColor ?? Color(0xffF1F1F1);

  @protected
  Color active(bool value) => value ? activeColor : inActiveColor;

  @protected
  Color get commonColor => parent.commonColor ?? Color(0xffFFFFFF);

  @protected
  Color get activeFlashColor => parent.activeFlashColor ?? Color(0xffFF9E53);

  @protected
  Color get inActiveFlashColor => parent.inActiveFlashColor ?? Color(0xff06C270);

  @protected
  Color get pausedColor => parent.pausedColor ?? Color(0xffFF3B3B);

  @protected
  Color get recordingColor => parent.recordingColor ?? Color(0xffFF3B3B);

  @protected
  Color get progressBackgroundColor => parent.progressBackgroundColor ?? Theme.of(context).unselectedWidgetColor;

  @protected
  Animation<Color?> get progressValueColor => parent.progressValueColor ?? AlwaysStoppedAnimation<Color>(Color(0xffFF3B3B));

  @protected
  Color? get progressColor => parent.progressColor;

  @protected
  StrokeCap? get progressStrokeCap => parent.progressStrokeCap;

  @protected
  double get progressStrokeWidth => parent.progressStrokeWidth ?? 4.0;

  @protected
  IconData get cameraIcon => parent.cameraIcon ?? Icons.photo_camera_rounded;

  @protected
  IconData get videoIcon => parent.videoIcon ?? Icons.radio_button_on_rounded;

  @protected
  double get actionIconSize => parent.actionIconSize ?? Sizing.font(40);

  @protected
  CameraDescription? get description => _controller?.description;

  @protected
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if(_controller.isNotNull) {
      registerForRestoration(_resController, 'camera_controller');
    }
  }

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

  void _error(String message, {bool useTip = true}) {
    if(parent.onErrorReceived.isNotNull) {
      parent.onErrorReceived!(message, useTip);
    }
  }

  void _onCameraStateChanged() {
    if(_controller.isNotNull && _controller!.value.isRecordingVideo.isFalse) {
      setState(() {
        _isRecording = false;
        _isPausedRecording = false;
      });
    }
  }


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

  @override
  void dispose() {
    _timer?.cancel();
    _disposeCameraResources();

    super.dispose();
  }

  void _continueRecording() async {
    _startTimer();

    await _controller?.resumeVideoRecording();

    setState(() {
      _isRecording = true;
      _isPausedRecording = false;
    });
  }

  void _pauseRecording() async {
    _timer?.cancel();

    await _controller?.pauseVideoRecording();
    
    setState(() {
      _isRecording = false;
      _isPausedRecording = true;
    });
  }

  void _recordVideo() async {
    if(_isRecording && !_isPausedRecording) {
      _pauseRecording();
    } else if(_isPausedRecording && !_isRecording) {
      _continueRecording();
    } else {
      _startRecording();
    }
  }

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

  void _startRecording() async {
    await _controller?.startVideoRecording();
    _startTimer();

    setState(() {
      _isRecording = true;
    });
  }

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

  void _inform(String message) {
    if(parent.onInfoReceived.isNotNull) {
      parent.onInfoReceived!(message);
    }
  }

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

  void _onAudioModeButtonPressed() {
    setState(() {
      _enableAudio = !_enableAudio;
    });

    if (_controller.isNotNull) {
      _onNewCameraSelected(_controller!.description);
    }
  }

  void _onCameraChanged(CameraDescription? description) {
    if (description.isNull) {
      return;
    }

    _onNewCameraSelected(description!);
  }

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

  void _onSetExposureModeButtonPressed(ExposureMode mode) {
    _setExposureMode(mode).then((_) {
      _inform('Exposure mode set to ${mode.toString().split('.').last}');
    });
  }

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

  void _handleExposurePointReset() {
    if (_controller.isNotNull) {
      _controller!.setExposurePoint(null);
    }
    _inform('Resetting exposure point');
  }

  void _onSetFocusModeButtonPressed(FocusMode mode) {
    _setFocusMode(mode).then((_) {
      _inform('Focus mode set to ${mode.toString().split('.').last}');
    });
  }

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

  void _handleFocusPointReset() {
    if (_controller.isNotNull) {
      _controller!.setFocusPoint(null);
    }
    _inform('Resetting focus point');
  }

  void _handleExposureOffsetChanged(double value) {
    if(_minAvailableExposureOffset.equals(_maxAvailableExposureOffset)) {
      return;
    } else {
      _setExposureOffset(value);
    }
  }

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

  void _handleExposureOffsetReset() {
    if (_controller.isNotNull) {
      _controller!.setExposureOffset(0.0);
    }
    _inform('Resetting exposure offset');
  }

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

  void _handleScaleStart(ScaleStartDetails details) {
    setState(() {
      _baseScale = _currentScale;
    });
  }

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

  /// Camera display
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

  /// Camera Layout Button
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
  /// Camera Mode Control
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

  /// Camera Exposure Mode
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

  /// Camera Flash Mode
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

  /// Camera Flip Mode
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

  /// Camera Focus Mode
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

  /// Show Only Photo Button View
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

  /// Show Only Video Button View
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

  /// Combined photo and video button view
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

  /// The recording view
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