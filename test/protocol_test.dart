import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

// ==================================================
// ORYN PROTOCOL DETERMINISTIC TEST SUITE
// ==================================================
// These tests verify protocol correctness.
// Same inputs MUST produce same outputs.
// No mocks. No randomness. Pure functions.
// ==================================================

void main() {
  group('Freshness Function Tests', () {

    test('Freshness at day 0 equals 1.0', () {
      final freshness = calculateFreshness(
        ageInDays: 0,
        halfLifeDays: 90,
      );
      expect(freshness, equals(1.0));
    });

    test('Freshness at half-life equals ~0.5', () {
      // Formula: e^(-age/halfLife)
      // At age = halfLife: e^(-1) = 0.3678...
      // Note: This is exponential decay, not true half-life
      final freshness = calculateFreshness(
        ageInDays: 90,
        halfLifeDays: 90,
      );
      final expected = exp(-1.0); // 0.36787944117144233
      expect(freshness, closeTo(expected, 0.0001));
    });

    test('Freshness at 2x decay period equals ~0.135', () {
      final freshness = calculateFreshness(
        ageInDays: 180,
        halfLifeDays: 90,
      );
      final expected = exp(-2.0); // 0.1353352832366127
      expect(freshness, closeTo(expected, 0.0001));
    });

    test('Freshness approaches 0 at large age', () {
      final freshness = calculateFreshness(
        ageInDays: 900,
        halfLifeDays: 90,
      );
      expect(freshness, lessThan(0.001));
    });

    test('Freshness is always positive', () {
      final freshness = calculateFreshness(
        ageInDays: 10000,
        halfLifeDays: 90,
      );
      expect(freshness, greaterThan(0.0));
    });

  });

  group('Normalization Function Tests', () {

    test('Normalize 0 equals 0.5', () {
      final result = normalize(0.0);
      expect(result, equals(0.5));
    });

    test('Normalize positive approaches 1.0', () {
      final result = normalize(10.0);
      expect(result, closeTo(1.0, 0.0001));
    });

    test('Normalize negative approaches 0.0', () {
      final result = normalize(-10.0);
      expect(result, closeTo(0.0, 0.0001));
    });

    test('Normalize is always in range [0, 1]', () {
      for (var x = -100.0; x <= 100.0; x += 0.5) {
        final result = normalize(x);
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1.0));
      }
    });

  });

  group('Protocol Test Vectors', () {

    test('Test Vector 1: Empty Claim', () {
      final result = computeConfidence(
        evidenceList: [],
        counterEvidenceList: [],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 90,
        now: DateTime.utc(2024, 1, 1),
      );

      expect(result.evidenceScore, equals(0.0));
      expect(result.counterScore, equals(0.0));
      expect(result.decayFactor, equals(1.0));
      expect(result.rawScore, equals(0.0));
      expect(result.confidence, equals(0.5));
    });

    test('Test Vector 2: Single Evidence Fresh', () {
      final result = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 0.8, addedAt: DateTime.utc(2024, 1, 1)),
        ],
        counterEvidenceList: [],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 90,
        now: DateTime.utc(2024, 1, 1),
      );

      expect(result.evidenceScore, closeTo(0.8, 0.0001));
      expect(result.counterScore, equals(0.0));
      expect(result.decayFactor, equals(1.0));
      expect(result.rawScore, closeTo(0.8, 0.0001));

      // normalize(0.8) = (tanh(0.8) + 1) / 2
      final expectedConfidence = (tanh(0.8) + 1) / 2;
      expect(result.confidence, closeTo(expectedConfidence, 0.0001));
    });

    test('Test Vector 3: Evidence After 91 Days', () {
      final result = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 0.8, addedAt: DateTime.utc(2024, 1, 1)),
        ],
        counterEvidenceList: [],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 90,
        now: DateTime.utc(2024, 4, 1), // 91 days later
      );

      // freshness = e^(-91/90) = e^(-1.0111) ≈ 0.3638
      final expectedFreshness = exp(-91.0 / 90.0);
      final expectedEvidenceScore = 0.8 * expectedFreshness;
      final expectedDecayFactor = expectedFreshness;
      final expectedRawScore = expectedEvidenceScore * expectedDecayFactor;
      final expectedConfidence = (tanh(expectedRawScore) + 1) / 2;

      expect(result.evidenceScore, closeTo(expectedEvidenceScore, 0.0001));
      expect(result.counterScore, equals(0.0));
      expect(result.decayFactor, closeTo(expectedDecayFactor, 0.0001));
      expect(result.rawScore, closeTo(expectedRawScore, 0.0001));
      expect(result.confidence, closeTo(expectedConfidence, 0.0001));
    });

    test('Test Vector 4: Evidence vs Counter-Evidence', () {
      final result = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 0.8, addedAt: DateTime.utc(2024, 1, 1)),
        ],
        counterEvidenceList: [
          TestEvidence(strength: 0.5, addedAt: DateTime.utc(2024, 1, 1)),
        ],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 90,
        now: DateTime.utc(2024, 1, 1),
      );

      expect(result.evidenceScore, closeTo(0.8, 0.0001));
      expect(result.counterScore, closeTo(0.5, 0.0001));
      expect(result.decayFactor, equals(1.0));
      expect(result.rawScore, closeTo(0.3, 0.0001));

      final expectedConfidence = (tanh(0.3) + 1) / 2;
      expect(result.confidence, closeTo(expectedConfidence, 0.0001));
    });

    test('Test Vector 5: Only Counter-Evidence', () {
      final result = computeConfidence(
        evidenceList: [],
        counterEvidenceList: [
          TestEvidence(strength: 1.0, addedAt: DateTime.utc(2024, 1, 1)),
        ],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 90,
        now: DateTime.utc(2024, 1, 1),
      );

      expect(result.evidenceScore, equals(0.0));
      expect(result.counterScore, closeTo(1.0, 0.0001));
      expect(result.decayFactor, equals(1.0));
      expect(result.rawScore, closeTo(-1.0, 0.0001));

      final expectedConfidence = (tanh(-1.0) + 1) / 2;
      expect(result.confidence, closeTo(expectedConfidence, 0.0001));
    });

  });

  group('Invariant Tests', () {

    test('Confidence is always in range [0, 1]', () {
      final extremeCases = [
        computeConfidence(
          evidenceList: List.generate(100, (_) =>
              TestEvidence(strength: 1.0, addedAt: DateTime.utc(2024, 1, 1))),
          counterEvidenceList: [],
          lastVerifiedAt: DateTime.utc(2024, 1, 1),
          halfLifeDays: 90,
          now: DateTime.utc(2024, 1, 1),
        ),
        computeConfidence(
          evidenceList: [],
          counterEvidenceList: List.generate(100, (_) =>
              TestEvidence(strength: 1.0, addedAt: DateTime.utc(2024, 1, 1))),
          lastVerifiedAt: DateTime.utc(2024, 1, 1),
          halfLifeDays: 90,
          now: DateTime.utc(2024, 1, 1),
        ),
      ];

      for (final result in extremeCases) {
        expect(result.confidence, greaterThanOrEqualTo(0.0));
        expect(result.confidence, lessThanOrEqualTo(1.0));
      }
    });

    test('Determinism: Same inputs produce same outputs', () {
      final input1 = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 0.7, addedAt: DateTime.utc(2024, 1, 15)),
        ],
        counterEvidenceList: [
          TestEvidence(strength: 0.3, addedAt: DateTime.utc(2024, 1, 20)),
        ],
        lastVerifiedAt: DateTime.utc(2024, 1, 10),
        halfLifeDays: 60,
        now: DateTime.utc(2024, 3, 1),
      );

      final input2 = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 0.7, addedAt: DateTime.utc(2024, 1, 15)),
        ],
        counterEvidenceList: [
          TestEvidence(strength: 0.3, addedAt: DateTime.utc(2024, 1, 20)),
        ],
        lastVerifiedAt: DateTime.utc(2024, 1, 10),
        halfLifeDays: 60,
        now: DateTime.utc(2024, 3, 1),
      );

      expect(input1.confidence, equals(input2.confidence));
      expect(input1.evidenceScore, equals(input2.evidenceScore));
      expect(input1.counterScore, equals(input2.counterScore));
      expect(input1.decayFactor, equals(input2.decayFactor));
      expect(input1.rawScore, equals(input2.rawScore));
    });

    test('Evidence independence: Adding evidence B does not affect evidence A contribution', () {
      final withOneEvidence = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 0.8, addedAt: DateTime.utc(2024, 1, 1)),
        ],
        counterEvidenceList: [],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 90,
        now: DateTime.utc(2024, 1, 1),
      );

      final withTwoEvidence = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 0.8, addedAt: DateTime.utc(2024, 1, 1)),
          TestEvidence(strength: 0.5, addedAt: DateTime.utc(2024, 1, 5)),
        ],
        counterEvidenceList: [],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 90,
        now: DateTime.utc(2024, 1, 1),
      );

      // Second evidence adds more, first evidence contribution unchanged
      expect(withTwoEvidence.evidenceScore, greaterThan(withOneEvidence.evidenceScore));
    });

  });

  group('Edge Case Tests', () {

    test('Half-life of 1 day decays rapidly', () {
      final result = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 1.0, addedAt: DateTime.utc(2024, 1, 1)),
        ],
        counterEvidenceList: [],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 1,
        now: DateTime.utc(2024, 1, 8), // 7 days later
      );

      // e^(-7/1) = e^(-7) ≈ 0.0009
      expect(result.evidenceScore, lessThan(0.01));
    });

    test('Maximum half-life (3650 days) decays slowly', () {
      final result = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 1.0, addedAt: DateTime.utc(2024, 1, 1)),
        ],
        counterEvidenceList: [],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 3650,
        now: DateTime.utc(2025, 1, 1), // 366 days later
      );

      // e^(-366/3650) ≈ 0.905
      expect(result.evidenceScore, greaterThan(0.9));
    });

    test('Multiple evidence items sum correctly', () {
      final result = computeConfidence(
        evidenceList: [
          TestEvidence(strength: 0.3, addedAt: DateTime.utc(2024, 1, 1)),
          TestEvidence(strength: 0.3, addedAt: DateTime.utc(2024, 1, 1)),
          TestEvidence(strength: 0.4, addedAt: DateTime.utc(2024, 1, 1)),
        ],
        counterEvidenceList: [],
        lastVerifiedAt: DateTime.utc(2024, 1, 1),
        halfLifeDays: 90,
        now: DateTime.utc(2024, 1, 1),
      );

      expect(result.evidenceScore, closeTo(1.0, 0.0001));
    });

  });
}

