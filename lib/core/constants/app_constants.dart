class AppConstants {
  AppConstants._();

  static const String appName = 'TechiNews';
  static const String appTagline = 'AI Intelligence for the Tech Ecosystem';
  static const String appVersion = '0.1.0';

  static const Duration defaultAnimation = Duration(milliseconds: 250);
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration slowAnimation = Duration(milliseconds: 400);

  static const int feedPageSize = 20;
  static const int trendingPageSize = 10;

  // Storage keys
  static const String prefsKeyThemeMode = 'theme_mode';
  static const String prefsKeyOnboardingComplete = 'onboarding_complete';
  static const String prefsKeyUserInterests = 'user_interests';
  static const String prefsKeyNotificationMode = 'notification_mode';
  static const String prefsKeyAuthToken = 'auth_token';

  // Hive boxes
  static const String hiveBoxSavedArticles = 'saved_articles';
  static const String hiveBoxReadHistory = 'read_history';
  static const String hiveBoxNotifications = 'notifications';
}

class Interests {
  Interests._();

  static const List<String> all = [
    'Artificial Intelligence',
    'Startups',
    'Open Source',
    'Cybersecurity',
    'Web Development',
    'Mobile Development',
    'Space Tech',
    'Robotics',
    'Finance Tech',
    'Blockchain',
    'Apple',
    'Google',
    'NVIDIA',
    'OpenAI',
    'Meta',
    'Microsoft',
    'Hiring',
    'Funding',
    'Product Launches',
  ];
}
