/// {@template zap_library}
/// # Zap Dart Library
///
/// `zap` is a high-performance, composable network and socket abstraction framework built in Dart.
/// It provides tools for:
///
/// - 🔌 **HTTP clients** with request/response modeling
/// - 🧩 **WebSocket** communication
/// - ⚡ **Reactive stream-based Flux system**
/// - 🛠️ Customizable interceptors and lifecycle hooks
/// - 🛰️ Real-time sync integrations via `Zync`
///
/// ## 📦 Modules Breakdown:
///
/// ### ✅ Core HTTP
/// - `zap_client.dart`: Typed HTTP client abstraction
/// - `request.dart`, `response.dart`: Strongly typed HTTP request/response models
/// - `form_data.dart`, `multipart_file.dart`: Multipart/form-data support
/// - `http_status.dart`: Status code mappings
/// - `graphql_response.dart`: Specialized response for GraphQL APIs
///
/// ### 📡 Socket Layer
/// - `zap_socket.dart`: Real-time socket interface abstraction
/// - `socket_status.dart`, `socket_type.dart`: Enum types for socket state management
/// - `socket_messenger.dart`: Message envelope for socket event/data structures
///
/// ### 🔁 Zap Lifecycle
/// - `zap_lifecycle.dart`: Hooks and lifecycle callbacks
/// - `zap_interface.dart`: Contract for implementing custom zap systems
/// - `zap_inst.dart`: Global instance reference
///
/// ### 🔒 Certificates
/// - `certificates.dart`: Load and manage HTTPS certificates (useful in native environments)
///
/// ### 🔄 Zync (Real-time Sync Engine)
/// - `zync.dart`: Bi-directional state sync manager
/// - `zync_interface.dart`: Interface to integrate Zync
/// - `zync_config.dart`, `zync_response.dart`, `zync_error_response.dart`: Config and results
///
/// ### 🌊 Flux (Reactive Streams)
/// - `flux.dart`: Lightweight reactive state manager
/// - `flux_interface.dart`: Reactive contract
/// - `flux_config.dart`: Setup details
///
/// ### ⚙️ Configuration
/// - `zap_config.dart`: Main configuration entry
/// - `definitions.dart`: App constants, routing keys, and misc
///
/// ### 📍 Location Support
/// - `location_data.dart`, `location_information.dart`: Geolocation response models
///
/// ### ⚠️ Exception Handling
/// - `zap_exception.dart`: Base exception class
/// - `graphql_error.dart`: Specialized GraphQL error structure
/// - `controller_advice.dart`: Runtime hints and controller-level warnings
///
/// ### 📑 Data Models
/// - `api_response.dart`: Unified API response wrapper
/// - `session_response.dart`: Session payload models
/// - `zap_page.dart`: Paginated result abstraction
/// - `cancel_token.dart`: Manual request cancellation
///
/// ### 🧩 Utilities & Extensions
/// - `api_response_extension.dart`: Common helpers on API responses
/// - `zap_modifier.dart`: Modify outgoing requests globally
/// - `zap_utils.dart`: Miscellaneous utility methods
///
/// ---
///
/// ## 🧱 How to Use
///
/// ### ⚡ Simple HTTP Request
/// ```dart
/// final client = ZapClient();
/// final response = await client.get('https://api.example.com/users');
/// if (response.isSuccess) {
///   print(response.data);
/// }
/// ```
///
/// ### 🧠 Intercept & Modify Requests
/// ```dart
/// client.addModifier((request) {
///   request.headers['Authorization'] = 'Bearer token';
///   return request;
/// });
/// ```
///
/// ### 🔌 Real-time with Zync
/// ```dart
/// final zync = Zync();
/// zync.connect();
/// zync.onSync((event) => handleIncomingData(event));
/// ```
///
/// ### 🌊 Use Flux
/// ```dart
/// final counter = Flux<int>(0);
/// counter.listen((value) => print('Counter: $value'));
/// counter.value++;
/// ```
///
/// ---
///
/// ## 📈 Extensibility
///
/// You can define custom:
/// - 📤 HTTP request modifiers
/// - 🪝 Lifecycle hooks via `ZapLifecycle`
/// - 🧠 Logic via Flux/Zync
/// - 📦 Encoders and decoders
///
/// ## 🔐 SSL/TLS Custom Certificates
/// ```dart
/// await CertificateManager.addCertificate('assets/cert.pem');
/// ```
///
/// ## 🧪 Testing
/// Mock any part of `zap` via interfaces: `ZapClientInterface`, `ZyncInterface`, etc.
///
/// {@endtemplate}
library;

/// --- CORE HTTP MODULES ---
export 'src/http/certificates/certificates.dart';
export 'src/http/client/zap_client.dart';
export 'src/http/multipart/form_data.dart';
export 'src/http/multipart/multipart_file.dart';
export 'src/http/request/request.dart';
export 'src/http/response/response.dart';
export 'src/http/response/graphql_response.dart';
export 'src/http/utils/http_status.dart';
export 'src/http/utils/http_headers.dart';
export 'src/http/utils/http_content_type.dart';
export 'src/http/utils/http_method.dart';
export 'src/http/modifier/zap_modifier.dart';

/// --- ENUM TYPES ---
export 'src/enums/socket_status.dart';
export 'src/enums/zync_state.dart';
export 'src/enums/socket_type.dart';
export 'src/enums/exception_type.dart';

/// --- EXTENSIONS ---
export 'src/extensions/api_response_extension.dart';

/// --- EXCEPTIONS ---
export 'src/exceptions/graphql_error.dart';
export 'src/exceptions/zap_exception.dart';
export 'src/exceptions/controller_advice.dart';

/// --- CORE ZAP RUNTIME ---
export 'src/core/zap.dart';
export 'src/core/zap_interface.dart';
export 'src/core/zap_lifecycle.dart';
export 'src/core/zap_socket.dart';
export 'src/core/zap_inst.dart';

/// --- DEFINITIONS ---
export 'src/definitions.dart';

/// --- DATA MODELS ---
export 'src/models/response/api_response.dart';
export 'src/models/response/session_response.dart';
export 'src/models/location/location_data.dart';
export 'src/models/location/location_information.dart';
export 'src/models/zync/zync_config.dart';
export 'src/models/zync/zync_error_response.dart';
export 'src/models/zync/zync_response.dart';
export 'src/models/zap_page.dart';
export 'src/models/cancel_token.dart';
export 'src/models/zap_config.dart';
export 'src/models/flux_config.dart';
export 'src/models/error.dart';
export 'src/models/socket_messenger.dart';

/// --- FLUX SYSTEM ---
export 'src/flux/flux.dart';
export 'src/flux/flux_interface.dart';

/// --- ZYNC SYNC ENGINE ---
export 'src/zync/zync.dart';
export 'src/zync/zync_interface.dart';

/// --- UTILITIES ---
export 'src/zap_utils/zap_utils.dart';