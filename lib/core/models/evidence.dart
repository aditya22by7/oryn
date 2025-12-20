import 'package:isar/isar.dart';

part 'evidence.g.dart';

enum EvidenceType {
  link,
  document,
  dataset,
  experiment,
}

@embedded
class Evidence {
  String? id;

  @enumerated
  EvidenceType type = EvidenceType.link;

  String? reference;

  DateTime? addedAt;

  double strength = 0.5; // 0.0 to 1.0

  Evidence({
    this.id,
    this.type = EvidenceType.link,
    this.reference,
    this.addedAt,
    this.strength = 0.5,
  });
}