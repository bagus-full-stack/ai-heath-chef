import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n_extensions.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/local_ai_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/purchase_provider.dart';
import '../utils/journal_export.dart';
import '../widgets/animated_async_value.dart';
import 'coming_soon_screen.dart';

const _kLanguageNames = {'fr': 'Français', 'en': 'English'};

Future<void> _showLanguagePicker(BuildContext context, WidgetRef ref, Locale current) async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final code in supportedLocaleCodes)
              ListTile(
                title: Text(_kLanguageNames[code]!),
                trailing: current.languageCode == code
                    ? const Icon(Icons.check_rounded, color: Color(0xFF6B66FF))
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(Locale(code));
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      );
    },
  );
}

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
            content: Text(context.l10n.profileLogoutError(e.toString())),
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
    final localAiSettings = ref.watch(localAiSettingsProvider).value;
    final currentLocale = ref.watch(localeProvider).value ?? const Locale('fr');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.l10n.profileTitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black,
          ),
        ),
      ),
      body: profileAsync.animatedWhen(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.profileLoadError(error.toString()),
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
                    context.l10n.profileDefaultUserName,
                email: user?.email ?? context.l10n.profileUnknownUser,
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
                  title: context.l10n.profileSectionGeneral,
                  items: [
                    _SettingsItem(
                      icon: Icons.person_outline_rounded,
                      title: context.l10n.profileAccountTitle,
                      subtitle: context.l10n.profileAccountSubtitle,
                      onTap: () => context.push('/account'),
                    ),
                    _SettingsItem(
                      icon: Icons.notifications_none_rounded,
                      title: context.l10n.profileNotificationsTitle,
                      subtitle: context.l10n.profileNotificationsSubtitle,
                      onTap: () => context.push('/notifications'),
                    ),
                    _SettingsItem(
                      icon: Icons.credit_card_outlined,
                      title: context.l10n.profileSubscriptionTitle,
                      subtitle: context.l10n.profileSubscriptionSubtitle,
                      badge: isPro ? context.l10n.profileActiveBadge : null,
                      onTap: () => context.push('/paywall'),
                    ),
                    _SettingsItem(
                      icon: Icons.insights_rounded,
                      title: context.l10n.profileAdvancedAnalyticsTitle,
                      subtitle: context.l10n.profileAdvancedAnalyticsSubtitle,
                      badge: isPro ? null : context.l10n.profileProBadge,
                      onTap: () => context.push('/nutrition_trends'),
                    ),
                    _SettingsItem(
                      icon: Icons.monitor_weight_outlined,
                      title: context.l10n.profileWeightTrackingTitle,
                      subtitle: context.l10n.profileWeightTrackingSubtitle,
                      onTap: () => context.push('/weight_trend'),
                    ),
                    _SettingsItem(
                      icon: Icons.ios_share_rounded,
                      title: context.l10n.profileExportJournalTitle,
                      subtitle: context.l10n.profileExportJournalSubtitle,
                      onTap: () => exportMealJournalCsv(ref),
                    ),
                    _SettingsItem(
                      icon: Icons.language_rounded,
                      title: context.l10n.profileLanguageTitle,
                      subtitle: _kLanguageNames[currentLocale.languageCode]!,
                      onTap: () => _showLanguagePicker(context, ref, currentLocale),
                    ),
                    _SettingsItem(
                      icon: Icons.shield_outlined,
                      title: context.l10n.profileSecurityTitle,
                      subtitle: context.l10n.profileSecuritySubtitle,
                      onTap: () => context.push(
                        '/coming-soon',
                        extra: ComingSoonArgs(
                          title: context.l10n.profileSecurityTitle,
                          message: context.l10n.profileSecurityComingSoonMessage,
                          icon: Icons.shield_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsGroup(
                  title: context.l10n.profileSectionSupport,
                  items: [
                    _SettingsItem(
                      icon: Icons.help_outline_rounded,
                      title: context.l10n.profileHelpCenterTitle,
                      subtitle: context.l10n.profileHelpCenterSubtitle,
                      onTap: () => context.push('/help'),
                    ),
                    _SettingsItem(
                      icon: Icons.description_outlined,
                      title: context.l10n.profileTermsTitle,
                      subtitle: context.l10n.profileTermsSubtitle,
                      onTap: () => context.push('/terms'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SettingsGroup(
                  title: context.l10n.profileSectionPersonalization,
                  items: [
                    _SettingsItem(
                      icon: Icons.local_fire_department_outlined,
                      title: context.l10n.profileGoalsTitle,
                      subtitle: context.l10n.profileGoalsSubtitle,
                      onTap: () => context.push('/account'),
                    ),
                    _SettingsItem(
                      icon: Icons.restaurant_menu_rounded,
                      title: context.l10n.profileDietaryPrefsTitle,
                      subtitle: currentProfile.allergies.isEmpty
                          ? currentProfile.dietTypeLabel(context)
                          : context.l10n.profileDietaryPrefsSubtitleWithAllergies(
                              currentProfile.dietTypeLabel(context),
                              currentProfile.allergies.length,
                            ),
                      onTap: () => context.push('/dietary_preferences'),
                    ),
                    _SettingsItem(
                      icon: Icons.auto_awesome_rounded,
                      title: context.l10n.profileCoachTitle,
                      subtitle: context.l10n.profileCoachSubtitle(currentProfile.coachToneLabel(context)),
                      onTap: () => context.push('/coach_personalization'),
                    ),
                    _SettingsItem(
                      icon: Icons.memory_rounded,
                      title: context.l10n.profileLocalAiTitle,
                      subtitle: localAiSettings == null
                          ? context.l10n.profileLocalAiSubtitleDefault
                          : !localAiSettings.enabled
                              ? context.l10n.profileLocalAiSubtitleDisabled
                              : localAiSettings.isDownloaded
                                  ? context.l10n.profileLocalAiSubtitleEnabled
                                  : context.l10n.profileLocalAiSubtitleEnabledNotDownloaded,
                      onTap: () => context.push('/local_ai_settings'),
                    ),
                    _SettingsItem(
                      icon: Icons.info_outline_rounded,
                      title: context.l10n.profileAboutTitle,
                      subtitle: context.l10n.profileAboutSubtitle,
                      onTap: () => context.push('/about'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _logout(context, ref),
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: Text(
                    context.l10n.profileLogoutButton,
                    style: const TextStyle(
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
                    context.l10n.profileVersionText,
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
                child: Text(
                  context.l10n.profileProBadgeHeader,
                  style: const TextStyle(
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
                title: context.l10n.profileAgeLabel,
                value: profile.age == 0 ? '—' : context.l10n.profileAgeValue(profile.age),
                icon: Icons.cake_outlined,
                accentColor: const Color(0xFF6B66FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: context.l10n.profileCurrentWeightLabel,
                value: profile.currentWeight == 0
                    ? '—'
                    : context.l10n.profileWeightValue(profile.currentWeight.toStringAsFixed(1)),
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
                title: context.l10n.profileTargetWeightLabel,
                value: profile.targetWeight == 0
                    ? '—'
                    : context.l10n.profileWeightValue(profile.targetWeight.toStringAsFixed(1)),
                icon: Icons.flag_outlined,
                accentColor: const Color(0xFFFFB54A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: context.l10n.profileGoalLabel,
                value: profile.goalLabel(context),
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
