import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/l10n_extensions.dart';
import '../models/selected_plan.dart';
import '../providers/purchase_provider.dart';
import '../services/purchase_service.dart';
import '../widgets/animated_async_value.dart';
import '../widgets/staggered_entrance.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedIndex = 0;
  bool _isRestoring = false;

  static const Color _primaryColor = Color(0xFF6B66FF);

  /// Plans affichés tant qu'aucune offre RevenueCat n'a pu être chargée
  /// (ex: clés API non configurées en développement). L'achat est désactivé
  /// pour ces plans (SelectedPlan.package == null).
  List<SelectedPlan> _fallbackPlans(BuildContext context) => [
    SelectedPlan(
      title: context.l10n.paywallPlanAnnualTitle,
      priceLabel: '39.99€',
      periodLabel: context.l10n.paywallPeriodYear,
      badge: context.l10n.paywallBadgePopular,
    ),
    SelectedPlan(
      title: context.l10n.paywallPlanMonthlyTitle,
      priceLabel: '4.99€',
      periodLabel: context.l10n.paywallPeriodMonth,
    ),
  ];

  List<SelectedPlan> _plansFromOffering(BuildContext context, Offering offering) {
    if (offering.availablePackages.isEmpty) {
      return _fallbackPlans(context);
    }
    return offering.availablePackages.map((package) {
      final isAnnual = package.packageType == PackageType.annual;
      final periodLabel = switch (package.packageType) {
        PackageType.annual => context.l10n.paywallPeriodYear,
        PackageType.monthly => context.l10n.paywallPeriodMonth,
        PackageType.weekly => context.l10n.paywallPeriodWeek,
        PackageType.lifetime => '',
        _ => '',
      };
      final title = switch (package.packageType) {
        PackageType.annual => context.l10n.paywallPlanAnnualTitle,
        PackageType.monthly => context.l10n.paywallPlanMonthlyTitle,
        PackageType.weekly => context.l10n.paywallPlanWeeklyTitle,
        PackageType.lifetime => context.l10n.paywallPlanLifetimeTitle,
        _ => package.storeProduct.title,
      };
      return SelectedPlan(
        title: title,
        priceLabel: package.storeProduct.priceString,
        periodLabel: periodLabel,
        badge: isAnnual ? context.l10n.paywallBadgePopular : null,
        package: package,
      );
    }).toList();
  }

  void _continueToCheckout(SelectedPlan plan) {
    context.push('/checkout', extra: plan);
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) {
      return;
    }
    setState(() => _isRestoring = true);
    try {
      final outcome = await PurchaseService.instance.restorePurchases();
      if (!mounted) {
        return;
      }
      final isEntitled = outcome == PurchaseOutcome.success;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEntitled
                ? context.l10n.paywallRestoreSuccess
                : context.l10n.paywallRestoreNone,
          ),
          backgroundColor: isEntitled ? const Color(0xFF45C48C) : null,
        ),
      );
      if (isEntitled) {
        ref.invalidate(entitlementProvider);
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.paywallRestoreError(e.toString())),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1020),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              bottom: 160,
              left: -70,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pinkAccent.withValues(alpha: 0.12),
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        _TopIconButton(
                          icon: Icons.close_rounded,
                          onTap: () => context.pop(),
                        ),
                        const Spacer(),
                        Text(
                          context.l10n.paywallHeaderBadge,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          context.l10n.paywallTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.paywallSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        StaggeredEntrance(
                          child: _BenefitCard(
                            icon: Icons.photo_camera_back_rounded,
                            title: context.l10n.paywallBenefitPhotoTitle,
                            subtitle: context.l10n.paywallBenefitPhotoSubtitle,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 80),
                          child: _BenefitCard(
                            icon: Icons.bubble_chart_rounded,
                            title: context.l10n.paywallBenefitCoachTitle,
                            subtitle: context.l10n.paywallBenefitCoachSubtitle,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 160),
                          child: _BenefitCard(
                            icon: Icons.auto_graph_rounded,
                            title: context.l10n.paywallBenefitAnalyticsTitle,
                            subtitle: context.l10n.paywallBenefitAnalyticsSubtitle,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 240),
                          child: _BenefitCard(
                            icon: Icons.no_food_rounded,
                            title: context.l10n.paywallBenefitAdsFreeTitle,
                            subtitle: context.l10n.paywallBenefitAdsFreeSubtitle,
                          ),
                        ),
                        if (PurchaseService.instance.isDemoMode) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.science_outlined, color: Colors.amber.shade300, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    context.l10n.paywallDemoModeNotice,
                                    style: TextStyle(color: Colors.amber.shade200, fontSize: 12, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Text(
                          context.l10n.paywallChooseForfaitLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        offeringsAsync.animatedWhen(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(color: _primaryColor),
                            ),
                          ),
                          error: (error, stack) => _buildPlans(_fallbackPlans(context)),
                          data: (offering) => _buildPlans(
                            offering == null ? _fallbackPlans(context) : _plansFromOffering(context, offering),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _isRestoring ? null : _restorePurchases,
                            child: _isRestoring
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white70,
                                    ),
                                  )
                                : Text(
                                    context.l10n.paywallRestoreButton,
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlans(List<SelectedPlan> plans) {
    final selectedIndex = _selectedIndex < plans.length ? _selectedIndex : 0;
    final selectedPlan = plans[selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < plans.length; i++) ...[
          _PlanCard(
            plan: plans[i],
            selected: selectedIndex == i,
            onTap: () => setState(() => _selectedIndex = i),
          ),
          if (i != plans.length - 1) const SizedBox(height: 14),
        ],
        const SizedBox(height: 20),
        _SummaryStrip(plan: selectedPlan),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () => _continueToCheckout(selectedPlan),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            minimumSize: const Size(double.infinity, 58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
          child: Text(
            context.l10n.paywallUnlockButton,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6B66FF).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFB8B5FF), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SelectedPlan plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? primaryColor.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? primaryColor : Colors.white.withValues(alpha: 0.08),
            width: 1.7,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? primaryColor : Colors.white54, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            plan.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.priceLabel} ${plan.periodLabel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!plan.isPurchasable) ...[
                    const SizedBox(height: 4),
                    Text(
                      PurchaseService.instance.isDemoMode
                          ? context.l10n.paywallPreviewDemoMode
                          : context.l10n.paywallPreviewConfigPending,
                      style: TextStyle(color: Colors.amber.shade200, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final SelectedPlan plan;

  const _SummaryStrip({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.paywallSelectionSummary(plan.title, plan.priceLabel, plan.periodLabel),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
