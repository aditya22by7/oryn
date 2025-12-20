import 'dart:math';

/// Time Decay Engine
///
/// Prevents permanent truth. All proof becomes stale.
/// Uses exponential decay based on half-life principle.
class DecayEngine {

  /// Calculates freshness factor for a piece of evidence
  ///
  /// Returns value between 0.0 (completely stale) and 1.0 (perfectly fresh)
  ///
  /// Formula: freshness = e^(-ageInDays / halfLifeDays)
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

    // Clamp between 0 and 1
    return freshness.clamp(0.0, 1.0);
  }

  /// Calculates decay factor for a claim based on last verification
  ///
  /// Returns value between 0.0 (completely decayed) and 1.0 (recently verified)
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

  /// Calculates days until confidence drops below threshold
  ///
  /// Useful for displaying "re-verify in X days" warnings
  static int daysUntilThreshold({
    required DateTime lastVerifiedAt,
    required int halfLifeDays,
    required double currentConfidence,
    double threshold = 0.5,
    DateTime? currentTime,
  }) {
    if (currentConfidence <= threshold) return 0;

    final now = currentTime ?? DateTime.now();
    final currentAge = now.difference(lastVerifiedAt).inDays;

    // Solve for days: threshold = confidence * e^(-days/halfLife)
    // days = -halfLife * ln(threshold / confidence)
    final ratio = threshold / currentConfidence;
    if (ratio <= 0 || ratio >= 1) return 0;

    final totalDays = (-halfLifeDays * log(ratio)).ceil();
    final remainingDays = totalDays - currentAge;

    return remainingDays > 0 ? remainingDays : 0;
  }

  /// Returns human-readable decay status
  static String getDecayStatus(double freshness) {
    if (freshness >= 0.9) return 'Fresh';
    if (freshness >= 0.7) return 'Recent';
    if (freshness >= 0.5) return 'Aging';
    if (freshness >= 0.3) return 'Stale';
    if (freshness >= 0.1) return 'Decaying';
    return 'Expired';
  }
}