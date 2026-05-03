# zap

**HTTP**, **WebSockets**, session-aware **Flux** client, real-time **Zync** wrapper, **ZapUtils**, and shared models for Hapnium networking. Works on Flutter with **`dart:io`** and **web** (`package:web`) code paths.

**Import:** `package:zap/zap.dart`  
**Flutter:** required by `pubspec.yaml`.

---

## Layout (what is actually exported)

Everything ships from a **single** library: `zap.dart`. There are **no** separate `zap_pulse` / `zap_socket` import paths.

| Area | Types / entry |
|------|----------------|
| HTTP | **`ZapClient`**, **`Request`**, **`Response`**, **`FormData`**, **`MultipartFile`**, **`HttpMethod`**, headers/status/content-type helpers |
| Core orchestration | **`Zap`** extends **`ZapInterface`** — `get` / `post` / `put` / `patch` / `delete`, GraphQL response type, **`CancelToken`**, **`cancelAllRequests`**, lifecycle hooks |
| Config | **`ZapConfig`** (timeouts, base URL, redirects, certs, user agent, …) |
| Modifiers | **`ZapModifier`** pipeline on **`ZapClient`** — global request/response shaping (e.g. auth headers) |
| Certificates | **`CertificateManager`** (or equivalent in `certificates.dart`) for trusted PEM material |
| Sockets | **`ZapSocket`** abstraction; concrete IO / HTML sockets under `src/socket/` |
| Flux | **`Flux`** — **singleton** authenticated HTTP facade returning **`Response<ApiResponse>`**; **`FluxConfig`** (session, logging, **`disposeOnCompleted`**, custom Zap client factory) |
| Zync | **`Zync`** — **singleton** WebSocket-style client with **`ZyncConfig`**, topics, **`ZyncState`**, **`SocketMessenger`** |
| Models | **`ApiResponse`**, **`SessionResponse`**, **`ZapPage`**, location payloads, **`ZyncResponse`** / **`ZyncErrorResponse`**, **`CancelToken`** |
| Utils | **`ZapUtils.instance`** — public IP (`ipify`), image bytes fetch, **`LocationInformation`**, distance matrix helpers (uses an internal **`Zap`** with default config) |
| Errors | **`ZapException`**, **`GraphQLError`**, **`ControllerAdvice`**, **`ExceptionType`** |

---

## Core HTTP (`Zap` + `ZapClient`)

`Zap` wraps **`ZapConfig`** and lazily builds a **`ZapClient`**. Prefer relative paths if **`baseUrl`** is set in config.

```dart
import 'package:zap/zap.dart';

Future<void> example() async {
  final zap = Zap(
    zapConfig: ZapConfig(
      baseUrl: 'https://api.example.com',
      timeout: const Duration(seconds: 15),
    ),
  );

  final response = await zap.get<Map<String, dynamic>>(
    '/users',
    decoder: (data) => data as Map<String, dynamic>,
  );

  if (response.isSuccessful) {
    // use response.body
  }

  final cancel = CancelToken();
  zap.post('/upload', bytes, cancelToken: cancel);
  cancel.cancel('user cancelled');
}
```

`Zap` tracks active **`CancelToken`**s and can cancel them in bulk via **`cancelAllRequests`**.

### `ZapInterface` method reference (`Zap` implements this)

| Method | Notes |
|--------|--------|
| **`get<T>(url, {headers, contentType, query, decoder, cancelToken})`** | GET; **`decoder`** parses body to `T`. |
| **`post<T>(url, body, {contentType, headers, query, decoder, uploadProgress, cancelToken})`** | POST; **`url`** may be nullable per signature. |
| **`put<T>(url, body, {…})`** | PUT. |
| **`patch<T>(url, body, {…})`** | PATCH. |
| **`delete<T>(url, {headers, contentType, query, decoder, cancelToken})`** | DELETE. |
| **`request<T>(url, method, {body, …})`** | Low-level verb. |
| **`send<T>(Request<T> request, {cancelToken})`** | Send a built **`Request`**. |
| **`socket(url, {ping})`** | Returns **`ZapSocket`**. |
| **`query<T>(graphqlQuery, {url, variables, headers, cancelToken})`** | GraphQL query → **`GraphQLResponse<T>`**. |
| **`mutation<T>(graphqlMutation, {…})`** | GraphQL mutation. |
| **`cancelAllRequests([reason])`** | Cancel tracked tokens. |
| **`dispose()`** / **`isDisposed`** | Tear down client/sockets. |

