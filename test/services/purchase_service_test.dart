import 'package:flutter_test/flutter_test.dart';
import 'package:ai_health_chef/services/purchase_service.dart';

// Les tests tournent en debug avec les clés RevenueCat factices : mode démo.
// Le cas "release sans clés = jamais PRO" ne peut pas être testé ici
// (`kReleaseMode` est une constante de compilation).
void main() {
  test('demo mode: not PRO until a simulated purchase, then restore and entitlement agree', () async {
    final service = PurchaseService.instance;
    expect(service.isDemoMode, isTrue);
    expect(await service.isEntitledToPro(), isFalse);
    expect(await service.restorePurchases(), PurchaseOutcome.none);

    expect(await service.purchasePackage(null), PurchaseOutcome.success);

    expect(await service.isEntitledToPro(), isTrue);
    expect(await service.restorePurchases(), PurchaseOutcome.success);
  });
}
