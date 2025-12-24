# Oryn Protocol Edge Cases

Version: 0.0.1

This document defines expected behavior in unusual situations.

## 1. Empty States

### 1.1 No Evidence, No Counter-Evidence

Input:
claim.evidence = []
claim.counter_evidence = []

Behavior:
evidence_score = 0.0
counter_score = 0.0
raw_score = 0.0
confidence = 0.5 (neutral)

Rationale: A claim with no proof is neither true nor false. Neutral confidence.

### 1.2 No Claims in Database

Input:
database.claims = []

Behavior:
List displays empty state
Export produces valid JSON with empty claims array
All filters return empty results

### 1.3 Empty Statement

Input:
claim.statement = "" or null

Behavior:
REJECT claim creation
Display validation error
Do not store claim

Rationale: A claim must claim something.

## 2. Extreme Values

### 2.1 Maximum Evidence

Input:
claim.evidence = [1000 items, each strength = 1.0]

Behavior:
evidence_score = 1000.0 (before normalization)
After normalization: confidence approaches 1.0
confidence never equals exactly 1.0

Rationale: tanh normalization ensures asymptotic approach to 1.0.

### 2.2 Maximum Counter-Evidence

Input:
claim.counter_evidence = [1000 items, each strength = 1.0]
claim.evidence = []

Behavior:
raw_score = -1000.0 (before normalization)
After normalization: confidence approaches 0.0
confidence never equals exactly 0.0

Rationale: tanh normalization ensures asymptotic approach to 0.0.

### 2.3 Equal Evidence and Counter-Evidence

Input:
claim.evidence = [{strength: 0.8}]
claim.counter_evidence = [{strength: 0.8}]
(same timestamps)

Behavior:
evidence_score = 0.8
counter_score = 0.8
raw_score = 0.0
confidence = 0.5 (neutral)

Rationale: Balanced proof yields neutral confidence.

### 2.4 Strength = 0.0

Input:
evidence.strength = 0.0

Behavior:
Evidence is valid
Contributes 0.0 to evidence_score
Still stored and displayed
Still decays (though contribution remains 0)

Rationale: Zero-strength evidence may be upgraded later.

### 2.5 Strength = 1.0

Input:
evidence.strength = 1.0

Behavior:
Evidence is valid
Contributes maximum to evidence_score
Subject to decay like all evidence

Rationale: Even perfect evidence decays over time.

## 3. Time Edge Cases

### 3.1 Zero Age (Just Added)

Input:
evidence.added_at = now
age = 0 days

Behavior:
freshness = 1.0 (maximum)
Full contribution to confidence

### 3.2 Extreme Age (Very Old)

Input:
evidence.added_at = 10 years ago
half_life = 90 days

Behavior:
freshness = e^(-3650/90) = approximately 0.0
Negligible contribution to confidence
Evidence still stored (never auto-deleted)

### 3.3 Future Timestamp

Input:
evidence.added_at = tomorrow

Behavior:
UNDEFINED in protocol
Implementation SHOULD reject
Implementation MAY treat as now

Rationale: Future timestamps indicate clock error or manipulation.

### 3.4 Minimum Half-Life

Input:
claim.decay_half_life_days = 1

Behavior:
Very rapid decay
After 7 days: freshness = e^(-7) = 0.0009 (0.09%)
Valid but aggressive

### 3.5 Maximum Half-Life

Input:
claim.decay_half_life_days = 3650

Behavior:
Very slow decay
After 1 year: freshness = e^(-365/3650) = 0.905 (90.5%)
Valid for long-term claims

## 4. Computation Edge Cases

### 4.1 Division by Zero Prevention

Input:
decay_half_life_days = 0

Behavior:
REJECT at validation
Never reaches computation
Half-life minimum is 1

### 4.2 Floating Point Precision

Input:
Many small freshness values summed

Behavior:
Use double precision (64-bit)
Accept minor floating point variance
Two implementations may differ by < 0.0000001

Tolerance:
Confidence values within 1e-7 are considered equal

### 4.3 Overflow Prevention

Input:
Extremely large evidence_score

Behavior:
tanh function naturally bounds output
No overflow possible after normalization
Output always in (0.0, 1.0)

## 5. Data Integrity Edge Cases

### 5.1 Duplicate Evidence ID

