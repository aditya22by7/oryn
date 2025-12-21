# Oryn

A truth-resolution protocol where claims exist only while they can be continuously proven, challenged, and re-validated over time.

## What This Is

Oryn is a local-first proof engine that evaluates claims using:

- **Evidence** — supporting proof that increases confidence
- **Counter-evidence** — challenging proof that decreases confidence
- **Time decay** — all proof becomes stale over time
- **Computed confidence** — never manually set, always derived

## What This Is Not

- Not a social network
- Not a knowledge base
- Not a fact-checking service
- Not an AI product

## Core Principle

- Traditional systems: Authority → Truth
- Oryn: Proof over time → Provisional Truth


## The Claim Object

The atomic unit of Oryn:

Claim
├── statement (text)
├── scope (domain)
├── created_at (timestamp)
├── last_verified_at (timestamp)
├── decay_half_life_days (integer)
├── evidence[] (list)
│ ├── type (link | document | dataset | experiment)
│ ├── reference (string)
│ ├── strength (0.0 - 1.0)
│ └── added_at (timestamp)
├── counter_evidence[] (list)
│ └── (same structure as evidence)
└── confidence_score (0.0 - 1.0, computed)


## Confidence Calculation
confidence = normalize(
(Σ evidence_strength × freshness)

    (Σ counter_strength × freshness)
    ) × decay_factor


Where:
- `freshness = e^(-age_in_days / half_life)`
- `decay_factor` drops if claim not re-verified

## Time Decay

Proof is not permanent.

| Age (days) | Half-life 90 | Freshness |
|------------|--------------|-----------|
| 0          | 90           | 100%      |
| 90         | 90           | 50%       |
| 180        | 90           | 25%       |
| 365        | 90           | 1.7%      |

Claims must be re-validated. Authority cannot freeze truth.

## What Users Can Do

- Create claims
- Attach evidence
- Attach counter-evidence
- See confidence change over time
- Re-verify claims

## What Users Cannot Do

- Like or upvote
- Follow or subscribe
- Comment or discuss
- Build reputation
- Override computed confidence

## Running Locally

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/oryn.git
cd oryn

# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run
flutter run -d linux

lib/
├── core/
│   ├── models/
│   │   ├── claim.dart
│   │   ├── evidence.dart
│   │   └── counter_evidence.dart
│   └── engines/
│       ├── decay/
│       ├── confidence/
│       ├── claim/
│       └── evidence/
├── data/
│   ├── local/
│   └── repositories/
└── presentation/
    ├── screens/
    └── widgets/

Philosophy

This system does not guarantee truth. It measures confidence.

Key properties:

    Deterministic
    Auditable
    Forkable
    Offline-first
    No central authority

If you disagree with a claim's evaluation, fork the data.

- License

MIT License. See LICENSE file.

## Explicit Non-Goals

Oryn explicitly does **NOT** provide:

- **Truth:** It measures confidence based on available proof; it does not declare absolute truth.
- **Consensus:** It is designed for individual verification, not global agreement. Disagreement is resolved by forking, not arguing.
- **Authority:** The system has no admin roles, no privileged users, and no central "fact-checkers."
- **Social Validation:** There are no likes, upvotes, follower counts, or other social metrics. The validity of a claim is independent of its popularity.
- **Moderation:** There is no mechanism for human moderation or censorship of claims.
- **Global Agreement:** Two users with different sets of evidence for the same claim will compute different confidence scores. This is correct behavior.

- Contributing

Open issues for bugs. Open PRs for fixes.

No feature requests that introduce:

    User accounts
    Reputation systems
    Social features
    Centralized moderation
    AI-based truth detection

These re-introduce authority.
Status

v0.0.1 — Local-first proof of concept.
