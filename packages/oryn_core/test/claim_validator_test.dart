import 'package:test/test.dart';
import 'package:oryn_core/oryn_core.dart';

void main() {
  group('ClaimValidator', () {

    final fixedTime = DateTime.utc(2024, 6, 1, 12, 0, 0);

    group('validateClaim', () {

      test('accepts valid claim', () {
        final claim = Claim(
          id: 'test-1',
          protocolVersion: '0.0.1',
          statement: 'This is a valid test claim',
          scope: 'Testing',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [],
          counterEvidenceList: [],
          confidenceScore: 0.5,
        );

        final result = ClaimValidator.validateClaim(claim);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('rejects empty statement', () {
        final claim = Claim(
          id: 'test-2',
          protocolVersion: '0.0.1',
          statement: '',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [],
          counterEvidenceList: [],
          confidenceScore: 0.5,
        );

        final result = ClaimValidator.validateClaim(claim);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Statement is required'));
      });

      test('rejects statement over 1000 characters', () {
        final claim = Claim(
          id: 'test-3',
          protocolVersion: '0.0.1',
          statement: 'x' * 1001,
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [],
          counterEvidenceList: [],
          confidenceScore: 0.5,
        );

        final result = ClaimValidator.validateClaim(claim);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Statement must be 1000 characters or less'));
      });

      test('rejects invalid half-life', () {
        final claim = Claim(
          id: 'test-4',
          protocolVersion: '0.0.1',
          statement: 'Valid statement',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 0,
          evidenceList: [],
          counterEvidenceList: [],
          confidenceScore: 0.5,
        );

        final result = ClaimValidator.validateClaim(claim);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Decay half-life must be at least 1 day'));
      });

      test('rejects confidence out of range', () {
        final claim = Claim(
          id: 'test-5',
          protocolVersion: '0.0.1',
          statement: 'Valid statement',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [],
          counterEvidenceList: [],
          confidenceScore: 1.5,
        );

        final result = ClaimValidator.validateClaim(claim);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Confidence score must be between 0.0 and 1.0'));
      });

      test('detects duplicate evidence IDs', () {
        final claim = Claim(
          id: 'test-6',
          protocolVersion: '0.0.1',
          statement: 'Valid statement',
          createdAt: fixedTime,
          lastVerifiedAt: fixedTime,
          decayHalfLifeDays: 90,
          evidenceList: [
            Evidence(
              id: 'same-id',
              type: EvidenceType.link,
              reference: 'https://example1.com',
              addedAt: fixedTime,
              strength: 0.5,
            ),
            Evidence(
              id: 'same-id',
              type: EvidenceType.link,
              reference: 'https://example2.com',
              addedAt: fixedTime,
              strength: 0.5,
            ),
          ],
          counterEvidenceList: [],
          confidenceScore: 0.5,
        );

        final result = ClaimValidator.validateClaim(claim);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Duplicate evidence IDs detected'));
      });

    });

    group('validateEvidence', () {

      test('accepts valid evidence', () {
        final evidence = Evidence(
          id: 'ev-1',
          type: EvidenceType.link,
          reference: 'https://example.com',
          addedAt: fixedTime,
          strength: 0.8,
        );

        final result = ClaimValidator.validateEvidence(evidence);
        expect(result.isValid, isTrue);
      });

      test('rejects empty reference', () {
        final evidence = Evidence(
          id: 'ev-2',
          type: EvidenceType.link,
          reference: '',
          addedAt: fixedTime,
          strength: 0.8,
        );

        final result = ClaimValidator.validateEvidence(evidence);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Reference is required'));
      });

      test('rejects strength out of range', () {
        final evidence = Evidence(
          id: 'ev-3',
          type: EvidenceType.link,
          reference: 'https://example.com',
          addedAt: fixedTime,
          strength: 1.5,
        );

        final result = ClaimValidator.validateEvidence(evidence);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Strength must be between 0.0 and 1.0'));
      });

      test('warns on zero strength', () {
        final evidence = Evidence(
          id: 'ev-4',
          type: EvidenceType.link,
          reference: 'https://example.com',
          addedAt: fixedTime,
          strength: 0.0,
        );

        final result = ClaimValidator.validateEvidence(evidence);
        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isTrue);
        expect(result.warnings, contains('Evidence has zero strength (contributes nothing)'));
      });

    });

    group('validateForCreation', () {

      test('accepts valid creation parameters', () {
        final result = ClaimValidator.validateForCreation(
          statement: 'This is a valid claim',
          scope: 'Testing',
          decayHalfLifeDays: 90,
        );

        expect(result.isValid, isTrue);
      });

      test('rejects empty statement', () {
        final result = ClaimValidator.validateForCreation(
          statement: '   ',
          decayHalfLifeDays: 90,
        );

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Statement is required'));
      });

    });

  });
}