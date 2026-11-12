class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String currentUser = '/auth/me';

  static const String qrGenerate = '/qr/generate';
  static const String attendanceScan = '/attendance/scan';
  static const String attendanceRecord = '/attendance/record';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceMe = '/attendance/me';

  static const String adminEmployees = '/admin/employees';
  static const String adminAttendance = '/admin/attendance';
  static const String adminSummary = '/admin/summary';
  static const String adminAnalytics = '/admin/analytics';
}
