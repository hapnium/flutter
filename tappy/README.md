# tappy

**Local + in-app notifications** for Flutter using **`flutter_local_notifications`**, **`toastification`**, **`fluttertoast`**, and **`timezone`**. The app must be wrapped with **`TappyApplication`**. The global **`Tappy`** singleton (private class **`_Tappy`**) extends **`TappyInterface`** and owns **`handleNotificationResponse`**.

**Import:** `package:tappy/tappy.dart`

---

## Architecture

| Component | Responsibility |
|-----------|------------------|
| **`TappyApplication`** | Injects default or custom **`DeviceNotification`**, **`DeviceNotificationBuilder`**, **`DeviceNotificationManager`**, **`InAppNotification`**; calls **`Tappy.*` setters**; initializes plugin + **`ToastificationWrapper`**. |
| **`Tappy` (`_Tappy`)** | Singleton; **`handleNotificationResponse`** parses **`NotificationResponse` → `Notifier`** via **`TappyType.parse`**, optional tap **`handler`**, then **`lifecycle.onTapped`**. |
| **`TappyInterface`** | Holds **`controller`**, getters for device/in-app services (throw **`TappyException`** if not initialized). |
| **`TappyController`** | Singleton **`TappyController.instance`**; broadcast streams + buffers for created/tapped **`Notifier`**s. |
| **`TappyMixin`** | Exposes **`controller`** and **`createdStream`**, **`tappedStream`**, **`receivedStream`**, **`scheduledStream`**, **`inAppStream`**, **`launchedAppStream`**. |
| **`TappyLifecycle`** | App hooks (e.g. **`onTapped`**) — provide custom impl or use **`DefaultTappyLifecycle`**. |

Typed **`Notifier`** subclasses live under **`src/models/types/`** (call, chat, trip, schedule, transaction, nearby, blink, …). **`TappyType.parse`** maps payload → **`Notifier`**.

---

## `TappyApplication` — constructor reference

| Parameter | Type | Purpose |
|-----------|------|---------|
| **`child`** | `Widget` | Typically **`MaterialApp`**. |
| **`info`** | **`TappyInformation`** | **`androidIcon`**, **`TappyApp`** role, optional **`iosIcon`**. |
| **`platform`** | **`TappyPlatform`** | **`ANDROID`** / **`IOS`**. |
| **`showLog`** | `bool` | Verbose init (default `true`). |
| **`skipDeviceNotificationInitializationOnWeb`** | `bool` | Skip device plugin on web (default `true`). |
| **`lifecycle`** | **`TappyLifecycle?`** | Custom lifecycle; else default. |
| **`deviceNotificationBuilder`** | **`DeviceNotificationBuilderInterface?`** | Build notifications from **`RemoteNotificationConfig`**. |
| **`deviceNotificationManager`** | **`DeviceNotificationManagerInterface?`** | Dismiss by id/channel/group/all. |
| **`deviceNotificationService`** | **`DeviceNotificationInterface?`** | Permission + **`init`** + launch callbacks. |
| **`inAppNotificationService`** | **`InAppNotificationInterface?`** | Toastification-backed in-app UI. |
| **`onPermitted`** | **`PermissionCallback?`** | `void Function(bool granted)`. |
| **`onLaunchedByNotification`** | **`NotificationTapHandler?`** | Cold start from notification. |
| **`handler`** | **`NotificationTapHandler?`** | Foreground tap handling. |
| **`backgroundHandler`** | **`NotificationResponseHandler?`** | Must be a **`@pragma('vm:entry-point')`** top-level function for background isolate. |
| **`inAppConfigurer`** | **`InAppNotificationConfigurer?`** | Adjust in-app / toast config. |

After **`runApp(TappyApplication(...))`**, use **`Tappy.deviceNotificationService`**, **`Tappy.inAppNotificationService`**, **`Tappy.deviceNotificationManager`**, **`Tappy.deviceNotificationBuilder`**, **`Tappy.lifecycle`**, **`Tappy.appInformation`**, **`Tappy.platform`**.

---

## `Tappy` — methods and inherited getters

**Direct call:**

| Method | Description |
|--------|-------------|
| **`handleNotificationResponse(NotificationResponse response, {NotificationTapHandler? handler})`** | Parses response → **`Notifier`**, runs optional **`handler`**, then **`lifecycle.onTapped(notifier)`**. |

