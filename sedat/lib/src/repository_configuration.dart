import 'dart:typed_data';

import 'package:hive_ce_flutter/hive_flutter.dart';

final class RepositoryConfiguration {
  final HiveCipher? encryptionCipher;
  final int Function(dynamic, dynamic) keyComparator;
  final bool Function(int, int) compactionStrategy;
  final bool crashRecovery;
  final String? path;
  final Uint8List? bytes;
  final String? collection;
  final List<int>? encryptionKey;

  const RepositoryConfiguration({
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

/// Efficient default implementation to compare keys
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

const _deletedRatio = 0.15;
const _deletedThreshold = 60;

/// Default compaction strategy compacts if 15% of total values and at least 60
/// values have been deleted
bool _defaultCompactionStrategy(int entries, int deletedEntries) {
  return deletedEntries > _deletedThreshold &&
      deletedEntries / entries > _deletedRatio;
}