// notification_messages.dart

class NotificationMessages {
  // Streak Notifications
  static const String streakReminderTitle = "Don't lose your streak!";
  static const String streakReminderBody =
      'You have a few hours left to log your drinks and keep your streak alive!';

  static const String streakOnFireTitle = 'Your streak is on fire!';
  static const String streakOnFireBody =
      "Keep it going by logging today's drinks!";

  static const String streakLastChanceTitle = 'Last chance to log today!';
  static const String streakLastChanceBody =
      'Log your drinks now to keep your streak alive!';

  // Achievement Progress Notifications
  static const String achievementCloseTitle = "You're close to an achievement!";
  static String achievementCloseBody(String achievementName) =>
      "Log one more drink to earn the '$achievementName' badge.";

  static const String diverseDrinkerTitle = "You're close to a new badge!";
  static const String diverseDrinkerBody =
      'Try one more drink type to unlock the \'Diverse Drinker\' badge.';

  // Weekly Consumption Summary Notifications
  static String weeklySummaryTitle = 'Your Weekly Alcohol Report';
  static String weeklySummaryBody(int beerCount, int shotCount) =>
      'You consumed $beerCount beers and $shotCount shots this week. Ready to track more?';

  static const String setNewGoalTitle = 'Set a New Goal!';
  static const String setNewGoalBody =
      'Check your stats and set a new alcohol consumption goal for the week.';

  // Motivational and Encouragement Notifications
  static const String motivationFriendlyTitle = "Don't leave us hanging!";
  static const String motivationFriendlyBody =
      'It\'s time to log what you drank today 🍻.';

  static const String motivationPlayfulTitle = 'Keep the secret!';
  static const String motivationPlayfulBody =
      'Track today\'s drinks, and we promise to keep it a secret 😉.';

  static const String habitBuildingTitle = "You're building a great habit!";
  static const String habitBuildingBody =
      'One day at a time. Keep tracking to build your streak!';

  // Social Engagement and Leaderboard Notifications
  static String leaderboardMovedUpTitle(int position) =>
      "You've moved up to position $position!";
  static const String leaderboardMovedUpBody =
      'Keep it up to stay ahead in your association leaderboard!';

  static String leaderboardFallingBehindTitle(int overtakenBy) =>
      'You are about to be overtaken!';
  static const String leaderboardFallingBehindBody =
      'Log your drinks to stay ahead in the competition.';

  static const String topStreakTitle = "You're in the Top Streak!";
  static const String topStreakBody =
      "You've entered the top 10 longest streaks. Can you reach the top?";
}
