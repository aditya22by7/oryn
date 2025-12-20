# Oryn Claim Object Specification

Version: 0.0.1

## Overview

The Claim Object is the atomic unit of the Oryn protocol. All truth evaluation happens through this structure.

## Schema

### Claim

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string (UUID) | Yes | Unique identifier |
| statement | string | Yes | The declarative claim |
| scope | string | No | Domain context |
| created_at | ISO 8601 timestamp | Yes | Creation time |
| last_verified_at | ISO 8601 timestamp | Yes | Last re-verification time |
| decay_half_life_days | integer | Yes | Days until evidence strength halves |
| evidence | Evidence[] | No | Supporting proof |
| counter_evidence | CounterEvidence[] | No | Challenging proof |
| confidence_score | float (0.0-1.0) | Yes | Computed, read-only |

### Evidence

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string (UUID) | Yes | Unique identifier |
| type | enum | Yes | link, document, dataset, experiment |
| reference | string | Yes | URL or identifier |
| added_at | ISO 8601 timestamp | Yes | When evidence was added |
| strength | float (0.0-1.0) | Yes | Subjective strength |

### CounterEvidence

Same structure as Evidence.

## JSON Example
```json
{
  "id": "abc123",
  "statement": "This AI model exhibits demographic bias",
  "scope": "AI / ML / Ethics",
  "created_at": "2024-01-15T10:30:00Z",
  "last_verified_at": "2024-01-15T10:30:00Z",
  "decay_half_life_days": 90,
  "evidence": [
    {
      "id": "ev001",
      "type": "dataset",
      "reference": "https://arxiv.org/abs/example",
      "added_at": "2024-01-15T11:00:00Z",
      "strength": 0.8
    }
  ],
  "counter_evidence": [
    {
      "id": "ce001",
      "type": "document",
      "reference": "https://company.com/bias-report.pdf",
      "added_at": "2024-01-16T09:00:00Z",
      "strength": 0.4
    }
  ],
  "confidence_score": 0.62
}

## Rules

1. Confidence is computed, never set manually
2. Claims can exist with confidence = 0
3. Claims without evidence are valid
4. Evidence does not expire, but its impact decays
5. Re-verification resets decay timer, not evidence

## Confidence Formula

evidence_score = Σ (evidence.strength × freshness(evidence.added_at))
counter_score = Σ (counter.strength × freshness(counter.added_at))
decay_factor = freshness(claim.last_verified_at)
raw_score = (evidence_score - counter_score) × decay_factor
confidence = normalize(raw_score)

Where:

freshness(date) = e^(-age_in_days / decay_half_life_days)
normalize(x) = (tanh(x) + 1) / 2

## Interoperability

This specification is implementation-agnostic. Any system that:

1. Stores claims in this format
2. Computes confidence using this formula
3. Applies time decay correctly

Is Oryn-compatible.

## Versioning

This is version 0.0.1. Breaking changes increment the minor version.