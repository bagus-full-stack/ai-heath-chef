import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../local_db/local_db_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/storage_image_provider.dart';
import '../providers/weekly_meal_plan_provider.dart';
import '../services/data_export_service.dart';
import 'daily_nutrition_summary.dart';
import 'ics_export.dart';
import 'nutrition_targets.dart';

String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
String _fmt1(double v) => v.toStringAsFixed(1);

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

  await SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(utf8.encode(buffer.toString()), name: 'journal_repas.csv', mimeType: 'text/csv'),
    ],
    text: 'Journal alimentaire',
  ));
}

/// Exporte le bilan nutritionnel des 7 derniers jours en PDF (jour par jour
/// + moyennes/cibles) et ouvre le sélecteur de partage natif — format lisible
/// à donner à un nutritionniste, contrairement au CSV brut ligne par repas de
/// [exportMealJournalCsv].
Future<void> exportWeeklyNutritionSummaryPdf(WidgetRef ref) async {
  final meals = await ref.read(mealRepositoryProvider).getMealsSince(7);
  final days = buildDailyNutritionSummaries(meals, days: 7);
  final profile = await ref.read(profileProvider.future);
  final targets = computeNutritionTargets(profile);

  int sumKcal = 0;
  double sumProt = 0, sumGluc = 0, sumLip = 0, sumFiber = 0, sumSugar = 0, sumSatFat = 0;
  for (final d in days) {
    sumKcal += d.kcal;
    sumProt += d.prot;
    sumGluc += d.gluc;
    sumLip += d.lip;
    sumFiber += d.fiber;
    sumSugar += d.sugar;
    sumSatFat += d.satFat;
  }
  final n = days.length;

  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  String fmt(double v) => v.toStringAsFixed(1);

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bilan nutritionnel hebdomadaire',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('${profile?.fullName ?? 'Utilisateur'} — ${fmtDate(days.first.day)} au ${fmtDate(days.last.day)}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Kcal', 'Prot (g)', 'Gluc (g)', 'Lip (g)', 'Fibres (g)', 'Sucres (g)', 'AGS (g)'],
            data: [
              for (final d in days)
                [fmtDate(d.day), '${d.kcal}', fmt(d.prot), fmt(d.gluc), fmt(d.lip), fmt(d.fiber), fmt(d.sugar), fmt(d.satFat)],
            ],
            cellAlignment: pw.Alignment.centerRight,
            cellAlignments: {0: pw.Alignment.centerLeft},
          ),
          pw.SizedBox(height: 16),
          pw.Text('Moyenne quotidienne', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Kcal', 'Prot (g)', 'Gluc (g)', 'Lip (g)', 'Fibres (g)', 'Sucres (g)', 'AGS (g)'],
            data: [
              [
                '${(sumKcal / n).round()}',
                fmt(sumProt / n),
                fmt(sumGluc / n),
                fmt(sumLip / n),
                fmt(sumFiber / n),
                fmt(sumSugar / n),
                fmt(sumSatFat / n),
              ],
            ],
            cellAlignment: pw.Alignment.centerRight,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Cibles quotidiennes estimées : ${targets.kcal} kcal · '
            '${targets.protein.round()}g prot. · ${targets.carbs.round()}g gluc. · ${targets.fat.round()}g lip.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    ),
  );

  await SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(await doc.save(), name: 'bilan_nutritionnel_hebdo.pdf', mimeType: 'application/pdf'),
    ],
    text: 'Bilan nutritionnel hebdomadaire',
  ));
}

