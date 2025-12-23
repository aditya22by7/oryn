import 'package:test/test.dart';
import 'package:oryn_core/oryn_core.dart';

void main() {
  group('DecayEngine', () {

    group('calculateFreshness', () {

      test('returns 1.0 for zero age', () {
        final now = DateTime.now();
        final freshness = DecayEngine.calculateFreshness(
          addedAt: now,
          halfLifeDays: 90,
          currentTime: now,
        );
        expect(freshness, equals(1.0));
      });

      test('returns approximately 0.368 at half-life', () {
        final now = DateTime.now();
        final addedAt = now.subtract(const Duration(days: 90));
        final freshness = DecayEngine.calculateFreshness(
          addedAt: addedAt,
          halfLifeDays: 90,
          currentTime: now,
        );
        // e^(-1) ≈ 0.368
        expect(freshness, closeTo(0.368, 0.001));
      });

      test('returns approximately 0.135 at 2x half-life', () {
        final now = DateTime.now();
        final addedAt = now.subtract(const Duration(days: 180));
        final freshness = DecayEngine.calculateFreshness(
          addedAt: addedAt,
          halfLifeDays: 90,
          currentTime: now,
        );
        // e^(-2) ≈ 0.135
        expect(freshness, closeTo(0.135, 0.001));
      });

      test('approaches zero for very old evidence', () {
        final now = DateTime.now();
        final addedAt = now.subtract(const Duration(days: 900));
        final freshness = DecayEngine.calculateFreshness(
          addedAt: addedAt,
          halfLifeDays: 90,
          currentTime: now,
        );
        expect(freshness, lessThan(0.001));
      });

      test('is always positive', () {
        final now = DateTime.now();
        final addedAt = now.subtract(const Duration(days: 10000));
        final freshness = DecayEngine.calculateFreshness(
          addedAt: addedAt,
          halfLifeDays: 90,
          currentTime: now,
        );
        expect(freshness, greaterThan(0.0));
      });

      test('handles zero half-life by returning 0.0', () {
        final now = DateTime.now();
        final addedAt = now.subtract(const Duration(days: 10));
        final freshness = DecayEngine.calculateFreshness(
          addedAt: addedAt,
          halfLifeDays: 0,
          currentTime: now,
        );
        expect(freshness, equals(0.0));
      });

      test('handles future timestamp by returning 1.0', () {
        final now = DateTime.now();
        final addedAt = now.add(const Duration(days: 10));
        final freshness = DecayEngine.calculateFreshness(
          addedAt: addedAt,
          halfLifeDays: 90,
          currentTime: now,
        );
        expect(freshness, equals(1.0));
      });

    });

    group('getDecayStatus', () {

      test('returns fresh for freshness >= 0.9', () {
        expect(DecayEngine.getDecayStatus(0.95), equals(DecayStatus.fresh));
        expect(DecayEngine.getDecayStatus(0.9), equals(DecayStatus.fresh));
      });

      test('returns recent for freshness >= 0.7', () {
        expect(DecayEngine.getDecayStatus(0.8), equals(DecayStatus.recent));
        expect(DecayEngine.getDecayStatus(0.7), equals(DecayStatus.recent));
      });

      test('returns aging for freshness >= 0.5', () {
        expect(DecayEngine.getDecayStatus(0.6), equals(DecayStatus.aging));
        expect(DecayEngine.getDecayStatus(0.5), equals(DecayStatus.aging));
      });

      test('returns stale for freshness >= 0.3', () {
        expect(DecayEngine.getDecayStatus(0.4), equals(DecayStatus.stale));
        expect(DecayEngine.getDecayStatus(0.3), equals(DecayStatus.stale));
      });

      test('returns decaying for freshness >= 0.1', () {
        expect(DecayEngine.getDecayStatus(0.2), equals(DecayStatus.decaying));
        expect(DecayEngine.getDecayStatus(0.1), equals(DecayStatus.decaying));
      });

      test('returns expired for freshness < 0.1', () {
        expect(DecayEngine.getDecayStatus(0.05), equals(DecayStatus.expired));
        expect(DecayEngine.getDecayStatus(0.0), equals(DecayStatus.expired));
      });

    });

  });
}