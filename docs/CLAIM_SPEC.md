# Oryn Protocol Specification

Version: 0.0.1
Status: Draft
Last Updated: 2024

## 1. Overview

Oryn is a truth-resolution protocol where claims exist only while they can be continuously proven, challenged, and re-validated over time.

This document defines the protocol precisely. Any implementation that follows this specification MUST produce identical outputs for identical inputs.

## 2. Definitions

### 2.1 Claim

A Claim is the atomic unit of the Oryn protocol.

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| id | string | Yes | UUID v4 format, immutable after creation |
| statement | string | Yes | 1-1000 characters, UTF-8 |
| scope | string | No | 0-200 characters, UTF-8 |
| created_at | timestamp | Yes | ISO 8601, UTC, immutable after creation |
| last_verified_at | timestamp | Yes | ISO 8601, UTC |
| decay_half_life_days | integer | Yes | Range: 1-3650 |
| evidence | array | No | List of Evidence objects |
| counter_evidence | array | No | List of CounterEvidence objects |
| confidence_score | float | Yes | Range: 0.0-1.0, computed only |

### 2.2 Evidence

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| id | string | Yes | UUID v4 format, immutable |
| type | enum | Yes | One of: link, document, dataset, experiment |
| reference | string | Yes | 1-2000 characters |
| added_at | timestamp | Yes | ISO 8601, UTC, immutable |
| strength | float | Yes | Range: 0.0-1.0 |

### 2.3 CounterEvidence

Identical structure to Evidence.

## 3. Mathematical Definitions

### 3.1 Freshness Function

The freshness of evidence measures how recent it is.

Formula:

    freshness(added_at, half_life, now) = e^(-age / half_life)

    where:
      age = (now - added_at) in days
      half_life = decay_half_life_days
      e = Euler's number (2.718281828...)

Properties:
- freshness(0 days) = 1.0
- freshness(half_life days) = 0.5
- freshness(infinity) approaches 0.0
- Always in range (0.0, 1.0]

### 3.2 Evidence Score Function

Formula:

    evidence_score(claim, now) = SUM of (evidence.strength * freshness(evidence.added_at, claim.half_life, now))

    for each evidence in claim.evidence

### 3.3 Counter-Evidence Score Function

Formula:

    counter_score(claim, now) = SUM of (counter.strength * freshness(counter.added_at, claim.half_life, now))

    for each counter in claim.counter_evidence

### 3.4 Claim Decay Factor

Formula:

    decay_factor(claim, now) = freshness(claim.last_verified_at, claim.half_life, now)

### 3.5 Raw Score Function

Formula:

    raw_score(claim, now) = (evidence_score - counter_score) * decay_factor

### 3.6 Normalization Function

Formula:

    normalize(x) = (tanh(x) + 1) / 2

    where:
      tanh(x) = (e^x - e^(-x)) / (e^x + e^(-x))

Properties:
- normalize(negative infinity) approaches 0.0
- normalize(0) = 0.5
- normalize(positive infinity) approaches 1.0
- Always in range (0.0, 1.0)

### 3.7 Confidence Score Function (Final)

Formula:

    confidence(claim, now) = normalize(raw_score(claim, now))

## 4. Invariants

These conditions MUST always hold. Violation indicates implementation bug.

### 4.1 Immutability Invariants

| Field | Rule |
|-------|------|
| claim.id | MUST NOT change after creation |
| claim.created_at | MUST NOT change after creation |
| evidence.id | MUST NOT change after creation |
| evidence.added_at | MUST NOT change after creation |

### 4.2 Range Invariants

| Field | Rule |
|-------|------|
| confidence_score | MUST be in range [0.0, 1.0] |
| evidence.strength | MUST be in range [0.0, 1.0] |
| decay_half_life_days | MUST be in range [1, 3650] |
| freshness output | MUST be in range (0.0, 1.0] |

### 4.3 Computation Invariants

| Rule | Description |
|------|-------------|
| Determinism | Same inputs MUST produce same outputs |
| No manual confidence | confidence_score MUST only be set by computation |
| Monotonic time | now MUST always be >= created_at |

### 4.4 Structural Invariants

