import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shopping_item.dart';

const _prefsKey = 'shopping_list_items';

/// Liste de courses, persistée localement (SharedPreferences — une simple
/// liste cochable n'a pas besoin d'une table Drift). Alimentée depuis les
/// idées du Coach IA (voir [MealSuggestionCard]).
final shoppingListProvider = AsyncNotifierProvider<ShoppingListNotifier, List<ShoppingItem>>(
  ShoppingListNotifier.new,
);

class ShoppingListNotifier extends AsyncNotifier<List<ShoppingItem>> {
  @override
  Future<List<ShoppingItem>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(ShoppingItem.fromJson).toList();
  }

  Future<void> _persist(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  /// Ajoute [names] à la liste, en ignorant les doublons (insensible à la
  /// casse) déjà présents.
  Future<void> addItems(List<String> names) async {
    final current = state.value ?? [];
    final existing = current.map((i) => i.name.toLowerCase()).toSet();
    final additions = names
        .where((n) => n.trim().isNotEmpty && existing.add(n.trim().toLowerCase()))
        .map((n) => ShoppingItem(name: n.trim()))
        .toList();
    if (additions.isEmpty) return;
    final updated = [...current, ...additions];
    state = AsyncValue.data(updated);
    await _persist(updated);
  }

  Future<void> toggle(int index) async {
    final current = <ShoppingItem>[...state.value ?? []];
    current[index] = current[index].copyWith(checked: !current[index].checked);
    state = AsyncValue.data(current);
    await _persist(current);
  }

  Future<void> remove(int index) async {
    final current = <ShoppingItem>[...state.value ?? []]..removeAt(index);
    state = AsyncValue.data(current);
    await _persist(current);
  }

  Future<void> clearChecked() async {
    final current = (state.value ?? <ShoppingItem>[]).where((i) => !i.checked).toList();
    state = AsyncValue.data(current);
    await _persist(current);
  }
}
