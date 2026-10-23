import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/l10n/app_localizations.dart';

void main() {
  Future<String> welcomeFor(WidgetTester tester, Locale locale) async {
    String? captured;
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        captured = AppLocalizations.of(context)!.coachWelcomeMessage;
        return const SizedBox();
      }),
    ));
    return captured!;
  }

  testWidgets('coach welcome message is in English under the en locale, never French',
      (tester) async {
    final message = await welcomeFor(tester, const Locale('en'));

    expect(
      message,
      "Hello, I'm your nutrition coach. What would you like to improve today?",
    );
    expect(message, isNot(contains('coach nutrition')));
  });

  testWidgets('coach welcome message is in French under the fr locale', (tester) async {
    final message = await welcomeFor(tester, const Locale('fr'));

    expect(
      message,
      "Bonjour, je suis votre coach nutrition. Que souhaitez-vous améliorer aujourd'hui ?",
    );
  });
}
