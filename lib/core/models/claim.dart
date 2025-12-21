import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'evidence.dart';
import 'counter_evidence.dart';

part 'claim.freezed.dart';
part 'claim.g.dart';

// --- Pure Data Class (for JSON, business logic) ---
@freezed
class ClaimData with _$ClaimData {
  const factory ClaimData({
    required String id,
    required String statement,
    String? scope,
    required DateTime createdAt,
    required DateTime lastVerifiedAt,
    @Default('0.0.1') String protocolVersion,
    @Default(90) int decayHalfLifeDays,
    @Default([]) List<EvidenceData> evidenceList,
    @Default([]) List<CounterEvidenceData> counterEvidenceList,
    @Default(0.0) double confidenceScore,
  }) = _ClaimData;

  factory ClaimData.fromJson(Map<String, dynamic> json) =>
      _$ClaimDataFromJson(json);

  factory ClaimData.create({
    required String statement,
    String? scope,
    int decayHalfLifeDays = 90,
  }) {
    final now = DateTime.now().toUtc();
    return ClaimData(
      id: const Uuid().v4(),
      statement: statement,
      scope: scope,
      createdAt: now,
      lastVerifiedAt: now,
      decayHalfLifeDays: decayHalfLifeDays,
    );
  }
}

// --- Isar Database Object ---
@collection
class Claim {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  String? id;

  String protocolVersion = '0.0.1';

  String? statement;

  String? scope;

  DateTime? createdAt;

  DateTime? lastVerifiedAt;

  int decayHalfLifeDays = 90;

  List<Evidence> evidenceList = [];

  List<CounterEvidence> counterEvidenceList = [];

  double confidenceScore = 0.0;

  // Empty constructor for Isar
  Claim();

  // --- Factory: Create New Claim ---
  factory Claim.create({
    required String statement,
    String? scope,
    int decayHalfLifeDays = 90,
  }) {
    final now = DateTime.now();
    return Claim()
      ..id = const Uuid().v4()
      ..protocolVersion = '0.0.1'
      ..statement = statement
      ..scope = scope
      ..createdAt = now
      ..lastVerifiedAt = now
      ..decayHalfLifeDays = decayHalfLifeDays
      ..evidenceList = []
      ..counterEvidenceList = []
      ..confidenceScore = 0.0;
  }

  // --- copyWith Method ---
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
    return Claim()
      ..isarId = isarId
      ..id = id ?? this.id
      ..protocolVersion = protocolVersion ?? this.protocolVersion
      ..statement = statement ?? this.statement
      ..scope = scope ?? this.scope
      ..createdAt = createdAt ?? this.createdAt
      ..lastVerifiedAt = lastVerifiedAt ?? this.lastVerifiedAt
      ..decayHalfLifeDays = decayHalfLifeDays ?? this.decayHalfLifeDays
      ..evidenceList = evidenceList ?? List.from(this.evidenceList)
      ..counterEvidenceList = counterEvidenceList ?? List.from(this.counterEvidenceList)
      ..confidenceScore = confidenceScore ?? this.confidenceScore;
  }

  // --- Conversion Methods ---

  // Convert from pure data class to Isar object
  factory Claim.fromData(ClaimData data) {
    return Claim()
      ..id = data.id
      ..protocolVersion = data.protocolVersion
      ..statement = data.statement
      ..scope = data.scope
      ..createdAt = data.createdAt
      ..lastVerifiedAt = data.lastVerifiedAt
      ..decayHalfLifeDays = data.decayHalfLifeDays
      ..evidenceList = data.evidenceList.map((e) => Evidence.fromData(e)).toList()
      ..counterEvidenceList = data.counterEvidenceList.map((c) => CounterEvidence.fromData(c)).toList()
      ..confidenceScore = data.confidenceScore;
  }

  // Convert from Isar object to pure data class
  ClaimData toData() {
    return ClaimData(
      id: id!,
      protocolVersion: protocolVersion,
      statement: statement!,
      scope: scope,
      createdAt: createdAt!,
      lastVerifiedAt: lastVerifiedAt!,
      decayHalfLifeDays: decayHalfLifeDays,
      evidenceList: evidenceList.map((e) => e.toData()).toList(),
      counterEvidenceList: counterEvidenceList.map((c) => c.toData()).toList(),
      confidenceScore: confidenceScore,
    );
  }
}