import 'package:uuid/uuid.dart';
import '../../models/claim.dart';
import '../../models/evidence.dart';
import '../../models/counter_evidence.dart';
import '../confidence/confidence_engine.dart';

/// Evidence Engine
///
/// Handles adding, removing, and managing evidence and counter-evidence.
/// Every modification triggers confidence recalculation.
class EvidenceEngine {
  static const _uuid = Uuid();

  /// Adds evidence to a claim and returns updated claim with new confidence
  static Claim addEvidence({
    required Claim claim,
    required EvidenceType type,
    required String reference,
    required double strength,
    DateTime? addedAt,
  }) {
    final evidence = Evidence(
      id: _uuid.v4(),
      type: type,
      reference: reference,
      strength: strength.clamp(0.0, 1.0),
      addedAt: addedAt ?? DateTime.now(),
    );

    final updatedEvidenceList = [...claim.evidenceList, evidence];

    final updatedClaim = claim.copyWith(
      evidenceList: updatedEvidenceList,
    );

    // Recalculate confidence
    final newConfidence = ConfidenceEngine.computeConfidence(updatedClaim);

    return updatedClaim.copyWith(confidenceScore: newConfidence);
  }

  /// Removes evidence from a claim by ID and returns updated claim
  static Claim removeEvidence({
    required Claim claim,
    required String evidenceId,
  }) {
    final updatedEvidenceList = claim.evidenceList
        .where((e) => e.id != evidenceId)
        .toList();

    final updatedClaim = claim.copyWith(
      evidenceList: updatedEvidenceList,
    );

    // Recalculate confidence
    final newConfidence = ConfidenceEngine.computeConfidence(updatedClaim);

    return updatedClaim.copyWith(confidenceScore: newConfidence);
  }

  /// Adds counter-evidence to a claim and returns updated claim
  static Claim addCounterEvidence({
    required Claim claim,
    required CounterEvidenceType type,
    required String reference,
    required double strength,
    DateTime? addedAt,
  }) {
    final counter = CounterEvidence(
      id: _uuid.v4(),
      type: type,
      reference: reference,
      strength: strength.clamp(0.0, 1.0),
      addedAt: addedAt ?? DateTime.now(),
    );

    final updatedCounterList = [...claim.counterEvidenceList, counter];

    final updatedClaim = claim.copyWith(
      counterEvidenceList: updatedCounterList,
    );

    // Recalculate confidence
    final newConfidence = ConfidenceEngine.computeConfidence(updatedClaim);

    return updatedClaim.copyWith(confidenceScore: newConfidence);
  }

  /// Removes counter-evidence from a claim by ID
  static Claim removeCounterEvidence({
    required Claim claim,
    required String counterEvidenceId,
  }) {
    final updatedCounterList = claim.counterEvidenceList
        .where((c) => c.id != counterEvidenceId)
        .toList();

    final updatedClaim = claim.copyWith(
      counterEvidenceList: updatedCounterList,
    );

    // Recalculate confidence
    final newConfidence = ConfidenceEngine.computeConfidence(updatedClaim);

    return updatedClaim.copyWith(confidenceScore: newConfidence);
  }

  /// Updates strength of existing evidence
  static Claim updateEvidenceStrength({
    required Claim claim,
    required String evidenceId,
    required double newStrength,
  }) {
    final updatedEvidenceList = claim.evidenceList.map((e) {
      if (e.id == evidenceId) {
        return Evidence(
          id: e.id,
          type: e.type,
          reference: e.reference,
          addedAt: e.addedAt,
          strength: newStrength.clamp(0.0, 1.0),
        );
      }
      return e;
    }).toList();

    final updatedClaim = claim.copyWith(
      evidenceList: updatedEvidenceList,
    );

    final newConfidence = ConfidenceEngine.computeConfidence(updatedClaim);

    return updatedClaim.copyWith(confidenceScore: newConfidence);
  }

  /// Updates strength of existing counter-evidence
  static Claim updateCounterEvidenceStrength({
    required Claim claim,
    required String counterEvidenceId,
    required double newStrength,
  }) {
    final updatedCounterList = claim.counterEvidenceList.map((c) {
      if (c.id == counterEvidenceId) {
        return CounterEvidence(
          id: c.id,
          type: c.type,
          reference: c.reference,
          addedAt: c.addedAt,
          strength: newStrength.clamp(0.0, 1.0),
        );
      }
      return c;
    }).toList();

    final updatedClaim = claim.copyWith(
      counterEvidenceList: updatedCounterList,
    );

    final newConfidence = ConfidenceEngine.computeConfidence(updatedClaim);

    return updatedClaim.copyWith(confidenceScore: newConfidence);
  }
}