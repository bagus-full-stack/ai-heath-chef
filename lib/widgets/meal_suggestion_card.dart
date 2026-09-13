import 'package:flutter/material.dart';

import '../models/meal_suggestion.dart';

const Color _kPrimaryColor = Color(0xFF6B66FF);

const Map<String, IconData> _kTimeSlotIcons = {
  'Petit-déjeuner': Icons.free_breakfast_rounded,
  'Déjeuner': Icons.lunch_dining_rounded,
  'Dîner': Icons.dinner_dining_rounded,
  'Collation': Icons.apple_rounded,
};

/// Carte présentant une idée de repas générée par l'IA. Pas d'image réseau
/// (l'IA ne fournit pas de photo réelle du plat) : on utilise à la place une
/// icône représentative du moment de la journée, pour rester fiable hors
/// ligne et éviter d'afficher des visuels non représentatifs du plat.
class MealSuggestionCard extends StatelessWidget {
  final MealSuggestion suggestion;
  final VoidCallback onAdd;

  const MealSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _kTimeSlotIcons[suggestion.timeSlot] ?? Icons.restaurant_rounded;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Icon(icon, size: 48, color: _kPrimaryColor),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    suggestion.timeSlot,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (suggestion.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    suggestion.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_outlined,
                      size: 16,
                      color: _kPrimaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${suggestion.kcal} kcal',
                      style: const TextStyle(
                        color: _kPrimaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MacroMini(label: 'PROT', value: '${suggestion.prot.toStringAsFixed(0)}g'),
                    _MacroMini(label: 'GLUC', value: '${suggestion.gluc.toStringAsFixed(0)}g'),
                    _MacroMini(label: 'LIP', value: '${suggestion.lip.toStringAsFixed(0)}g'),
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
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
}

class _MacroMini extends StatelessWidget {
  final String label;
  final String value;

  const _MacroMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
