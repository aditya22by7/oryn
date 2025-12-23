# oryn_core

Core engine for the Oryn truth-resolution protocol.

## Features

- Pure Dart (no Flutter dependency)
- Zero external dependencies
- Deterministic confidence computation
- Time-based decay engine
- Claim validation

## Installation

Add to your pubspec.yaml:

    dependencies:
      oryn_core:
        path: packages/oryn_core

## Usage

    import 'package:oryn_core/oryn_core.dart';

    // Create a claim
    final claim = Claim.create(
      statement: 'The Earth orbits the Sun',
      scope: 'Astronomy',
    );

    // Add evidence
    final claimWithEvidence = claim.addEvidence(
      Evidence.create(
        type: EvidenceType.link,
        reference: 'https://nasa.gov/solar-system',
        strength: 0.8,
      ),
    );

    // Compute confidence
    final confidence = ConfidenceEngine.compute(claimWithEvidence);
    print('Confidence: $confidence'); // 0.0 - 1.0

## Protocol Version

This package implements Oryn Protocol v0.0.1.

## License

MIT License