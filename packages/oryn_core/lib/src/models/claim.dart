import 'evidence.dart';
import 'counter_evidence.dart';

/// A claim in the Oryn protocol
///
/// The atomic unit of truth evaluation.
/// Pure Dart. No external dependencies.
class Claim {
  final String id;
  final String protocolVersion;
  final String statement;
  final String? scope;
  final DateTime createdAt;
  final DateTime lastVerifiedAt;
  final int decayHalfLifeDays;
  final List<Evidence> evidenceList;
  final List<CounterEvidence> counterEvidenceList;
  final double confidenceScore;

  const Claim({
    required this.id,
    required this.protocolVersion,
    required this.statement,
    this.scope,
    required this.createdAt,
    required this.lastVerifiedAt,
    required this.decayHalfLifeDays,
    required this.evidenceList,
    required this.counterEvidenceList,
    required this.confidenceScore,
  });

  /// Creates a new claim with generated ID and current timestamp
  factory Claim.create({
    required String statement,
    String? scope,
    int decayHalfLifeDays = 90,
  }) {
    final now = DateTime.now();
    return Claim(
      id: _generateId(),
      protocolVersion: '0.0.1',
      statement: statement,
      scope: scope,
      createdAt: now,
      lastVerifiedAt: now,
      decayHalfLifeDays: decayHalfLifeDays.clamp(1, 3650),
      evidenceList: const [],
      counterEvidenceList: const [],
      confidenceScore: 0.5,
    );
  }

  /// Creates a copy with optional field overrides
  Claim copyWith({
    String? id,
    String? protocolVersion,
    String? statement,
    String? scope,
    DateTime? createdAt,
    DateTime? lastVerifiedAt,
    int? decayHalfLifeDays,
    List<Evidence>? evidenceList,
    List<CounterEvidence>? counterEvidenceList,
    double? confidenceScore,
  }) {
    return Claim(
      id: id ?? this.id,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      statement: statement ?? this.statement,
      scope: scope ?? this.scope,
      createdAt: createdAt ?? this.createdAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      decayHalfLifeDays: decayHalfLifeDays ?? this.decayHalfLifeDays,
      evidenceList: evidenceList ?? List.unmodifiable(this.evidenceList),
      counterEvidenceList: counterEvidenceList ?? List.unmodifiable(this.counterEvidenceList),
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  /// Adds evidence and returns new claim
  Claim addEvidence(Evidence evidence) {
    return copyWith(
      evidenceList: [...evidenceList, evidence],
    );
  }

  /// Removes evidence by ID and returns new claim
  Claim removeEvidence(String evidenceId) {
    return copyWith(
      evidenceList: evidenceList.where((e) => e.id != evidenceId).toList(),
    );
  }

  /// Adds counter-evidence and returns new claim
  Claim addCounterEvidence(CounterEvidence counter) {
    return copyWith(
      counterEvidenceList: [...counterEvidenceList, counter],
    );
  }

  /// Removes counter-evidence by ID and returns new claim
  Claim removeCounterEvidence(String counterId) {
    return copyWith(
      counterEvidenceList: counterEvidenceList.where((c) => c.id != counterId).toList(),
    );
  }

  /// Re-verifies the claim (resets decay timer)
  Claim reverify() {
    return copyWith(
      lastVerifiedAt: DateTime.now(),
    );
  }

  /// Updates confidence score (should only be called by ConfidenceEngine)
  Claim withConfidence(double confidence) {
    return copyWith(
      confidenceScore: confidence.clamp(0.0, 1.0),
    );
  }

  /// Converts to JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'protocol_version': protocolVersion,
      'statement': statement,
      'scope': scope,
      'created_at': createdAt.toUtc().toIso8601String(),
      'last_verified_at': lastVerifiedAt.toUtc().toIso8601String(),
      'decay_half_life_days': decayHalfLifeDays,
      'evidence': evidenceList.map((e) => e.toJson()).toList(),
      'counter_evidence': counterEvidenceList.map((c) => c.toJson()).toList(),
      'confidence_score': confidenceScore,
    };
  }

  /// Creates from JSON Map
  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] as String,
      protocolVersion: json['protocol_version'] as String? ?? '0.0.1',
      statement: json['statement'] as String,
      scope: json['scope'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastVerifiedAt: DateTime.parse(json['last_verified_at'] as String),
      decayHalfLifeDays: json['decay_half_life_days'] as int? ?? 90,
      evidenceList: (json['evidence'] as List<dynamic>?)
          ?.map((e) => Evidence.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      counterEvidenceList: (json['counter_evidence'] as List<dynamic>?)
          ?.map((c) => CounterEvidence.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.5,
    );
  }

  static String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final hash = now.hashCode.abs();
    return 'claim_${now.toRadixString(36)}_${hash.toRadixString(36)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Claim && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Claim(id: $id, statement: "${statement.length > 30 ? '${statement.substring(0, 30)}...' : statement}", confidence: $confidenceScore)';
  }
}