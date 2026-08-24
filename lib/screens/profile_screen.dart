import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/purchase_provider.dart';
import 'coming_soon_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(authServiceProvider).signOut();

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final entitlementAsync = ref.watch(entitlementProvider);
    final isPro = entitlementAsync.value ?? false;
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'MON PROFIL',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Impossible de charger le profil : $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (profile) {
          final currentProfile = profile ??
              UserProfile(
                userId: user?.id ?? '',
                fullName: user?.userMetadata?['full_name'] as String? ??
                    user?.email?.split('@').first.replaceAll('.', ' ') ??
                    'Utilisateur',
                email: user?.email ?? 'Utilisateur inconnu',
                sex: 'other',
                age: 0,
                currentWeight: 0,
                targetWeight: 0,
                goal: 'maintain',
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(profile: currentProfile, isPro: isPro),
                const SizedBox(height: 18),
                _QuickStatsSection(profile: currentProfile),
                const SizedBox(height: 18),
                _SettingsGroup(
                  title: 'GÉNÉRAL',
                  items: [
                    _SettingsItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Compte',
                      subtitle: 'Informations personnelles',
                      onTap: () => context.push('/account'),
                    ),
                    _SettingsItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Rappels repas et suivi',
                      badge: '2 Nouveaux',
                      onTap: () => context.push(
                        '/coming-soon',
                        extra: const ComingSoonArgs(
                          title: 'Notifications',
                          message: 'La gestion des rappels et notifications arrive bientôt.',
                          icon: Icons.notifications_none_rounded,
                        ),
                      ),
                    ),
                    _SettingsItem(
                      icon: Icons.credit_card_outlined,
                      title: 'Abonnement',
                      subtitle: 'Plan PRO et facturation',
                      badge: isPro ? 'Actif' : null,
                      onTap: () => context.push('/paywall'),
                    ),
                    _SettingsItem(
                      icon: Icons.shield_outlined,
                      title: 'Sécurité et Confidentialité',
                      subtitle: 'Données et sécurité',
                      onTap: () => context.push(
                        '/coming-soon',
                        extra: const ComingSoonArgs(
                          title: 'Sécurité et Confidentialité',
                          message: 'Les réglages de sécurité et confidentialité arrivent bientôt.',
                          icon: Icons.shield_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsGroup(
                  title: 'ASSISTANCE',
                  items: [
                    _SettingsItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Centre d’aide',
                      subtitle: 'FAQ, guides et tutoriels',
                      onTap: () => context.push(
                        '/coming-soon',
                        extra: const ComingSoonArgs(
                          title: 'Centre d’aide',
                          message: 'Le centre d’aide et la FAQ arrivent bientôt.',
                          icon: Icons.help_outline_rounded,
                        ),
                      ),
                    ),
                    _SettingsItem(
                      icon: Icons.description_outlined,
                      title: 'Conditions d’utilisation',
                      subtitle: 'CGU et mentions légales',
                      onTap: () => context.push(
                        '/coming-soon',
                        extra: const ComingSoonArgs(
                          title: 'Conditions d’utilisation',
                          message: 'Les conditions d’utilisation seront bientôt consultables ici.',
                          icon: Icons.description_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsGroup(
                  title: 'PERSONNALISATION',
                  items: [
                    _SettingsItem(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Mes objectifs',
                      subtitle: 'Calories et macros',
                      onTap: () => context.push('/account'),
                    ),
                    _SettingsItem(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Préférences alimentaires',
                      subtitle: 'Végétarien, halal, allergies...',
                      onTap: () => context.push(
                        '/coming-soon',
                        extra: const ComingSoonArgs(
                          title: 'Préférences alimentaires',
                          message: 'Le réglage de tes préférences et allergies arrive bientôt.',
                          icon: Icons.restaurant_menu_rounded,
                        ),
                      ),
                    ),
                    _SettingsItem(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Coach IA',
                      subtitle: 'Ton ton, tes conseils, tes prompts',
                      onTap: () => context.push(
                        '/coming-soon',
                        extra: const ComingSoonArgs(
                          title: 'Coach IA',
                          message: 'La personnalisation du Coach IA arrive bientôt.',
                          icon: Icons.auto_awesome_rounded,
                        ),
                      ),
                    ),
                    _SettingsItem(
                      icon: Icons.info_outline_rounded,
                      title: 'À propos',
                      subtitle: 'Version et informations',
                      onTap: () => context.push(
                        '/coming-soon',
                        extra: const ComingSoonArgs(
                          title: 'À propos',
                          message: 'AI Health Chef v1.0.0',
                          icon: Icons.info_outline_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _logout(context, ref),
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: Colors.redAccent, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'AI Health Chef v1.0.0',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isPro;

  const _ProfileHeader({required this.profile, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
              child: profile.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.grey.shade500,
                    )
                  : null,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profile.fullName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isPro) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Pro',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ],
    );
  }
}

class _QuickStatsSection extends StatelessWidget {
  final UserProfile profile;

  const _QuickStatsSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Âge',
                value: profile.age == 0 ? '—' : '${profile.age} ans',
                icon: Icons.cake_outlined,
                accentColor: const Color(0xFF6B66FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Poids actuel',
                value: profile.currentWeight == 0 ? '—' : '${profile.currentWeight.toStringAsFixed(1)} kg',
                icon: Icons.monitor_weight_outlined,
                accentColor: const Color(0xFFF06B9E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Poids cible',
                value: profile.targetWeight == 0 ? '—' : '${profile.targetWeight.toStringAsFixed(1)} kg',
                icon: Icons.flag_outlined,
                accentColor: const Color(0xFFFFB54A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Objectif',
                value: profile.goalLabel,
                icon: Icons.track_changes_rounded,
                accentColor: const Color(0xFF45C48C),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsGroup({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _SettingsTile(item: item),
                if (index != items.length - 1) const SizedBox(height: 6),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });
}

class _SettingsTile extends StatelessWidget {
  final _SettingsItem item;

  const _SettingsTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(item.icon, color: Colors.black87),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        item.subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B66FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.badge!,
                style: const TextStyle(
                  color: Color(0xFF6B66FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        ],
      ),
      onTap: item.onTap,
    );
  }
}
