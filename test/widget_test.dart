import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('fromJson maps every Supabase column', () {
      final profile = UserProfile.fromJson({
        'user_id': 'abc-123',
        'full_name': 'Alex Martin',
        'email': 'alex@example.com',
        'sex': 'female',
        'age': 29,
        'current_weight': 62.5,
        'target_weight': 58.0,
        'goal': 'loseWeight',
        'updated_at': '2026-01-01T10:00:00.000Z',
      });

      expect(profile.userId, 'abc-123');
      expect(profile.fullName, 'Alex Martin');
      expect(profile.email, 'alex@example.com');
      expect(profile.sex, 'female');
      expect(profile.age, 29);
      expect(profile.currentWeight, 62.5);
      expect(profile.targetWeight, 58.0);
      expect(profile.goal, 'loseWeight');
      expect(profile.updatedAt, DateTime.parse('2026-01-01T10:00:00.000Z'));
    });

    test('fromJson falls back to defaults for missing fields', () {
      final profile = UserProfile.fromJson({'user_id': 'abc-123'});

      expect(profile.fullName, 'Utilisateur');
      expect(profile.email, '');
      expect(profile.sex, 'other');
      expect(profile.age, 0);
      expect(profile.currentWeight, 0);
      expect(profile.targetWeight, 0);
      expect(profile.goal, 'maintain');
      expect(profile.updatedAt, isNull);
    });

    test('sexLabel translates known values and defaults to Autre', () {
      expect(
        UserProfile.fromJson({'user_id': '1', 'sex': 'male'}).sexLabel,
        'Homme',
      );
      expect(
        UserProfile.fromJson({'user_id': '1', 'sex': 'female'}).sexLabel,
        'Femme',
      );
      expect(
        UserProfile.fromJson({'user_id': '1', 'sex': 'other'}).sexLabel,
        'Autre',
      );
    });

    test('goalLabel translates known values and defaults to Maintien', () {
      expect(
        UserProfile.fromJson({'user_id': '1', 'goal': 'loseWeight'}).goalLabel,
        'Perte de poids',
      );
      expect(
        UserProfile.fromJson({'user_id': '1', 'goal': 'gainMuscle'}).goalLabel,
        'Prise de masse',
      );
      expect(
        UserProfile.fromJson({'user_id': '1', 'goal': 'maintain'}).goalLabel,
        'Maintien',
      );
    });
  });
}
