// ignore_for_file: deprecated_member_use_from_same_package

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';

import 'base_repository.dart';
import 'repository_mixin.dart';

/// An abstract class for configuring secure local database access using Hive.
///
/// This class provides a standardized way to initialize Hive, open repositories,
/// and perform any necessary setup for your database. You should extend this
/// class and implement the abstract methods to customize the configuration for
/// your specific application.
abstract class AbstractSecureDatabaseConfigurer {
  /// Initializes the secure database.
  ///
  /// This method performs the following steps:
  ///
  /// 1. Initializes Hive using `Hive.initFlutter()`.
  /// 2. Opens all registered repositories by calling the `open()` method on
  ///    each repository, passing the configured `prefix`, `deviceName`, `platform`,
  ///    and `showLogs` values.
  /// 3. Calls the `setup()` method to allow subclasses to perform any
  ///    additional setup logic.
  ///
  /// This method should be called early in your application's lifecycle,
  /// typically in the `main` function or before using any repositories.
  @nonVirtual
  Future<void> initialize() {
    return Future.sync(() async {
      await Hive.initFlutter();

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

  /// Returns the prefix to use for database box names.
  ///
  /// This prefix is used to distinguish the database boxes for your application
  /// from other boxes that might be created by other libraries or apps.
  String get prefix;

  /// Returns the deviceName identifier.
  ///
  /// This is used as part of the key for data stored in the box.
  /// It can be used, for example, to differentiate data for different devices
  /// using the same app.
  String deviceName = "";

  /// Returns the platform identifier.
  ///
  /// Similar to [deviceName], this is used as part of the data key and can be used to
  /// differentiate data for different platforms (e.g., Android, iOS, Web).
  ///
  /// Defaults to an empty string
  String platform = "";

  /// Whether to show logs during database operations.
  ///
  /// Defaults to [true]
  bool showLogs = true;

  /// Whether to destroy older saved data while uploading changes.
  ///
  /// Defaults to [true]
  bool canDestroySavedData = true;

  /// Returns a list of [BaseRepository] instances to be opened.
  ///
  /// This method *must* be overridden by subclasses to provide the repositories
  /// that should be used by the application.
  @mustBeOverridden
  List<BaseRepository> repositories() => [];

  /// Performs any additional setup logic after the repositories are opened.
  ///
  /// This method is called after the `repositories()` are opened and can be used
  /// to perform any other initialization or configuration, such as setting up
  /// indexes or performing migrations.
  Future<void> setup() async {}

  /// Clears the database.
  ///
  /// This method *should* be overridden by subclasses to provide the logic for
  /// clearing the database.  If not overridden, it will be called by [clearAll]
  /// after all repositories are cleared.
  Future<void> clear() async {}

  /// Clears all repositories and then calls the [clear] method.
  ///
  /// This method iterates through all registered repositories and calls their
  /// `delete()` method to clear their contents.  After all repositories have
  /// been cleared, it calls the [clear] method to allow subclasses to perform
  /// any additional cleanup.
  ///
  /// This method is marked with `@mustCallSuper` to ensure that subclasses call
  /// it when overriding it, allowing for the repository clearing logic to be
  /// executed.
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

  /// Closes all repositories.
  /// 
  /// This method iterates through all registered repositories and calls their
  /// `close()` method to close their contents.
  /// 
  /// This method is marked with `@mustCallSuper` to ensure that subclasses call
  /// it when overriding it, allowing for the repository closing logic to be
  /// executed.
  @mustCallSuper
  Future<void> closeAll() {
    return Future.sync(() async {
      for (final repository in repositories()) {
        await repository.close(); // Await the close operation
      }
    }); // Await the close operation
  }
}