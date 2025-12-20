import 'package:isar/isar.dart';
import 'evidence.dart';
import 'counter_evidence.dart';

part 'claim.g.dart';

@collection
class Claim {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  String? id;

  String? statement;

  String? scope;

  DateTime? createdAt;

  DateTime? lastVerifiedAt;

  int decayHalfLifeDays = 90;

  List<Evidence> evidenceList = [];

  List<CounterEvidence> counterEvidenceList = [];

  double confidenceScore = 0.0; // 0.0 to 1.0, computed not manual

  Claim({
    this.id,
    this.statement,
    this.scope,
    this.createdAt,
    this.lastVerifiedAt,
    this.decayHalfLifeDays = 90,
    this.evidenceList = const [],
    this.counterEvidenceList = const [],
    this.confidenceScore = 0.0,
  });

  /// Creates a new Claim with generated ID and timestamps
  factory Claim.create({
    required String statement,
    String? scope,
    int decayHalfLifeDays = 90,
  }) {
    final now = DateTime.now();
    return Claim(
      id: _generateUuid(),
      statement: statement,
      scope: scope,
      createdAt: now,
      lastVerifiedAt: now,
      decayHalfLifeDays: decayHalfLifeDays,
      evidenceList: [],
      counterEvidenceList: [],
      confidenceScore: 0.0,
    );
  }

  /// Copy with modifications
  Claim copyWith({
    String? id,
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
      statement: statement ?? this.statement,
      scope: scope ?? this.scope,
      createdAt: createdAt ?? this.createdAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      decayHalfLifeDays: decayHalfLifeDays ?? this.decayHalfLifeDays,
      evidenceList: evidenceList ?? List.from(this.evidenceList),
      counterEvidenceList: counterEvidenceList ?? List.from(this.counterEvidenceList),
      confidenceScore: confidenceScore ?? this.confidenceScore,
    )..isarId = isarId;
  }

  static String _generateUuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now.hashCode;
    return '${now.toRadixString(36)}-${random.toRadixString(36)}';
  }
}