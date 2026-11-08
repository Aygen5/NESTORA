/// Global application constants, smart home defaults, and validation rules.
class AppConstants {
  AppConstants._();

  // Brand & Platform Information
  static const String appName = 'Nestora';
  static const String appSubtitle = 'Akıllı Yaşam';
  static const String appVersion = '1.0.0';

  // Virtual Smart Home Simulation Defaults
  static const String defaultHomeName = "Aygen'in Evi";
  static const double defaultRoomTemp = 22.0;
  static const double minClimateTemp = 16.0;
  static const double maxClimateTemp = 30.0;
  static const double climateTempStep = 0.5;

  static const int minBrightness = 0;
  static const int maxBrightness = 100;
  static const int defaultBrightness = 72;

  // Network & Interaction Debounce
  static const Duration sliderDebounceDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(milliseconds: 1800);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);

  // SharedPreferences Keys
  static const String prefThemeMode = 'nestora_theme_mode';
  static const String prefProfilePhotoPath = 'nestora_profile_photo_path';
  static const String prefRememberMe = 'nestora_remember_me';
  static const String prefUserHomeName = 'nestora_user_home_name';

  // Input Validation Constants
  static const int minPasswordLength = 8;
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp upperCaseRegex = RegExp(r'[A-Z]');
  static final RegExp lowerCaseRegex = RegExp(r'[a-z]');
  static final RegExp digitRegex = RegExp(r'[0-9]');
  static final RegExp specialCharRegex = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
}

