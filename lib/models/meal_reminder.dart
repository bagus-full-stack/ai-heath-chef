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

  String get label {
    switch (this) {
      case MealReminderSlot.breakfast:
        return 'Petit-déjeuner';
      case MealReminderSlot.lunch:
        return 'Déjeuner';
      case MealReminderSlot.dinner:
        return 'Dîner';
    }
  }

  String get notificationBody {
    switch (this) {
      case MealReminderSlot.breakfast:
        return 'Pense à prendre en photo ton petit-déjeuner pour le logguer !';
      case MealReminderSlot.lunch:
        return 'Pense à prendre en photo ton déjeuner pour le logguer !';
      case MealReminderSlot.dinner:
        return 'Pense à prendre en photo ton dîner pour le logguer !';
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
