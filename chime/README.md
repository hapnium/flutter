# chime

Flutter notification stack: **device** notifications (`flutter_local_notifications`), **in-app** toasts (`toastification` / `fluttertoast`), **event routing**, **broadcast streams**, and optional **push-builder** helpers. A global **`Chime`** registry ties **`ChimeController`**, **`ChimeInAppNotification`**, and **`ChimePushNotification`** together.

**Import:** `package:chime/chime.dart`

---

## Concepts (read this first)

| Piece | Role |
|--------|------|
| **`Chime`** | Static registry: holds controller, in-app handler, push handler; **`Chime.mixable`** exposes **`ChimeMixin`** for advanced use. |
| **`ChimeApplication`** | Root widget: calls `Chime.setApplicationName` / `setPlatform`, registers controller & push, wraps child in **`ToastificationWrapper`**. |
| **`ChimeController`** | Streams + **`publishEvent`** + buffers for created/tapped notifications. Default impl is **`DefaultChimeController`** (`@internal`, constructed by **`getController()`** when unset). |
| **`ChimeInAppNotification`** | Contract for success/error/info/warning/custom toasts and **`dismissInAppNotification`**. Default is **`DefaultChimeInAppNotification`** (`@internal`). |
| **`ChimePushNotification`** | Permission + **`initialize`** + launch-from-notification. Default is **`DefaultChimePushNotification`** (`@internal`). |
| **`ChimeMixin`** | Forwards streams, **`publishEvent`**, buffer APIs, and **`FlutterLocalNotificationsPlugin`** helpers (**`dismissById`**, **`dismissAll`**, **`dismissChannelNotifications`**, **`dismissGroupedNotifications`**) to **`Chime.getController()`**. |
| **`ChimePushNotificationBuilder`** | Abstract helper: **`pushChimeNotification`**, **`pushScheduledChimeNotification`**, timezone + sound + vibration helpers for FCM/APNs-style integrations. |

Payload hierarchy (see `chime_notification.dart`):

- **`ChimeNotification`** — `id`, `identifier`, `action`, `input`, `payload` (JSON string), `data` map; **`getPayloadAsJson()`**, **`toJson()`**.
- **`ChimeCreatedNotification`** — adds `title`, `body`, **`NotificationDetails?`** (required for scheduling/showing via plugin).
- **`ChimeScheduledNotification`** — adds **`TZDateTime scheduledDate`**, optional **`AndroidScheduleMode`**, **`DateTimeComponents`**.
- **`ChimeAppNotification`** / **`ChimeCreatedAppNotification`** / **`ChimeCreatedCustomAppNotification`** — in-app / toast-backed types.

Events (**`ChimeEvent`**, `chime_event.dart`): **`NotificationReceivedEvent`** (includes **`NotificationResponse`**, **`isBackgroundNotification`**), **`NotificationCreatedEvent`**, **`NotificationScheduledEvent`**, **`NotificationLaunchedAppEvent`**, **`NotificationTappedEvent`**, **`NotificationClosedEvent`**, **`NotificationDismissedEvent`**, **`NotificationFailedEvent`** (`error`, `stackTrace`).

---

## `Chime` class — static API

| Member | Type | Description |
|--------|------|-------------|
| **`showLogs`** | `bool` | Global flag; **`ChimeMixin.showChimeLogs`** reads this. Components may log when true. |
| **`getController()`** | `ChimeController` | Returns **`_controller`** or a **new `DefaultChimeController`** each time if unset. Prefer **`setController`** once at startup. |
| **`setController(ChimeController c)`** | `void` | Replace controller instance. |
| **`mixable`** | `ChimeMixin` | **`Chime._()`** instance used as mixin host for **`Chime.mixable.dismissAll()`**-style calls (forwards to controller + plugin). |
| **`setApplicationName(String)`** | `void` | Used by push default channel naming / logs; **`getPushNotification`** may update via optional args. |
| **`setPlatform(ChimePlatform)`** | `void` | **`ANDROID`**, **`IOS`**, **`WEB`**. |
| **`setShowLogs(bool)`** | `void` | Sets **`Chime.showLogs`**. |
| **`getInAppNotification()`** | `ChimeInAppNotification` | Returns set instance or **new `DefaultChimeInAppNotification`** per call if unset. |
| **`setChimeInAppNotification(...)`** | `void` | Register custom in-app implementation (e.g. tests or branded UI). |
| **`getPushNotification({applicationName, platform})`** | `ChimePushNotification` | Returns set instance or builds **`DefaultChimePushNotification(_applicationName, _platform)`**, optionally updating name/platform from args. |
| **`setChimePushNotification(...)`** | `void` | Register custom push service. |

