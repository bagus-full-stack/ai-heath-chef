import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/meal_reminder.dart';
import '../providers/notification_settings_provider.dart';

const Color _kPrimaryColor = Color(0xFF6B66FF);

/// Réglages des rappels de repas : un interrupteur + une heure par créneau
/// (petit-déjeuner/déjeuner/dîner), chacun déclenchant une notification
/// locale quotidienne.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kPrimaryColor)),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              'Impossible de charger les réglages de notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              'Reçois un rappel pour penser à logguer chacun de tes repas.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            for (final slot in MealReminderSlot.values) ...[
              _ReminderRow(slot: slot, setting: settings[slot]!),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends ConsumerWidget {
  final MealReminderSlot slot;
  final MealReminderSetting setting;

  const _ReminderRow({required this.slot, required this.setting});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: setting.hour, minute: setting.minute),
    );
    if (picked == null) {
      return;
    }
    await ref.read(notificationSettingsProvider.notifier).setTime(slot, picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeLabel =
        '${setting.hour.toString().padLeft(2, '0')}:${setting.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: _kPrimaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: setting.enabled ? () => _pickTime(context, ref) : null,
                  child: Text(
                    setting.enabled ? 'Rappel à $timeLabel' : 'Désactivé',
                    style: TextStyle(
                      color: setting.enabled ? _kPrimaryColor : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: setting.enabled,
            activeThumbColor: _kPrimaryColor,
            onChanged: (value) => ref.read(notificationSettingsProvider.notifier).setEnabled(slot, value),
          ),
        ],
      ),
    );
  }
}
