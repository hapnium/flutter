/// Re-export of `package:toastification`.
///
/// Provides the toastification overlay system used by Chime's in-app
/// notification pipeline. This includes [ToastificationItem],
/// [ToastificationType], [ToastificationStyle], [ToastificationBuilder],
/// and the global [toastification] instance for showing, dismissing, and
/// managing toast notifications.
///
/// Import this file when you need direct access to toastification for
/// building custom in-app notification UIs or managing overlay toasts
/// outside of Chime's default notification methods.
library;

export 'package:toastification/toastification.dart';