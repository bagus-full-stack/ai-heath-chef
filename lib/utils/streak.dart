/// Nombre de jours consécutifs se terminant à [today] (ou [today] - 1, pour
/// ne pas casser le streak avant la fin de la journée en cours) présents
/// dans [loggedDays]. [loggedDays] doit contenir des [DateTime] normalisés
/// à minuit (voir [MealRepository.getCurrentStreak]).
int computeStreak(Set<DateTime> loggedDays, DateTime today) {
  var cursor = DateTime(today.year, today.month, today.day);
  if (!loggedDays.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!loggedDays.contains(cursor)) return 0;
  }

  var streak = 0;
  while (loggedDays.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Paliers de streak célébrés par un badge/toast, du plus petit au plus grand.
const streakMilestones = [7, 30, 100];

/// Plus haut palier de [streakMilestones] atteint par [streak], ou `null` si
/// aucun (streak encore sous 7 jours).
int? highestStreakMilestone(int streak) {
  int? result;
  for (final milestone in streakMilestones) {
    if (streak >= milestone) result = milestone;
  }
  return result;
}
