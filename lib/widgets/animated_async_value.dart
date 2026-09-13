import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Variante de [AsyncValue.when] qui enchaîne un fondu (`AnimatedSwitcher`)
/// entre les états chargement/erreur/données, au lieu du changement brutal
/// par défaut. Mêmes callbacks que `when` — un simple renommage d'appel
/// suffit à l'adopter sur un écran existant.
extension AnimatedAsyncValue<T> on AsyncValue<T> {
  Widget animatedWhen({
    required Widget Function() loading,
    required Widget Function(Object error, StackTrace stackTrace) error,
    required Widget Function(T data) data,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    final child = when(loading: loading, error: error, data: data);
    final stateKey = when(
      loading: () => 'loading',
      error: (_, _) => 'error',
      data: (_) => 'data',
    );

    return AnimatedSwitcher(
      duration: duration,
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}
