import 'dart:math';
import '../models/claim.dart';
import '../engines/decay/decay_engine.dart';
import '../engines/confidence/confidence_engine.dart';

/// Decay Visualization Service
///
/// Generates data points for visualizing confidence decay over time.
class DecayVisualizationService {

  /// Generates confidence values over a time range
  /// Returns list of data points for graphing
  static List<DecayDataPoint> generateDecayCurve({
    required Claim claim,
    int daysToProject = 365,
    int dataPoints = 50,
  }) {
    final points = <DecayDataPoint>[];
    final now = DateTime.now();

    // Calculate interval between data points
    final intervalDays = daysToProject / dataPoints;

    for (int i = 0; i <= dataPoints; i++) {
      final daysFromNow = (i * intervalDays).round();
      final futureDate = now.add(Duration(days: daysFromNow));

      // Calculate confidence at this future date
      final confidence = ConfidenceEngine.computeConfidence(
        claim,
        currentTime: futureDate,
      );

      points.add(DecayDataPoint(
        day: daysFromNow,
        confidence: confidence,
        date: futureDate,
      ));
    }

    return points;
  }

  /// Generates historical confidence values
  /// Shows how confidence has changed since claim creation
  static List<DecayDataPoint> generateHistoricalCurve({
    required Claim claim,
    int dataPoints = 50,
  }) {
    final points = <DecayDataPoint>[];
    final now = DateTime.now();
    final createdAt = claim.createdAt ?? now;

    // Calculate days since creation
    final daysSinceCreation = now.difference(createdAt).inDays;
    if (daysSinceCreation <= 0) {
      // Claim was just created, return single point
      return [
        DecayDataPoint(
          day: 0,
          confidence: claim.confidenceScore,
          date: now,
        ),
      ];
    }

    final intervalDays = daysSinceCreation / dataPoints;

    for (int i = 0; i <= dataPoints; i++) {
      final daysFromCreation = (i * intervalDays).round();
      final pastDate = createdAt.add(Duration(days: daysFromCreation));

      // Calculate confidence at this past date
      final confidence = ConfidenceEngine.computeConfidence(
        claim,
        currentTime: pastDate,
      );

      points.add(DecayDataPoint(
        day: daysFromCreation,
        confidence: confidence,
        date: pastDate,
      ));
    }

    return points;
  }

  /// Calculates key decay milestones
  static DecayMilestones calculateMilestones({
    required Claim claim,
  }) {
    final now = DateTime.now();
    final currentConfidence = claim.confidenceScore;
    final halfLife = claim.decayHalfLifeDays;
    final lastVerified = claim.lastVerifiedAt ?? claim.createdAt ?? now;

    // Days until various confidence thresholds
    final daysUntil50Percent = _daysUntilConfidence(
      claim: claim,
      targetConfidence: 0.5,
      currentTime: now,
    );

    final daysUntil30Percent = _daysUntilConfidence(
      claim: claim,
      targetConfidence: 0.3,
      currentTime: now,
    );

    final daysUntil10Percent = _daysUntilConfidence(
      claim: claim,
      targetConfidence: 0.1,
      currentTime: now,
    );

    // Days since last verification
    final daysSinceVerification = now.difference(lastVerified).inDays;

    // Decay rate (percentage lost per day)
    final decayRatePerDay = (1 - exp(-1.0 / halfLife)) * 100;

    return DecayMilestones(
      currentConfidence: currentConfidence,
      daysSinceVerification: daysSinceVerification,
      daysUntil50Percent: daysUntil50Percent,
      daysUntil30Percent: daysUntil30Percent,
      daysUntil10Percent: daysUntil10Percent,
      decayRatePerDay: decayRatePerDay,
      halfLifeDays: halfLife,
    );
  }

  /// Calculates days until confidence drops to target
  static int? _daysUntilConfidence({
    required Claim claim,
    required double targetConfidence,
    required DateTime currentTime,
  }) {
    final currentConfidence = ConfidenceEngine.computeConfidence(
      claim,
      currentTime: currentTime,
    );

    // If already below target, return 0
    if (currentConfidence <= targetConfidence) return 0;

    // Binary search for the day when confidence drops below target
    int low = 0;
    int high = 3650; // Max 10 years

    while (low < high) {
      final mid = (low + high) ~/ 2;
      final futureDate = currentTime.add(Duration(days: mid));
      final futureConfidence = ConfidenceEngine.computeConfidence(
        claim,
        currentTime: futureDate,
      );

      if (futureConfidence <= targetConfidence) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // If never reaches target within 10 years, return null
    if (low >= 3650) return null;

    return low;
  }

  /// Gets decay status with color coding
  static DecayStatus getDecayStatus(Claim claim) {
    final confidence = claim.confidenceScore;
    final daysSinceVerification = DateTime.now()
        .difference(claim.lastVerifiedAt ?? claim.createdAt ?? DateTime.now())
        .inDays;

    if (confidence >= 0.7 && daysSinceVerification < 30) {
      return DecayStatus.healthy;
    } else if (confidence >= 0.5 && daysSinceVerification < 60) {
      return DecayStatus.stable;
    } else if (confidence >= 0.3) {
      return DecayStatus.declining;
    } else if (confidence >= 0.1) {
      return DecayStatus.critical;
    } else {
      return DecayStatus.expired;
    }
  }
}

/// Single data point for decay visualization
class DecayDataPoint {
  final int day;
  final double confidence;
  final DateTime date;

  const DecayDataPoint({
    required this.day,
    required this.confidence,
    required this.date,
  });
}

/// Key milestones in the decay timeline
class DecayMilestones {
  final double currentConfidence;
  final int daysSinceVerification;
  final int? daysUntil50Percent;
  final int? daysUntil30Percent;
  final int? daysUntil10Percent;
  final double decayRatePerDay;
  final int halfLifeDays;

  const DecayMilestones({
    required this.currentConfidence,
    required this.daysSinceVerification,
    required this.daysUntil50Percent,
    required this.daysUntil30Percent,
    required this.daysUntil10Percent,
    required this.decayRatePerDay,
    required this.halfLifeDays,
  });
}

/// Decay status categories
enum DecayStatus {
  healthy,
  stable,
  declining,
  critical,
  expired,
}

extension DecayStatusExtension on DecayStatus {
  String get displayName {
    switch (this) {
      case DecayStatus.healthy:
        return 'Healthy';
      case DecayStatus.stable:
        return 'Stable';
      case DecayStatus.declining:
        return 'Declining';
      case DecayStatus.critical:
        return 'Critical';
      case DecayStatus.expired:
        return 'Expired';
    }
  }

  String get description {
    switch (this) {
      case DecayStatus.healthy:
        return 'Recently verified with high confidence';
      case DecayStatus.stable:
        return 'Confidence is holding steady';
      case DecayStatus.declining:
        return 'Confidence is decreasing, consider reverifying';
      case DecayStatus.critical:
        return 'Needs immediate reverification';
      case DecayStatus.expired:
        return 'Confidence too low, add more evidence';
    }
  }
}