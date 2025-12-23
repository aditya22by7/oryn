# Oryn Protocol Invariants

Version: 0.0.1

These rules must never be violated by any Oryn-compatible implementation.

## 1. Immutability Invariants

### 1.1 Claim ID

    Once assigned, claim.id MUST NOT change.

### 1.2 Creation Timestamp

    Once assigned, claim.created_at MUST NOT change.

### 1.3 Evidence ID

    Once assigned, evidence.id MUST NOT change.

### 1.4 Evidence Timestamp

    Once assigned, evidence.added_at MUST NOT change.

Rationale: Immutable identifiers ensure claims and evidence can be referenced reliably across time and systems.

## 2. Computation Invariants

### 2.1 Determinism

    Given identical inputs, confidence computation MUST produce identical outputs.

    Same claim + same evidence + same timestamp = same confidence score.

### 2.2 No Manual Confidence

    confidence_score MUST only be set by computation.
    
    No user, admin, or system may directly assign a confidence value.

### 2.3 No Authority Inputs

    Confidence computation MUST NOT consider:
    - Who created the claim
    - Who added the evidence
    - Reputation scores
    - Vote counts
    - Follower counts
    - Any social metric

Rationale: Authority-based inputs would undermine the proof-driven nature of the protocol.

## 3. Range Invariants

### 3.1 Confidence Score

    confidence_score MUST be in range [0.0, 1.0]

### 3.2 Evidence Strength

    evidence.strength MUST be in range [0.0, 1.0]

### 3.3 Decay Half-Life

    decay_half_life_days MUST be in range [1, 3650]

### 3.4 Freshness

    freshness output MUST be in range (0.0, 1.0]
    
    Freshness is never exactly 0 (asymptotic decay).
    Freshness is exactly 1.0 only when age = 0.

## 4. Decay Invariants

### 4.1 Monotonic Decay

    Freshness MUST decrease monotonically as age increases.
    
    If age_1 < age_2, then freshness(age_1) > freshness(age_2)

### 4.2 Time-Based Only

    Decay MUST be based solely on elapsed time.
    
    No external factors may accelerate or slow decay.

### 4.3 Re-verification Reset

    Re-verifying a claim resets the decay timer for the claim.
    It does NOT reset decay timers for individual evidence.

## 5. Structural Invariants

### 5.1 Evidence Independence

    Adding or removing evidence A MUST NOT affect the stored properties of evidence B.

### 5.2 Claim Independence

    Modifying claim A MUST NOT affect the stored properties of claim B.

### 5.3 No Circular References

    A claim MUST NOT reference itself as evidence (directly or indirectly).

## 6. Behavioral Invariants

### 6.1 Empty Claim

    A claim with no evidence and no counter-evidence:
    - Is valid
    - Has confidence = 0.5 (neutral)
    - Decays over time

### 6.2 Zero Strength Evidence

    Evidence with strength = 0.0:
    - Is valid
    - Contributes nothing to confidence
    - Still decays

### 6.3 Expired Evidence

    Evidence with very low freshness:
    - Remains in the evidence list
    - Contributes negligibly to confidence
    - Is never automatically deleted

## 7. Violation Handling

If an implementation detects an invariant violation:

1. It MUST reject the operation
2. It MUST NOT silently correct the data
3. It SHOULD log the violation
4. It MUST NOT proceed with corrupted state

## 8. Invariant Versioning

These invariants apply to protocol version 0.0.1.

Future versions may:
- Add new invariants (minor version bump)
- Modify invariants (major version bump)

Invariants are never removed, only deprecated.