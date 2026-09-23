import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../models/meal.dart';
import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/purchase_provider.dart';
import '../utils/nutrition_targets.dart';
import '../widgets/animated_async_value.dart';
import '../widgets/staggered_entrance.dart';

const _primaryColor = Color(0xFF6B66FF);
const _protColor = Colors.blue;
const _glucColor = Colors.orange;
const _lipColor = Colors.pink;
const _fiberColor = Colors.green;
const _sugarColor = Colors.redAccent;
const _satFatColor = Colors.brown;

String _dayLabel(BuildContext context, int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return context.l10n.nutritionTrendsDayMon;
    case DateTime.tuesday:
      return context.l10n.nutritionTrendsDayTue;
    case DateTime.wednesday:
      return context.l10n.nutritionTrendsDayWed;
    case DateTime.thursday:
      return context.l10n.nutritionTrendsDayThu;
    case DateTime.friday:
      return context.l10n.nutritionTrendsDayFri;
    case DateTime.saturday:
      return context.l10n.nutritionTrendsDaySat;
    default:
      return context.l10n.nutritionTrendsDaySun;
  }
}

class _DaySummary {
  final DateTime day;
  int kcal = 0;
  double prot = 0;
  double gluc = 0;
  double lip = 0;
  double fiber = 0;
  double sugar = 0;
  double satFat = 0;

  _DaySummary(this.day);
}

/// Écran PRO : tendances nutritionnelles et macros détaillées sur les 7
/// derniers jours (voir bénéfice "Analyses avancées" du paywall).
class NutritionTrendsScreen extends ConsumerWidget {
  const NutritionTrendsScreen({super.key});

