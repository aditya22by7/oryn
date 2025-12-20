import 'package:flutter/material.dart';
import '../../core/models/evidence.dart';
import '../../core/models/counter_evidence.dart';
import '../../core/engines/decay/decay_engine.dart';

/// Displays a single piece of evidence or counter-evidence
class EvidenceTile extends StatelessWidget {
  final String id;
  final String type;
  final String reference;
  final double strength;
  final DateTime? addedAt;
  final int halfLifeDays;
  final bool isCounter;
  final VoidCallback? onDelete;

  const EvidenceTile({
    super.key,
    required this.id,
    required this.type,
    required this.reference,
    required this.strength,
    required this.addedAt,
    required this.halfLifeDays,
    this.isCounter = false,
    this.onDelete,
  });

  /// Creates from Evidence object
  factory EvidenceTile.fromEvidence({
    required Evidence evidence,
    required int halfLifeDays,
    VoidCallback? onDelete,
  }) {
    return EvidenceTile(
      id: evidence.id ?? '',
      type: evidence.type.name,
      reference: evidence.reference ?? '',
      strength: evidence.strength,
      addedAt: evidence.addedAt,
      halfLifeDays: halfLifeDays,
      isCounter: false,
      onDelete: onDelete,
    );
  }

  /// Creates from CounterEvidence object
  factory EvidenceTile.fromCounterEvidence({
    required CounterEvidence counter,
    required int halfLifeDays,
    VoidCallback? onDelete,
  }) {
    return EvidenceTile(
      id: counter.id ?? '',
      type: counter.type.name,
      reference: counter.reference ?? '',
      strength: counter.strength,
      addedAt: counter.addedAt,
      halfLifeDays: halfLifeDays,
      isCounter: true,
      onDelete: onDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final freshness = addedAt != null
        ? DecayEngine.calculateFreshness(
      addedAt: addedAt!,
      halfLifeDays: halfLifeDays,
    )
        : 1.0;

    final decayStatus = DecayEngine.getDecayStatus(freshness);
    final effectiveStrength = strength * freshness;
    final accentColor = isCounter ? Colors.red[400]! : Colors.green[400]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const Spacer(),

              // Delete button
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey[700],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Reference
          Text(
            reference,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Strength and decay row
          Row(
            children: [
              // Original strength
              Text(
                'Strength: ${(strength * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),

              const SizedBox(width: 12),

              // Effective strength
              Text(
                'Effective: ${(effectiveStrength * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: accentColor.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),

              const Spacer(),

              // Decay status
              Text(
                decayStatus,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}