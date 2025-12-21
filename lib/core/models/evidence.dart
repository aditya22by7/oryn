import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'evidence.freezed.dart';
part 'evidence.g.dart';

enum EvidenceType { link, document, dataset, experiment }

// Pure data class for JSON serialization
@freezed
class EvidenceData with _$EvidenceData {
  const factory EvidenceData({
    required String id,
    @Default(EvidenceType.link) EvidenceType type,
    required String reference,
    required DateTime addedAt,
    @Default(0.5) double strength,
  }) = _EvidenceData;

  factory EvidenceData.fromJson(Map<String, dynamic> json) =>
      _$EvidenceDataFromJson(json);
}

// Isar-compatible embedded object
@embedded
class Evidence {
  String? id;

  @enumerated
  EvidenceType type = EvidenceType.link;

  String? reference;

  DateTime? addedAt;

  double strength = 0.5;

  Evidence({
    this.id,
    this.type = EvidenceType.link,
    this.reference,
    this.addedAt,
    this.strength = 0.5,
  });

  factory Evidence.fromData(EvidenceData data) {
    return Evidence(
      id: data.id,
      type: data.type,
      reference: data.reference,
      addedAt: data.addedAt,
      strength: data.strength,
    );
  }

  EvidenceData toData() {
    return EvidenceData(
      id: id!,
      type: type,
      reference: reference!,
      addedAt: addedAt!,
      strength: strength,
    );
  }
}