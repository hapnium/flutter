import 'dart:typed_data';

import 'package:hive_ce_flutter/hive_flutter.dart';

/// {@template secure_repository_configuration}
/// Configuration options for a single repository (Hive box).
///
/// This immutable value object controls low-level details of how a
/// repository's Hive box is opened and managed:
/// - `encryptionCipher` and `encryptionKey` configure encryption for the box.
/// - `keyComparator` controls how storage keys are compared for ordering.
/// - `compactionStrategy` decides when the underlying store should be compacted.
/// - `crashRecovery` selects whether to enable Hive's crash recovery behavior.
/// - `path` and `bytes` allow overriding the storage location or providing
///   preloaded data for testing.
///
/// Typical usage:
/// ```dart
/// final cfg = SecureRepositoryConfiguration(
///   encryptionKey: myKey,
///   compactionStrategy: (entries, deleted) => deleted > 100,
/// );
/// ```
/// {@endtemplate}
final class SecureRepositoryConfiguration {
  /// Optional Hive `HiveCipher` used to encrypt/decrypt the box.
  ///
  /// If both [encryptionCipher] and [encryptionKey] are null, the box will be
  /// opened unencrypted. Use either a `HiveCipher` instance or an
  /// `encryptionKey` as appropriate for your security model.
  final HiveCipher? encryptionCipher;

  /// Comparator used to order keys stored in the box.
  ///
  /// The comparator should return `-1`, `0` or `1` just like `Comparator`.
  /// The default comparator handles `int` and `String` keys efficiently and
  /// falls back to a stable ordering for other types.
  final int Function(dynamic, dynamic) keyComparator;

  /// Strategy used to determine when compaction should occur.
  ///
  /// The function receives the current `entries` count and `deletedEntries`.
  /// Return `true` to indicate that compaction should run. The default
  /// implementation compacts when at least 15% of entries and 60 deleted
  /// entries are present.
  final bool Function(int, int) compactionStrategy;

  /// Whether to enable crash recovery when opening the box.
  ///
  /// Defaults to `true`. Setting this to `false` may improve performance but
  /// increases the risk of data corruption on crashes.
  final bool crashRecovery;

  /// Optional explicit path where the box files should be stored.
  ///
  /// Use this to control storage location (for example in testing), otherwise
  /// the platform default path is used.
  final String? path;

  /// Optional bytes that can be used to pre-populate or restore a box.
  ///
  /// This is primarily used for testing or migration flows where a binary
  /// snapshot is applied directly.
  final Uint8List? bytes;

  /// Optional collection identifier used by storage backends that support
  /// named collections (for example, Multi-store backends).
  final String? collection;

  /// Optional raw encryption key used by some backends which accept a key
  /// directly instead of a `HiveCipher` instance.
  final List<int>? encryptionKey;

  /// Create a new [SecureRepositoryConfiguration].
  ///
  /// Parameters:
  /// - [encryptionCipher]: use a custom `HiveCipher` implementation.
  /// - [keyComparator]: custom comparator for keys; defaults to an efficient
  ///   comparator that handles `int` and `String` well.
  /// - [compactionStrategy]: decides when compaction should occur; defaults to
  ///   a heuristic based on percentage and absolute deleted entries.
  /// - [crashRecovery]: enable Hive crash recovery; defaults to `true`.
  /// - [path], [bytes], [collection], [encryptionKey]: advanced options for
  ///   storage location, bootstrap data and encryption.
  /// 
  /// {@macro secure_repository_configuration}
  const SecureRepositoryConfiguration({
    this.encryptionCipher,
    this.keyComparator = _defaultKeyComparator,
    this.compactionStrategy = _defaultCompactionStrategy,
    this.crashRecovery = true,
    this.path,
    this.bytes,
    this.collection,
    this.encryptionKey,
  });
}

/// Default key comparator used when none is provided.
///
/// Behavior:
/// - If both keys are `int`, compare numerically.
/// - If the first key is `int` and the second is not, treat the `int` as
///   smaller (return `-1`).
/// - If the second key is `String`, attempt string comparison (casts the
///   first key to `String`).
/// - For other combinations fall back to a stable default ordering.
///
/// This comparator provides efficient handling for common key types while
/// remaining safe for mixed or unknown key types.
int _defaultKeyComparator(dynamic k1, dynamic k2) {
  if (k1 is int) {
    if (k2 is int) {
      if (k1 > k2) {
        return 1;
      } else if (k1 < k2) {
        return -1;
      } else {
        return 0;
      }
    } else {
      return -1;
    }
  } else if (k2 is String) {
    return (k1 as String).compareTo(k2);
  } else {
    return 1;
  }
}

/// Fraction of entries that must be deleted before compaction is
/// considered by the default strategy (15%).
const _deletedRatio = 0.15;

/// Absolute threshold of deleted entries for the default compaction strategy
/// (60 deleted entries).
const _deletedThreshold = 60;

/// Default compaction strategy.
///
/// The strategy returns `true` (compact) when both:
/// - the absolute number of deleted entries exceeds [_deletedThreshold], and
/// - the ratio of deleted entries to total entries exceeds [_deletedRatio].
///
/// This combination prevents frequent compaction on small datasets while
/// ensuring large stores are compacted when a meaningful portion of data has
/// been removed.
///
/// Example: `entries = 1000`, `deletedEntries = 200` → 200 > 60 && 200/1000 = 0.2 > 0.15 → compact.
bool _defaultCompactionStrategy(int entries, int deletedEntries) {
  return deletedEntries > _deletedThreshold &&
      deletedEntries / entries > _deletedRatio;
}

/// {@template secure_database_configuration}
/// High-level configuration used when initializing the Hive engine for the
/// secure database subsystem.
///
/// This controls global options such as the storage backend used for Hive,
/// the sub-directory where boxes are stored, and optional adapter `typeId`s
/// to register custom adapters such as `Color` or `TimeOfDay`.
///
/// Example:
/// ```dart
/// @override
/// SecureDatabaseConfiguration getConfiguration() => const SecureDatabaseConfiguration(
///   subDir: 'secure_db',
///   backendPreference: HiveStorageBackendPreference.native,
/// );
/// ```
/// {@endtemplate}
final class SecureDatabaseConfiguration {
  /// Optional sub-directory inside the application's data directory where
  /// Hive files will be stored. When `null`, the platform default location is
  /// used.
  final String? subDir;

  /// Preferred Hive storage backend. Defaults to [HiveStorageBackendPreference.native].
  final HiveStorageBackendPreference backendPreference;

  /// Optional [typeId] to register a `Color` adapter when opening boxes.
  ///
  /// If your application stores colors, provide a stable `typeId` to ensure
  /// consistent serialization across app versions.
  final int? colorAdapterTypeId;

  /// Optional [typeId] to register a `TimeOfDay` adapter when opening boxes.
  final int? timeOfDayAdapterTypeId;

  /// Create a [SecureDatabaseConfiguration].
  ///
  /// Parameters:
  /// - [backendPreference]: recommends the storage backend to use; defaults to
  ///   native storage.
  /// - [colorAdapterTypeId], [timeOfDayAdapterTypeId]: optional adapter ids to
  ///   register application-specific adapters when boxes are opened.
  /// - [subDir]: optional sub-directory to store Hive files under the app
  ///   data folder.
  /// 
  /// {@macro secure_database_configuration}
  const SecureDatabaseConfiguration({
    this.backendPreference = HiveStorageBackendPreference.native,
    this.colorAdapterTypeId,
    this.subDir,
    this.timeOfDayAdapterTypeId,
  });
}