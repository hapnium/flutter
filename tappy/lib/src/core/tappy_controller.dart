import 'dart:async';
import 'dart:collection';

import '../models/notifier.dart';

/// {@template tappy_controller}
/// A singleton controller for managing notification events in the application.
///
/// The `TappyController` provides a centralized way to handle different types
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
final class TappyController {
  /// The private constructor for the class.
  /// 
  /// {@macro tappy_controller}
  TappyController._internal();

  /// The singleton instance of the class.
  static final TappyController _instance = TappyController._internal();

  /// Allows internal access for adding tapped notifications.
  static TappyController get instance => _instance;

  /// Stream controller for notifications received.
  ///
  /// Emits events when a notification is received.
  final StreamController<Notifier> receivedController = StreamController.broadcast();

  /// Stream controller for notifications created.
  ///
  /// Emits events when a notification is created.
  final StreamController<Notifier> createdController = StreamController.broadcast();

  /// Stream controller for in-app notifications received.
  ///
  /// Emits events when an in-app notification is received.
  final StreamController<Notifier> inAppReceivedController = StreamController.broadcast();

  /// Stream controller for notifications scheduled.
  ///
  /// Emits events when a notification is scheduled.
  final StreamController<Notifier> scheduledController = StreamController.broadcast();

  /// Stream controller for app launches triggered by notifications.
  ///
  /// Emits events when the app is launched by tapping a notification.
  final StreamController<Notifier> launchedAppController = StreamController.broadcast();

  /// Stream controller for tapped notifications.
  ///
  /// Emits events when a notification is tapped.
  final StreamController<Notifier> tappedController = StreamController.broadcast();

  // Internal buffer to store created notifications when no listeners are active.
  final List<Notifier> _createdNotifications = [];

  // Internal buffer to store tapped notifications when no listeners are active.
  final List<Notifier> _tappedNotifications = [];

  /// List of tapped notifications
  /// 
  /// Returns a list of [Notifier] objects that have been tapped.
  List<Notifier> getTappedNotifications() => UnmodifiableListView(_tappedNotifications);

  /// List of created notifications
  /// 
  /// Returns a list of [Notifier] objects that have been created.  
  List<Notifier> getCreatedNotifications() => UnmodifiableListView(_createdNotifications);

  /// Checks whether a notification has already been created.
  ///
  /// - **notifier**: The notification to verify.
  ///
  /// Helps avoid showing duplicate notifications by checking internal records.
  bool hasCreatedNotification(Notifier notifier) => _createdNotifications.any((c) => c.foreign == notifier.foreign);

  /// Adds a newly created [Notifier] to the internal list.
  ///
  /// - **notifier**: The notification that was created.
  ///
  /// Prevents the same notification from being created multiple times.
  void addCreated(Notifier notifier) {
    _createdNotifications.add(notifier);
  }

  /// Removes a created [Notifier] from the internal list.
  ///
  /// - **foreign**: Optional foreign key identifier. *(Default: null)*
  /// - **id**: Optional notification ID. *(Default: null)*
  ///
  /// This ensures the notification can be recreated or ignored in future processing.
  void removeCreated({String? foreign, int? id}) {
    assert(foreign != null || id != null, "Either foreign or id must be provided");

    _createdNotifications.removeWhere((n) => (foreign != null && n.foreign == foreign) || (id != null && n.id == id));
  }

  /// Removes a tapped [Notifier] from the internal list.
  ///
  /// - **foreign**: Optional foreign key identifier. *(Default: null)*
  /// - **id**: Optional notification ID. *(Default: null)*
  ///
  /// Useful for clearing a tapped notification once it's been processed.
  void removeTapped({String? foreign, int? id}) {
    assert(foreign != null || id != null, "Either foreign or id must be provided");

    _tappedNotifications.removeWhere((n) => (foreign != null && n.foreign == foreign) || (id != null && n.id == id));
  }

  /// Flushes all created notifications and exposes them.
  ///
  /// Should be used to release or clear internal state after processing.
  void flushCreatedNotifications() {
    for (final notifier in _createdNotifications) {
      createdController.add(notifier);
    }

    _createdNotifications.clear();
  }

  
  /// Flushes all pending tapped notifications and exposes them to listeners.
  ///
  /// Should be called when a listener becomes available to consume pending interactions.
  void flushPendingTappedNotifications() {
    for (final notifier in _tappedNotifications) {
      tappedController.add(notifier);
    }

    _tappedNotifications.clear();
  }
  
  /// Adds a tapped [Notifier] to the internal list.
  ///
  /// - **notifier**: The notification instance that was tapped.
  ///
  /// Used when the user interacts with the notification.
  void addTapped(Notifier notifier) {
    _tappedNotifications.add(notifier);
  }
}