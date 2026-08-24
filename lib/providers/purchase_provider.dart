import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/purchase_service.dart';

/// Offre RevenueCat courante (plans/abonnements configurés côté dashboard).
final offeringsProvider = FutureProvider<Offering?>((ref) async {
  return PurchaseService.instance.fetchCurrentOffering();
});

/// Statut d'abonnement PRO de l'utilisateur connecté.
final entitlementProvider = FutureProvider<bool>((ref) async {
  return PurchaseService.instance.isEntitledToPro();
});
