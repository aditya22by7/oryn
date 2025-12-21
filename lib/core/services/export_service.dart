import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/claim_repository.dart';
import '../models/claim.dart';

/// Export Service
///
/// Handles exporting claims to JSON format.
/// Users own their data. They must be able to export it.
class ExportService {

  /// Exports all claims to a JSON string
  static Future<String> exportAllClaimsToJson() async {
    final claims = await ClaimRepository.getAllClaims();

    final exportData = {
      'oryn_version': '0.0.1',
      'protocol_version': '0.0.1',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'claim_count': claims.length,
      'claims': claims.map((claim) => _claimToJson(claim)).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Exports a single claim to a JSON string
  static Future<String> exportClaimToJson(Claim claim) async {
    final exportData = {
      'oryn_version': '0.0.1',
      'protocol_version': '0.0.1',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'claim_count': 1,
      'claims': [_claimToJson(claim)],
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Saves JSON string to a file and returns the file path
  static Future<String> saveToFile(String jsonContent, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(jsonContent);
    return file.path;
  }

  /// Exports all claims and saves to file
  static Future<String> exportAllToFile() async {
    final json = await exportAllClaimsToJson();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'oryn_export_$timestamp.json';
    return saveToFile(json, filename);
  }

  /// Exports single claim and saves to file
  static Future<String> exportClaimToFile(Claim claim) async {
    final json = await exportClaimToJson(claim);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final claimIdShort = claim.id?.substring(0, 8) ?? 'unknown';
    final filename = 'oryn_claim_${claimIdShort}_$timestamp.json';
    return saveToFile(json, filename);
  }

  /// Converts Claim to JSON-compatible Map
  static Map<String, dynamic> _claimToJson(Claim claim) {
    return {
      'id': claim.id,
      'protocol_version': claim.protocolVersion,
      'statement': claim.statement,
      'scope': claim.scope,
      'created_at': claim.createdAt?.toUtc().toIso8601String(),
      'last_verified_at': claim.lastVerifiedAt?.toUtc().toIso8601String(),
      'decay_half_life_days': claim.decayHalfLifeDays,
      'confidence_score': claim.confidenceScore,
      'evidence': claim.evidenceList.map((e) => _evidenceToJson(e)).toList(),
      'counter_evidence': claim.counterEvidenceList.map((c) => _counterEvidenceToJson(c)).toList(),
    };
  }

  /// Converts Evidence to JSON-compatible Map
  static Map<String, dynamic> _evidenceToJson(dynamic evidence) {
    return {
      'id': evidence.id,
      'type': evidence.type.toString().split('.').last,
      'reference': evidence.reference,
      'added_at': evidence.addedAt?.toUtc().toIso8601String(),
      'strength': evidence.strength,
    };
  }

  /// Converts CounterEvidence to JSON-compatible Map
  static Map<String, dynamic> _counterEvidenceToJson(dynamic counter) {
    return {
      'id': counter.id,
      'type': counter.type.toString().split('.').last,
      'reference': counter.reference,
      'added_at': counter.addedAt?.toUtc().toIso8601String(),
      'strength': counter.strength,
    };
  }
}