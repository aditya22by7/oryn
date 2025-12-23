/// Counter-evidence types supported by Oryn
enum CounterEvidenceType {
  link,
  document,
  dataset,
  experiment,
}

/// Counter-evidence challenging a claim
///
/// Pure Dart. No external dependencies.
class CounterEvidence {
  final String id;
  final CounterEvidenceType type;
  final String reference;
  final DateTime addedAt;
  final double strength;

  const CounterEvidence({
    required this.id,
    required this.type,
    required this.reference,
    required this.addedAt,
    required this.strength,
  });

  /// Creates new counter-evidence with generated ID and current timestamp
  factory CounterEvidence.create({
    required CounterEvidenceType type,
    required String reference,
    required double strength,
    DateTime? addedAt,
  }) {
    return CounterEvidence(
      id: _generateId(),
      type: type,
      reference: reference,
      addedAt: addedAt ?? DateTime.now(),
      strength: strength.clamp(0.0, 1.0),
    );
  }

  /// Creates a copy with optional field overrides
  CounterEvidence copyWith({
    String? id,
    CounterEvidenceType? type,
    String? reference,
    DateTime? addedAt,
    double? strength,
  }) {
    return CounterEvidence(
      id: id ?? this.id,
      type: type ?? this.type,
      reference: reference ?? this.reference,
      addedAt: addedAt ?? this.addedAt,
      strength: strength ?? this.strength,
    );
  }

  /// Converts to JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'reference': reference,
      'added_at': addedAt.toUtc().toIso8601String(),
      'strength': strength,
    };
  }

  /// Creates from JSON Map
  factory CounterEvidence.fromJson(Map<String, dynamic> json) {
    return CounterEvidence(
      id: json['id'] as String,
      type: CounterEvidenceType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => CounterEvidenceType.link,
      ),
      reference: json['reference'] as String,
      addedAt: DateTime.parse(json['added_at'] as String),
      strength: (json['strength'] as num).toDouble(),
    );
  }

  static String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final hash = now.hashCode.abs();
    return 'ce_${now.toRadixString(36)}_${hash.toRadixString(36)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CounterEvidence && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CounterEvidence(id: $id, type: ${type.name}, strength: $strength)';
  }
}