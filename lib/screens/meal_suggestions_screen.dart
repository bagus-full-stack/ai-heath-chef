import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/meal_suggestions_provider.dart';
import '../widgets/animated_async_value.dart';
import '../widgets/meal_suggestion_card.dart';
import 'coach_screen.dart' show openCoachChatSheet, kCoachPrimaryColor;

/// Liste complète des idées de repas générées par l'IA, ouverte depuis
/// "Tout voir" sur l'écran du Coach.
class MealSuggestionsScreen extends ConsumerWidget {
  const MealSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(mealSuggestionsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Idées repas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kCoachPrimaryColor),
            tooltip: 'Régénérer',
            onPressed: () => ref.read(mealSuggestionsProvider.notifier).regenerate(),
          ),
        ],
      ),
      body: SafeArea(
        child: suggestionsAsync.animatedWhen(
          loading: () => const Center(
            child: CircularProgressIndicator(color: kCoachPrimaryColor),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Impossible de générer des idées de repas pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(mealSuggestionsProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: kCoachPrimaryColor),
                    child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          data: (suggestions) {
            if (suggestions.isEmpty) {
              return Center(
                child: Text(
                  'Aucune idée de repas disponible pour le moment.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }

            return RefreshIndicator(
              color: kCoachPrimaryColor,
              onRefresh: () => ref.read(mealSuggestionsProvider.notifier).regenerate(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return MealSuggestionCard(
                    suggestion: suggestion,
                    onAdd: () => openCoachChatSheet(
                      context,
                      presetMessage: 'Ajuste ce repas pour mon objectif: ${suggestion.title}',
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
