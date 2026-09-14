import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_reminder.dart';
import '../services/notification_service.dart';

/// Réglages des rappels de repas (activé + heure, par créneau), persistés
/// localement et répercutés sur les notifications programmées à chaque
/// changement.
final notificationSettingsProvider = AsyncNotifierProvider<NotificationSettingsNotifier,
    Map<MealReminderSlot, MealReminderSetting>>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier
    extends AsyncNotifier<Map<MealReminderSlot, MealReminderSetting>> {
  @override
  Future<Map<MealReminderSlot, MealReminderSetting>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final slot in MealReminderSlot.values)
        slot: MealReminderSetting(
          enabled: prefs.getBool(_enabledKey(slot)) ?? false,
          hour: prefs.getInt(_hourKey(slot)) ?? slot.defaultHour,
          minute: prefs.getInt(_minuteKey(slot)) ?? slot.defaultMinute,
        ),
    };
  }

  /// Active ou désactive le rappel d'un créneau. À l'activation, demande la
  /// permission système si besoin ; si elle est refusée, l'activation est
  /// annulée et l'interrupteur reste éteint.
  Future<void> setEnabled(MealReminderSlot slot, bool enabled) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        return;
      }
    }

    await _applyAndPersist(slot, current[slot]!.copyWith(enabled: enabled));
  }

  Future<void> setTime(MealReminderSlot slot, int hour, int minute) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    await _applyAndPersist(slot, current[slot]!.copyWith(hour: hour, minute: minute));
  }

  Future<void> _applyAndPersist(MealReminderSlot slot, MealReminderSetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey(slot), setting.enabled);
    await prefs.setInt(_hourKey(slot), setting.hour);
    await prefs.setInt(_minuteKey(slot), setting.minute);

    if (setting.enabled) {
      await NotificationService.instance.scheduleDailyReminder(
        id: slot.notificationId,
        title: 'Chef Santé',
        body: slot.notificationBody,
        hour: setting.hour,
        minute: setting.minute,
      );
    } else {
      await NotificationService.instance.cancelReminder(slot.notificationId);
    }

    final updated = Map<MealReminderSlot, MealReminderSetting>.from(state.value!);
    updated[slot] = setting;
    state = AsyncData(updated);
  }

  String _enabledKey(MealReminderSlot slot) => 'meal_reminder_${slot.name}_enabled';
  String _hourKey(MealReminderSlot slot) => 'meal_reminder_${slot.name}_hour';
  String _minuteKey(MealReminderSlot slot) => 'meal_reminder_${slot.name}_minute';
}
