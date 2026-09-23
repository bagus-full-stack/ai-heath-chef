import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../models/selected_plan.dart';
import '../providers/purchase_provider.dart';
import '../services/purchase_service.dart';
import '../widgets/success_transition_dialog.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final SelectedPlan? plan;

  const CheckoutScreen({super.key, this.plan});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessing = false;

  SelectedPlan get _plan =>
      widget.plan ??
      SelectedPlan(
        title: context.l10n.checkoutDefaultPlanTitle,
        priceLabel: '—',
        periodLabel: '',
      );

  Future<void> _confirmPurchase() async {
    if (_isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final outcome = await PurchaseService.instance.purchasePackage(_plan.package);
      if (!mounted) {
        return;
      }

      switch (outcome) {
        case PurchaseOutcome.success:
          ref.invalidate(entitlementProvider);
          await _showSuccessMoment(
            PurchaseService.instance.isDemoMode
                ? context.l10n.checkoutSuccessDemo
                : context.l10n.checkoutSuccessReal,
          );
          if (!mounted) {
            return;
          }
          context.go('/dashboard');
        case PurchaseOutcome.none:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.checkoutPendingConfirmation)),
          );
        case PurchaseOutcome.cancelled:
          break;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.checkoutPurchaseError(e.toString())),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Petit moment de célébration affiché juste après un achat réussi, avant
  /// de revenir au Dashboard — remplace le simple SnackBar par une
  /// confirmation visuelle qui a le temps d'être vue.
  Future<void> _showSuccessMoment(String message) async {
    final isSuccess = ValueNotifier<bool>(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessTransitionDialog(isSuccess: isSuccess, successMessage: message),
    );
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);
    final plan = _plan;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.checkoutAppBarTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OrderSummaryCard(plan: plan),
            const SizedBox(height: 16),
            _SectionCard(
              title: context.l10n.checkoutPaymentMethodLabel,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      PurchaseService.instance.isDemoMode
                          ? Icons.science_outlined
                          : Icons.verified_user_outlined,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      PurchaseService.instance.isDemoMode
                          ? context.l10n.checkoutDemoModeNotice
                          : context.l10n.checkoutSecurePaymentNotice,
                      style: const TextStyle(color: Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: context.l10n.checkoutSummaryLabel,
              child: Column(
                children: [
                  _SummaryRow(label: context.l10n.checkoutPlanLabel, value: plan.title),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: context.l10n.checkoutTotalLabel,
                    value: '${plan.priceLabel} ${plan.periodLabel}'.trim(),
                    emphasize: true,
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: context.l10n.checkoutRenewalLabel,
                    value: context.l10n.checkoutRenewalValue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _isProcessing ? null : _confirmPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.l10n.checkoutConfirmButton(plan.priceLabel, plan.periodLabel).trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.checkoutRenewalDisclaimer,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final SelectedPlan plan;

  const _OrderSummaryCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2C), Color(0xFF2E2F45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: Colors.amber, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.checkoutOrderSummaryBrand,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.title} • ${plan.priceLabel} ${plan.periodLabel}'.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (PurchaseService.instance.isDemoMode) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.checkoutOrderSummaryDemoNotice,
                    style: TextStyle(color: Colors.amber.shade300, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? const Color(0xFF6B66FF) : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: emphasize ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
