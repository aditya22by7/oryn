import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/claim_repository.dart';
import '../models/claim.dart';
import '../models/evidence.dart';
import '../models/counter_evidence.dart';

/// Export & Import Service
///
/// Handles exporting and importing claims to/from JSON format.
/// Users own their data. They must be able to export and import it.
class ExportService {

  // ==================== EXPORT ====================

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

  // ==================== IMPORT ====================

  /// Imports claims from a JSON string
  /// Returns ImportResult with success/failure details
  static Future<ImportResult> importFromJson(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Validate structure
      if (!data.containsKey('claims')) {
        return ImportResult(
          success: false,
          error: 'Invalid format: missing "claims" field',
          importedCount: 0,
          skippedCount: 0,
        );
      }

      final claimsList = data['claims'] as List<dynamic>;
      int importedCount = 0;
      int skippedCount = 0;
      final errors = <String>[];

      for (final claimJson in claimsList) {
        try {
          final claim = _jsonToClaim(claimJson as Map<String, dynamic>);

          // Check if claim already exists
          final existing = await ClaimRepository.getClaimById(claim.id!);
          if (existing != null) {
            skippedCount++;
            continue;
          }

          await ClaimRepository.saveClaim(claim);
          importedCount++;
        } catch (e) {
          errors.add('Failed to import claim: $e');
          skippedCount++;
        }
      }

      return ImportResult(
        success: true,
        importedCount: importedCount,
        skippedCount: skippedCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Failed to parse JSON: $e',
        importedCount: 0,
        skippedCount: 0,
      );
    }
  }

  /// Imports claims from a file path
  static Future<ImportResult> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          success: false,
          error: 'File not found: $filePath',
          importedCount: 0,
          skippedCount: 0,
        );
      }

      final jsonContent = await file.readAsString();
      return importFromJson(jsonContent);
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Failed to read file: $e',
        importedCount: 0,
        skippedCount: 0,
      );
    }
  }

  // ==================== CONVERSION HELPERS ====================

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

  /// Converts JSON Map to Claim
  static Claim _jsonToClaim(Map<String, dynamic> json) {
    final evidenceList = (json['evidence'] as List<dynamic>?)
        ?.map((e) => _jsonToEvidence(e as Map<String, dynamic>))
        .toList() ?? [];

    final counterList = (json['counter_evidence'] as List<dynamic>?)
        ?.map((c) => _jsonToCounterEvidence(c as Map<String, dynamic>))
        .toList() ?? [];

    return Claim()
      ..id = json['id'] as String?
      ..protocolVersion = json['protocol_version'] as String? ?? '0.0.1'
      ..statement = json['statement'] as String?
      ..scope = json['scope'] as String?
      ..createdAt = json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null
      ..lastVerifiedAt = json['last_verified_at'] != null
          ? DateTime.parse(json['last_verified_at'] as String)
          : null
      ..decayHalfLifeDays = json['decay_half_life_days'] as int? ?? 90
      ..confidenceScore = (json['confidence_score'] as num?)?.toDouble() ?? 0.0
      ..evidenceList = evidenceList
      ..counterEvidenceList = counterList;
  }

  /// Converts Evidence to JSON-compatible Map
  static Map<String, dynamic> _evidenceToJson(Evidence evidence) {
    return {
      'id': evidence.id,
      'type': evidence.type.name,
      'reference': evidence.reference,
      'added_at': evidence.addedAt?.toUtc().toIso8601String(),
      'strength': evidence.strength,
    };
  }

  /// Converts JSON Map to Evidence
  static Evidence _jsonToEvidence(Map<String, dynamic> json) {
    return Evidence(
      id: json['id'] as String?,
      type: EvidenceType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => EvidenceType.link,
      ),
      reference: json['reference'] as String?,
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : null,
      strength: (json['strength'] as num?)?.toDouble() ?? 0.5,
    );
  }

  /// Converts CounterEvidence to JSON-compatible Map
  static Map<String, dynamic> _counterEvidenceToJson(CounterEvidence counter) {
    return {
      'id': counter.id,
      'type': counter.type.name,
      'reference': counter.reference,
      'added_at': counter.addedAt?.toUtc().toIso8601String(),
      'strength': counter.strength,
    };
  }

  /// Converts JSON Map to CounterEvidence
  static CounterEvidence _jsonToCounterEvidence(Map<String, dynamic> json) {
    return CounterEvidence(
      id: json['id'] as String?,
      type: CounterEvidenceType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => CounterEvidenceType.link,
      ),
      reference: json['reference'] as String?,
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : null,
      strength: (json['strength'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

/// Result of import operation
class ImportResult {
  final bool success;
  final String? error;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;

  ImportResult({
    required this.success,
    this.error,
    required this.importedCount,
    required this.skippedCount,
    this.errors = const [],
  });

  String get summary {
    if (!success) return error ?? 'Import failed';
    return 'Imported: $importedCount, Skipped: $skippedCount';
  }
}