import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../local_db/app_database.dart' show WeightEntry;
import '../local_db/local_db_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/custom_reminders_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';

const _primaryColor = Color(0xFF6B66FF);

/// Courbe de progression du poids, alimentée par [WeightEntries] (base
/// locale) — le pendant de nutrition_trends_screen.dart pour le poids
/// plutôt que les calories. Enregistrer une pesée met aussi à jour
/// `profiles.current_weight`, seule source consultée ailleurs dans l'app
/// (IMC du dashboard, cibles caloriques).
class WeightTrendScreen extends ConsumerWidget {
  const WeightTrendScreen({super.key});

  Future<void> _logWeight(BuildContext context, WidgetRef ref, double defaultValue) async {
    final controller = TextEditingController(
      text: defaultValue > 0 ? defaultValue.toStringAsFixed(1) : '',
    );
    final weight = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sheetContext.l10n.weightTrendLogSheetTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  suffixText: 'kg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final value = double.tryParse(controller.text.trim().replaceAll(',', '.'));
                  if (value == null || value <= 0 || value > 400) return;
                  Navigator.pop(sheetContext, value);
                },
                child: Text(sheetContext.l10n.weightTrendLogSheetSaveButton),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (weight == null || !context.mounted) return;

    await ref.read(weightRepositoryProvider).addEntry(weight);

    final profile = await ref.read(profileProvider.future);
    if (profile != null) {
      await ref.read(authServiceProvider).upsertProfile(
            fullName: profile.fullName,
            sex: profile.sex,
            age: profile.age,
            currentWeight: weight,
            targetWeight: profile.targetWeight,
            heightCm: profile.heightCm,
            goal: profile.goal,
            avatarUrl: profile.avatarUrl,
          );
    }

    ref.invalidate(weightEntriesProvider);
    ref.invalidate(profileProvider);
  }

  /// Ajoute (ou, si déjà présent, ouvre les réglages pour) un rappel
  /// hebdomadaire de pesée — un simple préréglage du système de rappels
  /// personnalisés existant (voir custom_reminders_provider.dart).
  Future<void> _setupWeeklyReminder(BuildContext context, WidgetRef ref) async {
    final reminderName = context.l10n.weightTrendWeeklyReminderName;
    final reminders = await ref.read(customRemindersProvider.future);
    final alreadySet = reminders.any((r) => r.name == reminderName);

    if (alreadySet) {
      if (context.mounted) context.push('/notifications');
      return;
    }

    await ref.read(customRemindersProvider.notifier).add(reminderName, 8, 0, weekday: DateTime.monday);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.weightTrendWeeklyReminderAddedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weightEntriesProvider);
    final profileAsync = ref.watch(profileProvider);
    final targetWeight = profileAsync.maybeWhen(data: (p) => p?.targetWeight ?? 0, orElse: () => 0.0);
    final fallbackWeight = profileAsync.maybeWhen(data: (p) => p?.currentWeight ?? 0, orElse: () => 0.0);

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
          context.l10n.weightTrendTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _primaryColor)),
        error: (err, stack) => Center(child: Text(context.l10n.weightTrendErrorMessage(err.toString()))),
        data: (entries) {
          final latestWeight = entries.isNotEmpty ? entries.last.weightKg : fallbackWeight;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(weightEntriesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: context.l10n.weightTrendCurrentLabel,
                        value: latestWeight > 0 ? context.l10n.weightTrendKgValue(latestWeight.toStringAsFixed(1)) : '—',
                        color: const Color(0xFFF06B9E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: context.l10n.weightTrendTargetLabel,
                        value: targetWeight > 0 ? context.l10n.weightTrendKgValue(targetWeight.toStringAsFixed(1)) : '—',
                        color: const Color(0xFFFFB54A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      context.l10n.weightTrendEmptyState,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 1)],
                    ),
                    child: _WeightChart(entries: entries, targetWeight: targetWeight),
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _logWeight(context, ref, latestWeight),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.weightTrendLogButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _setupWeeklyReminder(context, ref),
                  icon: const Icon(Icons.notifications_active_outlined, color: _primaryColor),
                  label: Text(
                    context.l10n.weightTrendWeeklyReminderButton,
                    style: const TextStyle(color: _primaryColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 6, backgroundColor: color),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final double targetWeight;
  const _WeightChart({required this.entries, required this.targetWeight});

  @override
  Widget build(BuildContext context) {
    final weights = entries.map((e) => e.weightKg).toList();
    final minWeight = [if (targetWeight > 0) targetWeight, ...weights].reduce((a, b) => a < b ? a : b);
    final maxWeight = [if (targetWeight > 0) targetWeight, ...weights].reduce((a, b) => a > b ? a : b);
    final padding = ((maxWeight - minWeight) * 0.2).clamp(1.0, 20.0);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minWeight - padding,
          maxY: maxWeight + padding,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                  final d = entries[i].recordedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 9, color: Colors.black45)),
                  );
                },
              ),
            ),
          ),
          extraLinesData: targetWeight > 0
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: targetWeight,
                    color: Colors.green.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [6, 4],
                  ),
                ])
              : null,
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < entries.length; i++) FlSpot(i.toDouble(), entries[i].weightKg)],
              isCurved: true,
              color: _primaryColor,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: _primaryColor.withValues(alpha: 0.08)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} kg',
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
