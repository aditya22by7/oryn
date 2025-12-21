# Oryn Protocol v0.0.1

A truth-resolution protocol where claims exist only while they can be continuously proven, challenged, and re-validated over time.

## 1. What Oryn Is

Oryn is a protocol for evaluating claims based on evidence, counter-evidence, and time decay.

It is:
- A computation model
- A data specification
- A reference implementation

It is not:
- A social network
- A fact-checking service
- An AI truth detector
- A consensus mechanism

## 2. The Claim Object

A claim is the atomic unit of Oryn.

Claim
id                    (UUID, immutable)
statement             (text, 1-1000 chars)
scope                 (optional category)
created_at            (timestamp, immutable)
last_verified_at      (timestamp)
decay_half_life_days  (integer, 1-3650)
evidence[]            (list)
counter_evidence[]    (list)
confidence_score      (0.0-1.0, computed only)

### Evidence Object

Evidence
id          (UUID, immutable)
type        (link | document | dataset | experiment)
reference   (URL or identifier)
added_at    (timestamp, immutable)
strength    (0.0-1.0)

Counter-evidence has identical structure.

## 3. How Confidence Is Computed

Confidence is never set manually. It is always derived.

### 3.1 Freshness Function

    freshness(age, half_life) = e^(-age / half_life)

Where:
- age = days since evidence was added (or claim was verified)
- half_life = claim's decay_half_life_days
- e = Euler's number (2.718...)

### 3.2 Evidence Score

    evidence_score = SUM of (evidence.strength * freshness(evidence.age))

### 3.3 Counter-Evidence Score

    counter_score = SUM of (counter.strength * freshness(counter.age))

### 3.4 Decay Factor

    decay_factor = freshness(days_since_verification, half_life)

### 3.5 Raw Score

    raw_score = (evidence_score - counter_score) * decay_factor

### 3.6 Normalization

    normalize(x) = (tanh(x) + 1) / 2

Where:
tanh(x) = (e^x - e^(-x)) / (e^x + e^(-x))

### 3.7 Final Confidence

    confidence = normalize(raw_score)

## 4. Time Decay

All proof becomes stale.

| Days Since Added | Half-Life 90 | Freshness |
|------------------|--------------|-----------|
| 0                | 90           | 100%      |
| 90               | 90           | 36.8%     |
| 180              | 90           | 13.5%     |
| 365              | 90           | 1.7%      |

This prevents:
- Permanent authority
- Frozen consensus
- Stale claims persisting indefinitely

Re-verification resets the decay timer.

## 5. Invariants

These conditions must always hold:

| Rule | Description |
|------|-------------|
| Immutable IDs | claim.id and evidence.id never change |
| Immutable timestamps | created_at and added_at never change |
| Computed confidence | confidence_score is never manually set |
| Range bounds | All scores remain in [0.0, 1.0] |
| Determinism | Same inputs always produce same outputs |

## 6. What Oryn Does NOT Provide

Oryn explicitly does not provide:

- Truth: It measures confidence, not absolute truth
- Consensus: Users may compute different scores from different evidence
- Authority: No admin roles, no privileged users
- Social validation: No likes, votes, followers, or reputation
- Moderation: No human gatekeeping of claims
- Global agreement: Disagreement is resolved by forking, not arguing

## 7. Reference Implementation

The reference implementation is at:

    https://github.com/aditya22by7/oryn

Language: Dart / Flutter
License: MIT
Version: 0.0.1

## 8. Versioning

    MAJOR.MINOR.PATCH

    MAJOR: Breaking changes to confidence formula
    MINOR: New fields or behaviors (backward compatible)
    PATCH: Clarifications only

This document describes protocol version 0.0.1.

Any implementation that:
1. Uses this data structure
2. Computes confidence using these formulas
3. Respects these invariants

Is Oryn-compatible.

## 9. Design Principles

1. Proof over authority: Evidence determines confidence, not reputation
2. Decay over permanence: All proof must be renewed
3. Computation over declaration: Confidence is derived, never asserted
4. Local over central: No server required
5. Fork over argue: Disagreement creates branches, not conflict

## 10. Closing Note

Oryn is infrastructure.

It does not tell you what is true.
It tells you how confident you can be, given the evidence you have, accounting for time.

What you do with that is up to you.