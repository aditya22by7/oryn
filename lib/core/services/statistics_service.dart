import '../models/claim.dart';
import '../../data/repositories/claim_repository.dart';

/// Statistics Service
///
/// Calculates overview statistics for all claims.
class StatisticsService {

  /// Gets complete statistics for all claims
  static Future<ClaimStatistics> getStatistics() async {
    final claims = await ClaimRepository.getAllClaims();

    if (claims.isEmpty) {
      return ClaimStatistics.empty();
    }

    // Count by confidence level
    int highConfidence = 0;
    int moderateConfidence = 0;
    int lowConfidence = 0;
    int unverified = 0;

    // Count by evidence
    int withEvidence = 0;
    int withCounterEvidence = 0;
    int noEvidence = 0;

    // Needs attention
    int needsReverification = 0;

    // Totals
    int totalEvidence = 0;
    int totalCounterEvidence = 0;
    double totalConfidence = 0;

    // Scopes
    final scopeCounts = <String, int>{};

    for (final claim in claims) {
      // Confidence levels
      if (claim.confidenceScore >= 0.7) {
        highConfidence++;
      } else if (claim.confidenceScore >= 0.4) {
        moderateConfidence++;
      } else if (claim.confidenceScore >= 0.1) {
        lowConfidence++;
      } else {
        unverified++;
      }

      // Evidence counts
      if (claim.evidenceList.isNotEmpty) {
        withEvidence++;
      }
      if (claim.counterEvidenceList.isNotEmpty) {
        withCounterEvidence++;
      }
      if (claim.evidenceList.isEmpty && claim.counterEvidenceList.isEmpty) {
        noEvidence++;
      }

      // Needs reverification (confidence < 0.3)
      if (claim.confidenceScore < 0.3) {
        needsReverification++;
      }

      // Totals
      totalEvidence += claim.evidenceList.length;
      totalCounterEvidence += claim.counterEvidenceList.length;
      totalConfidence += claim.confidenceScore;

      // Scopes
      if (claim.scope != null && claim.scope!.isNotEmpty) {
        scopeCounts[claim.scope!] = (scopeCounts[claim.scope!] ?? 0) + 1;
      }
    }

    // Sort scopes by count
    final sortedScopes = scopeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ClaimStatistics(
      totalClaims: claims.length,
      highConfidence: highConfidence,
      moderateConfidence: moderateConfidence,
      lowConfidence: lowConfidence,
      unverified: unverified,
      withEvidence: withEvidence,
      withCounterEvidence: withCounterEvidence,
      noEvidence: noEvidence,
      needsReverification: needsReverification,
      totalEvidence: totalEvidence,
      totalCounterEvidence: totalCounterEvidence,
      averageConfidence: totalConfidence / claims.length,
      topScopes: sortedScopes.take(5).map((e) => ScopeCount(e.key, e.value)).toList(),
    );
  }
}

/// Statistics about all claims
class ClaimStatistics {
  final int totalClaims;
  final int highConfidence;
  final int moderateConfidence;
  final int lowConfidence;
  final int unverified;
  final int withEvidence;
  final int withCounterEvidence;
  final int noEvidence;
  final int needsReverification;
  final int totalEvidence;
  final int totalCounterEvidence;
  final double averageConfidence;
  final List<ScopeCount> topScopes;

  const ClaimStatistics({
    required this.totalClaims,
    required this.highConfidence,
    required this.moderateConfidence,
    required this.lowConfidence,
    required this.unverified,
    required this.withEvidence,
    required this.withCounterEvidence,
    required this.noEvidence,
    required this.needsReverification,
    required this.totalEvidence,
    required this.totalCounterEvidence,
    required this.averageConfidence,
    required this.topScopes,
  });

  factory ClaimStatistics.empty() {
    return const ClaimStatistics(
      totalClaims: 0,
      highConfidence: 0,
      moderateConfidence: 0,
      lowConfidence: 0,
      unverified: 0,
      withEvidence: 0,
      withCounterEvidence: 0,
      noEvidence: 0,
      needsReverification: 0,
      totalEvidence: 0,
      totalCounterEvidence: 0,
      averageConfidence: 0.0,
      topScopes: [],
    );
  }

  bool get isEmpty => totalClaims == 0;
}

/// Scope with count
class ScopeCount {
  final String scope;
  final int count;

  const ScopeCount(this.scope, this.count);
}