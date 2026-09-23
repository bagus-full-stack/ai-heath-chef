import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../models/ingredient.dart';
import '../models/meal_analysis_args.dart';
import '../providers/locale_provider.dart';
import '../providers/meal_provider.dart';

const _primaryColor = Color(0xFF6B66FF);

/// Recherche d'un aliment par nom (repas maison, resto...) dans la base
/// Open Food Facts, sans passer par une photo ou un code-barres. Le résultat
/// choisi est chargé tel quel dans l'écran d'analyse existant
/// ([MealAnalysisScreen] via [MealAnalysisArgs.manualIngredients]), qui gère
/// déjà l'ajustement des quantités et la sauvegarde.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<Ingredient>>? _searchFuture;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _searchFuture = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  void _search(String query) {
    final lang = ref.read(localeProvider).value?.languageCode ?? 'fr';
    setState(() {
      _query = query;
      _searchFuture = ref.read(productLookupServiceProvider).searchByName(query, lang: lang);
    });
  }

  void _selectResult(Ingredient ingredient) {
    context.push('/meal_analysis', extra: MealAnalysisArgs(manualIngredients: [ingredient]));
  }

  void _addManually() {
    context.push('/meal_analysis', extra: const MealAnalysisArgs(manualIngredients: []));
  }

  @override
  Widget build(BuildContext context) {
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
          context.l10n.foodSearchTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: context.l10n.foodSearchFieldHint,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primaryColor, width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
            Expanded(child: _buildBody(context)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: TextButton(
                  onPressed: _addManually,
                  child: Text(
                    context.l10n.foodSearchAddManuallyButton,
                    style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final future = _searchFuture;
    if (future == null) {
      return _buildMessage(
        icon: Icons.restaurant_menu,
        message: context.l10n.foodSearchInitialPrompt,
      );
    }

    return FutureBuilder<List<Ingredient>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (snapshot.hasError) {
          return _buildMessage(
            icon: Icons.error_outline,
            message: snapshot.error.toString(),
            color: Colors.redAccent,
          );
        }

        final results = snapshot.data ?? const [];
        if (results.isEmpty) {
          return _buildMessage(
            icon: Icons.search_off,
            message: context.l10n.foodSearchNoResults(_query),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          itemCount: results.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ingredient = results[index];
            return _ResultTile(
              ingredient: ingredient,
              onTap: () => _selectResult(ingredient),
            );
          },
        );
      },
    );
  }

  Widget _buildMessage({required IconData icon, required String message, Color? color}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color ?? Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color ?? Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;

  const _ResultTile({required this.ingredient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.foodSearchKcalPer100g(ingredient.kcalPer100g.toStringAsFixed(0)),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