---

## `ChimeApplication` widget

Wrap **`MaterialApp`** / **`CupertinoApp`**. In **`initState`** (post-frame), it:

1. **`Chime.setApplicationName`**, **`setPlatform`**, **`setShowLogs`**
2. Uses **`configuration.controller`** or **`DefaultChimeController`**, registers **`configuration.eventListeners`**
3. Unless **`platform == WEB && skipDeviceNotificationInitializationOnWeb`**: creates **`DefaultChimePushNotification`**, **`setChimePushNotification`**, **`initialize`** with **`initializationSettings`**, wires **`onBackgroundNotification`**, **`onLaunchedByNotification`**
4. **`Chime.setController(controller)`**; optional **`setChimeInAppNotification`**

| Parameter | Purpose |
|-----------|---------|
| **`child`** | Your app root. |
| **`applicationName`** | Channel / logging label. |
| **`platform`** | **`ChimePlatform`**. |
| **`configuration`** | **`ChimeConfiguration`**: optional **`controller`**, **`eventListeners`**, **`inAppNotification`**, **`pushNotification`**. |
| **`showLog`** | Passed to **`Chime.setShowLogs`**. |
| **`skipDeviceNotificationInitializationOnWeb`** | Skips plugin init on web (default `true`). |
| **`onPermitted`** | After permission check callback. |
| **`onLaunchedByNotification`** | **`ChimeNotificationCallback`** when app opened from notification. |
| **`onForegroundNotification`** | Passed to **`initialize`** as **`onNotificationTapped`**. |
| **`onBackgroundNotification`** | **`NotificationResponseCallback`**; combined with internal dispatcher **`chimeBackgroundNotificationDispatcher`** (see below). |
| **`inAppConfigurer`** | Mutates **`InAppConfiguration`** for **`ToastificationWrapper`**. |
| **`initializationSettings`** | **`InitializationSettings`** for **`flutter_local_notifications`**. |

**`build`**: merges **`InAppConfiguration`** into **`ToastificationConfig`** and returns **`ToastificationWrapper`**.

---

## `ChimeController` (contract + behavior)

**`ChimeController`** extends **`ChimeStreamable`** and implements **`ChimeEventManager`** + **`ChimeNotificationManager`**.

### Event dispatch — `publishEvent(ChimeEvent event)`

**`DefaultChimeController.publishEvent`**:

1. Notifies all **`ChimeEventListener`**s whose **`supportsChimeEvent`** returns true (`await Future.wait`).
2. Then routes by event type: updates streams / buffers (e.g. **`NotificationCreatedEvent`** → **`emitCreatedNotification`** + append to `_createdNotifications`; **`NotificationTappedEvent`** → emit + buffer; **`NotificationReceivedEvent`** → **`emitReceivedNotification`**, etc.).

Register listeners: **`addChimeEventListener`**, remove: **`removeChimeEventListener`**, **`removeChimeEventListeners`**, **`removeAllChimeEventListeners`**. **`dispose`** closes streams and clears listeners.

### Streams (`ChimeStreamable`)

Each stream is backed by a **broadcast** `StreamController`. Emit helpers only add if **`hasXxxListener()`** is true (except scheduling path also emits created — see **`emitScheduledNotification`**).

