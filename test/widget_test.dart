import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/l10n/app_localizations.dart';
import 'package:ai_health_chef/models/user_profile.dart';

/// Runs [test] with a [BuildContext] that has French localizations loaded,
/// since `sexLabel`/`goalLabel` read their strings from `context.l10n`.
Future<void> _withFrenchContext(
  WidgetTester tester,
  void Function(BuildContext context) test,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) {
          test(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

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

    testWidgets('sexLabel translates known values and defaults to Autre', (tester) async {
      await _withFrenchContext(tester, (context) {
        expect(
          UserProfile.fromJson({'user_id': '1', 'sex': 'male'}).sexLabel(context),
          'Homme',
        );
        expect(
          UserProfile.fromJson({'user_id': '1', 'sex': 'female'}).sexLabel(context),
          'Femme',
        );
        expect(
          UserProfile.fromJson({'user_id': '1', 'sex': 'other'}).sexLabel(context),
          'Autre',
        );
      });
    });

    testWidgets('goalLabel translates known values and defaults to Maintien', (tester) async {
      await _withFrenchContext(tester, (context) {
        expect(
          UserProfile.fromJson({'user_id': '1', 'goal': 'loseWeight'}).goalLabel(context),
          'Perte de poids',
        );
        expect(
          UserProfile.fromJson({'user_id': '1', 'goal': 'gainMuscle'}).goalLabel(context),
          'Prise de masse',
        );
        expect(
          UserProfile.fromJson({'user_id': '1', 'goal': 'maintain'}).goalLabel(context),
          'Maintien',
        );
      });
    });
  });
}
