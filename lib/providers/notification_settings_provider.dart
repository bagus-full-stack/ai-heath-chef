import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/meal_reminder.dart';
import '../services/notification_service.dart';
import 'dashboard_provider.dart';
import 'locale_provider.dart';

/// Id de notification dédié au rappel "pas encore loggé aujourd'hui",
/// au-delà des créneaux fixes (1001-1003, voir [MealReminderSlotInfo]) et des
/// rappels personnalisés (2000+, voir custom_reminders_provider.dart).
const _kNoLogReminderId = 1004;

/// Réglages des rappels de repas (activé + heure, par créneau), persistés
/// localement et répercutés sur les notifications programmées à chaque
/// changement.
final notificationSettingsProvider =
    AsyncNotifierProvider<
      NotificationSettingsNotifier,
      Map<MealReminderSlot, MealReminderSetting>
    >(NotificationSettingsNotifier.new);

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
    await _applyAndPersist(
      slot,
      current[slot]!.copyWith(hour: hour, minute: minute),
    );
  }

  Future<void> _applyAndPersist(
    MealReminderSlot slot,
    MealReminderSetting setting,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey(slot), setting.enabled);
    await prefs.setInt(_hourKey(slot), setting.hour);
    await prefs.setInt(_minuteKey(slot), setting.minute);

    if (setting.enabled) {
      final locale = ref.read(localeProvider).value ?? const Locale('fr');
      await NotificationService.instance.scheduleReminder(
        id: slot.notificationId,
        title: 'AI Health Chef',
        body: slot.notificationBody(lookupAppLocalizations(locale)),
        hour: setting.hour,
        minute: setting.minute,
      );
    } else {
      await NotificationService.instance.cancelReminder(slot.notificationId);
    }

    final updated = Map<MealReminderSlot, MealReminderSetting>.from(
      state.value!,
    );
    updated[slot] = setting;
    state = AsyncData(updated);
  }

  String _enabledKey(MealReminderSlot slot) =>
      'meal_reminder_${slot.name}_enabled';
  String _hourKey(MealReminderSlot slot) => 'meal_reminder_${slot.name}_hour';
  String _minuteKey(MealReminderSlot slot) =>
      'meal_reminder_${slot.name}_minute';
}

/// Réglage du rappel "pas encore loggé aujourd'hui" (désactivé par défaut,
/// 20h) : contrairement aux créneaux fixes, sa notification n'est
/// (re)programmée que si l'utilisateur n'a effectivement rien loggé
/// aujourd'hui — voir [noLogReminderReconcilerProvider].
final noLogReminderProvider =
    AsyncNotifierProvider<NoLogReminderNotifier, MealReminderSetting>(
      NoLogReminderNotifier.new,
    );

class NoLogReminderNotifier extends AsyncNotifier<MealReminderSetting> {
  static const _enabledKey = 'no_log_reminder_enabled';
  static const _hourKey = 'no_log_reminder_hour';
  static const _minuteKey = 'no_log_reminder_minute';

  @override
  Future<MealReminderSetting> build() async {
    final prefs = await SharedPreferences.getInstance();
    return MealReminderSetting(
      enabled: prefs.getBool(_enabledKey) ?? false,
      hour: prefs.getInt(_hourKey) ?? 20,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;
    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return;
    } else {
      await NotificationService.instance.cancelReminder(_kNoLogReminderId);
    }
    await _persist(current.copyWith(enabled: enabled));
  }

  Future<void> setTime(int hour, int minute) async {
    final current = state.value;
    if (current == null) return;
    await _persist(current.copyWith(hour: hour, minute: minute));
  }

  Future<void> _persist(MealReminderSetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, setting.enabled);
    await prefs.setInt(_hourKey, setting.hour);
    await prefs.setInt(_minuteKey, setting.minute);
    state = AsyncData(setting);
  }
}

/// (Re)programme ou annule le rappel "pas encore loggé aujourd'hui" à chaque
/// changement des repas du jour ou du réglage — recalculé à l'ouverture de
/// l'app plutôt qu'en tâche de fond (aucun code Dart ne tourne pendant que
/// l'app est fermée avec flutter_local_notifications), donc reste basé sur
/// l'état constaté à la dernière ouverture, pas en temps réel toute la
/// journée.
final noLogReminderReconcilerProvider = FutureProvider<void>((ref) async {
  final setting = await ref.watch(noLogReminderProvider.future);
  if (!setting.enabled) {
    return;
  }

  final meals = await ref.watch(todayMealsProvider.future);
  try {
    if (meals.isEmpty) {
      final locale = ref.read(localeProvider).value ?? const Locale('fr');
      await NotificationService.instance.scheduleReminder(
        id: _kNoLogReminderId,
        title: 'AI Health Chef',
        body: lookupAppLocalizations(locale).notificationSettingsBodyNoLog,
        hour: setting.hour,
        minute: setting.minute,
      );
    } else {
      await NotificationService.instance.cancelReminder(_kNoLogReminderId);
    }
  } catch (_) {
    // Best-effort : permission pas encore accordée, ou plugin pas prêt.
  }
});