**From `TappyInterface` (same singleton):**

| Getter | Returns |
|--------|---------|
| **`controller`** | **`TappyController.instance`**. |
| **`deviceNotificationService`** | **`DeviceNotificationInterface`** — **`requestPermission`**, **`isPermitted`**, **`init`**, **`onAppLaunchedByNotification`**. |
| **`inAppNotificationService`** | **`InAppNotificationInterface`**. |
| **`deviceNotificationManager`** | **`DeviceNotificationManagerInterface`**. |
| **`deviceNotificationBuilder`** | **`DeviceNotificationBuilderInterface`**. |
| **`lifecycle`** | **`TappyLifecycle`**. |
| **`appInformation`** | **`TappyInformation`**. |
| **`platform`** | **`TappyPlatform`**. |

---

## Device notifications

### `DeviceNotificationInterface` (see `device_notification.dart`)

| Method | Purpose |
|--------|---------|
| **`requestPermission()`** | `Future<bool>` — platform permission prompt. |
| **`isPermitted`** | `Future<bool>` — current permission state. |
| **`init(NotificationTapHandler? handler, NotificationResponseHandler? backgroundHandler)`** | Wire tap handlers + plugin init. |
| **`onAppLaunchedByNotification(NotificationTapHandler)`** | Register cold-start handler. |

Default implementation: **`DefaultDeviceNotification`** — uses shared **`FlutterLocalNotificationsPlugin`** instance, Android icon from **`TappyInformation.androidIcon`**.

### `DeviceNotificationBuilderInterface`

| Method | Purpose |
|--------|---------|
| **`build(RemoteNotificationConfig<T> config)`** | Turn server/FCM-style **`RemoteNotificationConfig`** into a displayed notification (your implementation). |

Use this when remote payloads need consistent mapping to channels, actions, and **`Notifier`** payloads.

### `DeviceNotificationManagerInterface`

| Method | Purpose |
|--------|---------|
| **`dismissById(int id)`** | Cancel one notification. |
| **`dismissAll()`** | Clear all. |
| **`dismissChannelNotifications(String channel)`** | By Android channel id. |
| **`dismissGroupedNotifications(String groupKey)`** | By group key (Android). |

---

## In-app notifications — `InAppNotificationInterface`

All toast-style methods use **`InAppNotificationCallback`** = `void Function(String id)` for optional lifecycle hooks.

| Method | Description |
|--------|-------------|
| **`success({title, required message, duration, position, onTapped, onClosed, onCompleted, onDismissed})`** | Success toast. |
| **`error(...)`** | Error toast. |
| **`info(...)`** | Info toast. |
| **`warn(...)`** | Warning toast. |
| **`tip({color, required message, duration, textColor})`** | Short **`Fluttertoast`**. |
| **`custom({duration, required Widget content, position, ...})`** | Custom widget toast. |
| **`dismissInAppNotification({required String id})`** | Dismiss by toast id; semantics depend on implementation (**`id.isEmpty`** may mean dismiss all — see **`DefaultInAppNotification`**). |

Example after init:

```dart
Tappy.inAppNotificationService.info(message: 'Profile updated');
```

---

## `TappyController` streams and buffers

| Stream | When it fires |
|--------|----------------|
| **`receivedController.stream`** | Notification received. |
| **`createdController.stream`** | Notification created. |
| **`inAppReceivedController.stream`** | In-app notification. |
| **`scheduledController.stream`** | Scheduled. |
| **`launchedAppController.stream`** | App opened from notification. |
| **`tappedController.stream`** | User tapped notification. |

**`TappyMixin`** aliases these as **`receivedStream`**, **`createdStream`**, etc.

Buffer APIs: **`getTappedNotifications()`**, **`getCreatedNotifications()`**, **`flushCreatedNotifications`**, **`flushPendingTappedNotifications`** (see full **`tappy_controller.dart`**).

---

## Background taps

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tappy/tappy.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  Tappy.handleNotificationResponse(response, handler: (notifier) {
    // Runs in background isolate constraints
  });
}
```

Pass **`backgroundHandler: notificationTapBackground`** into **`TappyApplication`**.

---

## Installation (private monorepo)

```yaml
dependencies:
  tappy:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: tappy
```

---

## License

See [LICENSE](LICENSE) in this package directory.
