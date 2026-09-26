import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/utils/streak.dart';

DateTime _day(DateTime today, int offset) {
  final d = DateTime(today.year, today.month, today.day);
  return d.subtract(Duration(days: -offset));
}

void main() {
  final today = DateTime(2026, 9, 27);

  group('computeStreak', () {
    test('returns 0 for an empty set', () {
      expect(computeStreak({}, today), 0);
    });

    test('counts consecutive days ending today', () {
      final loggedDays = {
        _day(today, 0),
        _day(today, -1),
        _day(today, -2),
      };
      expect(computeStreak(loggedDays, today), 3);
    });

    test('still counts when yesterday was logged but not today yet (grace period)', () {
      final loggedDays = {
        _day(today, -1),
        _day(today, -2),
      };
      expect(computeStreak(loggedDays, today), 2);
    });

    test('stops at a gap in days', () {
      final loggedDays = {
        _day(today, 0),
        _day(today, -1),
        _day(today, -3),
      };
      expect(computeStreak(loggedDays, today), 2);
    });

    test('returns 0 when no days are near today', () {
      final loggedDays = {_day(today, -5)};
      expect(computeStreak(loggedDays, today), 0);
    });
  });

  group('highestStreakMilestone', () {
    test('returns null below the first milestone', () {
      expect(highestStreakMilestone(6), isNull);
    });

    test('returns the exact milestone when reached', () {
      expect(highestStreakMilestone(7), 7);
      expect(highestStreakMilestone(30), 30);
    });

    test('returns the highest milestone reached, not the closest', () {
      expect(highestStreakMilestone(45), 30);
      expect(highestStreakMilestone(150), 100);
    });
  });
}
