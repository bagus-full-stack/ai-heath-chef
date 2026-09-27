import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Nom du jour de la semaine dans la langue courante ([weekday] : 1 = lundi
/// ... 7 = dimanche). 2024-01-01 était un lundi, donc `DateTime(2024, 1, weekday)`
/// tombe toujours sur le bon jour — évite d'écrire 7 clés ARB par langue.
String weekdayName(BuildContext context, int weekday, {bool short = false}) {
  final locale = Localizations.localeOf(context).toString();
  final date = DateTime(2024, 1, weekday);
  return short
      ? DateFormat.E(locale).format(date)
      : DateFormat.EEEE(locale).format(date);
}
