import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../local_db/local_db_provider.dart';
import '../models/meal_reminder.dart';
import '../services/notification_service.dart';
import 'dashboard_provider.dart';
import 'locale_provider.dart';

/// Id de notification dédié au rappel "pas encore loggé aujourd'hui",
/// au-delà des créneaux fixes (1001-1003, voir [MealReminderSlotInfo]) et des
/// rappels personnalisés (2000+, voir custom_reminders_provider.dart).
const _kNoLogReminderId = 1004;

/// Vrai dès qu'une restauration depuis Supabase a été tentée sur cet appareil
/// (voir [NotificationSettingsNotifier._restoreFromBackupIfNeeded]).
const _kRestoredPrefsKey = 'meal_reminder_restored';

/// Réglages des rappels de repas (activé + heure, par créneau), persistés
/// localement et répercutés sur les notifications programmées à chaque
/// changement. Sauvegardés dans la même table Supabase que les rappels
/// personnalisés (`custom_reminders_backup`, colonne `fixed_reminders`) pour
/// survivre à une désinstallation (voir [_pushBackup]/[_restoreFromBackupIfNeeded],
/// même logique one-shot que CustomRemindersNotifier).
final notificationSettingsProvider =
    AsyncNotifierProvider<
      NotificationSettingsNotifier,
      Map<MealReminderSlot, MealReminderSetting>
    >(NotificationSettingsNotifier.new);

class NotificationSettingsNotifier
    extends AsyncNotifier<Map<MealReminderSlot, MealReminderSetting>> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<Map<MealReminderSlot, MealReminderSetting>> build() async {
    final prefs = await SharedPreferences.getInstance();
    // Tant que l'utilisateur n'a jamais réglé un créneau lui-même (pas de
    // valeur en prefs), on propose l'heure habituelle déduite de son
    // historique de repas plutôt que l'horaire fixe par défaut — dès qu'il
    // règle/active un créneau, cette heure est persistée et n'est plus
    // recalculée (voir _applyAndPersist).
    final typicalTimes = await ref
        .read(mealRepositoryProvider)
        .getTypicalMealTimes();
    final hasAnyLocalSetting = MealReminderSlot.values.any(
      (slot) => prefs.containsKey(_enabledKey(slot)),
    );
    final current = {
      for (final slot in MealReminderSlot.values)
        slot: MealReminderSetting(
          enabled: prefs.getBool(_enabledKey(slot)) ?? false,
          hour:
              prefs.getInt(_hourKey(slot)) ??
              typicalTimes[slot]?.hour ??
              slot.defaultHour,
          minute:
              prefs.getInt(_minuteKey(slot)) ??
              typicalTimes[slot]?.minute ??
              slot.defaultMinute,
        ),
    };

    if (hasAnyLocalSetting) {
      return current;
    }
    return _restoreFromBackupIfNeeded(prefs, current);
  }

  /// Tentative unique (par appareil) de restauration depuis la sauvegarde
  /// Supabase, uniquement si l'utilisateur n'a encore jamais réglé un
  /// créneau sur cet appareil — pour ne jamais écraser un réglage local.
  Future<Map<MealReminderSlot, MealReminderSetting>>
  _restoreFromBackupIfNeeded(
    SharedPreferences prefs,
    Map<MealReminderSlot, MealReminderSetting> fallback,
  ) async {
    if (prefs.getBool(_kRestoredPrefsKey) ?? false) {
      return fallback;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return fallback;
    }

    try {
      final row = await _supabase
          .from('custom_reminders_backup')
          .select('fixed_reminders')
          .eq('user_id', user.id)
          .maybeSingle();
      await prefs.setBool(_kRestoredPrefsKey, true);

      final backup = row?['fixed_reminders'] as Map<String, dynamic>?;
      if (backup == null) {
        return fallback;
      }

      final restored = <MealReminderSlot, MealReminderSetting>{};
      for (final slot in MealReminderSlot.values) {
        final saved = backup[slot.name] as Map<String, dynamic>?;
        final setting = saved == null
            ? fallback[slot]!
            : MealReminderSetting(
                enabled: saved['enabled'] as bool,
                hour: saved['hour'] as int,
                minute: saved['minute'] as int,
              );
        await prefs.setBool(_enabledKey(slot), setting.enabled);
        await prefs.setInt(_hourKey(slot), setting.hour);
        await prefs.setInt(_minuteKey(slot), setting.minute);
        restored[slot] = setting;

        if (setting.enabled) {
          try {
            final locale = ref.read(localeProvider).value ?? const Locale('fr');
            await NotificationService.instance.scheduleReminder(
              id: slot.notificationId,
              title: 'AI Health Chef',
              body: slot.notificationBody(lookupAppLocalizations(locale)),
              hour: setting.hour,
              minute: setting.minute,
            );
          } catch (_) {
            // Permission pas encore accordée sur ce nouvel appareil : le
            // réglage reste restauré, reprogrammable manuellement.
          }
        }
      }
      return restored;
    } catch (_) {
      // Pas de réseau : on retentera au prochain démarrage (flag pas posé).
      return fallback;
    }
  }

  Future<void> _pushBackup(
    Map<MealReminderSlot, MealReminderSetting> settings,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('custom_reminders_backup').upsert({
        'user_id': user.id,
        'fixed_reminders': {
          for (final entry in settings.entries)
            entry.key.name: {
              'enabled': entry.value.enabled,
              'hour': entry.value.hour,
              'minute': entry.value.minute,
            },
        },
      });
    } catch (_) {
      // Best-effort : la prochaine modification retentera la sauvegarde.
    }
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
    unawaited(_pushBackup(updated));
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
