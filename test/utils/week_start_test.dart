import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/utils/week_start.dart';

void main() {
  test('resolves to Monday of the same week for a mid-week date', () {
    expect(weekStartKey(DateTime(2026, 9, 30)), '2026-09-28'); // Wednesday -> Monday
  });

  test('resolves to itself when already Monday', () {
    expect(weekStartKey(DateTime(2026, 9, 28)), '2026-09-28');
  });

  test('resolves to the previous Monday for a Sunday', () {
    expect(weekStartKey(DateTime(2026, 9, 27)), '2026-09-21'); // Sunday -> previous Monday
  });
}
