import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../local_db/local_db_provider.dart';

const _csvHeader =
    'Date,Heure,Repas,Kcal,Proteines (g),Glucides (g),Lipides (g),Fibres (g),Sucres (g),Graisses saturees (g)';

/// Exporte les [days] derniers jours du journal alimentaire en CSV (ouvrable
/// dans Excel/Sheets — suffisant pour un partage avec un nutritionniste,
/// sans dépendance PDF) et ouvre le sélecteur de partage natif.
Future<void> exportMealJournalCsv(WidgetRef ref, {int days = 90}) async {
  final meals = await ref.read(mealRepositoryProvider).getMealsSince(days);

  final buffer = StringBuffer('$_csvHeader\n');
  for (final meal in meals) {
    final d = meal.createdAt;
    final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    buffer.writeln([
      date,
      time,
      _csvEscape(meal.name),
      meal.totalKcal,
      meal.totalProt.toStringAsFixed(1),
      meal.totalGluc.toStringAsFixed(1),
      meal.totalLip.toStringAsFixed(1),
      meal.totalFiber.toStringAsFixed(1),
      meal.totalSugar.toStringAsFixed(1),
      meal.totalSatFat.toStringAsFixed(1),
    ].join(','));
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/journal_repas.csv');
  await file.writeAsString(buffer.toString());

  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Journal alimentaire'));
}

String _csvEscape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
