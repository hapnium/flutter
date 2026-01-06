// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

extension DurationExtension on Duration {
  /// Converts the duration to a formatted string in HH:MM:SS or MM:SS format.
  /// 
  /// This extension method converts a `Duration` object into a formatted string 
  /// representing the duration in hours, minutes, and seconds. 
  /// 
  /// If the duration is less than an hour, it will be formatted as "MM:SS". 
  /// Otherwise, it will be formatted as "HH:MM:SS". 
  String get asTime {
    String formattedDuration = toString().split('.').first;
    List<String> parts = formattedDuration.split(':');

    // Format as "00:00:00" (hours, minutes, and seconds)
    if (formattedDuration.contains(':') && formattedDuration.split(':').length == 3 && int.parse(parts[0]) > 0) {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    // Format as "00:00" (minutes and seconds)
    if (formattedDuration.contains(':')) {
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return formattedDuration;
  }
}