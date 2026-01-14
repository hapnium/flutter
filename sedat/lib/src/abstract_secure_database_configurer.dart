// ignore_for_file: deprecated_member_use_from_same_package

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';

import 'base_repository.dart';
import 'repository_configuration.dart';
import 'repository_mixin.dart';

/// Base class that defines how to configure and manage a secure local
/// database backed by Hive.
///
/// Subclasses provide concrete repository instances and may override
/// lifecycle hooks to customize initialization, cleanup and teardown logic.
///
/// Responsibilities:
/// - Initialize Hive with the application's configuration
/// - Open and register repositories returned by [repositories]
/// - Provide optional setup, clear and close hooks for subclasses
///
/// Example:
/// ```dart
/// class MyConfigurer extends AbstractSecureDatabaseConfigurer {
///   @override
///   String get prefix => 'com.example.app';
///
///   @override
///   List<BaseRepository> repositories() => [MyRepo()];
///
///   @override
///   Future<void> setup() async {
///     // additional initialization
///   }
/// }
/// ```
abstract class AbstractSecureDatabaseConfigurer {
  /// Initialize Hive and open the configured repositories.
  ///
  /// This performs the following sequence of steps (in order):
  /// 1. Calls `Hive.initFlutter` with values supplied by
  ///    [SecureDatabaseConfiguration] (either the optional [config] parameter
  ///    or the result of [getConfiguration]).
  /// 2. If [repositories] is non-empty, opens each repository by calling
  ///    `repository.open(...)`, passing the current `prefix`, `deviceName`,
  ///    `platform`, `showLogs` and `canDestroySavedData` values.
  /// 3. Registers the opened repositories with [RepositoryContext.INSTANCE].
  /// 4. Awaits [setup] to allow subclasses to perform additional async work.
  ///
  /// Notes and guidance:
  /// - Call this method once during application startup (for example,
  ///   in `main()` before `runApp`) and `await` it; it is not intended to be
  ///   re-entered concurrently. Repeated calls may re-open repositories or
  ///   create unexpected state depending on your repository implementations.
  /// - If any repository's `open()` throws an error, `initialize` will
  ///   complete with that exception and any subsequent repositories will not be
  ///   opened. If you require partial-failure handling, override [setup]
  ///   or implement a wrapper that catches and handles repository errors.
  /// - The order of repositories returned by [repositories] is respected; if
  ///   repositories depend on each other, return them in the required order.
  /// - Implementations should return stable repository instances from
  ///   [repositories] (do not create new instances on every call) so that
  ///   lifecycle methods (`clearAll`/`closeAll`) operate on the same objects.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   final configurer = MyConfigurer();
  ///   await configurer.initialize(); // waits for Hive and repos to be ready
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [config] (optional): an instance of [SecureDatabaseConfiguration] to
  ///   customize Hive initialization. If omitted, [getConfiguration] is used.
  ///
  /// Returns a [Future] that completes when initialization and setup finish.
  @nonVirtual
  Future<void> initialize([SecureDatabaseConfiguration? config]) {
    final configuration = config ?? getConfiguration();

    return Future.sync(() async {
      await Hive.initFlutter(
        configuration.subDir,
        configuration.backendPreference,
        configuration.colorAdapterTypeId,
        configuration.timeOfDayAdapterTypeId
      );

      if (repositories().isNotEmpty) {
        for (final repository in repositories()) {
          await repository.open(
            prefix: prefix,
            device: deviceName,
            platform: platform,
            showLogs: showLogs,
            canDestroy: canDestroySavedData
          );
        }

        RepositoryContext.INSTANCE.register(repositories());
      }

      await setup();
    }); // Make sure setup is awaited
  }

  /// A short string used as a prefix for Hive box names created by the
  /// repositories.
  ///
  /// This value is included in the final Hive box name and in internal key
  /// construction. Implementations must provide a non-empty prefix to avoid
  /// collisions with other Hive boxes on the same device. Prefer using a
  /// reverse-domain style identifier, e.g. `com.example.myapp`.
  ///
  /// Constraints and recommendations:
  /// - Keep it short and readable; it will appear in file-system names.
  /// - Avoid characters that are invalid in file names on target platforms.
  /// - Use the same prefix consistently for all repositories belonging to the
  ///   same application.
  ///
  /// Example: `com.example.myapp`
  String get prefix;

  /// An identifier for the device (for example, a UUID or a user-friendly
  /// device name).
  ///
  /// This value may be used by repositories when constructing keys or
  /// differentiating stored data across devices. Keep it stable per device to
  /// allow long-lived delegation of data to a particular device.
  ///
  /// Notes:
  /// - The value is incorporated into internal key construction and may also
  ///   appear in box metadata; avoid secrets and sensitive data in this field.
  /// - Default is an empty string (no device identifier recorded).
  ///
  /// Example: `device-550e8400-e29b-41d4-a716-446655440000`
  String deviceName = "";

  /// An identifier for the platform (for example, `android`, `ios`, `web`).
  ///
  /// This may be incorporated into keys or used for platform-specific
  /// behavior. Use short, stable values. Default is an empty string.
  ///
  /// Example: `android` or `ios`
  String platform = "";