/// Exporte un bilan des 30 derniers jours (nutrition jour par jour + poids)
/// en PDF — pensé pour un suivi nutritionniste plus complet que le bilan
/// hebdomadaire de [exportWeeklyNutritionSummaryPdf], dont il réutilise la
/// même structure de calculs ([buildDailyNutritionSummaries]).
/// ponytail: pw.MultiPage plutôt que pw.Page, le tableau de 30 lignes ne
/// tiendrait pas sur une seule page A4.
Future<void> exportMonthlyNutritionSummaryPdf(WidgetRef ref) async {
  final meals = await ref.read(mealRepositoryProvider).getMealsSince(30);
  final days = buildDailyNutritionSummaries(meals, days: 30);
  final profile = await ref.read(profileProvider.future);
  final targets = computeNutritionTargets(profile);
  final weightEntries = await ref.read(weightRepositoryProvider).getEntriesSince(30);

  int sumKcal = 0;
  double sumProt = 0, sumGluc = 0, sumLip = 0, sumFiber = 0, sumSugar = 0, sumSatFat = 0;
  for (final d in days) {
    sumKcal += d.kcal;
    sumProt += d.prot;
    sumGluc += d.gluc;
    sumLip += d.lip;
    sumFiber += d.fiber;
    sumSugar += d.sugar;
    sumSatFat += d.satFat;
  }
  final n = days.length;

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text('Bilan nutritionnel mensuel', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('${profile?.fullName ?? 'Utilisateur'} — ${_fmtDate(days.first.day)} au ${_fmtDate(days.last.day)}'),
        pw.SizedBox(height: 16),
        pw.Text('Moyenne quotidienne', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Kcal', 'Prot (g)', 'Gluc (g)', 'Lip (g)', 'Fibres (g)', 'Sucres (g)', 'AGS (g)'],
          data: [
            [
              '${(sumKcal / n).round()}',
              _fmt1(sumProt / n),
              _fmt1(sumGluc / n),
              _fmt1(sumLip / n),
              _fmt1(sumFiber / n),
              _fmt1(sumSugar / n),
              _fmt1(sumSatFat / n),
            ],
          ],
          cellAlignment: pw.Alignment.centerRight,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Cibles quotidiennes estimées : ${targets.kcal} kcal · '
          '${targets.protein.round()}g prot. · ${targets.carbs.round()}g gluc. · ${targets.fat.round()}g lip.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        if (weightEntries.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Évolution du poids', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(
            '${weightEntries.first.weightKg.toStringAsFixed(1)} kg → ${weightEntries.last.weightKg.toStringAsFixed(1)} kg '
            '(${(weightEntries.last.weightKg - weightEntries.first.weightKg) >= 0 ? '+' : ''}'
            '${(weightEntries.last.weightKg - weightEntries.first.weightKg).toStringAsFixed(1)} kg)',
          ),
        ],
        pw.SizedBox(height: 16),
        pw.Text('Détail quotidien', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Kcal', 'Prot (g)', 'Gluc (g)', 'Lip (g)', 'Fibres (g)', 'Sucres (g)', 'AGS (g)'],
          data: [
            for (final d in days)
              [
                _fmtDate(d.day),
                '${d.kcal}',
                _fmt1(d.prot),
                _fmt1(d.gluc),
                _fmt1(d.lip),
                _fmt1(d.fiber),
                _fmt1(d.sugar),
                _fmt1(d.satFat),
              ],
          ],
          cellAlignment: pw.Alignment.centerRight,
          cellAlignments: {0: pw.Alignment.centerLeft},
        ),
      ],
    ),
  );

  await SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(await doc.save(), name: 'bilan_nutritionnel_mensuel.pdf', mimeType: 'application/pdf'),
    ],
    text: 'Bilan nutritionnel mensuel',
  ));
}

/// Exporte le plan de repas des 7 prochains jours (voir
/// weeklyMealPlanProvider) en calendrier .ics et ouvre le sélecteur de
/// partage natif — permet d'importer les repas dans Google/Apple/Outlook
/// Calendar comme rappels, sans dépendance supplémentaire.
Future<void> exportWeeklyMealPlanIcs(WidgetRef ref) async {
  final plan = await ref.read(weeklyMealPlanProvider.future);
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  final ics = buildWeeklyMealPlanIcs(plan, monday);

  await SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(utf8.encode(ics), name: 'plan_repas_semaine.ics', mimeType: 'text/calendar'),
    ],
    text: 'Plan de repas de la semaine',
  ));
}

/// Exporte toutes les données personnelles de l'utilisateur (profil, repas,
/// poids, hydratation, chat, plans de repas, préférences — voir
/// [DataExportService]) en un unique JSON et ouvre le sélecteur de partage
/// natif. Droit d'accès/portabilité RGPD, voir
/// docs/PRIVACY_POLICY_DRAFT.md section 7.
Future<void> exportAllUserData(WidgetRef ref) async {
  final service = DataExportService(
    ref.read(appDatabaseProvider),
    null,
    ref.read(storageImageServiceProvider),
  );
  final export = await service.buildExport();

  await SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(utf8.encode(jsonEncode(export)), name: 'export_donnees.json', mimeType: 'application/json'),
    ],
    text: 'Export de mes données',
  ));
}

String _csvEscape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
