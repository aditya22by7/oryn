import 'package:flutter/material.dart';
import '../../core/engines/confidence/confidence_engine.dart';

/// Visual representation of confidence score
///
/// Transparent, informational, not gamified
class ConfidenceBar extends StatelessWidget {
  final double confidence;
  final bool showLabel;
  final bool showPercentage;

  const ConfidenceBar({
    super.key,
    required this.confidence,
    this.showLabel = true,
    this.showPercentage = true,
  });

  Color _getColor() {
    if (confidence >= 0.7) return const Color(0xFF4CAF50);
    if (confidence >= 0.5) return const Color(0xFFFFC107);
    if (confidence >= 0.3) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final level = ConfidenceEngine.getConfidenceLevel(confidence);
    final percentage = (confidence * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                if (showPercentage)
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: confidence.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}