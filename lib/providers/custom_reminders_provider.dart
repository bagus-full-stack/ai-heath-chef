import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_reminder.dart';
import '../services/notification_service.dart';

const _kPrefsKey = 'custom_reminders';

/// Rappels personnalisés (nom + heure) ajoutés librement par l'utilisateur,
/// en plus des créneaux fixes petit-déjeuner/déjeuner/dîner. Persistés
/// localement (liste JSON) et répercutés sur les notifications programmées.
final customRemindersProvider =
    AsyncNotifierProvider<CustomRemindersNotifier, List<CustomReminder>>(
  CustomRemindersNotifier.new,
);

class CustomRemindersNotifier extends AsyncNotifier<List<CustomReminder>> {
  @override
  Future<List<CustomReminder>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => CustomReminder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Ajoute un nouveau rappel (activé par défaut) et programme sa
  /// notification. Demande la permission système si besoin ; si elle est
  /// refusée, le rappel n'est pas créé.
  Future<void> add(String name, int hour, int minute) async {
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
    );

    await NotificationService.instance.scheduleDailyReminder(
      id: reminder.id,
      title: 'Chef Santé',
      body: reminder.name,
      hour: reminder.hour,
      minute: reminder.minute,
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
      await NotificationService.instance.scheduleDailyReminder(
        id: reminder.id,
        title: 'Chef Santé',
        body: reminder.name,
        hour: reminder.hour,
        minute: reminder.minute,
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
  }

  /// Id de notification unique (au-delà des ids fixes 1001-1003 des
  /// créneaux repas), dérivé de l'horodatage de création.
  int _generateId() => 2000 + (DateTime.now().millisecondsSinceEpoch % 100000000);
}
