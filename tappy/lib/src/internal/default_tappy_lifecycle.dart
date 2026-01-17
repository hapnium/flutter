import '../core/tappy_lifecycle.dart';

/// {@template tappy_controller}
/// A singleton controller for managing notification events in the application.
///
/// The `DefaultTappyLifecycle` provides a centralized way to handle different types
/// of notification events through various stream controllers. These streams
/// allow for listening to events such as notifications received, created,
/// scheduled, tapped, and more.
///
/// This class is designed as a singleton, and only the global instance
/// `tappyController` is exposed for use. Users cannot create additional
/// instances of this class.
///
/// Example usage:
/// ```dart
/// notificationReceivedController.stream.listen((notifier) {
///   // Handle the received notification.
/// });
/// ```
/// 
/// {@endtemplate}
final class DefaultTappyLifecycle extends TappyLifecycle {}