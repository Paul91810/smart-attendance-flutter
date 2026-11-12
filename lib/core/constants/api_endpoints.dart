/// Centralized API endpoint paths.
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String currentUser = '/auth/me';

  // QR Session and Attendance endpoints
  static const String qrGenerate = '/qr/generate';
  static const String attendanceScan = '/attendance/scan';
  static const String attendanceRecord = '/attendance/record';
  static const String attendanceHistory = '/attendance/history';
  static const String adminAnalytics = '/admin/analytics';
}
