part of 'tappy_application.dart';

class _TappyApplicationState extends State<TappyApplication> {
  InAppConfiguration _config = InAppConfiguration();

  @override
  void initState() {
   _init();

    super.initState();
  }

  void _init() {
    // Initialize dependencies.
    Tappy.platform = widget.platform;
    Tappy.appInformation = widget.info;
    Tappy.lifecycle = widget.lifecycle ?? DefaultTappyLifecycle();
    Tappy.showLogs = widget.showLog;
    Tappy.inAppNotificationService = widget.inAppNotificationService ?? DefaultInAppNotification();

    // Skip initialization for web platforms.
    if (PlatformEngine.isWeb && widget.skipDeviceNotificationInitializationOnWeb) {
      /// Skip
    } else {
      Tappy.deviceNotificationBuilder = widget.deviceNotificationBuilder ?? DefaultDeviceNotificationBuilder();
      Tappy.deviceNotificationManager = widget.deviceNotificationManager ?? DefaultDeviceNotificationManager();
      Tappy.deviceNotificationService = widget.deviceNotificationService ?? DefaultDeviceNotification();
      Tappy.deviceNotificationService.init(widget.handler, widget.backgroundHandler);

      // Handle app launches triggered by notifications.
      Tappy.deviceNotificationService.onAppLaunchedByNotification((note) {
        process(widget.onLaunchedByNotification, onProcess: (value) => value(note));
      });
    }

    // Update the notification permission status.
    process(widget.onPermitted, onProcess: (value) async => value(await Tappy.deviceNotificationService.isPermitted));
  }

  @override
  void didUpdateWidget(covariant TappyApplication oldWidget) {
    if(widget.inAppConfigurer != oldWidget.inAppConfigurer) {
      _init();
      setState(() {});
    }

    if(widget.handler != oldWidget.handler || widget.backgroundHandler != oldWidget.backgroundHandler) {
      Tappy.deviceNotificationService.init(widget.handler, widget.backgroundHandler);
    }

    if(widget.onLaunchedByNotification != oldWidget.onLaunchedByNotification) {
      Tappy.deviceNotificationService.onAppLaunchedByNotification((note) {
        process(widget.onLaunchedByNotification, onProcess: (value) => value(note));
      });
    }

    if(widget.onPermitted != oldWidget.onPermitted) {
      process(widget.onPermitted, onProcess: (value) async => value(await Tappy.deviceNotificationService.isPermitted));
    }

    if(widget.info != oldWidget.info || widget.platform != oldWidget.platform) {
      Tappy.appInformation = widget.info;
      Tappy.platform = widget.platform;
    }

    if(widget.showLog != oldWidget.showLog) {
      Tappy.showLogs = widget.showLog;
    }

    if(widget.deviceNotificationBuilder != oldWidget.deviceNotificationBuilder) {
      Tappy.deviceNotificationBuilder = widget.deviceNotificationBuilder ?? DefaultDeviceNotificationBuilder();
    }

    if(widget.deviceNotificationManager != oldWidget.deviceNotificationManager) {
      Tappy.deviceNotificationManager = widget.deviceNotificationManager ?? DefaultDeviceNotificationManager();
    }

    if(widget.deviceNotificationService != oldWidget.deviceNotificationService) {
      Tappy.deviceNotificationService = widget.deviceNotificationService ?? DefaultDeviceNotification();
    }

    if(widget.inAppNotificationService != oldWidget.inAppNotificationService) {
      Tappy.inAppNotificationService = widget.inAppNotificationService ?? DefaultInAppNotification();
    }

    if(widget.lifecycle != oldWidget.lifecycle) {
      Tappy.lifecycle = widget.lifecycle ?? DefaultTappyLifecycle();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    ToastificationConfig c = ToastificationConfigProvider.maybeOf(context)?.config ?? const ToastificationConfig();

    if(widget.inAppConfigurer case final configurer?) {
      InAppConfiguration built = configurer(_config);

      c = c.copyWith(
        alignment: built.alignment,
        itemWidth: built.itemWidth,
        clipBehavior: built.clipBehavior,
        animationDuration: built.animationDuration,
        animationBuilder: built.animationBuilder,
        marginBuilder: built.marginBuilder,
        applyMediaQueryViewInsets: built.applyMediaQueryViewInsets,
      );

      setState(() {
        _config = built;
      });
    }

    return ToastificationWrapper(
      config: c,
      child: widget.child,
    );
  }
}