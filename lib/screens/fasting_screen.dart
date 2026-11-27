import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/fasting_provider.dart';
import '../config/app_colors.dart';

final _primaryColor = AppColors.brand;
const _goalOptions = [12, 14, 16, 18, 20, 24];

/// Jeûne intermittent : fenêtre horaire (objectif de durée) + minuteur —
/// complète le suivi macros existant (dashboard) sans se substituer à lui.
/// Le minuteur ne tourne qu'à l'écran ouvert (pas de tâche de fond) ; il
/// suffit à rafraîchir l'affichage, `startedAt` étant persisté indépendamment.
class FastingScreen extends ConsumerStatefulWidget {
  const FastingScreen({super.key});

  @override
  ConsumerState<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends ConsumerState<FastingScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fastingAsync = ref.watch(fastingProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip, 
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.fastingTitle,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
      ),
      body: fastingAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: _primaryColor)),
        error: (err, stack) => Center(child: Text(err.toString())),
        data: (fasting) {
          final elapsed = fasting.elapsed;
          final progress = fasting.isFasting
              ? (elapsed.inSeconds / (fasting.goalHours * 3600)).clamp(0.0, 1.0)
              : 0.0;
          final goalReached = fasting.isFasting && elapsed.inHours >= fasting.goalHours;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: fasting.isFasting ? progress : 0,
                          strokeWidth: 12,
                          backgroundColor: AppColors.grey200,
                          color: goalReached ? Colors.green : _primaryColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.fastingElapsedValue(
                              elapsed.inHours.toString(),
                              (elapsed.inMinutes % 60).toString().padLeft(2, '0'),
                            ),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fasting.isFasting
                                ? context.l10n.fastingStatusFasting
                                : context.l10n.fastingStatusIdle,
                            style: TextStyle(color: AppColors.grey600, fontSize: 13),
                          ),
                          if (goalReached) ...[
                            const SizedBox(height: 6),
                            Text(
                              context.l10n.fastingGoalReachedMessage,
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.l10n.fastingGoalLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hours in _goalOptions)
                    ChoiceChip(
                      label: Text(context.l10n.fastingHoursValue(hours.toString())),
                      selected: fasting.goalHours == hours,
                      selectedColor: _primaryColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: fasting.goalHours == hours ? _primaryColor : AppColors.ink87,
                        fontWeight: fasting.goalHours == hours ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => ref.read(fastingProvider.notifier).setGoalHours(hours),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => fasting.isFasting
                    ? ref.read(fastingProvider.notifier).stop()
                    : ref.read(fastingProvider.notifier).start(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: fasting.isFasting ? Colors.redAccent : _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  fasting.isFasting ? context.l10n.fastingStopButton : context.l10n.fastingStartButton,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
