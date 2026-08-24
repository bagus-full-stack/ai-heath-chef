import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/selected_plan.dart';
import '../services/purchase_service.dart';

class CheckoutScreen extends StatefulWidget {
  final SelectedPlan? plan;

  const CheckoutScreen({super.key, this.plan});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  SelectedPlan get _plan =>
      widget.plan ??
      const SelectedPlan(
        title: 'Abonnement PRO',
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                PurchaseService.instance.isDemoMode
                    ? 'Achat simulé (mode démo) : accès PRO débloqué !'
                    : 'Abonnement activé, bienvenue dans AI Health Chef PRO !',
              ),
              backgroundColor: const Color(0xFF45C48C),
            ),
          );
          context.go('/dashboard');
        case PurchaseOutcome.none:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Achat effectué, en attente de confirmation.')),
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
          content: Text('Échec de l’achat : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
        title: const Text(
          'Finaliser la commande',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              title: 'MOYEN DE PAIEMENT',
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
                          ? 'Mode démo : cet achat est simulé, aucun paiement ni compte '
                              'App Store / Google Play n’est sollicité.'
                          : 'Paiement géré en toute sécurité par l’App Store / Google Play. '
                              'Aucune information bancaire n’est demandée dans l’application.',
                      style: const TextStyle(color: Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'RÉCAPITULATIF',
              child: Column(
                children: [
                  _SummaryRow(label: 'Forfait', value: plan.title),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: 'Total',
                    value: '${plan.priceLabel} ${plan.periodLabel}'.trim(),
                    emphasize: true,
                  ),
                  const SizedBox(height: 10),
                  const _SummaryRow(
                    label: 'Renouvellement',
                    value: 'Automatique, résiliable à tout moment',
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
                      'Confirmer • ${plan.priceLabel} ${plan.periodLabel}'.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              'L’abonnement se renouvelle automatiquement sauf annulation au moins 24h '
              'avant la fin de la période, depuis les réglages de ton compte App Store '
              'ou Google Play.',
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
                  'AI Health Chef PRO',
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
                    'Mode démo — l’achat sera simulé, aucun paiement réel',
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
