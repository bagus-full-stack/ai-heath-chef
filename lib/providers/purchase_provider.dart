import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/purchase_service.dart';
import 'profile_provider.dart';

/// Offre RevenueCat courante (plans/abonnements configurés côté dashboard).
final offeringsProvider = FutureProvider<Offering?>((ref) async {
  return PurchaseService.instance.fetchCurrentOffering();
});

/// Statut d'abonnement PRO de l'utilisateur connecté. Un compte admin
/// (`profiles.is_admin`, activable uniquement depuis le SQL Editor Supabase)
/// est toujours considéré PRO, indépendamment de tout abonnement RevenueCat.
final entitlementProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile?.isAdmin == true) {
    return true;
  }
  return PurchaseService.instance.isEntitledToPro();
});
