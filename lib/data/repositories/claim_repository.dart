import 'package:isar/isar.dart';
import '../../core/models/claim.dart';
import '../../core/engines/claim/claim_engine.dart';
import '../local/database.dart';

/// Claim Repository
///
/// Handles persistence of claims to local storage.
/// All operations go through Isar database.
class ClaimRepository {

  /// Saves a claim to local storage
  static Future<Claim> saveClaim(Claim claim) async {
    final db = await OrynDatabase.getInstance();

    await db.writeTxn(() async {
      await db.claims.put(claim);
    });

    return claim;
  }

  /// Gets all claims from local storage
  ///
  /// Returns claims with refreshed confidence scores
  static Future<List<Claim>> getAllClaims() async {
    final db = await OrynDatabase.getInstance();
    final claims = await db.claims.where().findAll();

    // Refresh confidence for each claim
    return claims.map((c) => ClaimEngine.refreshConfidence(c)).toList();
  }

  /// Gets a single claim by ID
  static Future<Claim?> getClaimById(String id) async {
    final db = await OrynDatabase.getInstance();
    final claim = await db.claims.filter().idEqualTo(id).findFirst();

    if (claim == null) return null;

    return ClaimEngine.refreshConfidence(claim);
  }

  /// Gets a single claim by Isar ID
  static Future<Claim?> getClaimByIsarId(int isarId) async {
    final db = await OrynDatabase.getInstance();
    final claim = await db.claims.get(isarId);

    if (claim == null) return null;

    return ClaimEngine.refreshConfidence(claim);
  }

  /// Deletes a claim from local storage
  static Future<bool> deleteClaim(String id) async {
    final db = await OrynDatabase.getInstance();

    final claim = await db.claims.filter().idEqualTo(id).findFirst();
    if (claim == null) return false;

    await db.writeTxn(() async {
      await db.claims.delete(claim.isarId);
    });

    return true;
  }

  /// Deletes a claim by Isar ID
  static Future<bool> deleteClaimByIsarId(int isarId) async {
    final db = await OrynDatabase.getInstance();

    await db.writeTxn(() async {
      await db.claims.delete(isarId);
    });

    return true;
  }

  /// Gets claims that need re-verification
  static Future<List<Claim>> getClaimsNeedingReverification({
    double threshold = 0.3,
  }) async {
    final claims = await getAllClaims();
    return claims.where((c) => c.confidenceScore < threshold).toList();
  }

  /// Gets claims sorted by confidence (highest first)
  static Future<List<Claim>> getClaimsByConfidence({
    bool ascending = false,
  }) async {
    final claims = await getAllClaims();
    claims.sort((a, b) => ascending
        ? a.confidenceScore.compareTo(b.confidenceScore)
        : b.confidenceScore.compareTo(a.confidenceScore));
    return claims;
  }

  /// Gets claims filtered by scope
  static Future<List<Claim>> getClaimsByScope(String scope) async {
    final db = await OrynDatabase.getInstance();
    final claims = await db.claims.filter().scopeEqualTo(scope).findAll();
    return claims.map((c) => ClaimEngine.refreshConfidence(c)).toList();
  }

  /// Gets total claim count
  static Future<int> getClaimCount() async {
    final db = await OrynDatabase.getInstance();
    return db.claims.count();
  }

  /// Clears all claims (use with caution)
  static Future<void> clearAllClaims() async {
    final db = await OrynDatabase.getInstance();
    await db.writeTxn(() async {
      await db.claims.clear();
    });
  }

  /// Exports all claims as JSON-compatible list
  static Future<List<Map<String, dynamic>>> exportAllClaims() async {
    final claims = await getAllClaims();
    return claims.map((c) => _claimToMap(c)).toList();
  }

  static Map<String, dynamic> _claimToMap(Claim claim) {
    return {
      'id': claim.id,
      'statement': claim.statement,
      'scope': claim.scope,
      'createdAt': claim.createdAt?.toIso8601String(),
      'lastVerifiedAt': claim.lastVerifiedAt?.toIso8601String(),
      'decayHalfLifeDays': claim.decayHalfLifeDays,
      'confidenceScore': claim.confidenceScore,
      'evidenceCount': claim.evidenceList.length,
      'counterEvidenceCount': claim.counterEvidenceList.length,
    };
  }
}