**`Response<T>`** helpers include **`isSuccessful`**, **`hasError`**, **`unauthorized`**, **`status`** (**`HttpStatus`**), **`body`**, etc. (**`response.dart`**).

**`ZapClient`** (underlying transport) adds interceptors, default content type, redirect limits, **`ZapModifier`**, response interceptors, certificate trust, **`baseUrl`** resolution — see **`zap_client.dart`** and **`client_handler.dart`**.

---

## Flux (authenticated API layer)

**`FluxInterface`** methods (all return **`Future<Response<ApiResponse>>`**):

| Method | Parameters (common) |
|--------|----------------------|
| **`get`** | **`endpoint`**, **`query`**, **`useAuth`** (default `true`), **`token`** (**`CancelToken`**). |
| **`post`** | **`endpoint`**, **`body`**, **`query`**, **`onProgress`**, **`useAuth`**, **`token`**. |
| **`put`** | Same shape as post. |
| **`patch`** | Same shape as post. |
| **`delete`** | **`endpoint`**, **`query`**, optional **`body`**, **`useAuth`**, **`token`**. |

**Singleton rules**

- Construct **once**: `Flux(config: FluxConfig(...))`. A **second** `Flux(...)` throws **`ZapException`** until **`Flux.dispose()`**.
- Use **`Flux.instance`** after creation.
- **`Flux.dispose()`** disposes underlying Zap client and clears singleton.
- **`Flux.cancelAllRequests([reason])`** forwards to the instance.
- Responses are **`Response<ApiResponse>`**; **`FluxConfig.execute`** applies auth headers and session refresh semantics you configure.
- If **`disposeOnCompleted`** is true in config, **each** call disposes the singleton when the request finishes (check your config carefully for long-lived apps).

```dart
Flux(
  config: FluxConfig(
    session: mySession,
    showRequestLogs: true,
    // onSessionRefreshed, authHeaderBuilder, etc.
  ),
);

final r = await Flux.instance.get(endpoint: '/me', useAuth: true);
```

---

## Zync (real-time)

Singleton pattern similar to Flux: **`Zync(config: ...)`**, then **`Zync.instance`**, **`Zync.dispose()`**.

`ZyncConfig` carries **`url`**, **`SessionResponse`**, optional auth header name/prefix or **`authHeaderBuilder`**, reconnect and ping options, and callbacks (**`onReceived`**, **`onError`**, state changes).

### `ZyncInterface` method reference

| API | Description |
|-----|-------------|
| **`isConnected`**, **`connectionState`** | Connection flags (**`ZyncState`**). |
| **`connectionStateStream`**, **`dataStream`**, **`errorStream`** | Broadcast streams (**`ZyncResponse`**, **`ZyncErrorResponse`**). |
| **`connectionStateController`**, **`dataController`**, **`errorController`** | Underlying controllers (advanced). |
| **`connect()`** / **`disconnect()`** | Open/close WebSocket. |
| **`send({endpoint, data, headers})`** | Send on a logical endpoint/topic. |
| **`subscribe({topic, onMessage})`** / **`unsubscribe(topic)`** | Topic callbacks. |
| **`on(SocketType event, callback)`** / **`off(SocketType event)`** | Typed socket events. |
| **`emit(SocketType event, data)`** | Emit to server. |

Implementation details: **`src/zync/zync.dart`** (reconnect, auth headers, **`SocketMessenger`**).

---

## ZapUtils

`ZapUtils.instance` provides **`fetchIpAddress`**, **`fetchImageData`** / **`fetchImageDataAsync`**, **`getLocationInformation`**, **`getTotalDistanceAndTime`** (Google distance matrix style), all implemented with an internal **`Zap`** client.

---

## Definitions and logging

**`Z`** / **`Z.log`** in `definitions.dart` tie into optional logging (see package). **`tracing`** is listed under **dev_dependencies** for tests, not a runtime requirement of `zap` itself.

---

## Installation (private monorepo)

```yaml
dependencies:
  zap:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: zap
```

---

## Testing

Tests under `test/` (e.g. flux refresh/retry). Run:

```bash
flutter test
```

---

## License

See [LICENSE](LICENSE) in this package directory.
