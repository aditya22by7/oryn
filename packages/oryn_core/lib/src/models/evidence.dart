/// Evidence types supported by Oryn
enum EvidenceType {
  link,
  document,
  dataset,
  experiment,
}

/// Evidence supporting or countering a claim
///
/// Pure Dart. No external dependencies.
class Evidence {
  final String id;
  final EvidenceType type;
  final String reference;
  final DateTime addedAt;
  final double strength;

  const Evidence({
    required this.id,
    required this.type,
    required this.reference,
    required this.addedAt,
    required this.strength,
  });

  /// Creates new evidence with generated ID and current timestamp
  factory Evidence.create({
    required EvidenceType type,
    required String reference,
    required double strength,
    DateTime? addedAt,
  }) {
    return Evidence(
      id: _generateId(),
      type: type,
      reference: reference,
      addedAt: addedAt ?? DateTime.now(),
      strength: strength.clamp(0.0, 1.0),
    );
  }

  /// Creates a copy with optional field overrides
  Evidence copyWith({
    String? id,
    EvidenceType? type,
    String? reference,
    DateTime? addedAt,
    double? strength,
  }) {
    return Evidence(
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
  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      id: json['id'] as String,
      type: EvidenceType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => EvidenceType.link,
      ),
      reference: json['reference'] as String,
      addedAt: DateTime.parse(json['added_at'] as String),
      strength: (json['strength'] as num).toDouble(),
    );
  }

  static String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final hash = now.hashCode.abs();
    return 'ev_${now.toRadixString(36)}_${hash.toRadixString(36)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Evidence && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Evidence(id: $id, type: ${type.name}, strength: $strength)';
  }
}