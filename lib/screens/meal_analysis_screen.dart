import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/meal_provider.dart';
import '../providers/dashboard_provider.dart';
import '../local_db/local_db_provider.dart';
import '../models/ingredient.dart';
import '../widgets/animated_async_value.dart';
import '../widgets/success_transition_dialog.dart';
import '../l10n/l10n_extensions.dart';

class MealAnalysisScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final String? barcode;
  final bool isProduct;
  final List<Ingredient>? manualIngredients;

  const MealAnalysisScreen({
    super.key,
    this.imagePath,
    this.barcode,
    this.isProduct = false,
    this.manualIngredients,
  });

  @override
  ConsumerState<MealAnalysisScreen> createState() => _MealAnalysisScreenState();
}

class _MealAnalysisScreenState extends ConsumerState<MealAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // On lance l'analyse (IA ou recherche produit) juste après la
    // construction initiale de l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAnalysis());
  }

  void _startAnalysis() {
    if (widget.manualIngredients != null) {
      ref.read(mealProvider.notifier).loadManual(widget.manualIngredients!);
    } else if (widget.barcode != null) {
      ref.read(mealProvider.notifier).loadFromBarcode(widget.barcode!);
    } else if (widget.imagePath != null) {
      ref
          .read(mealProvider.notifier)
          .analyzeImage(widget.imagePath!, isProduct: widget.isProduct);
    }
  }

  bool get _isManualFlow => widget.manualIngredients != null;
  bool get _isProductFlow => widget.barcode != null || widget.isProduct;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    // On écoute l'état de notre Provider (loading, data, ou error)
    final mealState = ref.watch(mealProvider);

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
          _isManualFlow
              ? context.l10n.mealAnalysisTitleManual
              : _isProductFlow
              ? context.l10n.mealAnalysisTitleProduct
              : context.l10n.mealAnalysisTitleMeal,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: primaryColor),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.l10n.mealAnalysisHowItWorksTitle),
                content: Text(context.l10n.mealAnalysisHowItWorksBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.mealAnalysisHowItWorksConfirm),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Zone de l'image (Toujours visible)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.imagePath != null)
                      Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                    else
                      Icon(
                        widget.barcode != null
                            ? Icons.qr_code_scanner_rounded
                            : _isManualFlow
                            ? Icons.edit_note_rounded
                            : Icons.fastfood,
                        size: 80,
                        color: Colors.grey,
                      ),

                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.barcode != null
                              ? context.l10n.mealAnalysisBadgeBarcode
                              : _isManualFlow
                              ? context.l10n.mealAnalysisBadgeManual
                              : context.l10n.mealAnalysisBadgeAi,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Gestion de l'affichage selon l'état de l'IA
              mealState.animatedWhen(
                // ÉTAT 1 : CHARGEMENT
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 20),
                      Text(
                        widget.barcode != null
                            ? context.l10n.mealAnalysisLoadingBarcode
                            : widget.isProduct
                            ? context.l10n.mealAnalysisLoadingLabel
                            : context.l10n.mealAnalysisLoadingPlate,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.mealAnalysisLoadingHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),

                // ÉTAT 2 : ERREUR
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.mealAnalysisErrorTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _startAnalysis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: Text(
                          context.l10n.mealAnalysisRetryButton,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // ÉTAT 3 : SUCCÈS (On affiche les données !)
                data: (ingredients) {
                  // Sécurité : liste vide inattendue pour les flux photo/
                  // code-barres. En saisie manuelle, une liste vide est le
                  // point de départ normal (l'utilisateur ajoute via le
                  // bouton "Ajouter un ingrédient" ci-dessous).
                  if (ingredients.isEmpty && !_isManualFlow)
                    return const SizedBox.shrink();

                  // Calculs totaux
                  final totalKcal = ingredients.fold<int>(
                    0,
                    (sum, item) => sum + item.currentKcal,
                  );
                  final totalProt = ingredients.fold<double>(
                    0,
                    (sum, item) => sum + item.currentProt,
                  );
                  final totalGluc = ingredients.fold<double>(
                    0,
                    (sum, item) => sum + item.currentGluc,
                  );
                  final totalLip = ingredients.fold<double>(
                    0,
                    (sum, item) => sum + item.currentLip,
                  );
                  final totalFiber = ingredients.fold<double>(
                    0,
                    (sum, item) => sum + item.currentFiber,
                  );
                  final totalSugar = ingredients.fold<double>(
                    0,
                    (sum, item) => sum + item.currentSugar,
                  );
                  final totalSatFat = ingredients.fold<double>(
                    0,
                    (sum, item) => sum + item.currentSatFat,
                  );

                  return Column(
                    children: [
                      // En-tête Ingrédients & Total
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.mealAnalysisIngredientsTitle,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  context.l10n.mealAnalysisIngredientsSubtitle,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TweenAnimationBuilder<int>(
                                  duration: const Duration(milliseconds: 300),
                                  tween: IntTween(begin: totalKcal, end: totalKcal),
                                  builder: (context, value, child) => Text(
                                    '$value',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  context.l10n.mealAnalysisTotalKcalLabel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Liste Dynamique des ingrédients
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            ...ingredients.map(
                              (item) => Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => ref
                                    .read(mealProvider.notifier)
                                    .removeIngredient(item.id),
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                child: _buildIngredientCard(item, ref, primaryColor),
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final ingredient =
                                    await showModalBottomSheet<Ingredient>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          const _AddIngredientSheet(),
                                    );
                                if (ingredient != null) {
                                  ref
                                      .read(mealProvider.notifier)
                                      .addIngredient(ingredient);
                                }
                              },
                              icon: const Icon(
                                Icons.add,
                                color: Colors.black54,
                              ),
                              label: Text(
                                context.l10n.mealAnalysisAddIngredientButton,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Résumé Nutritionnel
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.mealAnalysisNutritionSummaryTitle,
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSummaryMacro(
                                    context.l10n.mealAnalysisMacroProtein,
                                    totalProt,
                                    primaryColor,
                                  ),
                                  _buildSummaryMacro(
                                    context.l10n.mealAnalysisMacroCarbs,
                                    totalGluc,
                                    Colors.orange,
                                  ),
                                  _buildSummaryMacro(
                                    context.l10n.mealAnalysisMacroFat,
                                    totalLip,
                                    Colors.pink,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSummaryMacro(
                                    context.l10n.mealAnalysisMacroFiber,
                                    totalFiber,
                                    Colors.green,
                                  ),
                                  _buildSummaryMacro(
                                    context.l10n.mealAnalysisMacroSugar,
                                    totalSugar,
                                    Colors.redAccent,
                                  ),
                                  _buildSummaryMacro(
                                    context.l10n.mealAnalysisMacroSatFat,
                                    totalSatFat,
                                    Colors.brown,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // BOUTON DE SAUVEGARDE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton(
                          onPressed: ingredients.isEmpty ? null : () async {
                            final isSuccess = ValueNotifier<bool>(false);
                            try {
                              // On affiche un indicateur de chargement, qui se
                              // transformera en confirmation visuelle une fois
                              // la sauvegarde terminée.
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => SuccessTransitionDialog(isSuccess: isSuccess),
                              );

                              // Sauvegarde locale d'abord (utilisable hors
                              // ligne), avec synchronisation Supabase en
                              // arrière-plan — voir lib/local_db/meal_repository.dart.
                              final mealName = _isProductFlow
                                  ? ingredients.first.name
                                  : context.l10n.mealAnalysisDefaultMealName;
                              await ref.read(mealRepositoryProvider).saveMeal(
                                ingredients,
                                mealName,
                                imagePath: widget.imagePath,
                                lang: Localizations.localeOf(context).languageCode,
                              );

                              // On invalide le cache du journal pour qu'il recharge
                              // les repas à jour au retour sur le Dashboard.
                              ref.invalidate(todayMealsProvider);

                              // On laisse le temps de voir la confirmation
                              // visuelle avant de fermer le dialogue.
                              isSuccess.value = true;
                              await Future.delayed(const Duration(milliseconds: 700));

                              // On ferme le dialogue de chargement
                              if (context.mounted) Navigator.pop(context);

                              // On retourne au Dashboard !
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.mealAnalysisSaveSuccessSnackbar,
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                context.go('/dashboard');
                              }
                            } catch (e) {
                              if (context.mounted)
                                Navigator.pop(context); // Fermer le loader
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            context.l10n.mealAnalysisSaveButton,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS REUTILISABLES ---

  Widget _buildIngredientCard(
    Ingredient item,
    WidgetRef ref,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(mealProvider.notifier)
                          .removeIngredient(item.id),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    TweenAnimationBuilder<int>(
                      duration: const Duration(milliseconds: 300),
                      tween: IntTween(begin: item.currentKcal, end: item.currentKcal),
                      builder: (context, value, child) => Text(
                        context.l10n.mealAnalysisKcalValue(value.toString()),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        _buildMacroBadge(
                          context.l10n.mealAnalysisBadgeProt,
                          item.currentProt,
                          primaryColor,
                        ),
                        const SizedBox(width: 8),
                        _buildMacroBadge(
                          context.l10n.mealAnalysisBadgeGluc,
                          item.currentGluc,
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildMacroBadge(
                          context.l10n.mealAnalysisBadgeLip,
                          item.currentLip,
                          Colors.pink,
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () => ref
                                .read(mealProvider.notifier)
                                .decrement(item.id),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          TweenAnimationBuilder<int>(
                            duration: const Duration(milliseconds: 200),
                            tween: IntTween(begin: item.weight, end: item.weight),
                            builder: (context, value, child) => Text(
                              context.l10n.mealAnalysisWeightValue(value.toString()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () => ref
                                .read(mealProvider.notifier)
                                .increment(item.id),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: value, end: value),
          builder: (context, animatedValue, child) => Text(
            context.l10n.mealAnalysisGramsValue(animatedValue.toStringAsFixed(1)),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryMacro(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: value, end: value),
          builder: (context, animatedValue, child) => Text(
            context.l10n.mealAnalysisGramsValue(animatedValue.toStringAsFixed(1)),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Formulaire d'ajout manuel d'un ingrédient. Les valeurs saisies décrivent
/// la portion ajoutée (poids + macros pour ce poids) ; elles sont converties
/// en valeurs "pour 100g" pour rester cohérentes avec le modèle [Ingredient],
/// qui recalcule les totaux à partir du poids ajustable via +/-.
class _AddIngredientSheet extends StatefulWidget {
  const _AddIngredientSheet();

  @override
  State<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<_AddIngredientSheet> {
  static const primaryColor = Color(0xFF6B66FF);

  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _kcalController = TextEditingController();
  final _protController = TextEditingController();
  final _glucController = TextEditingController();
  final _lipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _kcalController.dispose();
    _protController.dispose();
    _glucController.dispose();
    _lipController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final weight = int.tryParse(_weightController.text.trim());
    final kcal = double.tryParse(
      _kcalController.text.trim().replaceAll(',', '.'),
    );
    final prot =
        double.tryParse(_protController.text.trim().replaceAll(',', '.')) ?? 0;
    final gluc =
        double.tryParse(_glucController.text.trim().replaceAll(',', '.')) ?? 0;
    final lip =
        double.tryParse(_lipController.text.trim().replaceAll(',', '.')) ?? 0;

    if (name.isEmpty) {
      _showError(context.l10n.mealAnalysisErrorNameRequired);
      return;
    }
    if (weight == null || weight <= 0) {
      _showError(context.l10n.mealAnalysisErrorWeightInvalid);
      return;
    }
    if (kcal == null || kcal < 0) {
      _showError(context.l10n.mealAnalysisErrorCaloriesInvalid);
      return;
    }

    final ratio = 100 / weight;
    Navigator.of(context).pop(
      Ingredient(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        weight: weight,
        kcalPer100g: kcal * ratio,
        protPer100g: prot * ratio,
        glucPer100g: gluc * ratio,
        lipPer100g: lip * ratio,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.mealAnalysisAddIngredientSheetTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.mealAnalysisAddIngredientSubtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _fieldDecoration(context.l10n.mealAnalysisFieldNameLabel),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration(
                        context.l10n.mealAnalysisFieldWeightLabel,
                        suffixText: context.l10n.mealAnalysisUnitGrams,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _kcalController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration(
                        context.l10n.mealAnalysisFieldCaloriesLabel,
                        suffixText: context.l10n.mealAnalysisUnitKcal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _protController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration(
                        context.l10n.mealAnalysisMacroProtein,
                        suffixText: context.l10n.mealAnalysisUnitGrams,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _glucController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration(
                        context.l10n.mealAnalysisMacroCarbs,
                        suffixText: context.l10n.mealAnalysisUnitGrams,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lipController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration(
                        context.l10n.mealAnalysisMacroFat,
                        suffixText: context.l10n.mealAnalysisUnitGrams,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  context.l10n.mealAnalysisSubmitButton,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, {String? suffixText}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
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
        borderSide: const BorderSide(color: primaryColor, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
