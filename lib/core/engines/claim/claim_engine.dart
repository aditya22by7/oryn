import '../../models/claim.dart';
import '../confidence/confidence_engine.dart';

/// Claim Engine
///
/// Handles CRUD operations for claims.
/// Manages claim lifecycle: creation, verification, decay.
class ClaimEngine {

  /// Creates a new claim with initial confidence of 0
  static Claim createClaim({
    required String statement,
    String? scope,
    int decayHalfLifeDays = 90,
  }) {
    return Claim.create(
      statement: statement,
      scope: scope,
      decayHalfLifeDays: decayHalfLifeDays,
    );
  }

  /// Updates claim statement and/or scope
  static Claim editClaim({
    required Claim claim,
    String? statement,
    String? scope,
    int? decayHalfLifeDays,
  }) {
    final updatedClaim = claim.copyWith(
      statement: statement ?? claim.statement,
      scope: scope ?? claim.scope,
      decayHalfLifeDays: decayHalfLifeDays ?? claim.decayHalfLifeDays,
    );

    // Recalculate confidence in case decay changed
    final newConfidence = ConfidenceEngine.computeConfidence(updatedClaim);

    return updatedClaim.copyWith(confidenceScore: newConfidence);
  }

  /// Re-verifies a claim - resets the decay timer
  ///
  /// This is the mechanism to keep a claim "alive"
  /// Without re-verification, confidence naturally decays
  static Claim reverifyClaim(Claim claim) {
    final updatedClaim = claim.copyWith(
      lastVerifiedAt: DateTime.now(),
    );

    // Recalculate confidence with new verification time
    final newConfidence = ConfidenceEngine.computeConfidence(updatedClaim);

    return updatedClaim.copyWith(confidenceScore: newConfidence);
  }

  /// Recalculates confidence for a claim
  ///
  /// Use this when displaying claims to get current confidence
  /// (accounts for time decay since last calculation)
  static Claim refreshConfidence(Claim claim) {
    final newConfidence = ConfidenceEngine.computeConfidence(claim);
    return claim.copyWith(confidenceScore: newConfidence);
  }

  /// Checks if claim needs re-verification
  ///
  /// Returns true if confidence has dropped below threshold
  static bool needsReverification(Claim claim, {double threshold = 0.3}) {
    final currentConfidence = ConfidenceEngine.computeConfidence(claim);
    return currentConfidence < threshold;
  }

  /// Gets claim age in days
  static int getClaimAgeDays(Claim claim) {
    if (claim.createdAt == null) return 0;
    return DateTime.now().difference(claim.createdAt!).inDays;
  }

  /// Gets days since last verification
  static int getDaysSinceVerification(Claim claim) {
    final lastVerified = claim.lastVerifiedAt ?? claim.createdAt;
    if (lastVerified == null) return 0;
    return DateTime.now().difference(lastVerified).inDays;
  }

  /// Validates claim data
  static ClaimValidation validateClaim(Claim claim) {
    final errors = <String>[];

    if (claim.statement == null || claim.statement!.trim().isEmpty) {
      errors.add('Statement is required');
    }

    if (claim.statement != null && claim.statement!.length > 1000) {
      errors.add('Statement must be less than 1000 characters');
    }

    if (claim.decayHalfLifeDays < 1) {
      errors.add('Decay half-life must be at least 1 day');
    }

    if (claim.decayHalfLifeDays > 3650) {
      errors.add('Decay half-life must be less than 10 years');
    }

    return ClaimValidation(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// Result of claim validation
class ClaimValidation {
  final bool isValid;
  final List<String> errors;

  const ClaimValidation({
    required this.isValid,
    required this.errors,
  });
}