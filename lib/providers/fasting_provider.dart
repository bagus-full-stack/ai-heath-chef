import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _goalHoursKey = 'fasting_goal_hours';
const _startedAtKey = 'fasting_started_at';

/// État du jeûne intermittent : objectif de durée (ex. 16h dans un 16:8) et,
/// si un jeûne est en cours, son heure de départ. Purement local
/// (SharedPreferences) — un minuteur perso n'a pas besoin de sync Supabase,
/// même pattern que shopping_list_provider.dart.
class FastingState {
  final int goalHours;
  final DateTime? startedAt;

  const FastingState({required this.goalHours, this.startedAt});

  Duration get elapsed => startedAt == null ? Duration.zero : DateTime.now().difference(startedAt!);
  bool get isFasting => startedAt != null;

  FastingState copyWith({int? goalHours, DateTime? startedAt, bool clearStartedAt = false}) {
    return FastingState(
      goalHours: goalHours ?? this.goalHours,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
    );
  }
}

final fastingProvider = AsyncNotifierProvider<FastingNotifier, FastingState>(FastingNotifier.new);

class FastingNotifier extends AsyncNotifier<FastingState> {
  @override
  Future<FastingState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final startedAtRaw = prefs.getString(_startedAtKey);
    return FastingState(
      goalHours: prefs.getInt(_goalHoursKey) ?? 16,
      startedAt: startedAtRaw != null ? DateTime.tryParse(startedAtRaw) : null,
    );
  }

  Future<void> setGoalHours(int hours) async {
    final current = state.value;
    if (current == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalHoursKey, hours);
    state = AsyncData(current.copyWith(goalHours: hours));
  }

  Future<void> start() async {
    final current = state.value;
    if (current == null) return;
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startedAtKey, now.toIso8601String());
    state = AsyncData(current.copyWith(startedAt: now));
  }

  Future<void> stop() async {
    final current = state.value;
    if (current == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_startedAtKey);
    state = AsyncData(current.copyWith(clearStartedAt: true));
  }
}
