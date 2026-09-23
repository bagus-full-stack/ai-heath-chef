import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';

/// Moment de la journée pour lequel on peut programmer un rappel de repas.
enum MealReminderSlot { breakfast, lunch, dinner }

extension MealReminderSlotInfo on MealReminderSlot {
  /// Id stable utilisé pour programmer/annuler la notification native
  /// correspondante (un id par créneau, jamais réutilisé ailleurs dans l'app).
  int get notificationId {
    switch (this) {
      case MealReminderSlot.breakfast:
        return 1001;
      case MealReminderSlot.lunch:
        return 1002;
      case MealReminderSlot.dinner:
        return 1003;
    }
  }

  String label(BuildContext context) {
    switch (this) {
      case MealReminderSlot.breakfast:
        return context.l10n.notificationSettingsSlotBreakfast;
      case MealReminderSlot.lunch:
        return context.l10n.notificationSettingsSlotLunch;
      case MealReminderSlot.dinner:
        return context.l10n.notificationSettingsSlotDinner;
    }
  }

  String notificationBody(AppLocalizations l10n) {
    switch (this) {
      case MealReminderSlot.breakfast:
        return l10n.notificationSettingsBodyBreakfast;
      case MealReminderSlot.lunch:
        return l10n.notificationSettingsBodyLunch;
      case MealReminderSlot.dinner:
        return l10n.notificationSettingsBodyDinner;
    }
  }

  /// Heure par défaut proposée avant que l'utilisateur ne la personnalise.
  int get defaultHour {
    switch (this) {
      case MealReminderSlot.breakfast:
        return 8;
      case MealReminderSlot.lunch:
        return 12;
      case MealReminderSlot.dinner:
        return 19;
    }
  }

  int get defaultMinute {
    switch (this) {
      case MealReminderSlot.breakfast:
        return 0;
      case MealReminderSlot.lunch:
        return 30;
      case MealReminderSlot.dinner:
        return 30;
    }
  }
}

/// Réglage courant d'un rappel : activé ou non, et à quelle heure.
class MealReminderSetting {
  final bool enabled;
  final int hour;
  final int minute;

  const MealReminderSetting({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  MealReminderSetting copyWith({bool? enabled, int? hour, int? minute}) {
    return MealReminderSetting(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}
