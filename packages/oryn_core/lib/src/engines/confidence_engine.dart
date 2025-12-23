import 'dart:math';
import '../models/claim.dart';
import '../models/evidence.dart';
import '../models/counter_evidence.dart';
import 'decay_engine.dart';

/// Confidence Engine
///
/// Computes provisional truth numerically.
/// Confidence is derived, never manually set.
///
/// Pure Dart. No external dependencies.
class ConfidenceEngine {

  /// Computes confidence score for a claim
  ///
  /// Returns value between 0.0 and 1.0
  static double compute(Claim claim, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();

    // Calculate weighted evidence sum
    final evidenceScore = _calculateEvidenceScore(
      claim.evidenceList,
      claim.decayHalfLifeDays,
      now,
    );

    // Calculate weighted counter-evidence sum
    final counterScore = _calculateCounterEvidenceScore(
      claim.counterEvidenceList,
      claim.decayHalfLifeDays,
      now,
    );

    // Calculate claim decay factor
    final claimDecay = DecayEngine.calculateClaimDecay(
      lastVerifiedAt: claim.lastVerifiedAt,
      halfLifeDays: claim.decayHalfLifeDays,
      currentTime: now,
    );

    // Raw score: evidence minus counter-evidence
    final rawScore = evidenceScore - counterScore;

    // Apply claim decay
    final decayedScore = rawScore * claimDecay;

    // Normalize to 0.0 - 1.0 range
    return _normalize(decayedScore);
  }

  /// Computes confidence and returns updated claim
  static Claim computeAndUpdate(Claim claim, {DateTime? currentTime}) {
    final confidence = compute(claim, currentTime: currentTime);
    return claim.withConfidence(confidence);
  }

  /// Returns detailed breakdown of confidence calculation
  static ConfidenceBreakdown getBreakdown(Claim claim, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();

    final evidenceScore = _calculateEvidenceScore(
      claim.evidenceList,
      claim.decayHalfLifeDays,
      now,
    );

    final counterScore = _calculateCounterEvidenceScore(
      claim.counterEvidenceList,
      claim.decayHalfLifeDays,
      now,
    );

    final claimDecay = DecayEngine.calculateClaimDecay(
      lastVerifiedAt: claim.lastVerifiedAt,
      halfLifeDays: claim.decayHalfLifeDays,
      currentTime: now,
    );

    final rawScore = evidenceScore - counterScore;
    final decayedScore = rawScore * claimDecay;
    final finalConfidence = _normalize(decayedScore);

    return ConfidenceBreakdown(
      evidenceScore: evidenceScore,
      counterEvidenceScore: counterScore,
      claimDecayFactor: claimDecay,
      rawScore: rawScore,
      decayedScore: decayedScore,
      finalConfidence: finalConfidence,
      evidenceCount: claim.evidenceList.length,
      counterEvidenceCount: claim.counterEvidenceList.length,
    );
  }

  /// Returns human-readable confidence level
  static ConfidenceLevel getConfidenceLevel(double confidence) {
    if (confidence >= 0.9) return ConfidenceLevel.veryHigh;
    if (confidence >= 0.7) return ConfidenceLevel.high;
    if (confidence >= 0.5) return ConfidenceLevel.moderate;
    if (confidence >= 0.3) return ConfidenceLevel.low;
    if (confidence >= 0.1) return ConfidenceLevel.veryLow;
    return ConfidenceLevel.unverified;
  }

  static double _calculateEvidenceScore(
      List<Evidence> evidenceList,
      int halfLifeDays,
      DateTime now,
      ) {
    if (evidenceList.isEmpty) return 0.0;

    double totalScore = 0.0;

    for (final evidence in evidenceList) {
      final freshness = DecayEngine.calculateFreshness(
        addedAt: evidence.addedAt,
        halfLifeDays: halfLifeDays,
        currentTime: now,
      );

      totalScore += evidence.strength * freshness;
    }

    return totalScore;
  }

  static double _calculateCounterEvidenceScore(
      List<CounterEvidence> counterList,
      int halfLifeDays,
      DateTime now,
      ) {
    if (counterList.isEmpty) return 0.0;

    double totalScore = 0.0;

    for (final counter in counterList) {
      final freshness = DecayEngine.calculateFreshness(
        addedAt: counter.addedAt,
        halfLifeDays: halfLifeDays,
        currentTime: now,
      );

      totalScore += counter.strength * freshness;
    }

    return totalScore;
  }

  /// Hyperbolic tangent
  static double _tanh(double x) {
    final expX = exp(x);
    final expNegX = exp(-x);
    return (expX - expNegX) / (expX + expNegX);
  }

  /// Normalizes score to 0.0 - 1.0 range
  static double _normalize(double rawScore) {
    if (rawScore == 0) return 0.5;
    return (_tanh(rawScore) + 1) / 2;
  }
}

/// Confidence level categories
enum ConfidenceLevel {
  veryHigh,
  high,
  moderate,
  low,
  veryLow,
  unverified,
}

extension ConfidenceLevelExtension on ConfidenceLevel {
  String get displayName {
    switch (this) {
      case ConfidenceLevel.veryHigh:
        return 'Very High';
      case ConfidenceLevel.high:
        return 'High';
      case ConfidenceLevel.moderate:
        return 'Moderate';
      case ConfidenceLevel.low:
        return 'Low';
      case ConfidenceLevel.veryLow:
        return 'Very Low';
      case ConfidenceLevel.unverified:
        return 'Unverified';
    }
  }
}

/// Detailed breakdown of confidence calculation
class ConfidenceBreakdown {
  final double evidenceScore;
  final double counterEvidenceScore;
  final double claimDecayFactor;
  final double rawScore;
  final double decayedScore;
  final double finalConfidence;
  final int evidenceCount;
  final int counterEvidenceCount;

  const ConfidenceBreakdown({
    required this.evidenceScore,
    required this.counterEvidenceScore,
    required this.claimDecayFactor,
    required this.rawScore,
    required this.decayedScore,
    required this.finalConfidence,
    required this.evidenceCount,
    required this.counterEvidenceCount,
  });

  @override
  String toString() {
    return '''
ConfidenceBreakdown:
  Evidence Score: ${evidenceScore.toStringAsFixed(4)} ($evidenceCount items)
  Counter Score: ${counterEvidenceScore.toStringAsFixed(4)} ($counterEvidenceCount items)
  Claim Decay: ${claimDecayFactor.toStringAsFixed(4)}
  Raw Score: ${rawScore.toStringAsFixed(4)}
  Decayed Score: ${decayedScore.toStringAsFixed(4)}
  Final Confidence: ${finalConfidence.toStringAsFixed(4)}
''';
  }
}