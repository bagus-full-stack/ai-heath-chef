/// Rappel ajouté librement par l'utilisateur (nom + heure), en plus des
/// créneaux fixes de [MealReminderSlot]. Contrairement à ceux-ci, il peut y
/// en avoir un nombre quelconque, et l'utilisateur peut les supprimer.
class CustomReminder {
  /// Sert à la fois d'identifiant et d'id de notification native — généré
  /// une fois à la création, jamais réutilisé.
  final int id;
  final String name;
  final int hour;
  final int minute;
  final bool enabled;

  const CustomReminder({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  CustomReminder copyWith({String? name, int? hour, int? minute, bool? enabled}) {
    return CustomReminder(
      id: id,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory CustomReminder.fromJson(Map<String, dynamic> json) {
    return CustomReminder(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
