import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'counter_evidence.freezed.dart';
part 'counter_evidence.g.dart';

enum CounterEvidenceType { link, document, dataset, experiment }

// Pure data class for JSON serialization
@freezed
class CounterEvidenceData with _$CounterEvidenceData {
  const factory CounterEvidenceData({
    required String id,
    @Default(CounterEvidenceType.link) CounterEvidenceType type,
    required String reference,
    required DateTime addedAt,
    @Default(0.5) double strength,
  }) = _CounterEvidenceData;

  factory CounterEvidenceData.fromJson(Map<String, dynamic> json) =>
      _$CounterEvidenceDataFromJson(json);
}

// Isar-compatible embedded object
@embedded
class CounterEvidence {
  String? id;

  @enumerated
  CounterEvidenceType type = CounterEvidenceType.link;

  String? reference;

  DateTime? addedAt;

  double strength = 0.5;

  CounterEvidence({
    this.id,
    this.type = CounterEvidenceType.link,
    this.reference,
    this.addedAt,
    this.strength = 0.5,
  });

  factory CounterEvidence.fromData(CounterEvidenceData data) {
    return CounterEvidence(
      id: data.id,
      type: data.type,
      reference: data.reference,
      addedAt: data.addedAt,
      strength: data.strength,
    );
  }

  CounterEvidenceData toData() {
    return CounterEvidenceData(
      id: id!,
      type: type,
      reference: reference!,
      addedAt: addedAt!,
      strength: strength,
    );
  }
}