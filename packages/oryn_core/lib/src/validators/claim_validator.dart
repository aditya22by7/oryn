import '../models/claim.dart';
import '../models/evidence.dart';
import '../models/counter_evidence.dart';

/// Claim Validator
///
/// Validates claims and evidence according to protocol rules.
///
/// Pure Dart. No external dependencies.
class ClaimValidator {

  /// Validates a claim
  static ValidationResult validateClaim(Claim claim) {
    final errors = <String>[];
    final warnings = <String>[];

    // Required fields
    if (claim.id.isEmpty) {
      errors.add('Claim ID is required');
    }

    if (claim.statement.isEmpty) {
      errors.add('Statement is required');
    }

    // Length limits
    if (claim.statement.length > 1000) {
      errors.add('Statement must be 1000 characters or less');
    }

    if (claim.scope != null && claim.scope!.length > 200) {
      errors.add('Scope must be 200 characters or less');
    }

    // Range limits
    if (claim.decayHalfLifeDays < 1) {
      errors.add('Decay half-life must be at least 1 day');
    }

    if (claim.decayHalfLifeDays > 3650) {
      errors.add('Decay half-life must be 3650 days or less');
    }

    if (claim.confidenceScore < 0.0 || claim.confidenceScore > 1.0) {
      errors.add('Confidence score must be between 0.0 and 1.0');
    }

    // Timestamp validation
    if (claim.createdAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      errors.add('Created timestamp cannot be in the future');
    }

    if (claim.lastVerifiedAt.isBefore(claim.createdAt)) {
      warnings.add('Last verified timestamp is before created timestamp');
    }

    // Protocol version
    if (claim.protocolVersion.isEmpty) {
      errors.add('Protocol version is required');
    }

    // Validate evidence
    for (int i = 0; i < claim.evidenceList.length; i++) {
      final evidenceResult = validateEvidence(claim.evidenceList[i]);
      for (final error in evidenceResult.errors) {
        errors.add('Evidence[$i]: $error');
      }
      for (final warning in evidenceResult.warnings) {
        warnings.add('Evidence[$i]: $warning');
      }
    }

    // Validate counter-evidence
    for (int i = 0; i < claim.counterEvidenceList.length; i++) {
      final counterResult = validateCounterEvidence(claim.counterEvidenceList[i]);
      for (final error in counterResult.errors) {
        errors.add('CounterEvidence[$i]: $error');
      }
      for (final warning in counterResult.warnings) {
        warnings.add('CounterEvidence[$i]: $warning');
      }
    }

    // Check for duplicate evidence IDs
    final evidenceIds = claim.evidenceList.map((e) => e.id).toSet();
    if (evidenceIds.length != claim.evidenceList.length) {
      errors.add('Duplicate evidence IDs detected');
    }

    // Check for duplicate counter-evidence IDs
    final counterIds = claim.counterEvidenceList.map((c) => c.id).toSet();
    if (counterIds.length != claim.counterEvidenceList.length) {
      errors.add('Duplicate counter-evidence IDs detected');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates evidence
  static ValidationResult validateEvidence(Evidence evidence) {
    final errors = <String>[];
    final warnings = <String>[];

    if (evidence.id.isEmpty) {
      errors.add('Evidence ID is required');
    }

    if (evidence.reference.isEmpty) {
      errors.add('Reference is required');
    }

    if (evidence.reference.length > 2000) {
      errors.add('Reference must be 2000 characters or less');
    }

    if (evidence.strength < 0.0 || evidence.strength > 1.0) {
      errors.add('Strength must be between 0.0 and 1.0');
    }

    if (evidence.addedAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      errors.add('Added timestamp cannot be in the future');
    }

    // Warnings for edge cases
    if (evidence.strength == 0.0) {
      warnings.add('Evidence has zero strength (contributes nothing)');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates counter-evidence
  static ValidationResult validateCounterEvidence(CounterEvidence counter) {
    final errors = <String>[];
    final warnings = <String>[];

    if (counter.id.isEmpty) {
      errors.add('Counter-evidence ID is required');
    }

    if (counter.reference.isEmpty) {
      errors.add('Reference is required');
    }

    if (counter.reference.length > 2000) {
      errors.add('Reference must be 2000 characters or less');
    }

    if (counter.strength < 0.0 || counter.strength > 1.0) {
      errors.add('Strength must be between 0.0 and 1.0');
    }

    if (counter.addedAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      errors.add('Added timestamp cannot be in the future');
    }

    // Warnings for edge cases
    if (counter.strength == 0.0) {
      warnings.add('Counter-evidence has zero strength (contributes nothing)');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates claim for creation (stricter rules)
  static ValidationResult validateForCreation({
    required String statement,
    String? scope,
    int decayHalfLifeDays = 90,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    if (statement.trim().isEmpty) {
      errors.add('Statement is required');
    }

    if (statement.length > 1000) {
      errors.add('Statement must be 1000 characters or less');
    }

    if (scope != null && scope.length > 200) {
      errors.add('Scope must be 200 characters or less');
    }

    if (decayHalfLifeDays < 1 || decayHalfLifeDays > 3650) {
      errors.add('Decay half-life must be between 1 and 3650 days');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// Result of validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() {
    if (isValid && !hasWarnings) {
      return 'ValidationResult: Valid';
    }

    final buffer = StringBuffer('ValidationResult: ');
    buffer.writeln(isValid ? 'Valid with warnings' : 'Invalid');

    if (errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }

    return buffer.toString();
  }
}