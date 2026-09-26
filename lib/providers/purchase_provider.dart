import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/purchase_service.dart';
import 'profile_provider.dart';

const _kCachedEntitlementKey = 'cached_pro_entitlement';

/// Offre RevenueCat courante (plans/abonnements configurés côté dashboard).
final offeringsProvider = FutureProvider<Offering?>((ref) async {
  return PurchaseService.instance.fetchCurrentOffering();
});

/// Statut d'abonnement PRO de l'utilisateur connecté. Un compte admin
/// (`profiles.is_admin`, activable uniquement depuis le SQL Editor Supabase)
/// est toujours considéré PRO, indépendamment de tout abonnement RevenueCat.
/// Le dernier statut résolu est mis en cache pour rester valable hors ligne
/// (RevenueCat lui-même échoue parfois sans réseau plutôt que de retomber
/// sur son propre cache).
final entitlementProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile?.isAdmin == true) {
    return true;
  }

  final prefs = await SharedPreferences.getInstance();
  try {
    final entitled = await PurchaseService.instance.isEntitledToPro();
    await prefs.setBool(_kCachedEntitlementKey, entitled);
    return entitled;
  } catch (_) {
    return prefs.getBool(_kCachedEntitlementKey) ?? false;
  }
});