| Stream getter | Payload |
|---------------|---------|
| **`getReceivedChimeNotificationStream()`** | `ChimeNotification` |
| **`getCreatedChimeNotificationStream()`** | `ChimeCreatedNotification` |
| **`getScheduledChimeNotificationStream()`** | `ChimeScheduledNotification` |
| **`getLaunchedAppChimeNotificationStream()`** | `ChimeNotification` |
| **`getTappedChimeNotificationStream()`** | `ChimeNotification` |
| **`getClosedChimeNotificationStream()`** | `ChimeNotification` |
| **`getDismissedChimeNotificationStream()`** | `ChimeNotification` |
| **`getFailedChimeNotificationStream()`** | `ChimeNotification` |

### Buffer / dedupe (`ChimeNotificationManager`)

| Method | Purpose |
|--------|---------|
| **`getTappedNotifications()`** / **`getCreatedNotifications()`** | Read-only views of buffers. |
| **`getCreatedAppNotifications()`** | Maps buffered **`ChimeCreatedAppNotification`** to **`ChimeAppNotification`** summaries. |
| **`hasCreatedNotification(ChimeCreatedNotification)`** | Dedupe by **`identifier`** or instance. |
| **`addCreatedNotification`**, **`removeCreatedNotification`** | Manual buffer management. |
| **`addTappedNotification`**, **`removeTappedNotification`** | Tap buffer. |
| **`flushCreatedNotifications`** | **`emitCreatedNotification`** for each buffered then clear. |
| **`flushPendingTappedNotifications`** | **`emitTappedNotification`** for each pending tap then clear. |

---

## Device notifications — building & showing

### Using `ChimePushNotification` directly

Implement **`ChimePushNotification`** or rely on **`DefaultChimePushNotification`** (via **`ChimeApplication`**):

- **`requestPermission()`** — Android notification permission / iOS alert+badge+sound.
- **`isPermitted`** — **`areNotificationsEnabled`** / **`checkPermissions`**.
- **`getPlatform()`**, **`getApplicationName()`**
- **`initialize(...)`** — **`InitializationSettings`** required; optional **`onNotificationTapped`** (**`ChimeNotificationCallback`**) and **`onBackgroundNotificationReceived`** (**`NotificationResponseCallback`**). Registers **`chimeBackgroundNotificationDispatcher`** for background taps.
- **`onAppLaunchedByNotification`** — reads **`getNotificationAppLaunchDetails`**, publishes **`NotificationLaunchedAppEvent`**.

Background dispatcher (**`chime_push_notification.dart`**): **`@pragma('vm:entry-point') void chimeBackgroundNotificationDispatcher(NotificationResponse details)`** forwards to internal publisher (emits **`NotificationReceivedEvent`** with **`isBackgroundNotification: true`**) then your callback.

### Using `ChimePushNotificationBuilder`

Subclass **`ChimePushNotificationBuilder with ChimeMixin`** (gives **`plugin`**, **`publishEvent`**, **`hasCreatedNotification`**, etc.):

| Method | Purpose |
|--------|---------|
| **`pushChimeNotification(() async => ChimeCreatedNotification(...))`** | Builds notification; skips if **`hasCreatedNotification`**; **`plugin.show`**; **`publishEvent(NotificationCreatedEvent)`** or **`NotificationFailedEvent`**. |
| **`pushScheduledChimeNotification(onCreatedNotification: () => ChimeScheduledNotification(...))`** | Requires non-null **`notificationDetails`**; **`plugin.zonedSchedule`**; **`NotificationScheduledEvent`** or failed. |
| **`configureLocalTimeZone(String timezone)`** | **`tz.initializeTimeZones()`** + **`setLocalLocation`** (default `"Africa/Lagos"` if empty). |
| **`androidSound(ChimeSound sound)`** | **`RawResourceAndroidNotificationSound`**. |
| **`getLowVibrationPattern()`** / **medium** / **high** | `Int64List` patterns for Android details. |
| **`parseTimeToDate(String time)`** | Parses `"9:00 AM"`-style strings into today’s ISO datetime string. |
| **`showChimeLogs`** | Override to control **`tracing`** logs in builder (used in template examples). |

