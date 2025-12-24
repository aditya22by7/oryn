# oryn_core

Core engine for the Oryn truth-resolution protocol.

`oryn_core` is a pure Dart library that evaluates claims over time using:

- Evidence (supporting proof)
- Counter-evidence (challenging proof)
- Time decay (all proof becomes stale)
- Deterministic confidence computation

No Flutter. No I/O. No network. No dependencies.

---

## What It Does

- Represents claims as immutable data structures
- Attaches evidence and counter-evidence
- Applies exponential time decay to all proof
- Computes confidence scores deterministically in [0.0, 1.0]
- Validates claims and evidence against protocol rules

All logic is pure and testable.

---

## What It Does NOT Do

- It does NOT fetch data from the network
- It does NOT persist anything to disk
- It does NOT know about databases, Flutter, or UI
- It does NOT do fact-checking, moderation, or social features
- It does NOT provide "truth", only computed confidence

If you want storage, UI, or sync:  
build it around this library, not inside it.

---

## Protocol Version

This library implements **Oryn Protocol v0.0.1**, as described in:

- ORYN_PROTOCOL.md
- CLAIM_SPEC.md
- INVARIANTS.md
- VERSIONING.md
- EDGE_CASES.md

Repository:  
https://github.com/aditya22by7/oryn

---

## Installation

In your `pubspec.yaml`:

    dependencies:
      oryn_core: ^0.1.0

Then run:

    dart pub get

---

## Basic Usage

    import 'package:oryn_core/oryn_core.dart';
    
    // 1. Create a claim
    final claim = Claim.create(
      statement: 'The Earth orbits the Sun',
      scope: 'Astronomy',
      decayHalfLifeDays: 90,
    );
    
    // 2. Add evidence
    final withEvidence = claim.addEvidence(
      Evidence.create(
        type: EvidenceType.link,
        reference: 'https://nasa.gov/solar-system',
        strength: 0.8,
      ),
    );
    
    // 3. Compute confidence
    final updatedClaim = ConfidenceEngine.computeAndUpdate(withEvidence);
    print('Confidence: ${updatedClaim.confidenceScore}');
    
    // 4. View breakdown (for transparency)
    final breakdown = ConfidenceEngine.getBreakdown(updatedClaim);
    print(breakdown);

---

## API Overview

### Models

**Claim**
- `id`, `statement`, `scope`
- `createdAt`, `lastVerifiedAt`
- `decayHalfLifeDays`
- `evidenceList`, `counterEvidenceList`
- `confidenceScore` (computed)

**Evidence**
- `id`, `type`, `reference`
- `addedAt`, `strength`

**CounterEvidence**
- Same structure as Evidence

### Engines

**DecayEngine**
- `calculateFreshness(...)`
- `calculateClaimDecay(...)`
- `getDecayStatus(...)`

**ConfidenceEngine**
- `compute(Claim)`
- `computeAndUpdate(Claim)`
- `getBreakdown(Claim)`
- `getConfidenceLevel(double)`

### Validators

**ClaimValidator**
- `validateClaim(Claim)`
- `validateEvidence(Evidence)`
- `validateCounterEvidence(CounterEvidence)`
- `validateForCreation(...)`

---

## Determinism

Given the same:

- claim
- evidence and counter-evidence
- timestamps

`ConfidenceEngine.compute` will always return the same confidence value.

There is:

- No randomness
- No global state
- No external I/O

---

## License

MIT License — see LICENSE.