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

// Private implementation classes
class InternalIntSummaryStatistics {
  int count = 0;
  int sum = 0;
  int min = 0x7fffffff; // Integer.MAX_VALUE
  int max = -0x80000000; // Integer.MIN_VALUE

  void accept(int value) {
    count++;
    sum += value;
    if (value < min) min = value;
    if (value > max) max = value;
  }

  InternalIntSummaryStatistics combine(InternalIntSummaryStatistics other) {
    count += other.count;
    sum += other.sum;
    if (other.min < min) min = other.min;
    if (other.max > max) max = other.max;
    return this;
  }

  double get average => count > 0 ? sum / count : 0.0;
}

class InternalDoubleSummaryStatistics {
  int count = 0;
  double sum = 0.0;
  double min = double.infinity;
  double max = double.negativeInfinity;

  void accept(double value) {
    count++;
    sum += value;
    if (value < min) min = value;
    if (value > max) max = value;
  }

  InternalDoubleSummaryStatistics combine(InternalDoubleSummaryStatistics other) {
    count += other.count;
    sum += other.sum;
    if (other.min < min) min = other.min;
    if (other.max > max) max = other.max;
    return this;
  }

  double get average => count > 0 ? sum / count : 0.0;
}