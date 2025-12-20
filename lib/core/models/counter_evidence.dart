import 'package:isar/isar.dart';

part 'counter_evidence.g.dart';

enum CounterEvidenceType {
  link,
  document,
  dataset,
  experiment,
}

@embedded
class CounterEvidence {
  String? id;

  @enumerated
  CounterEvidenceType type = CounterEvidenceType.link;

  String? reference;

  DateTime? addedAt;

  double strength = 0.5; // 0.0 to 1.0

  CounterEvidence({
    this.id,
    this.type = CounterEvidenceType.link,
    this.reference,
    this.addedAt,
    this.strength = 0.5,
  });
}