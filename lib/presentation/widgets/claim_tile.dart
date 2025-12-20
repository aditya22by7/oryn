import 'package:flutter/material.dart';
import '../../core/models/claim.dart';
import '../../core/engines/claim/claim_engine.dart';
import '../../core/engines/decay/decay_engine.dart';
import 'confidence_bar.dart';

/// Single claim display for list view
///
/// Shows: statement, confidence, decay status, evidence counts
class ClaimTile extends StatelessWidget {
  final Claim claim;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ClaimTile({
    super.key,
    required this.claim,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final daysSinceVerification = ClaimEngine.getDaysSinceVerification(claim);
    final needsReverification = ClaimEngine.needsReverification(claim);

    final decayFreshness = DecayEngine.calculateFreshness(
      addedAt: claim.lastVerifiedAt ?? claim.createdAt ?? DateTime.now(),
      halfLifeDays: claim.decayHalfLifeDays,
    );
    final decayStatus = DecayEngine.getDecayStatus(decayFreshness);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: needsReverification
                ? const Color(0xFFF44336).withOpacity(0.3)
                : Colors.grey[900]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statement
            Text(
              claim.statement ?? 'No statement',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Scope
            if (claim.scope != null && claim.scope!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  claim.scope!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),

            // Confidence bar
            ConfidenceBar(confidence: claim.confidenceScore),

            const SizedBox(height: 12),

            // Meta row
            Row(
              children: [
                // Evidence count
                _MetaChip(
                  icon: Icons.add_circle_outline,
                  label: '${claim.evidenceList.length}',
                  color: Colors.green[700]!,
                ),
                const SizedBox(width: 12),

                // Counter-evidence count
                _MetaChip(
                  icon: Icons.remove_circle_outline,
                  label: '${claim.counterEvidenceList.length}',
                  color: Colors.red[700]!,
                ),

                const Spacer(),

                // Decay status
                Text(
                  '$decayStatus · ${daysSinceVerification}d ago',
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
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}