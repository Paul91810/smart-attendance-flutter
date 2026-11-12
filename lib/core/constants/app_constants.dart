/// Global application constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Attendance';
  static const String appVersion = '1.0.0';

  // QR Session constants (for Phase 2)
  static const int qrExpirySeconds = 60;
  static const int mockLatencyMs = 600;

  // Pagination / defaults
  static const int defaultPageSize = 20;
}
