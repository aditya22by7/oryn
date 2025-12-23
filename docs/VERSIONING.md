# Oryn Protocol Versioning

Version: 0.0.1

This document defines how Oryn protocol versions work.

## 1. Version Format

    MAJOR.MINOR.PATCH

    Example: 0.0.1, 0.1.0, 1.0.0

## 2. Version Components

### 2.1 MAJOR Version

Incremented when:
- Confidence formula changes
- Core data structures change incompatibly
- Invariants are modified
- Existing claims would compute differently

Impact:
- Old and new versions produce DIFFERENT outputs for same inputs
- Migration may be required
- Backward compatibility NOT guaranteed

### 2.2 MINOR Version

Incremented when:
- New optional fields are added
- New features are added (backward compatible)
- New invariants are added
- New edge cases are defined

Impact:
- Old claims remain valid
- Old and new versions produce SAME outputs for existing inputs
- Backward compatibility maintained

### 2.3 PATCH Version

Incremented when:
- Documentation clarified
- Typos fixed
- Examples added
- No behavioral changes

Impact:
- Zero impact on computation
- Pure documentation changes

## 3. Compatibility Rules

### 3.1 Forward Compatibility

    A v0.0.1 claim CAN be read by v0.1.0 implementation.
    
    Newer implementations MUST handle older claims.

### 3.2 Backward Compatibility

    A v0.1.0 claim MAY NOT be fully readable by v0.0.1 implementation.
    
    Older implementations MAY ignore unknown fields.
    Older implementations MUST NOT crash on unknown fields.

### 3.3 Cross-Version Confidence

    If MAJOR version differs:
        Confidence scores are NOT comparable.
    
    If only MINOR or PATCH differs:
        Confidence scores ARE comparable.

## 4. Protocol Version Storage

Every claim stores its protocol version:

    claim.protocol_version = "0.0.1"

This enables:
- Version detection
- Migration decisions
- Compatibility checks

## 5. Implementation Version vs Protocol Version

These are separate:

| Type | Example | Meaning |
|------|---------|---------|
| Protocol Version | 0.0.1 | Data format and computation rules |
| Implementation Version | 1.2.3 | Software release version |

An implementation may be at version 2.0.0 while still implementing protocol version 0.0.1.

## 6. Version Negotiation

When importing claims:

1. Read claim.protocol_version
2. Compare to supported versions
3. If supported: process normally
4. If unsupported MAJOR: reject or migrate
5. If unsupported MINOR: process with warnings
6. If unsupported PATCH: process normally

## 7. Deprecation Rules

### 7.1 Fields

Fields are never removed, only deprecated.

Deprecated fields:
- MUST still be readable
- MAY be ignored in computation
- SHOULD NOT be written to new claims

### 7.2 Invariants

Invariants are never removed, only deprecated.

Deprecated invariants:
- SHOULD still be respected
- MAY be replaced by stronger invariants

### 7.3 Formulas

Formulas are never removed.

Old formulas:
- MUST remain documented
- MUST be available for old claims
- MAY be superseded by new formulas (MAJOR version)

## 8. Migration

When MAJOR version changes:

### 8.1 Claim Migration

    Old claims MAY be migrated to new version.
    Migration MUST be explicit (not automatic).
    Original claim SHOULD be preserved.

### 8.2 Confidence Recomputation

    After migration, confidence MUST be recomputed.
    Old confidence values are invalidated.

### 8.3 Migration Audit

    Migration SHOULD be logged.
    Migration SHOULD be reversible.

## 9. Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.0.1 | 2024 | Initial protocol release |

## 10. Future Versions

Planned considerations for future versions:

### v0.1.0 (Potential)
- Claim linking
- Enhanced evidence types
- Batch operations

### v1.0.0 (Potential)
- Stable public API
- Long-term support commitment
- Formal verification

No timeline is committed. Stability over features.