**Building a `ChimeCreatedNotification`:**

```dart
ChimeCreatedNotification(
  id: 42, // notification id for cancel/replace
  identifier: 'msg:abc', // stable dedupe key
  title: 'Title',
  body: 'Body',
  payload: '{"route":"/inbox"}', // optional JSON for routing
  notificationDetails: NotificationDetails(
    android: AndroidNotificationDetails(
      'channel_id',
      'Channel name',
      channelDescription: '…',
    ),
    iOS: DarwinNotificationDetails(),
  ),
);
```

**Scheduled:** use **`ChimeScheduledNotification`** with **`scheduledDate: TZDateTime(...)`**, required **`notificationDetails`**, optional **`androidScheduleMode`**, **`dateTimeComponents`**.

---

## In-app notifications — `ChimeInAppNotification`

Implement the interface or use the default (toastification-backed). All **`showInApp*`** methods accept **`duration`** (seconds), **`Alignment position`** (except tip toast), and optional lifecycle callbacks **`InAppNotificationCallback`** = `void Function(String id)`:

| Method | Behavior |
|--------|----------|
| **`showInAppSuccessNotification`** | Green / check icon; **`NotificationCreatedEvent(ChimeCreatedAppNotification)`**. |
| **`showInAppErrorNotification`** | Red / error icon. |
| **`showInAppInfoNotification`** | Blue / info icon. |
| **`showInAppWarningNotification`** | Yellow / warning icon. |
| **`showInAppCustomNotification`** | **`ToastificationBuilder`**; **`ChimeCreatedCustomAppNotification`**. |
| **`showInAppNotification`** | Short **`Fluttertoast`** (tip-style); no Chime created event pattern like the others. |
| **`dismissInAppNotification({required String id})`** | **`id.isEmpty`** → **`toastification.dismissAll()`** + dismiss events for tracked app notifications; else **`dismissById`** + **`NotificationDismissedEvent`**. |

**`DefaultChimeInAppNotification`** (constructor has many styling fields: **`ChimeInAppStyle`**, colors, **`titleBuilder`** / **`descriptionBuilder`** / **`iconBuilder`**, padding, border, **`ToastificationCallbacks`** → **`publishEvent`** for tap/close/dismiss → **`ChimeAppNotification`**).

**`ChimeInAppMixin`**: delegates every interface method to **`Chime.getInAppNotification()`** so your class `with ChimeInAppMixin` can call **`showInAppInfoNotification`** without storing the notifier.

---

## `ChimeMixin` — plugin helpers

In addition to forwarding **controller** APIs, **`ChimeMixin`** exposes:

| Method | Behavior |
|--------|----------|
| **`dismissById(int id, {String? tag})`** | **`plugin.cancel`**. |
| **`dismissAll()`** | **`plugin.cancelAll`**. |
| **`dismissChannelNotifications(String channelId)`** | Filters **`getActiveNotifications()`** by **`channelId`**, cancels each. |
| **`dismissGroupedNotifications(String groupKey)`** | Same for **`groupKey`**. |

Override **`plugin`** if you use a shared **`FlutterLocalNotificationsPlugin`** instance.

---

## Minimal app setup

```dart
void main() {
  runApp(
    ChimeApplication(
      applicationName: 'MyApp',
      platform: ChimePlatform.ANDROID,
      configuration: const ChimeConfiguration(),
      initializationSettings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      child: MaterialApp(home: HomeScreen()),
    ),
  );
}
```

Subscribe to taps:

```dart
Chime.getController().getTappedChimeNotificationStream().listen((n) {
  final json = n.getPayloadAsJson();
});
```

Show in-app:

```dart
await Chime.getInAppNotification().showInAppInfoNotification(message: 'Saved');
```

---

## Installation (private monorepo)

```yaml
dependencies:
  chime:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: chime
```

---

## CI note

`chime` is not in the root GitHub Actions release matrix; add it if you tag releases like other packages.

---

## License

See [LICENSE](LICENSE) in this package directory.