  List<_DaySummary> _buildDailySummaries(List<Meal> meals, {int days = 7}) {
    final today = DateTime.now();
    final daySummaries = List.generate(days, (i) {
      final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: days - 1 - i));
      return _DaySummary(d);
    });

    for (final meal in meals) {
      final key = DateTime(meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
      final summary = daySummaries.firstWhere(
        (d) => d.day == key,
        orElse: () => _DaySummary(key),
      );
      summary.kcal += meal.totalKcal;
      summary.prot += meal.totalProt;
      summary.gluc += meal.totalGluc;
      summary.lip += meal.totalLip;
      summary.fiber += meal.totalFiber;
      summary.sugar += meal.totalSugar;
      summary.satFat += meal.totalSatFat;
    }
    return daySummaries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementAsync = ref.watch(entitlementProvider);
    final isPro = entitlementAsync.value ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.nutritionTrendsTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: !isPro
          ? _ProLockedView(loading: entitlementAsync.isLoading)
          : Consumer(
              builder: (context, ref, _) {
                final mealsAsync = ref.watch(nutritionTrendsProvider);
                final mealsAsync30 = ref.watch(nutritionTrends30Provider);
                final profileAsync = ref.watch(profileProvider);
                final targets = profileAsync.maybeWhen(
                  data: computeNutritionTargets,
                  orElse: () => NutritionTargets.fallback,
                );

                return mealsAsync.animatedWhen(
                  loading: () => const Center(child: CircularProgressIndicator(color: _primaryColor)),
                  error: (err, stack) => Center(child: Text(context.l10n.nutritionTrendsErrorMessage(err.toString()))),
                  data: (meals) {
                    final days = _buildDailySummaries(meals);

                    if (meals.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            context.l10n.nutritionTrendsEmptyState,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    final totalKcal = days.fold<int>(0, (sum, d) => sum + d.kcal);
                    final totalProt = days.fold<double>(0, (sum, d) => sum + d.prot);
                    final totalGluc = days.fold<double>(0, (sum, d) => sum + d.gluc);
                    final totalLip = days.fold<double>(0, (sum, d) => sum + d.lip);
                    final totalFiber = days.fold<double>(0, (sum, d) => sum + d.fiber);
                    final totalSugar = days.fold<double>(0, (sum, d) => sum + d.sugar);
                    final totalSatFat = days.fold<double>(0, (sum, d) => sum + d.satFat);

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(nutritionTrendsProvider),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          StaggeredEntrance(
                            child: _SectionCard(
                              title: context.l10n.nutritionTrendsCaloriesSectionTitle,
                              child: _CaloriesChart(days: days, targetKcal: targets.kcal),
                            ),
                          ),
                          const SizedBox(height: 16),
                          StaggeredEntrance(
                            delay: const Duration(milliseconds: 30),
                            child: _SectionCard(
                              title: context.l10n.nutritionTrends30DaySectionTitle,
                              child: mealsAsync30.maybeWhen(
                                data: (meals30) => _CaloriesTrend30Chart(
                                  days: _buildDailySummaries(meals30, days: 30),
                                  targetKcal: targets.kcal,
                                ),
                                orElse: () => const SizedBox(
                                  height: 160,
                                  child: Center(child: CircularProgressIndicator(color: _primaryColor)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          StaggeredEntrance(
                            delay: const Duration(milliseconds: 60),
                            child: _SectionCard(
                              title: context.l10n.nutritionTrendsMacroDistributionTitle,
                              child: _MacroDistribution(
                                totalProt: totalProt,
                                totalGluc: totalGluc,
                                totalLip: totalLip,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          StaggeredEntrance(
                            delay: const Duration(milliseconds: 120),
                            child: _SectionCard(
                              title: context.l10n.nutritionTrendsDailyAveragesTitle,
                              child: _DailyAverages(
                                avgKcal: totalKcal / 7,
                                avgProt: totalProt / 7,
                                avgGluc: totalGluc / 7,
                                avgLip: totalLip / 7,
                                targets: targets,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          StaggeredEntrance(
                            delay: const Duration(milliseconds: 180),
                            child: _SectionCard(
                              title: context.l10n.nutritionTrendsExtraNutrientsTitle,
                              child: _ExtraNutrients(
                                avgFiber: totalFiber / 7,
                                avgSugar: totalSugar / 7,
                                avgSatFat: totalSatFat / 7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ProLockedView extends StatelessWidget {
  final bool loading;
  const _ProLockedView({required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: _primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.insights_rounded, color: _primaryColor, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.nutritionTrendsProLockedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.nutritionTrendsProLockedDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/paywall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(context.l10n.nutritionTrendsGoProButton, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CaloriesChart extends StatelessWidget {
  final List<_DaySummary> days;
  final int targetKcal;
  const _CaloriesChart({required this.days, required this.targetKcal});

  @override
  Widget build(BuildContext context) {
    final maxKcal = [targetKcal, ...days.map((d) => d.kcal)].reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((d) {
          final heightRatio = maxKcal == 0 ? 0.0 : d.kcal / maxKcal;
          final overTarget = targetKcal > 0 && d.kcal > targetKcal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${d.kcal}', style: const TextStyle(fontSize: 9, color: Colors.black54)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    height: 90 * heightRatio,
                    decoration: BoxDecoration(
                      color: overTarget ? Colors.redAccent.withValues(alpha: 0.8) : _primaryColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dayLabel(context, d.day.weekday),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CaloriesTrend30Chart extends StatelessWidget {
  final List<_DaySummary> days;
  final int targetKcal;
  const _CaloriesTrend30Chart({required this.days, required this.targetKcal});

  @override
  Widget build(BuildContext context) {
    final maxKcal = [targetKcal, ...days.map((d) => d.kcal)].reduce((a, b) => a > b ? a : b).toDouble();
    final interval = maxKcal > 0 ? maxKcal / 4 : 1.0;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxKcal * 1.15,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: interval),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: interval,
                getTitlesWidget: (value, meta) => Text(
                  value.round().toString(),
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 6,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= days.length) return const SizedBox.shrink();
                  final d = days[i].day;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 9, color: Colors.black45)),
                  );
                },
              ),
            ),
          ),
          extraLinesData: targetKcal > 0
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: targetKcal.toDouble(),
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [6, 4],
                  ),
                ])
              : null,
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < days.length; i++) FlSpot(i.toDouble(), days[i].kcal.toDouble())],
              isCurved: true,
              color: _primaryColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: _primaryColor.withValues(alpha: 0.08)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.round()} kcal',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroDistribution extends StatelessWidget {
  final double totalProt;
  final double totalGluc;
  final double totalLip;
  const _MacroDistribution({required this.totalProt, required this.totalGluc, required this.totalLip});

  @override
  Widget build(BuildContext context) {
    final protKcal = totalProt * 4;
    final glucKcal = totalGluc * 4;
    final lipKcal = totalLip * 9;
    final totalMacroKcal = protKcal + glucKcal + lipKcal;

    final protPct = totalMacroKcal == 0 ? 0.0 : protKcal / totalMacroKcal;
    final glucPct = totalMacroKcal == 0 ? 0.0 : glucKcal / totalMacroKcal;
    final lipPct = totalMacroKcal == 0 ? 0.0 : lipKcal / totalMacroKcal;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                Expanded(flex: (protPct * 1000).round().clamp(1, 1000), child: Container(color: _protColor)),
                Expanded(flex: (glucPct * 1000).round().clamp(1, 1000), child: Container(color: _glucColor)),
                Expanded(flex: (lipPct * 1000).round().clamp(1, 1000), child: Container(color: _lipColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MacroLegend(color: _protColor, label: context.l10n.nutritionTrendsProteinLabel, percent: protPct),
            _MacroLegend(color: _glucColor, label: context.l10n.nutritionTrendsCarbsLabel, percent: glucPct),
            _MacroLegend(color: _lipColor, label: context.l10n.nutritionTrendsFatLabel, percent: lipPct),
          ],
        ),
      ],
    );
  }
}

class _MacroLegend extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;
  const _MacroLegend({required this.color, required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 5, backgroundColor: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 4),
        Text('${(percent * 100).round()}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DailyAverages extends StatelessWidget {
  final double avgKcal;
  final double avgProt;
  final double avgGluc;
  final double avgLip;
  final NutritionTargets targets;
  const _DailyAverages({
    required this.avgKcal,
    required this.avgProt,
    required this.avgGluc,
    required this.avgLip,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AverageRow(label: context.l10n.nutritionTrendsCaloriesLabel, value: '${avgKcal.round()} kcal', target: '/${targets.kcal} kcal', color: _primaryColor),
        const SizedBox(height: 10),
        _AverageRow(label: context.l10n.nutritionTrendsProteinLabel, value: '${avgProt.round()}g', target: '/${targets.protein.round()}g', color: _protColor),
        const SizedBox(height: 10),
        _AverageRow(label: context.l10n.nutritionTrendsCarbsLabel, value: '${avgGluc.round()}g', target: '/${targets.carbs.round()}g', color: _glucColor),
        const SizedBox(height: 10),
        _AverageRow(label: context.l10n.nutritionTrendsFatLabel, value: '${avgLip.round()}g', target: '/${targets.fat.round()}g', color: _lipColor),
      ],
    );
  }
}

/// Fibres/sucres/graisses saturées n'ont pas de cible personnalisée dans
/// [NutritionTargets] (contrairement aux macros principales) : on affiche
/// donc de simples moyennes, sans comparaison "/cible".
class _ExtraNutrients extends StatelessWidget {
  final double avgFiber;
  final double avgSugar;
  final double avgSatFat;
  const _ExtraNutrients({required this.avgFiber, required this.avgSugar, required this.avgSatFat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AverageRow(label: context.l10n.nutritionTrendsFiberLabel, value: '${avgFiber.round()}g', target: '', color: _fiberColor),
        const SizedBox(height: 10),
        _AverageRow(label: context.l10n.nutritionTrendsSugarLabel, value: '${avgSugar.round()}g', target: '', color: _sugarColor),
        const SizedBox(height: 10),
        _AverageRow(label: context.l10n.nutritionTrendsSatFatLabel, value: '${avgSatFat.round()}g', target: '', color: _satFatColor),
      ],
    );
  }
}

class _AverageRow extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final Color color;
  const _AverageRow({required this.label, required this.value, required this.target, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Text(target, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}
