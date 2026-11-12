import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/qr_session/domain/entities/qr_session.dart';

class MockAttendanceStore {
  MockAttendanceStore._();

  static final List<QrSession> issuedSessions = [];
  static final Set<String> usedNonces = <String>{};
  static final List<AttendanceRecord> recordedAttendance = <AttendanceRecord>[];

  static bool _seeded = false;

  static bool simulateOffline = false;
  static bool simulateServerError = false;

  static QrSession? get latestSession =>
      issuedSessions.isNotEmpty ? issuedSessions.last : null;

  static void seedInitialDataIfEmpty() {
    if (_seeded || recordedAttendance.isNotEmpty) return;
    _seeded = true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    var idCounter = 1;

    void addPair({
      required String employeeId,
      required DateTime day,
      required int inHour,
      required int inMinute,
      required int outHour,
      required int outMinute,
      double lat = 12.9716,
      double lng = 77.5946,
    }) {
      recordedAttendance.add(AttendanceRecord(
        id: idCounter++,
        employeeId: employeeId,
        type: AttendanceType.checkIn,
        timestamp: DateTime(day.year, day.month, day.day, inHour, inMinute),
        latitude: lat,
        longitude: lng,
        sessionId: 'SES-SEED-${idCounter - 1}',
        synced: true,
      ));
      recordedAttendance.add(AttendanceRecord(
        id: idCounter++,
        employeeId: employeeId,
        type: AttendanceType.checkOut,
        timestamp: DateTime(day.year, day.month, day.day, outHour, outMinute),
        latitude: lat,
        longitude: lng,
        sessionId: 'SES-SEED-${idCounter - 1}',
        synced: true,
      ));
    }

    void addSingle({
      required String employeeId,
      required DateTime day,
      required int inHour,
      required int inMinute,
      AttendanceType type = AttendanceType.checkIn,
      double lat = 12.9716,
      double lng = 77.5946,
    }) {
      recordedAttendance.add(AttendanceRecord(
        id: idCounter++,
        employeeId: employeeId,
        type: type,
        timestamp: DateTime(day.year, day.month, day.day, inHour, inMinute),
        latitude: lat,
        longitude: lng,
        sessionId: 'SES-SEED-${idCounter - 1}',
        synced: true,
      ));
    }

    // 2 Days Ago
    addPair(employeeId: 'EMP001', day: twoDaysAgo, inHour: 9, inMinute: 4, outHour: 17, outMinute: 32);
    addPair(employeeId: 'EMP002', day: twoDaysAgo, inHour: 9, inMinute: 15, outHour: 17, outMinute: 45);
    addPair(employeeId: 'EMP003', day: twoDaysAgo, inHour: 9, inMinute: 30, outHour: 18, outMinute: 0);
    addPair(employeeId: 'EMP004', day: twoDaysAgo, inHour: 8, inMinute: 55, outHour: 17, outMinute: 20);

    // Yesterday
    addPair(employeeId: 'EMP001', day: yesterday, inHour: 9, inMinute: 1, outHour: 17, outMinute: 30);
    addPair(employeeId: 'EMP002', day: yesterday, inHour: 9, inMinute: 22, outHour: 18, outMinute: 5);
    addPair(employeeId: 'EMP003', day: yesterday, inHour: 9, inMinute: 10, outHour: 17, outMinute: 40);
    addPair(employeeId: 'EMP005', day: yesterday, inHour: 8, inMinute: 50, outHour: 17, outMinute: 15);

    // Today: EMP001 (Present), EMP002 (Checked out), EMP003 (Present), EMP004 (Checked out)
    addSingle(employeeId: 'EMP001', day: today, inHour: 9, inMinute: 0);
    addPair(employeeId: 'EMP002', day: today, inHour: 9, inMinute: 12, outHour: 13, outMinute: 30);
    addSingle(employeeId: 'EMP003', day: today, inHour: 8, inMinute: 58);
    addPair(employeeId: 'EMP004', day: today, inHour: 9, inMinute: 18, outHour: 14, outMinute: 10);
  }

  static void reset() {
    issuedSessions.clear();
    usedNonces.clear();
    recordedAttendance.clear();
    simulateOffline = false;
    simulateServerError = false;
    _seeded = false;
  }
}
