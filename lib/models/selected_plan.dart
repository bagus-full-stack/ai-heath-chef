import 'package:purchases_flutter/purchases_flutter.dart';

/// Représentation d'affichage d'un plan d'abonnement, indépendante de la
/// source (offre RevenueCat réelle, ou plan de secours affiché pendant le
/// développement tant que RevenueCat n'est pas configuré).
class SelectedPlan {
  final String title;
  final String priceLabel;
  final String periodLabel;
  final String? badge;

  /// Le package RevenueCat à acheter. Null si aucune offre réelle n'a pu
  /// être chargée (ex: clés API RevenueCat non configurées) — dans ce cas
  /// l'achat est désactivé côté Checkout.
  final Package? package;

  const SelectedPlan({
    required this.title,
    required this.priceLabel,
    required this.periodLabel,
    this.badge,
    this.package,
  });

  bool get isPurchasable => package != null;
}
