import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/custom_reminder.dart';
import '../services/notification_service.dart';

const _kPrefsKey = 'custom_reminders';

/// Faux tant qu'une restauration depuis Supabase n'a pas été tentée sur cet
/// appareil (voir [CustomRemindersNotifier._restoreFromBackupIfNeeded]) —
/// évite de re-vérifier à chaque ouverture d'écran une fois fait.
const _kRestoredPrefsKey = 'custom_reminders_restored';

/// Rappels personnalisés (nom + heure) ajoutés librement par l'utilisateur,
/// en plus des créneaux fixes petit-déjeuner/déjeuner/dîner. Persistés
/// localement (liste JSON), répercutés sur les notifications programmées, et
/// sauvegardés dans la table Supabase `custom_reminders_backup` pour
/// survivre à une désinstallation ou se restaurer sur un nouvel appareil
/// (voir [_restoreFromBackupIfNeeded] — ponytail: restauration one-shot au
/// premier lancement sur un appareil "vide", pas de fusion en cas d'édition
/// concurrente sur deux appareils ; à revoir avec un `updated_at` si ça
/// devient un vrai usage multi-appareils simultané).
final customRemindersProvider =
    AsyncNotifierProvider<CustomRemindersNotifier, List<CustomReminder>>(
  CustomRemindersNotifier.new,
);

class CustomRemindersNotifier extends AsyncNotifier<List<CustomReminder>> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<CustomReminder>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    final local = raw == null || raw.isEmpty
        ? const <CustomReminder>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((item) => CustomReminder.fromJson(item as Map<String, dynamic>))
            .toList();

    return _restoreFromBackupIfNeeded(prefs, local);
  }

  /// Tentative unique (par appareil) de restauration depuis la sauvegarde
  /// Supabase, uniquement si rien n'existe encore localement — pour ne
  /// jamais écraser des rappels déjà présents sur cet appareil.
  Future<List<CustomReminder>> _restoreFromBackupIfNeeded(
    SharedPreferences prefs,
    List<CustomReminder> local,
  ) async {
    if (prefs.getBool(_kRestoredPrefsKey) ?? false) {
      return local;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return local;
    }

    if (local.isNotEmpty) {
      await prefs.setBool(_kRestoredPrefsKey, true);
      return local;
    }

    try {
      final row = await _supabase
          .from('custom_reminders_backup')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      await prefs.setBool(_kRestoredPrefsKey, true);

      final backedUp = (row?['reminders'] as List<dynamic>?)
              ?.map((item) => CustomReminder.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const <CustomReminder>[];
      if (backedUp.isEmpty) {
        return local;
      }

      for (final reminder in backedUp) {
        if (!reminder.enabled) continue;
        try {
          await NotificationService.instance.scheduleReminder(
            id: reminder.id,
            title: 'AI Health Chef',
            body: reminder.name,
            hour: reminder.hour,
            minute: reminder.minute,
            weekday: reminder.weekday,
          );
        } catch (_) {
          // Permission pas encore accordée sur ce nouvel appareil : le
          // rappel reste dans la liste, reprogrammable manuellement.
        }
      }

      await prefs.setString(
        _kPrefsKey,
        jsonEncode(backedUp.map((r) => r.toJson()).toList()),
      );
      return backedUp;
    } catch (_) {
      // Pas de réseau : on retentera au prochain démarrage de ce provider
      // (flag pas posé).
      return local;
    }
  }

  Future<void> _pushBackup(List<CustomReminder> reminders) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('custom_reminders_backup').upsert({
        'user_id': user.id,
        'reminders': reminders.map((r) => r.toJson()).toList(),
      });
    } catch (_) {
      // Best-effort : la prochaine modification retentera la sauvegarde.
    }
  }

  /// Ajoute un nouveau rappel (activé par défaut) et programme sa
  /// notification — quotidien, ou hebdomadaire si [weekday] est fourni
  /// (voir [CustomReminder.weekday]). Demande la permission système si
  /// besoin ; si elle est refusée, le rappel n'est pas créé.
  Future<void> add(String name, int hour, int minute, {int? weekday}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final granted = await NotificationService.instance.requestPermission();
    if (!granted) {
      return;
    }

    final reminder = CustomReminder(
      id: _generateId(),
      name: trimmed,
      hour: hour,
      minute: minute,
      weekday: weekday,
    );

    await NotificationService.instance.scheduleReminder(
      id: reminder.id,
      title: 'AI Health Chef',
      body: reminder.name,
      hour: reminder.hour,
      minute: reminder.minute,
      weekday: reminder.weekday,
    );

    final current = state.value ?? const <CustomReminder>[];
    await _persist([...current, reminder]);
  }

  Future<void> setEnabled(int id, bool enabled) async {
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

    final reminder = current.firstWhere((r) => r.id == id);
    final updated = reminder.copyWith(enabled: enabled);
    await _applyScheduling(updated);
    await _persist(current.map((r) => r.id == id ? updated : r).toList());
  }

  Future<void> setTime(int id, int hour, int minute) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final reminder = current.firstWhere((r) => r.id == id);
    final updated = reminder.copyWith(hour: hour, minute: minute);
    await _applyScheduling(updated);
    await _persist(current.map((r) => r.id == id ? updated : r).toList());
  }

  Future<void> remove(int id) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    await NotificationService.instance.cancelReminder(id);
    await _persist(current.where((r) => r.id != id).toList());
  }

  Future<void> _applyScheduling(CustomReminder reminder) async {
    if (reminder.enabled) {
      await NotificationService.instance.scheduleReminder(
        id: reminder.id,
        title: 'AI Health Chef',
        body: reminder.name,
        hour: reminder.hour,
        minute: reminder.minute,
        weekday: reminder.weekday,
      );
    } else {
      await NotificationService.instance.cancelReminder(reminder.id);
    }
  }

  Future<void> _persist(List<CustomReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPrefsKey,
      jsonEncode(reminders.map((r) => r.toJson()).toList()),
    );
    state = AsyncData(reminders);
    unawaited(_pushBackup(reminders));
  }

  /// Id de notification unique (au-delà des ids fixes 1001-1003 des
  /// créneaux repas), dérivé de l'horodatage de création.
  int _generateId() => 2000 + (DateTime.now().millisecondsSinceEpoch % 100000000);
}
