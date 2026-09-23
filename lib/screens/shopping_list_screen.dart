import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/animated_async_value.dart';

const _primaryColor = Color(0xFF6B66FF);

/// Liste de courses cochable, alimentée depuis les idées du Coach IA
/// (voir [shoppingListProvider]).
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListProvider);

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
          context.l10n.shoppingListTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rtl_rounded, color: _primaryColor),
            tooltip: context.l10n.shoppingListClearCheckedButton,
            onPressed: () => ref.read(shoppingListProvider.notifier).clearChecked(),
          ),
        ],
      ),
      body: itemsAsync.animatedWhen(
        loading: () => const Center(child: CircularProgressIndicator(color: _primaryColor)),
        error: (err, stack) => Center(child: Text(err.toString())),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.shoppingListEmptyState,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: ValueKey(item.name),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => ref.read(shoppingListProvider.notifier).remove(index),
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: CheckboxListTile(
                    value: item.checked,
                    onChanged: (_) => ref.read(shoppingListProvider.notifier).toggle(index),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: _primaryColor,
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: item.checked ? TextDecoration.lineThrough : null,
                        color: item.checked ? Colors.grey.shade400 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
