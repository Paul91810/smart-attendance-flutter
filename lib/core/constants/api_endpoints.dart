/// Centralized API endpoint paths.
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String currentUser = '/auth/me';

  // Future phase endpoints
  static const String qrGenerate = '/qr/generate';
  static const String attendanceRecord = '/attendance/record';
  static const String attendanceHistory = '/attendance/history';
  static const String adminAnalytics = '/admin/analytics';
}