| Rule | Description |
|------|-------------|
| Evidence independence | Removing evidence A MUST NOT affect evidence B |
| Claim independence | Modifying claim A MUST NOT affect claim B |
| No circular references | Claims MUST NOT reference themselves |

## 5. Undefined Behavior

The following scenarios are explicitly undefined. Implementations MAY handle them differently.

| Scenario | Why Undefined |
|----------|---------------|
| now < created_at | Time travel not supported |
| now < evidence.added_at | Time travel not supported |
| NaN or Infinity in calculations | Floating point edge cases |
| Empty statement | Protocol requires statement |
| decay_half_life_days = 0 | Division by zero |
| Concurrent modifications | No sync protocol defined |

Implementations SHOULD reject undefined inputs rather than produce undefined outputs.

## 6. Deterministic Test Vectors

Any Oryn implementation MUST pass these tests exactly.

### Test Vector 1: Empty Claim

Input:
claim.evidence = []
claim.counter_evidence = []
claim.last_verified_at = 2024-01-01T00:00:00Z
claim.decay_half_life_days = 90
now = 2024-01-01T00:00:00Z

Expected:
evidence_score = 0.0
counter_score = 0.0
decay_factor = 1.0
raw_score = 0.0
confidence = 0.5

### Test Vector 2: Single Evidence Fresh

Input:
claim.evidence = [
{ strength: 0.8, added_at: 2024-01-01T00:00:00Z }
]
claim.counter_evidence = []
claim.last_verified_at = 2024-01-01T00:00:00Z
claim.decay_half_life_days = 90
now = 2024-01-01T00:00:00Z

Expected:
evidence_score = 0.8
counter_score = 0.0
decay_factor = 1.0
raw_score = 0.8
confidence = 0.6899744811276125

### Test Vector 3: Evidence After Half-Life

Input:
claim.evidence = [
{ strength: 0.8, added_at: 2024-01-01T00:00:00Z }
]
claim.counter_evidence = []
claim.last_verified_at = 2024-01-01T00:00:00Z
claim.decay_half_life_days = 90
now = 2024-04-01T00:00:00Z  (91 days later)

Expected:
freshness = 0.4965853037914095
evidence_score = 0.3972682430331276
counter_score = 0.0
decay_factor = 0.4965853037914095
raw_score = 0.19729586915912482
confidence = 0.5975965819678779

### Test Vector 4: Evidence vs Counter-Evidence

Input:
claim.evidence = [
{ strength: 0.8, added_at: 2024-01-01T00:00:00Z }
]
claim.counter_evidence = [
{ strength: 0.5, added_at: 2024-01-01T00:00:00Z }
]
claim.last_verified_at = 2024-01-01T00:00:00Z
claim.decay_half_life_days = 90
now = 2024-01-01T00:00:00Z

Expected:
evidence_score = 0.8
counter_score = 0.5
decay_factor = 1.0
raw_score = 0.3
confidence = 0.6456563062257954

### Test Vector 5: Zero Confidence Floor

Input:
claim.evidence = []
claim.counter_evidence = [
{ strength: 1.0, added_at: 2024-01-01T00:00:00Z }
]
claim.last_verified_at = 2024-01-01T00:00:00Z
claim.decay_half_life_days = 90
now = 2024-01-01T00:00:00Z

Expected:
evidence_score = 0.0
counter_score = 1.0
decay_factor = 1.0
raw_score = -1.0
confidence = 0.11920292202211757

## 7. Versioning

### 7.1 Specification Version

This is version 0.0.1 of the Oryn Protocol Specification.

### 7.2 Version Format

    MAJOR.MINOR.PATCH

    MAJOR: Breaking changes to confidence formula
    MINOR: New fields or behaviors
    PATCH: Clarifications only

### 7.3 Compatibility

| Version Change | Confidence Output |
|----------------|-------------------|
| PATCH | Identical |
| MINOR | Identical for existing fields |
| MAJOR | May differ |

## 8. Interoperability

Any system that:

1. Stores claims in this format
2. Computes confidence using these formulas
3. Passes all test vectors

Is Oryn Protocol compliant.

## 9. Reference Implementation

The reference implementation is available at:

https://github.com/aditya22by7/oryn

Language: Dart/Flutter
License: MIT