  /// Returns the configuration used to initialize Hive.
  ///
  /// Override this to change default initialization parameters. The
  /// resulting [SecureDatabaseConfiguration] may contain:
  /// - `subDir`: (String?) optional sub-directory under the app data folder
  ///   where Hive files are stored.
  /// - `backendPreference`: (HiveStorageBackendPreference) preferred Hive
  ///   storage backend (native, memory, etc.).
  /// - `colorAdapterTypeId`: (int?) optional type id to register a color
  ///   adapter when opening boxes.
  /// - `timeOfDayAdapterTypeId`: (int?) optional type id for TimeOfDay adapter.
  ///
  /// Example override:
  /// ```dart
  /// @override
  /// SecureDatabaseConfiguration getConfiguration() => const SecureDatabaseConfiguration(
  ///   subDir: 'secure_db',
  ///   backendPreference: HiveStorageBackendPreference.native,
  /// );
  /// ```
  SecureDatabaseConfiguration getConfiguration() => SecureDatabaseConfiguration();

  /// If true, repositories may emit informational logs during operations.
  ///
  /// This controls repository-level logging such as open/close, delete and
  /// initialization messages. Defaults to `true`. In production you may want
  /// to set this to `false` to reduce log volume or avoid exposing internal
  /// details.
  bool showLogs = true;

  /// When true, repositories may delete or replace older saved data during
  /// certain operations (for example, when reconciling uploads).
  ///
  /// Use with caution; default is `true`. Note: the `open()` method of
  /// [BaseRepository] also exposes a deprecated `canDestroy` parameter —
  /// implementers should prefer repository-level configuration via
  /// [SecureRepositoryConfiguration] where possible and treat `canDestroySavedData`
  /// as a higher-level hint to your own logic.
  bool canDestroySavedData = true;

  /// Returns the list of repositories that should be opened and managed.
  ///
  /// Implementations MUST override this method and return the repositories
  /// relevant to the application. Returning an empty list means no repositories
  /// will be opened or registered.
  ///
  /// Important guidance:
  /// - Return the same repository instances on every call; do not create new
  ///   repository objects each time [repositories] is invoked. Lifecycle
  ///   operations such as `clearAll` and `closeAll` expect the same objects
  ///   that were opened during `initialize`.
  /// - Keep this method lightweight; it may be called by initialization,
  ///   clearing and closing routines.
  @mustBeOverridden
  List<BaseRepository> repositories() => [];

  /// Optional hook executed after repositories are opened and registered.
  ///
  /// Subclasses can override this method to perform additional async setup
  /// work — for example, run migrations, create indexes or warm caches.
  ///
  /// Important:
  /// - Any uncaught exceptions thrown from [setup] will propagate to
  ///   [initialize] and cause initialization to fail. If parts of setup are
  ///   optional, catch and handle exceptions locally.
  /// - Avoid long-running synchronous work in [setup]; favor async APIs so the
  ///   caller can await completion without blocking the UI thread.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> setup() async {
  ///   try {
  ///     await migrationService.migrate();
  ///   } catch (e) {
  ///     // handle or log non-fatal migration issues
  ///   }
  /// }
  /// ```
  Future<void> setup() async {}

  /// Optional hook to clear any additional state managed by the configurer.
  ///
  /// Called by [clearAll] after repository data has been deleted. Subclasses
  /// should override to remove any non-repository state (files, caches, tokens,
  /// or external resources). Exceptions thrown here will bubble to the caller of
  /// [clearAll]. Consider catching and logging non-fatal errors if you want
  /// the cleanup to continue for other resources.
  Future<void> clear() async {}

  /// Delete contents of all repositories, then call [clear] and reset context.
  ///
  /// This method iterates each repository returned by [repositories], awaits
  /// its `delete()` operation, then invokes [clear] and clears the
  /// [RepositoryContext.INSTANCE]. It is marked `@mustCallSuper`; overriding
  /// implementations should call `super.clearAll()` as part of their
  /// cleanup.
  ///
  /// Error handling:
  /// - If any repository's `delete()` throws, the method will throw and
  ///   subsequent repositories may not be deleted. If you need a best-effort
  ///   deletion across all repositories, handle errors accordingly, for
  ///   example:
  ///
  /// ```dart
  /// @override
  /// Future<void> clearAll() async {
  ///   for (final repo in repositories()) {
  ///     try {
  ///       await repo.delete();
  ///     } catch (e) {
  ///       // log and continue with other repositories
  ///     }
  ///   }
  ///   await clear();
  ///   RepositoryContext.INSTANCE.clear();
  /// }
  /// ```
  @mustCallSuper
  Future<void> clearAll() {
    return Future.sync(() async {
      for (final repository in repositories()) {
        await repository.delete(); // Await the delete operation
      }

      await clear();
      RepositoryContext.INSTANCE.clear();
    }); // Await the clear operation
  }

  /// Close all repositories managed by this configurer.
  ///
  /// This calls `close()` on every repository returned by [repositories].
  /// It is marked `@mustCallSuper`; if a subclass overrides the method it
  /// should call `super.closeAll()` to ensure repositories are properly
  /// closed.
  ///
  /// Notes on ordering and errors:
  /// - Close operations are performed in the order returned by [repositories].
  /// - If `close()` for a repository throws, this method will rethrow and
  ///   subsequent repositories may not be closed; wrap `close()` calls if you
  ///   require best-effort closes for all repositories.
  @mustCallSuper
  Future<void> closeAll() {
    return Future.sync(() async {
      for (final repository in repositories()) {
        await repository.close(); // Await the close operation
      }
    }); // Await the close operation
  }
}