Input:
Two evidence items with same id

Behavior:
REJECT second item
First item preserved
Log warning

### 5.2 Missing Required Fields

Input:
claim without id or created_at

Behavior:
REJECT claim
Do not store
Display validation error

### 5.3 Invalid Field Types

Input:
claim.confidence_score = "high" (string instead of number)

Behavior:
REJECT import
Do not corrupt database
Display parse error

## 6. Import/Export Edge Cases

### 6.1 Import Duplicate Claim

Input:
Imported claim.id already exists in database

Behavior:
SKIP imported claim
Preserve existing claim
Report as "skipped" in import summary

### 6.2 Import Invalid JSON

Input:
Malformed JSON file

Behavior:
REJECT entire import
No partial import
Display parse error

### 6.3 Export Empty Database

Input:
No claims to export

Behavior:
Produce valid JSON:
{
"oryn_version": "0.0.1",
"claims": []
}

## 7. UI Edge Cases

### 7.1 Very Long Statement

Input:
claim.statement = 1000 characters

Behavior:
Truncate in list view with "..."
Show full text in detail view
Accept at creation (within limit)

### 7.2 Special Characters in Statement

Input:
claim.statement contains emoji, unicode, newlines

Behavior:
Accept and store as-is
Display correctly
Export with proper encoding

### 7.3 Rapid Repeated Actions

Input:
User taps "Add Evidence" 10 times quickly

Behavior:
Process each request
May result in duplicate evidence (different IDs)
UI should debounce or disable during save

## 8. Recovery Edge Cases

### 8.1 Database Corruption

Behavior:
Detect on startup if possible
Offer export of recoverable data
Do not silently lose data

### 8.2 Interrupted Save

Behavior:
Use transactions where possible
Prefer failed save over partial save
User can retry

## 9. Summary Table

| Edge Case | Input | Output |
|-----------|-------|--------|
| No evidence | [] | confidence = 0.5 |
| Max evidence | [1000 × 1.0] | confidence → 1.0 |
| Max counter | [1000 × 1.0] | confidence → 0.0 |
| Balanced | equal evidence/counter | confidence = 0.5 |
| Zero strength | strength = 0.0 | valid, contributes 0 |
| Zero age | just added | freshness = 1.0 |
| Old evidence | 10 years | freshness → 0.0 |
| Future time | tomorrow | reject |
| Empty statement | "" | reject |
| Duplicate ID | same id twice | reject second |

## 10. Evidence Retraction

### 10.1 Rationale

Evidence is immutable once added:
- `id` must not change
- `added_at` must not change
- Historical state must remain inspectable

However, humans make mistakes:
- Wrong link added
- Misinterpreted source
- Later discovered to be fraudulent

Silent deletion or editing would:
- Erase history
- Enable retroactive truth rewriting
- Break auditability

Therefore, Oryn allows **retraction** but not silent removal.

### 10.2 Retraction vs Deletion

- **Deletion** (not allowed):
    - Evidence disappears as if it never existed
    - History is lost
    - Consumers cannot see what changed

- **Retraction** (allowed, recommended):
    - Evidence remains in the record
    - Marked as "retracted"
    - Contributes zero weight to confidence
    - Remains visible and auditable

### 10.3 Expected Behavior

When evidence is retracted:

1. The original evidence record MUST remain stored.
2. A "retracted" flag (or equivalent status) SHOULD be set.
3. Retraction SHOULD include:
    - Timestamp
    - Optional reason (text)
4. The confidence engine MUST treat retracted evidence as having **zero** effective strength.
5. Retraction events SHOULD be visible in any UI.

### 10.4 Non-Goals

Retracting evidence does **not**:

- Restore previous confidence scores automatically
- Remove the fact that the evidence was once considered
- Imply that the evidence source is globally invalid

It only means:
> "For this claim, this piece of evidence is no longer counted."

### 10.5 Current Implementation Status (v0.1.0)

In protocol v0.0.1 and engine v0.1.0:

- Retraction is defined at the **protocol level** only.
- There is **no** implementation of:
    - Evidence status
    - Retraction flag
    - Retraction UI

Any future implementation of retraction MUST:
- Respect all invariants
- Preserve historical data
- Remain deterministic

Until then, consumers SHOULD avoid silent deletion and instead model retraction explicitly if needed.