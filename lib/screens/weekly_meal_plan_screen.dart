import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/meal_suggestion.dart';
import '../providers/profile_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/weekly_meal_plan_provider.dart';
import '../utils/journal_export.dart';
import '../utils/weekday_name.dart';
import '../widgets/animated_async_value.dart';
import '../widgets/cloud_ai_consent_gate.dart';
import '../widgets/meal_suggestion_card.dart';
import 'coach_screen.dart' show openCoachChatSheet, kCoachPrimaryColor;
import '../l10n/l10n_extensions.dart';

/// Plan de repas des 7 prochains jours, généré par l'IA — ouvert depuis
/// l'icône calendrier sur l'écran "Idées repas" (voir meal_suggestions_screen.dart).
/// Même raison que meal_suggestions_screen.dart pour le découpage en deux
/// classes : [weeklyMealPlanProvider] appelle l'IA cloud dès son premier
/// `watch`, donc ce `watch` doit vivre dans [_WeeklyMealPlanContent], gardé
/// derrière CloudAiConsentGate.
class WeeklyMealPlanScreen extends StatelessWidget {
  const WeeklyMealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CloudAiConsentGate(child: _WeeklyMealPlanContent());
  }
}

class _WeeklyMealPlanContent extends ConsumerWidget {
  const _WeeklyMealPlanContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(weeklyMealPlanProvider);
    final allergies = ref.watch(profileProvider).value?.allergies ?? const [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.weeklyMealPlanTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.event_available_outlined,
              color: kCoachPrimaryColor,
            ),
            tooltip: context.l10n.weeklyMealPlanExportCalendarTooltip,
            onPressed: () async {
              try {
                await exportWeeklyMealPlanIcs(ref);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n.weeklyMealPlanExportCalendarError,
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kCoachPrimaryColor),
            tooltip: context.l10n.weeklyMealPlanRegenerateTooltip,
            onPressed: () =>
                ref.read(weeklyMealPlanProvider.notifier).regenerate(),
          ),
        ],
      ),
      body: SafeArea(
        child: planAsync.animatedWhen(
          loading: () => const Center(
            child: CircularProgressIndicator(color: kCoachPrimaryColor),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.weeklyMealPlanLoadError,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(weeklyMealPlanProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCoachPrimaryColor,
                    ),
                    child: Text(
                      context.l10n.weeklyMealPlanRetryButton,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (plan) {
            if (plan.isEmpty) {
              return Center(
                child: Text(
                  context.l10n.weeklyMealPlanEmptyMessage,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }

            final byDay = <int, List<MealSuggestion>>{};
            for (final meal in plan) {
              byDay.putIfAbsent(meal.day ?? 1, () => []).add(meal);
            }
            final days = byDay.keys.toList()..sort();

            return RefreshIndicator(
              color: kCoachPrimaryColor,
              onRefresh: () =>
                  ref.read(weeklyMealPlanProvider.notifier).regenerate(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final titles = plan.map((m) => m.title).toList();
                        ref
                            .read(shoppingListProvider.notifier)
                            .addItems(titles);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.l10n.weeklyMealPlanAddAllMessage(
                                titles.length.toString(),
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: kCoachPrimaryColor,
                      ),
                      label: Text(
                        context.l10n.weeklyMealPlanAddAllButton,
                        style: const TextStyle(color: kCoachPrimaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kCoachPrimaryColor),
                      ),
                    ),
                  ),
                  for (final day in days) ...[
                    const SizedBox(height: 24),
                    Text(
                      weekdayName(context, day),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final meal in byDay[day]!) ...[
                      MealSuggestionCard(
                        suggestion: meal,
                        allergies: allergies,
                        onAdd: () => openCoachChatSheet(
                          context,
                          presetMessage: context.l10n
                              .mealSuggestionsAdjustPresetMessage(meal.title),
                        ),
                        onAddToShoppingList: () {
                          ref.read(shoppingListProvider.notifier).addItems([
                            meal.title,
                          ]);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n
                                    .mealSuggestionsAddedToShoppingListMessage(
                                      meal.title,
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
