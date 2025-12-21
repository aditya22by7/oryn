import 'package:flutter/material.dart';
import '../../core/models/claim.dart';
import '../../core/services/decay_visualization_service.dart';

/// Decay Chart Widget
///
/// Displays a visual graph of confidence decay over time.
/// Shows projected future decay and key milestones.
class DecayChart extends StatelessWidget {
  final Claim claim;
  final int daysToProject;
  final double height;

  const DecayChart({
    super.key,
    required this.claim,
    this.daysToProject = 180,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final dataPoints = DecayVisualizationService.generateDecayCurve(
      claim: claim,
      daysToProject: daysToProject,
      dataPoints: 30,
    );

    final milestones = DecayVisualizationService.calculateMilestones(
      claim: claim,
    );

    final status = DecayVisualizationService.getDecayStatus(claim);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DECAY PROJECTION',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: height,
            child: _DecayGraph(
              dataPoints: dataPoints,
              daysToProject: daysToProject,
            ),
          ),

          const SizedBox(height: 16),

          // Milestones
          _MilestonesRow(milestones: milestones),
        ],
      ),
    );
  }
}

/// Status badge showing decay health
class _StatusBadge extends StatelessWidget {
  final DecayStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case DecayStatus.healthy:
        return Colors.green;
      case DecayStatus.stable:
        return Colors.blue;
      case DecayStatus.declining:
        return Colors.orange;
      case DecayStatus.critical:
        return Colors.red;
      case DecayStatus.expired:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// The actual graph rendering
class _DecayGraph extends StatelessWidget {
  final List<DecayDataPoint> dataPoints;
  final int daysToProject;

  const _DecayGraph({
    required this.dataPoints,
    required this.daysToProject,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _DecayGraphPainter(
        dataPoints: dataPoints,
        daysToProject: daysToProject,
      ),
    );
  }
}

/// Custom painter for the decay graph
class _DecayGraphPainter extends CustomPainter {
  final List<DecayDataPoint> dataPoints;
  final int daysToProject;

  _DecayGraphPainter({
    required this.dataPoints,
    required this.daysToProject,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final width = size.width;
    final height = size.height;

    // Padding for labels
    const leftPadding = 30.0;
    const bottomPadding = 20.0;
    const topPadding = 10.0;

    final graphWidth = width - leftPadding;
    final graphHeight = height - bottomPadding - topPadding;

    // Draw grid lines and labels
    _drawGrid(canvas, size, leftPadding, topPadding, graphWidth, graphHeight);

    // Draw threshold lines
    _drawThresholdLines(canvas, leftPadding, topPadding, graphWidth, graphHeight);

    // Draw the decay curve
    _drawCurve(canvas, leftPadding, topPadding, graphWidth, graphHeight);

    // Draw current position marker
    _drawCurrentMarker(canvas, leftPadding, topPadding, graphWidth, graphHeight);
  }

  void _drawGrid(Canvas canvas, Size size, double leftPadding, double topPadding, double graphWidth, double graphHeight) {
    final gridPaint = Paint()
      ..color = Colors.grey[900]!
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: Colors.grey[700],
      fontSize: 9,
    );

    // Horizontal lines (confidence levels)
    for (var i = 0; i <= 4; i++) {
      final y = topPadding + (graphHeight * (1 - i / 4));
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + graphWidth, y),
        gridPaint,
      );

      // Label
      final label = '${(i * 25)}%';
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - 6));
    }

    // Vertical lines (time)
    final monthInterval = daysToProject ~/ 6;
    for (var i = 0; i <= 6; i++) {
      final x = leftPadding + (graphWidth * i / 6);
      canvas.drawLine(
        Offset(x, topPadding),
        Offset(x, topPadding + graphHeight),
        gridPaint,
      );

      // Label
      final days = i * monthInterval;
      final label = days == 0 ? 'Now' : '${days}d';
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, topPadding + graphHeight + 4),
      );
    }
  }

  void _drawThresholdLines(Canvas canvas, double leftPadding, double topPadding, double graphWidth, double graphHeight) {
    // 30% threshold line (needs reverification)
    final threshold30Paint = Paint()
      ..color = Colors.orange.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final y30 = topPadding + graphHeight * (1 - 0.3);
    canvas.drawLine(
      Offset(leftPadding, y30),
      Offset(leftPadding + graphWidth, y30),
      threshold30Paint,
    );

    // 10% threshold line (critical)
    final threshold10Paint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final y10 = topPadding + graphHeight * (1 - 0.1);
    canvas.drawLine(
      Offset(leftPadding, y10),
      Offset(leftPadding + graphWidth, y10),
      threshold10Paint,
    );
  }

  void _drawCurve(Canvas canvas, double leftPadding, double topPadding, double graphWidth, double graphHeight) {
    if (dataPoints.length < 2) return;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final x = leftPadding + (graphWidth * point.day / daysToProject);
      final y = topPadding + graphHeight * (1 - point.confidence);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, topPadding + graphHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Close fill path
    final lastPoint = dataPoints.last;
    final lastX = leftPadding + (graphWidth * lastPoint.day / daysToProject);
    fillPath.lineTo(lastX, topPadding + graphHeight);
    fillPath.close();

    // Draw fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withOpacity(0.3),
          Colors.blue.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(leftPadding, topPadding, graphWidth, graphHeight));

    canvas.drawPath(fillPath, fillPaint);

    // Draw curve line
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  void _drawCurrentMarker(Canvas canvas, double leftPadding, double topPadding, double graphWidth, double graphHeight) {
    if (dataPoints.isEmpty) return;

    final currentPoint = dataPoints.first;
    final x = leftPadding;
    final y = topPadding + graphHeight * (1 - currentPoint.confidence);

    // Outer circle
    final outerPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 8, outerPaint);

    // Inner circle
    final innerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 4, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Row showing key milestones
class _MilestonesRow extends StatelessWidget {
  final DecayMilestones milestones;

  const _MilestonesRow({required this.milestones});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MilestoneItem(
          label: 'Current',
          value: '${(milestones.currentConfidence * 100).toStringAsFixed(1)}%',
          color: Colors.blue,
        ),
        const SizedBox(width: 16),
        _MilestoneItem(
          label: 'Until 50%',
          value: milestones.daysUntil50Percent != null
              ? '${milestones.daysUntil50Percent}d'
              : 'N/A',
          color: Colors.orange,
        ),
        const SizedBox(width: 16),
        _MilestoneItem(
          label: 'Until 30%',
          value: milestones.daysUntil30Percent != null
              ? '${milestones.daysUntil30Percent}d'
              : 'N/A',
          color: Colors.red,
        ),
        const SizedBox(width: 16),
        _MilestoneItem(
          label: 'Half-life',
          value: '${milestones.halfLifeDays}d',
          color: Colors.grey,
        ),
      ],
    );
  }
}

/// Single milestone item
class _MilestoneItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MilestoneItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}