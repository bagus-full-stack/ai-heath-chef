import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Résultat neutre d'un achat/restauration, indépendant du SDK RevenueCat —
/// permet à l'UI de réagir pareil que l'achat soit réel ou simulé (mode
/// démo).
enum PurchaseOutcome {
  /// L'utilisateur a bien l'entitlement PRO actif après l'opération.
  success,

  /// L'opération s'est terminée sans erreur mais sans entitlement actif
  /// (ex: aucun achat à restaurer).
  none,

  /// L'utilisateur a annulé l'achat.
  cancelled,
}

/// Wrapper autour du SDK RevenueCat (achats in-app natifs iOS/Android).
///
/// Configuration requise avant utilisation en production :
/// - Créer un projet RevenueCat et y déclarer les produits d'abonnement
///   (App Store Connect / Play Console) sous l'entitlement `entitlementId`.
/// - Remplacer `_androidApiKey` / `_iosApiKey` par les vraies clés publiques
///   RevenueCat (Project settings > API keys).
///
/// Tant que ces clés ne sont pas renseignées, le service tourne en
/// **mode démo** : aucun appel réseau/SDK n'est fait, les offres affichées
/// sont des plans de secours, et un achat "réussit" toujours après un court
/// délai simulé. Ça permet de développer et tester tout le parcours
/// (Paywall → Checkout → déblocage PRO) sans compte Apple/Google payant.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  // TODO: remplacer par les clés publiques RevenueCat du dashboard.
  // Tant que ces valeurs sont les placeholders ci-dessous, le service reste
  // en mode démo (voir [isDemoMode]).
  static const _androidApiKey = 'REVENUECAT_ANDROID_API_KEY';
  static const _iosApiKey = 'REVENUECAT_IOS_API_KEY';

  // TODO: doit correspondre à l'identifiant d'entitlement configuré dans
  // RevenueCat (ex: "pro").
  static const entitlementId = 'pro';

  bool _configured = false;

  /// Entitlement simulé en mode démo, pour que "Restaurer mes achats" et
  /// l'état PRO du profil restent cohérents avec un achat démo précédent
  /// pendant la session courante.
  bool _demoEntitled = false;

  String get _currentApiKey =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosApiKey : _androidApiKey;

  /// True tant que les clés API RevenueCat n'ont pas été renseignées.
  bool get isDemoMode =>
      _currentApiKey == 'REVENUECAT_ANDROID_API_KEY' || _currentApiKey == 'REVENUECAT_IOS_API_KEY';

  Future<void> configure({String? appUserId}) async {
    if (_configured) {
      return;
    }
    _configured = true;

    if (isDemoMode) {
      if (kDebugMode) {
        debugPrint(
          '[PurchaseService] Clés RevenueCat non configurées : mode démo activé '
          '(achats simulés, aucun appel réseau).',
        );
      }
      return;
    }

    await Purchases.setLogLevel(
      kDebugMode ? LogLevel.debug : LogLevel.warn,
    );
    await Purchases.configure(
      PurchasesConfiguration(_currentApiKey)..appUserID = appUserId,
    );
  }

  /// Récupère les offres (plans) disponibles, telles que configurées dans
  /// RevenueCat (Offerings > Packages). Renvoie `null` en mode démo — les
  /// écrans utilisent alors leurs plans de secours pour l'affichage.
  Future<Offering?> fetchCurrentOffering() async {
    if (isDemoMode) {
      return null;
    }
    final offerings = await Purchases.getOfferings();
    return offerings.current;
  }

  /// Lance le flux d'achat natif pour le package sélectionné (ou simule un
  /// achat réussi en mode démo, `package` peut alors être `null`).
  Future<PurchaseOutcome> purchasePackage(Package? package) async {
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      _demoEntitled = true;
      return PurchaseOutcome.success;
    }

    if (package == null) {
      throw Exception('Achat indisponible : configuration RevenueCat en attente.');
    }

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final isEntitled = result.customerInfo.entitlements.active.containsKey(entitlementId);
      return isEntitled ? PurchaseOutcome.success : PurchaseOutcome.none;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      rethrow;
    }
  }

  Future<PurchaseOutcome> restorePurchases() async {
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return _demoEntitled ? PurchaseOutcome.success : PurchaseOutcome.none;
    }

    final info = await Purchases.restorePurchases();
    final isEntitled = info.entitlements.active.containsKey(entitlementId);
    return isEntitled ? PurchaseOutcome.success : PurchaseOutcome.none;
  }

  Future<bool> isEntitledToPro() async {
    if (isDemoMode) {
      return _demoEntitled;
    }
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(entitlementId);
  }

  /// Associe l'identité RevenueCat à l'utilisateur Supabase connecté, pour
  /// que l'abonnement soit bien rattaché au bon compte.
  Future<void> logIn(String appUserId) async {
    if (!_configured || isDemoMode) {
      return;
    }
    await Purchases.logIn(appUserId);
  }

  /// Détache l'identité RevenueCat lors de la déconnexion.
  Future<void> logOut() async {
    if (!_configured || isDemoMode) {
      return;
    }
    await Purchases.logOut();
  }
}
