import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/features/auth/domain/entities/user.dart';
import 'package:smart_attendance/features/auth/domain/entities/user_role.dart';
import 'package:smart_attendance/features/qr_session/domain/entities/qr_session.dart';
import 'package:smart_attendance/features/qr_session/domain/validators/checkout_without_checkin_rule.dart';
import 'package:smart_attendance/features/qr_session/domain/validators/duplicate_attendance_rule.dart';
import 'package:smart_attendance/features/qr_session/domain/validators/expiry_rule.dart';
import 'package:smart_attendance/features/qr_session/domain/validators/nonce_reuse_rule.dart';
import 'package:smart_attendance/features/qr_session/domain/validators/qr_validation_rule.dart';
import 'package:smart_attendance/features/qr_session/domain/validators/qr_validator.dart';
import 'package:smart_attendance/features/qr_session/domain/validators/role_rule.dart';
import 'package:smart_attendance/features/qr_session/domain/validators/signature_rule.dart';

void main() {
  const secret = AppConstants.hmacSecret;
  final now = DateTime.now();

  const employeeUser = User(
    id: 'emp1',
    employeeId: 'EMP001',
    name: 'Alice Employee',
    email: 'alice@company.com',
    role: UserRole.employee,
  );

  const adminUser = User(
    id: 'adm1',
    employeeId: 'EMP000',
    name: 'Admin Boss',
    email: 'admin@company.com',
    role: UserRole.admin,
  );

  QrSession makeSession({
    String sessionId = 'SES-TEST-001',
    DateTime? issuedAt,
    DateTime? expiresAt,
    String nonce = 'nonce-test-123',
    String? signature,
  }) {
    final issued = issuedAt ?? now;
    final expires = expiresAt ?? now.add(const Duration(seconds: 60));
    final sig = signature ??
        QrSession.computeHmacSignature(
          sessionId: sessionId,
          issuedAt: issued,
          expiresAt: expires,
          nonce: nonce,
          secret: secret,
        );

    return QrSession(
      sessionId: sessionId,
      issuedAt: issued,
      expiresAt: expires,
      nonce: nonce,
      signature: sig,
    );
  }

  QrValidationContext makeContext({
    required QrSession session,
    User user = employeeUser,
    AttendanceType attendanceType = AttendanceType.checkIn,
    DateTime? scanTimestamp,
    double latitude = 12.9716,
    double longitude = 77.5946,
    String hmacSecret = secret,
    Set<String>? usedNonces,
    List<AttendanceRecord>? userAttendanceRecords,
  }) {
    return QrValidationContext(
      session: session,
      user: user,
      attendanceType: attendanceType,
      scanTimestamp: scanTimestamp ?? now,
      latitude: latitude,
      longitude: longitude,
      hmacSecret: hmacSecret,
      usedNonces: usedNonces ?? {},
      userAttendanceRecords: userAttendanceRecords ?? [],
    );
  }

  group('SignatureRule', () {
    const rule = SignatureRule();

    test('passes when signature matches HMAC-SHA256 calculation', () async {
      final session = makeSession();
      final context = makeContext(session: session);

      final result = await rule.validate(context);
      expect(result.isSuccess, isTrue);
    });

    test('fails with INVALID_SIGNATURE when signature is tampered', () async {
      final session = makeSession(signature: 'tampered-signature-string');
      final context = makeContext(session: session);

      final result = await rule.validate(context);
      expect(result.isFailure, isTrue);
      result.fold(
        (failure) => expect(failure.code, 'INVALID_SIGNATURE'),
        (_) => fail('Expected failure'),
      );
    });
  });

  group('ExpiryRule', () {
    const rule = ExpiryRule();

    test('passes when scanTimestamp is before expiresAt', () async {
      final session = makeSession(
        issuedAt: now.subtract(const Duration(seconds: 10)),
        expiresAt: now.add(const Duration(seconds: 50)),
      );
      final context = makeContext(session: session, scanTimestamp: now);

      final result = await rule.validate(context);
      expect(result.isSuccess, isTrue);
    });

    test('fails with QR_EXPIRED when scanTimestamp is past expiresAt', () async {
      final session = makeSession(
        issuedAt: now.subtract(const Duration(seconds: 70)),
        expiresAt: now.subtract(const Duration(seconds: 10)),
      );
      final context = makeContext(session: session, scanTimestamp: now);

      final result = await rule.validate(context);
      expect(result.isFailure, isTrue);
      result.fold(
        (failure) => expect(failure.code, 'QR_EXPIRED'),
        (_) => fail('Expected failure'),
      );
    });
  });

  group('NonceReuseRule', () {
    const rule = NonceReuseRule();

    test('passes when nonce has not been consumed yet', () async {
      final session = makeSession(nonce: 'fresh-nonce-999');
      final context = makeContext(
        session: session,
        usedNonces: {'other-nonce-111'},
      );

      final result = await rule.validate(context);
      expect(result.isSuccess, isTrue);
    });

    test('fails with QR_ALREADY_USED when nonce was previously recorded', () async {
      final session = makeSession(nonce: 'consumed-nonce-222');
      final context = makeContext(
        session: session,
        usedNonces: {'consumed-nonce-222'},
      );

      final result = await rule.validate(context);
      expect(result.isFailure, isTrue);
      result.fold(
        (failure) => expect(failure.code, 'QR_ALREADY_USED'),
        (_) => fail('Expected failure'),
      );
    });
  });

  group('RoleRule', () {
    const rule = RoleRule();

    test('passes for employee role', () async {
      final session = makeSession();
      final context = makeContext(session: session, user: employeeUser);

      final result = await rule.validate(context);
      expect(result.isSuccess, isTrue);
    });

    test('fails with FORBIDDEN when user role is admin', () async {
      final session = makeSession();
      final context = makeContext(session: session, user: adminUser);

      final result = await rule.validate(context);
      expect(result.isFailure, isTrue);
      result.fold(
        (failure) => expect(failure.code, 'FORBIDDEN'),
        (_) => fail('Expected failure'),
      );
    });
  });

  group('DuplicateAttendanceRule', () {
    const rule = DuplicateAttendanceRule();

    test('passes checkIn when no prior checkIn exists today', () async {
      final session = makeSession();
      final context = makeContext(
        session: session,
        attendanceType: AttendanceType.checkIn,
        userAttendanceRecords: [],
      );

      final result = await rule.validate(context);
      expect(result.isSuccess, isTrue);
    });

    test('fails with DUPLICATE_ATTENDANCE when checkIn already exists today', () async {
      final session = makeSession();
      final existingCheckIn = AttendanceRecord(
        id: 1,
        employeeId: employeeUser.employeeId,
        type: AttendanceType.checkIn,
        timestamp: now.subtract(const Duration(hours: 2)),
        latitude: 12.9,
        longitude: 77.5,
        sessionId: 'OLD-SES-1',
      );

      final context = makeContext(
        session: session,
        attendanceType: AttendanceType.checkIn,
        userAttendanceRecords: [existingCheckIn],
      );

      final result = await rule.validate(context);
      expect(result.isFailure, isTrue);
      result.fold(
        (failure) => expect(failure.code, 'DUPLICATE_ATTENDANCE'),
        (_) => fail('Expected failure'),
      );
    });
  });

  group('CheckOutWithoutCheckInRule', () {
    const rule = CheckOutWithoutCheckInRule();

    test('passes checkIn without prior records', () async {
      final session = makeSession();
      final context = makeContext(
        session: session,
        attendanceType: AttendanceType.checkIn,
        userAttendanceRecords: [],
      );

      final result = await rule.validate(context);
      expect(result.isSuccess, isTrue);
    });

    test('fails with NO_CHECK_IN when checkOut is attempted without prior checkIn', () async {
      final session = makeSession();
      final context = makeContext(
        session: session,
        attendanceType: AttendanceType.checkOut,
        userAttendanceRecords: [],
      );

      final result = await rule.validate(context);
      expect(result.isFailure, isTrue);
      result.fold(
        (failure) => expect(failure.code, 'NO_CHECK_IN'),
        (_) => fail('Expected failure'),
      );
    });

    test('passes checkOut when valid checkIn exists earlier today', () async {
      final session = makeSession();
      final existingCheckIn = AttendanceRecord(
        id: 1,
        employeeId: employeeUser.employeeId,
        type: AttendanceType.checkIn,
        timestamp: now.subtract(const Duration(hours: 4)),
        latitude: 12.9,
        longitude: 77.5,
        sessionId: 'OLD-SES-1',
      );

      final context = makeContext(
        session: session,
        attendanceType: AttendanceType.checkOut,
        userAttendanceRecords: [existingCheckIn],
      );

      final result = await rule.validate(context);
      expect(result.isSuccess, isTrue);
    });
  });

  group('QrValidator composite runner', () {
    const validator = QrValidator();

    test('passes all standard rules for valid employee checkIn', () async {
      final session = makeSession();
      final context = makeContext(session: session);

      final result = await validator.validate(context);
      expect(result.isSuccess, isTrue);
    });

    test('stops at first failing rule (e.g., tampered signature)', () async {
      final session = makeSession(signature: 'invalid-hash');
      final context = makeContext(
        session: session,
        user: adminUser, // Role rule would also fail, but signature rule is first
      );

      final result = await validator.validate(context);
      expect(result.isFailure, isTrue);
      result.fold(
        (failure) => expect(failure.code, 'INVALID_SIGNATURE'),
        (_) => fail('Expected failure'),
      );
    });
  });
}
