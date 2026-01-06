/// The core library for the **Tappy Notification Framework**, a unified interface for
/// managing local and in-app notifications across Android and iOS platforms.
///
/// The `tappy` library offers a complete, modular system for building highly interactive
/// and customizable notifications. It is designed to provide app developers with tools to:
///
/// - Display structured, categorized local notifications.
/// - Handle in-app notifications while the app is active.
/// - Track notification interactions (e.g., taps, dismissals).
/// - Integrate seamlessly with both Material and Cupertino apps.
/// - Configure platform-specific behaviors (icons, sounds, styles, etc.).
///
/// ---
/// ## 📦 Exported Components:
///
/// ### 🔧 Configuration
/// - [`tappy_event.dart`](src/config/tappy_event.dart): Defines supported notification lifecycle events.
/// - [`tappy_sound.dart`](src/config/tappy_sound.dart): Provides platform-specific sound configuration options.
///
/// ### 📄 Models
/// - [`remote_notification_config.dart`](src/models/remote_notification_config.dart): Structures for remote or FCM-compatible notification configuration.
/// - [`in_app_config.dart`](src/models/in_app_config.dart): Settings and behavior definitions for in-app notifications.
/// - Specific typed models for domain-specific notifications:
///   - [`call_notification.dart`](src/models/types/call_notification.dart)
///   - [`trip_notification.dart`](src/models/types/trip_notification.dart)
///   - [`schedule_notification.dart`](src/models/types/schedule_notification.dart)
///   - [`chat_notification.dart`](src/models/types/chat_notification.dart)
///   - [`transaction_notification.dart`](src/models/types/transaction_notification.dart)
///   - [`nearby_notification.dart`](src/models/types/nearby_notification.dart)
///   - [`blink_notification.dart`](src/models/types/blink_notification.dart)
/// - [`notifier.dart`](src/models/notifier.dart): The core notification payload model used across the framework.
/// - [`tappy_information.dart`](src/models/tappy_information.dart): Metadata configuration for app-specific identity.
///
/// ### 🧩 Enums
/// - [`app.dart`](src/enums/app.dart): Represents the logical role of the application (e.g., user, provider).
/// - [`tappy_platform.dart`](src/enums/tappy_platform.dart): Supported platforms (Android, iOS).
/// - [`in_app_style.dart`](src/enums/in_app_style.dart): UI styles for in-app notifications.
/// - [`in_app_state.dart`](src/enums/in_app_state.dart): Defines the current visibility state of the in-app notification.
/// - [`tappy_type.dart`](src/enums/tappy_type.dart): Enum to identify different types of notifications.
///
/// ### 🧪 Extensions
/// - [`tappy_event_extension.dart`](src/extensions/tappy_event_extension.dart): Enhancements for Tappy event handling.
/// - [`tappy_type_extension.dart`](src/extensions/tappy_type_extension.dart): Utilities and conversions for `TappyType`.
///
/// ### ⚠️ Exception
/// - [`tappy_exception.dart`](src/exception/tappy_exception.dart): Custom exception for improper usage or lifecycle violations.
///
/// ### 🧠 Core System
/// - [`tappy_application.dart`](src/tappy_application.dart): The root widget to initialize and configure Tappy.
/// - [`tappy_mixin.dart`](src/tappy_mixin.dart): A mixin to simplify notification stream access in widgets.
/// - [`tappy_lifecycle.dart`](src/tappy_lifecycle.dart): Abstract class to respond to lifecycle notification events (e.g., `onTapped`, `onCreated`).
/// - [`tappy.dart`](src/tappy.dart): Singleton controller and utility handler for notification processing.
/// - [`tappy_controller.dart`](src/tappy_controller.dart): Internal stream controller and notification state manager.
/// - [`device_notification.dart`](src/device_notification.dart): Interface for creating and displaying platform notifications.
/// - [`device_notification_builder.dart`](src/device_notification_builder.dart): Responsible for building styled notifications from models.
/// - [`device_notification_manager.dart`](src/device_notification_manager.dart): Used to manage active notifications (dismiss, group, etc.).
/// - [`in_app_notification.dart`](src/in_app_notification.dart): Interface for displaying in-app banners or overlays.
/// - [`tappy_interface.dart`](src/tappy_interface.dart): Shared base class used by `Tappy` to access services and enforce configuration.
///
/// ---
/// ## ✅ Usage Example:
/// ```dart
/// import 'package:tappy/tappy.dart';
///
/// void main() {
///   runApp(
///     TappyApplication(
///       app: AppInfo(
///         androidIcon: 'ic_notification',
///         app: TappyApp.user,
///       ),
///       platform: TappyPlatform.ANDROID,
///       child: MaterialApp(home: MyHomePage()),
///     ),
///   );
/// }
/// ```
///
/// ---
/// ## 💡 Notes:
/// - The `TappyApplication` widget **must wrap** your root app to properly initialize the framework.
/// - This library is designed to abstract both **Flutter Local Notifications** and **in-app messaging**, allowing a single point of configuration.
///
/// ---
///
/// {@category Notification}
library;

/// CONFIG
export 'src/config/tappy_event.dart';
export 'src/config/tappy_sound.dart';

/// MODELS
export 'src/models/remote_notification_config.dart';
export 'src/models/in_app_config.dart';

export 'src/models/types/call_notification.dart';
export 'src/models/types/trip_notification.dart';
export 'src/models/types/schedule_notification.dart';
export 'src/models/types/chat_notification.dart';
export 'src/models/types/transaction_notification.dart';
export 'src/models/types/nearby_notification.dart';
export 'src/models/types/blink_notification.dart';

export 'src/models/notifier.dart';
export 'src/models/tappy_information.dart';

/// ENUMS
export 'src/enums/app.dart';
export 'src/enums/tappy_platform.dart';
export 'src/enums/in_app_style.dart';
export 'src/enums/in_app_state.dart';
export 'src/enums/tappy_type.dart';

/// EXTENSIONS
export 'src/extensions/tappy_event_extension.dart';
export 'src/extensions/tappy_type_extension.dart';

/// EXCEPTION
export 'src/exception/tappy_exception.dart';

/// CORE
export 'src/tappy_application.dart';
export 'src/controller/tappy_mixin.dart';
export 'src/tappy_lifecycle.dart';
export 'src/tappy.dart';
export 'src/controller/tappy_controller.dart';
export 'src/device_notification.dart';
export 'src/device_notification_builder.dart';
export 'src/device_notification_manager.dart';
export 'src/in_app_notification.dart';
export 'src/tappy_interface.dart';
