import 'package:test/test.dart';
import 'package:oryn_core/oryn_core.dart';

void main() {
  group('ConfidenceEngine', () {

    final fixedTime = DateTime.utc(2024, 6, 1, 12, 0, 0);

    group('compute', () {

      test('returns 0.5 for empty claim', () {
        final claim = Claim(
          id: 'test-1',
          protocolVersion: '0.0.1',
          statement: 'Test claim',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [],
          counterEvidenceList: [],
          confidenceScore: 0.0,
        );

        final confidence = ConfidenceEngine.compute(claim, currentTime: fixedTime);
        expect(confidence, equals(0.5));
      });

      test('increases with evidence', () {
        final claim = Claim(
          id: 'test-2',
          protocolVersion: '0.0.1',
          statement: 'Test claim',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [
            Evidence(
              id: 'ev-1',
              type: EvidenceType.link,
              reference: 'https://example.com',
              addedAt: fixedTime,
              strength: 0.8,
            ),
          ],
          counterEvidenceList: [],
          confidenceScore: 0.0,
        );

        final confidence = ConfidenceEngine.compute(claim, currentTime: fixedTime);
        expect(confidence, greaterThan(0.5));
      });

      test('decreases with counter-evidence', () {
        final claim = Claim(
          id: 'test-3',
          protocolVersion: '0.0.1',
          statement: 'Test claim',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [],
          counterEvidenceList: [
            CounterEvidence(
              id: 'ce-1',
              type: CounterEvidenceType.link,
              reference: 'https://example.com',
              addedAt: fixedTime,
              strength: 0.8,
            ),
          ],
          confidenceScore: 0.0,
        );

        final confidence = ConfidenceEngine.compute(claim, currentTime: fixedTime);
        expect(confidence, lessThan(0.5));
      });

      test('balances evidence and counter-evidence', () {
        final claim = Claim(
          id: 'test-4',
          protocolVersion: '0.0.1',
          statement: 'Test claim',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [
            Evidence(
              id: 'ev-1',
              type: EvidenceType.link,
              reference: 'https://example.com',
              addedAt: fixedTime,
              strength: 0.5,
            ),
          ],
          counterEvidenceList: [
            CounterEvidence(
              id: 'ce-1',
              type: CounterEvidenceType.link,
              reference: 'https://counter.com',
              addedAt: fixedTime,
              strength: 0.5,
            ),
          ],
          confidenceScore: 0.0,
        );

        final confidence = ConfidenceEngine.compute(claim, currentTime: fixedTime);
        expect(confidence, closeTo(0.5, 0.01));
      });

      test('is always in range [0, 1]', () {
        // Maximum evidence
        final maxEvidence = Claim(
          id: 'test-5',
          protocolVersion: '0.0.1',
          statement: 'Test claim',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: List.generate(100, (i) => Evidence(
            id: 'ev-$i',
            type: EvidenceType.link,
            reference: 'https://example$i.com',
            addedAt: fixedTime,
            strength: 1.0,
          )),
          counterEvidenceList: [],
          confidenceScore: 0.0,
        );

        final maxConfidence = ConfidenceEngine.compute(maxEvidence, currentTime: fixedTime);
        expect(maxConfidence, lessThanOrEqualTo(1.0));
        expect(maxConfidence, greaterThan(0.9));

        // Maximum counter-evidence
        final maxCounter = Claim(
          id: 'test-6',
          protocolVersion: '0.0.1',
          statement: 'Test claim',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [],
          counterEvidenceList: List.generate(100, (i) => CounterEvidence(
            id: 'ce-$i',
            type: CounterEvidenceType.link,
            reference: 'https://counter$i.com',
            addedAt: fixedTime,
            strength: 1.0,
          )),
          confidenceScore: 0.0,
        );

        final minConfidence = ConfidenceEngine.compute(maxCounter, currentTime: fixedTime);
        expect(minConfidence, greaterThanOrEqualTo(0.0));
        expect(minConfidence, lessThan(0.1));
      });

      test('is deterministic', () {
        final claim = Claim(
          id: 'test-7',
          protocolVersion: '0.0.1',
          statement: 'Test claim',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [
            Evidence(
              id: 'ev-1',
              type: EvidenceType.link,
              reference: 'https://example.com',
              addedAt: fixedTime,
              strength: 0.7,
            ),
          ],
          counterEvidenceList: [
            CounterEvidence(
              id: 'ce-1',
              type: CounterEvidenceType.link,
              reference: 'https://counter.com',
              addedAt: fixedTime,
              strength: 0.3,
            ),
          ],
          confidenceScore: 0.0,
        );

        final confidence1 = ConfidenceEngine.compute(claim, currentTime: fixedTime);
        final confidence2 = ConfidenceEngine.compute(claim, currentTime: fixedTime);

        expect(confidence1, equals(confidence2));
      });

    });

    group('getConfidenceLevel', () {

      test('returns correct levels', () {
        expect(ConfidenceEngine.getConfidenceLevel(0.95), equals(ConfidenceLevel.veryHigh));
        expect(ConfidenceEngine.getConfidenceLevel(0.75), equals(ConfidenceLevel.high));
        expect(ConfidenceEngine.getConfidenceLevel(0.55), equals(ConfidenceLevel.moderate));
        expect(ConfidenceEngine.getConfidenceLevel(0.35), equals(ConfidenceLevel.low));
        expect(ConfidenceEngine.getConfidenceLevel(0.15), equals(ConfidenceLevel.veryLow));
        expect(ConfidenceEngine.getConfidenceLevel(0.05), equals(ConfidenceLevel.unverified));
      });

    });

  });
}