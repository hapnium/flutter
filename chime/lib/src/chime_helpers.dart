import 'package:flutter/foundation.dart';

import 'chime_mixin.dart';

/// {@template chime_helpers}
/// Public helper that exposes Chime mixin APIs in one place.
///
/// The [ChimeHelpers] instance combines [ChimeMixin] and [ChimeInAppMixin] so
/// consumers outside the library can access:
/// - controller streams and event publishing
/// - in-app notification helpers
/// - dismissal utilities and convenience methods
///
/// This is useful when you want a single, simple entry point instead of mixing
/// in multiple classes yourself. It delegates to the active controller and
/// in-app notifier configured by `ChimeApplication` or `Chime` setters.
///
/// ### Example
/// ```dart
/// // Publish an event.
/// await chime.publishEvent(
///   NotificationReceivedEvent(
///     ChimeNotification(
///       id: 1,
///       action: 'sync',
///       input: '',
///       identifier: 'sync:1',
///     ),
///     response: response,
///   ),
/// );
///
/// // Show an in-app notification.
/// await chime.showInAppSuccessNotification(
///   title: 'Saved',
///   message: 'Your changes were saved',
/// );
/// ```
/// {@endtemplate}
@internal
final class ChimeHelpers with ChimeMixin, ChimeInAppMixin {}

/// {@macro chime_helpers}
final ChimeHelpers chime = ChimeHelpers();