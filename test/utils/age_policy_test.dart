import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/utils/age_policy.dart';

void main() {
  group('isValidAge', () {
    test('rejects 15 (below kMinimumAge)', () {
      expect(isValidAge(15), isFalse);
    });

    test('accepts 16 (kMinimumAge)', () {
      expect(isValidAge(16), isTrue);
    });

    test('rejects 121 (above kMaximumAge)', () {
      expect(isValidAge(121), isFalse);
    });

    test('accepts 120 (kMaximumAge)', () {
      expect(isValidAge(120), isTrue);
    });
  });
}