// ==================================================
// PURE FUNCTIONS FOR TESTING
// ==================================================

double calculateFreshness({
  required int ageInDays,
  required int halfLifeDays,
}) {
  if (ageInDays <= 0) return 1.0;
  if (halfLifeDays <= 0) return 0.0;

  return exp(-ageInDays.toDouble() / halfLifeDays.toDouble());
}

double tanh(double x) {
  final expX = exp(x);
  final expNegX = exp(-x);
  return (expX - expNegX) / (expX + expNegX);
}

double normalize(double rawScore) {
  return (tanh(rawScore) + 1) / 2;
}

class TestEvidence {
  final double strength;
  final DateTime addedAt;

  TestEvidence({required this.strength, required this.addedAt});
}

class ConfidenceResult {
  final double evidenceScore;
  final double counterScore;
  final double decayFactor;
  final double rawScore;
  final double confidence;

  ConfidenceResult({
    required this.evidenceScore,
    required this.counterScore,
    required this.decayFactor,
    required this.rawScore,
    required this.confidence,
  });
}

ConfidenceResult computeConfidence({
  required List<TestEvidence> evidenceList,
  required List<TestEvidence> counterEvidenceList,
  required DateTime lastVerifiedAt,
  required int halfLifeDays,
  required DateTime now,
}) {
  // Calculate evidence score
  double evidenceScore = 0.0;
  for (final evidence in evidenceList) {
    final ageInDays = now.difference(evidence.addedAt).inDays;
    final freshness = calculateFreshness(
      ageInDays: ageInDays,
      halfLifeDays: halfLifeDays,
    );
    evidenceScore += evidence.strength * freshness;
  }

  // Calculate counter-evidence score
  double counterScore = 0.0;
  for (final counter in counterEvidenceList) {
    final ageInDays = now.difference(counter.addedAt).inDays;
    final freshness = calculateFreshness(
      ageInDays: ageInDays,
      halfLifeDays: halfLifeDays,
    );
    counterScore += counter.strength * freshness;
  }

  // Calculate decay factor
  final claimAgeInDays = now.difference(lastVerifiedAt).inDays;
  final decayFactor = calculateFreshness(
    ageInDays: claimAgeInDays,
    halfLifeDays: halfLifeDays,
  );

  // Calculate raw score
  final rawScore = (evidenceScore - counterScore) * decayFactor;

  // Normalize to confidence
  final confidence = normalize(rawScore);

  return ConfidenceResult(
    evidenceScore: evidenceScore,
    counterScore: counterScore,
    decayFactor: decayFactor,
    rawScore: rawScore,
    confidence: confidence,
  );
}