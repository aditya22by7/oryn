import 'dart:math';
import '../../models/claim.dart';
import '../../models/evidence.dart';
import '../../models/counter_evidence.dart';
import '../decay/decay_engine.dart';

/// Confidence Engine
///
/// Computes provisional truth numerically.
/// Confidence is derived, never manually set.
///
/// Formula:
/// confidence = (Σ evidence_strength × freshness) - (Σ counter_strength × freshness)) × decay_factor
class ConfidenceEngine {

  /// Computes confidence score for a claim
  ///
  /// Returns value between 0.0 and 1.0
  ///
  /// Properties:
  /// - Deterministic
  /// - Reproducible
  /// - Inspectable
  static double computeConfidence(Claim claim, {DateTime? currentTime}) {
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
      lastVerifiedAt: claim.lastVerifiedAt ?? claim.createdAt ?? now,
      halfLifeDays: claim.decayHalfLifeDays,
      currentTime: now,
    );

    // Raw score: evidence minus counter-evidence
    final rawScore = evidenceScore - counterScore;

    // Apply claim decay
    final decayedScore = rawScore * claimDecay;

    // Normalize to 0.0 - 1.0 range
    final normalizedScore = _normalize(decayedScore);

    return normalizedScore;
  }

  /// Calculates total weighted score from evidence list
  static double _calculateEvidenceScore(
      List<Evidence> evidenceList,
      int halfLifeDays,
      DateTime now,
      ) {
    if (evidenceList.isEmpty) return 0.0;

    double totalScore = 0.0;

    for (final evidence in evidenceList) {
      if (evidence.addedAt == null) continue;

      final freshness = DecayEngine.calculateFreshness(
        addedAt: evidence.addedAt!,
        halfLifeDays: halfLifeDays,
        currentTime: now,
      );

      final weightedStrength = evidence.strength * freshness;
      totalScore += weightedStrength;
    }

    return totalScore;
  }

  /// Calculates total weighted score from counter-evidence list
  static double _calculateCounterEvidenceScore(
      List<CounterEvidence> counterList,
      int halfLifeDays,
      DateTime now,
      ) {
    if (counterList.isEmpty) return 0.0;

    double totalScore = 0.0;

    for (final counter in counterList) {
      if (counter.addedAt == null) continue;

      final freshness = DecayEngine.calculateFreshness(
        addedAt: counter.addedAt!,
        halfLifeDays: halfLifeDays,
        currentTime: now,
      );

      final weightedStrength = counter.strength * freshness;
      totalScore += weightedStrength;
    }

    return totalScore;
  }

  /// Calculates hyperbolic tangent manually
  /// tanh(x) = (e^x - e^-x) / (e^x + e^-x)
  static double _tanh(double x) {
    final expX = exp(x);
    final expNegX = exp(-x);
    return (expX - expNegX) / (expX + expNegX);
  }

  /// Normalizes score to 0.0 - 1.0 range using sigmoid-like function
  static double _normalize(double rawScore) {
    // Using tanh for smooth normalization
    // Maps any real number to (-1, 1), then shift to (0, 1)
    if (rawScore == 0) return 0.0;

    final normalized = (_tanh(rawScore) + 1) / 2;

    return normalized.clamp(0.0, 1.0);
  }

  /// Returns detailed breakdown of confidence calculation
  /// Useful for transparency and debugging
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
      lastVerifiedAt: claim.lastVerifiedAt ?? claim.createdAt ?? now,
      halfLifeDays: claim.decayHalfLifeDays,
      currentTime: now,
    );

    final rawScore = evidenceScore - counterScore;
    final decayedScore = rawScore * claimDecay;
    final finalScore = _normalize(decayedScore);

    return ConfidenceBreakdown(
      evidenceScore: evidenceScore,
      counterEvidenceScore: counterScore,
      claimDecayFactor: claimDecay,
      rawScore: rawScore,
      decayedScore: decayedScore,
      finalConfidence: finalScore,
      evidenceCount: claim.evidenceList.length,
      counterEvidenceCount: claim.counterEvidenceList.length,
    );
  }

  /// Returns human-readable confidence level
  static String getConfidenceLevel(double confidence) {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.7) return 'High';
    if (confidence >= 0.5) return 'Moderate';
    if (confidence >= 0.3) return 'Low';
    if (confidence >= 0.1) return 'Very Low';
    return 'Unverified';
  }
}

/// Detailed breakdown of confidence calculation
/// For transparency - shows exactly how confidence was computed
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
Confidence Breakdown:
  Evidence Score: ${evidenceScore.toStringAsFixed(4)} ($evidenceCount items)
  Counter-Evidence Score: ${counterEvidenceScore.toStringAsFixed(4)} ($counterEvidenceCount items)
  Claim Decay Factor: ${claimDecayFactor.toStringAsFixed(4)}
  Raw Score: ${rawScore.toStringAsFixed(4)}
  Decayed Score: ${decayedScore.toStringAsFixed(4)}
  Final Confidence: ${finalConfidence.toStringAsFixed(4)}
''';
  }
}