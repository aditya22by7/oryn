import 'dart:math';

/// Decay Engine
///
/// Calculates freshness of evidence based on time elapsed.
/// All proof becomes stale over time.
///
/// Pure Dart. No external dependencies.
class DecayEngine {

  /// Calculates freshness factor for evidence
  ///
  /// Returns value between 0.0 (completely stale) and 1.0 (perfectly fresh)
  ///
  /// Formula: freshness = e^(-age / halfLife)
  static double calculateFreshness({
    required DateTime addedAt,
    required int halfLifeDays,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final ageInDays = now.difference(addedAt).inDays.toDouble();

    // Prevent negative age
    if (ageInDays <= 0) return 1.0;

    // Prevent division by zero
    if (halfLifeDays <= 0) return 0.0;

    final freshness = exp(-ageInDays / halfLifeDays);

    return freshness.clamp(0.0, 1.0);
  }

  /// Calculates decay factor for a claim based on last verification
  static double calculateClaimDecay({
    required DateTime lastVerifiedAt,
    required int halfLifeDays,
    DateTime? currentTime,
  }) {
    return calculateFreshness(
      addedAt: lastVerifiedAt,
      halfLifeDays: halfLifeDays,
      currentTime: currentTime,
    );
  }

  /// Returns days until freshness drops below threshold
  static int? daysUntilThreshold({
    required DateTime addedAt,
    required int halfLifeDays,
    required double threshold,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final currentFreshness = calculateFreshness(
      addedAt: addedAt,
      halfLifeDays: halfLifeDays,
      currentTime: now,
    );

    // Already below threshold
    if (currentFreshness <= threshold) return 0;

    // Calculate days until threshold
    // threshold = e^(-days / halfLife)
    // ln(threshold) = -days / halfLife
    // days = -halfLife * ln(threshold)
    final totalDays = (-halfLifeDays * log(threshold)).ceil();
    final currentAge = now.difference(addedAt).inDays;
    final remainingDays = totalDays - currentAge;

    return remainingDays > 0 ? remainingDays : 0;
  }

  /// Returns human-readable decay status
  static DecayStatus getDecayStatus(double freshness) {
    if (freshness >= 0.9) return DecayStatus.fresh;
    if (freshness >= 0.7) return DecayStatus.recent;
    if (freshness >= 0.5) return DecayStatus.aging;
    if (freshness >= 0.3) return DecayStatus.stale;
    if (freshness >= 0.1) return DecayStatus.decaying;
    return DecayStatus.expired;
  }
}

/// Decay status categories
enum DecayStatus {
  fresh,
  recent,
  aging,
  stale,
  decaying,
  expired,
}

extension DecayStatusExtension on DecayStatus {
  String get displayName {
    switch (this) {
      case DecayStatus.fresh:
        return 'Fresh';
      case DecayStatus.recent:
        return 'Recent';
      case DecayStatus.aging:
        return 'Aging';
      case DecayStatus.stale:
        return 'Stale';
      case DecayStatus.decaying:
        return 'Decaying';
      case DecayStatus.expired:
        return 'Expired';
    }
  }
}