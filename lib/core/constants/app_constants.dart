class AppConstants {
  static const String appName = '21-Day Habit Tracker';
  static const int lockDays = 21;

  // API - Update with your computer's IP
  static const String baseUrl =
      'http://192.168.1.30:3000/api'; // Change IP if needed

  // Hive Boxes
  static const String userBox = 'user_box';
  static const String tasksBox = 'tasks_box';
  static const String logsBox = 'logs_box';

  // Shared Preferences Keys
  static const String tokenKey = 'token';
  static const String userIdKey = 'user_id';
  static const String onboardingKey = 'onboarding_completed';

  // Categories
  static const List<String> categories = [
    'Health',
    'Fitness',
    'Productivity',
    'Learning',
    'Personal',
    'Work',
  ];

  // Colors for categories
  static const Map<String, int> categoryColors = {
    'Health': 0xFFEF4444,
    'Fitness': 0xFFF59E0B,
    'Productivity': 0xFF3B82F6,
    'Learning': 0xFF8B5CF6,
    'Personal': 0xFF10B981,
    'Work': 0xFF06B6D4,
  };
}
