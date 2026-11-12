import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/qr_session/data/models/qr_session_model.dart';
import '../../features/qr_session/domain/entities/qr_session.dart';
import '../../features/qr_session/domain/validators/qr_validation_rule.dart';
import '../../features/qr_session/domain/validators/qr_validator.dart';
import 'dummy_users.dart';
import 'mock_attendance_store.dart';

/// Interceptor that simulates a RESTful backend server with realistic network latency,
/// standard REST status codes, error handling, in-memory mock user authentication,
/// dynamic QR session generation, and strict attendance QR validation.
class MockApiInterceptor extends Interceptor {
  final int latencyMs;

  MockApiInterceptor({this.latencyMs = 600});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Simulate network latency (600ms default)
    if (latencyMs > 0) {
      await Future.delayed(Duration(milliseconds: latencyMs));
    }

    // Ensure mock data is seeded
    MockAttendanceStore.seedInitialDataIfEmpty();

    // Check simulation toggles for offline and server errors
    if (MockAttendanceStore.simulateOffline) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'No internet connection (Simulated Offline Mode)',
        ),
      );
    }

    if (MockAttendanceStore.simulateServerError) {
      return respondServerError(
        options,
        handler,
        code: 'SIMULATED_500',
        message: 'Internal server error (Simulated 500 Failure)',
      );
    }

    final path = options.path;
    final method = options.method.toUpperCase();

    try {
      // 2. Route matching
      if (path.endsWith('/auth/login') && method == 'POST') {
        return _handleLogin(options, handler);
      } else if (path.endsWith('/auth/logout') && method == 'POST') {
        return _handleLogout(options, handler);
      } else if (path.endsWith('/auth/me') && method == 'GET') {
        return _handleGetCurrentUser(options, handler);
      } else if (path.endsWith('/qr/generate') && method == 'POST') {
        return _handleGenerateQrSession(options, handler);
      } else if (path.endsWith('/attendance/scan') && method == 'POST') {
        return await _handleAttendanceScan(options, handler);
      } else if (path.endsWith('/attendance/record') && method == 'POST') {
        return _handleUploadAttendanceRecord(options, handler);
      } else if (path.endsWith('/attendance/me') && method == 'GET') {
        return _handleGetMyAttendance(options, handler);
      } else if (path.endsWith('/attendance/history') && method == 'GET') {
        return _handleGetAttendanceHistory(options, handler);
      } else if (path.endsWith('/admin/employees') && method == 'GET') {
        return _handleGetAdminEmployees(options, handler);
      } else if (path.endsWith('/admin/attendance') && method == 'GET') {
        return _handleGetAdminAttendance(options, handler);
      } else if (path.endsWith('/admin/summary') && method == 'GET') {
        return _handleGetAdminSummary(options, handler);
      } else {
        // Default: 404 Not Found
        return respondNotFound(
          options,
          handler,
          code: 'ROUTE_NOT_FOUND',
          message: 'Endpoint not found: $method $path',
        );
      }
    } catch (e) {
      return respondServerError(
        options,
        handler,
        code: 'INTERNAL_ERROR',
        message: 'Mock server encountered an unexpected error: $e',
      );
    }
  }

  // ===================== Route Handlers =====================

  void _handleLogin(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    Map<String, dynamic> data;
    if (options.data is Map<String, dynamic>) {
      data = options.data as Map<String, dynamic>;
    } else if (options.data is FormData) {
      final formData = options.data as FormData;
      data = {
        for (final entry in formData.fields) entry.key: entry.value,
      };
    } else {
      return respondError(
        options,
        handler,
        statusCode: 400,
        code: 'BAD_REQUEST',
        message: 'Invalid request body payload format',
      );
    }

    final identifier = (data['identifier'] ?? data['email'] ?? data['employeeId'] ?? '')
        .toString()
        .trim();
    final password = (data['password'] ?? '').toString();

    if (identifier.isEmpty || password.isEmpty) {
      return respondError(
        options,
        handler,
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: 'Email/Employee ID and password are required',
      );
    }

    final dummyUser = DummyUsersStore.findByIdentifier(identifier);
    if (dummyUser == null || dummyUser.password != password) {
      return respondUnauthorized(
        options,
        handler,
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email/employee ID or password',
      );
    }

    final token = 'mock-jwt-${dummyUser.id}-${DateTime.now().millisecondsSinceEpoch}';
    return respondSuccess(
      options,
      handler,
      data: {
        'token': token,
        'user': dummyUser.toUserMap(),
      },
    );
  }

  void _handleLogout(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    return respondSuccess(
      options,
      handler,
      data: {'message': 'Logged out successfully'},
    );
  }

  void _handleGetCurrentUser(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final user = _getAuthenticatedUser(options);
    if (user == null) {
      return respondUnauthorized(
        options,
        handler,
        code: 'UNAUTHORIZED',
        message: 'Missing or malformed Authorization header',
      );
    }

    return respondSuccess(
      options,
      handler,
      data: user.toUserMap(),
    );
  }

  /// POST /qr/generate: Admin-only endpoint generating HMAC-SHA256 time-limited dynamic QR sessions.
  void _handleGenerateQrSession(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final user = _getAuthenticatedUser(options);
    if (user == null) {
      return respondUnauthorized(
        options,
        handler,
        code: 'UNAUTHORIZED',
        message: 'Authentication required to generate attendance QR code.',
      );
    }

    // Role check: Only administrators are authorized to generate session codes
    if (user.role.toLowerCase() != 'admin') {
      return respondForbidden(
        options,
        handler,
        code: 'FORBIDDEN',
        message: 'Only administrators are authorized to generate attendance QR codes.',
      );
    }

    // =========================================================================
    // SECURITY DESIGN:
    // 1. Session ID: Globally unique timestamped identifier.
    // 2. Nonce: Cryptographically randomized string ensuring single-use consumption.
    // 3. Expiration: Strict 60-second validity window.
    // 4. HMAC-SHA256: Signature computed using app secret over canonical string
    //    `$sessionId:${issuedAt.toIso8601String()}:${expiresAt.toIso8601String()}:$nonce`.
    // =========================================================================
    final now = DateTime.now();
    final issuedAt = now;
    final expiresAt = now.add(const Duration(seconds: AppConstants.qrExpirySeconds));
    final sessionId = 'ses_${now.millisecondsSinceEpoch}_${Random().nextInt(10000)}';
    final nonce = 'nonce_${now.microsecondsSinceEpoch}_${Random().nextInt(999999)}';

    final signature = QrSession.computeHmacSignature(
      sessionId: sessionId,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      nonce: nonce,
      secret: AppConstants.hmacSecret,
    );

    final session = QrSession(
      sessionId: sessionId,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      nonce: nonce,
      signature: signature,
    );

    // Save session in mock store to enable nonce consumption tracking
    MockAttendanceStore.issuedSessions.add(session);

    return respondSuccess(
      options,
      handler,
      data: {
        'sessionId': session.sessionId,
        'issuedAt': session.issuedAt.toIso8601String(),
        'expiresAt': session.expiresAt.toIso8601String(),
        'nonce': session.nonce,
        'signature': session.signature,
      },
    );
  }

  /// POST /attendance/scan: Validates scanned QR payload through composite rules and marks attendance.
  Future<void> _handleAttendanceScan(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authUser = _getAuthenticatedUser(options);
    if (authUser == null) {
      return respondUnauthorized(
        options,
        handler,
        code: 'UNAUTHORIZED',
        message: 'Authentication required to mark attendance.',
      );
    }

    Map<String, dynamic> data;
    if (options.data is Map<String, dynamic>) {
      data = options.data as Map<String, dynamic>;
    } else {
      return respondError(
        options,
        handler,
        statusCode: 400,
        code: 'BAD_REQUEST',
        message: 'Invalid scan request body format.',
      );
    }

    final rawPayload = data['qrPayload'] as String? ?? '';
    final typeString = data['type'] as String? ?? 'CHECK_IN';
    final latitude = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (data['longitude'] as num?)?.toDouble() ?? 0.0;

    if (rawPayload.isEmpty) {
      return respondError(
        options,
        handler,
        statusCode: 400,
        code: 'INVALID_QR',
        message: 'Scanned payload is empty.',
      );
    }

    QrSessionModel sessionModel;
    try {
      sessionModel = QrSessionModel.fromRawPayload(rawPayload);
    } catch (_) {
      return respondError(
        options,
        handler,
        statusCode: 400,
        code: 'INVALID_SIGNATURE',
        message: 'Malformed or unrecognizable QR code payload.',
      );
    }

    final user = User(
      id: authUser.id,
      employeeId: authUser.employeeId,
      name: authUser.name,
      email: authUser.email,
      role: UserRole.fromString(authUser.role),
    );

    final validationContext = QrValidationContext(
      session: sessionModel,
      user: user,
      attendanceType: AttendanceType.fromString(typeString),
      scanTimestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      hmacSecret: AppConstants.hmacSecret,
      usedNonces: MockAttendanceStore.usedNonces,
      userAttendanceRecords: MockAttendanceStore.recordedAttendance,
    );

    const validator = QrValidator();
    final validationResult = await validator.validate(validationContext);

    if (validationResult.isFailure) {
      final failure = validationResult.error!;
      int statusCode = 400;
      if (failure.code == 'FORBIDDEN') statusCode = 403;
      if (failure.code == 'UNAUTHORIZED') statusCode = 401;

      return respondError(
        options,
        handler,
        statusCode: statusCode,
        code: failure.code ?? 'VALIDATION_FAILED',
        message: failure.message,
      );
    }

    // Validation passed: Mark single-use nonce as consumed
    MockAttendanceStore.usedNonces.add(sessionModel.nonce);

    final newRecord = AttendanceRecord(
      id: MockAttendanceStore.recordedAttendance.length + 1,
      employeeId: user.employeeId,
      type: AttendanceType.fromString(typeString),
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      sessionId: sessionModel.sessionId,
      synced: true,
    );

    MockAttendanceStore.recordedAttendance.add(newRecord);

    return respondSuccess(
      options,
      handler,
      data: {
        'id': newRecord.id,
        'employeeId': newRecord.employeeId,
        'type': newRecord.type.toTypeString(),
        'timestamp': newRecord.timestamp.toIso8601String(),
        'latitude': newRecord.latitude,
        'longitude': newRecord.longitude,
        'sessionId': newRecord.sessionId,
        'synced': true,
      },
    );
  }

  void _handleGetAttendanceHistory(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final user = _getAuthenticatedUser(options);
    if (user == null) {
      return respondUnauthorized(options, handler);
    }

    final userRecords = MockAttendanceStore.recordedAttendance
        .where((r) => r.employeeId == user.employeeId)
        .map((r) => {
              'id': r.id,
              'employeeId': r.employeeId,
              'type': r.type.toTypeString(),
              'timestamp': r.timestamp.toIso8601String(),
              'latitude': r.latitude,
              'longitude': r.longitude,
              'sessionId': r.sessionId,
              'synced': true,
            })
        .toList();

    return respondSuccess(options, handler, data: userRecords);
  }

  /// GET /attendance/me: Returns only the logged-in employee's attendance records.
  void _handleGetMyAttendance(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final user = _getAuthenticatedUser(options);
    if (user == null) {
      return respondUnauthorized(
        options,
        handler,
        code: 'UNAUTHORIZED',
        message: 'Invalid or missing authentication token',
      );
    }

    final records = MockAttendanceStore.recordedAttendance
        .where((r) => r.employeeId == user.employeeId)
        .toList();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final data = records
        .map((r) => {
              'id': r.id,
              'employeeId': r.employeeId,
              'type': r.type.toTypeString(),
              'timestamp': r.timestamp.toIso8601String(),
              'latitude': r.latitude,
              'longitude': r.longitude,
              'sessionId': r.sessionId,
              'synced': r.synced,
            })
        .toList();

    return respondSuccess(options, handler, data: data);
  }

  /// POST /attendance/record: Uploads an offline-recorded attendance item and marks it synced.
  void _handleUploadAttendanceRecord(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final user = _getAuthenticatedUser(options);
    if (user == null) {
      return respondUnauthorized(options, handler);
    }
    // Role check: Only employees can record attendance
    if (user.role != 'employee') {
      return respondForbidden(
        options,
        handler,
        code: 'FORBIDDEN',
        message: 'Only employees are authorized to record attendance.',
      );
    }

    final data = options.data is Map<String, dynamic>
        ? options.data as Map<String, dynamic>
        : jsonDecode(options.data.toString()) as Map<String, dynamic>;

    final employeeId = data['employeeId'] as String? ?? user.employeeId;
    final typeStr = data['type'] as String? ?? 'CHECK_IN';
    final type = AttendanceType.fromString(typeStr);
    final timestamp = data['timestamp'] != null
        ? DateTime.parse(data['timestamp'] as String)
        : DateTime.now();
    final latitude = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final sessionId = data['sessionId'] as String? ?? 'OFFLINE-SYNC';

    // Prevent duplicate upload if same sessionId + employeeId + type already exists
    final alreadyExists = MockAttendanceStore.recordedAttendance.any((r) =>
        r.employeeId == employeeId &&
        r.type == type &&
        r.timestamp.year == timestamp.year &&
        r.timestamp.month == timestamp.month &&
        r.timestamp.day == timestamp.day);

    if (alreadyExists) {
      final existing = MockAttendanceStore.recordedAttendance.firstWhere((r) =>
          r.employeeId == employeeId &&
          r.type == type &&
          r.timestamp.year == timestamp.year &&
          r.timestamp.month == timestamp.month &&
          r.timestamp.day == timestamp.day);
      return respondSuccess(options, handler, data: {
        'id': existing.id,
        'employeeId': existing.employeeId,
        'type': existing.type.toTypeString(),
        'timestamp': existing.timestamp.toIso8601String(),
        'latitude': existing.latitude,
        'longitude': existing.longitude,
        'sessionId': existing.sessionId,
        'synced': true,
      });
    }

    final newId = MockAttendanceStore.recordedAttendance.length + 1;
    final record = AttendanceRecord(
      id: newId,
      employeeId: employeeId,
      type: type,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      sessionId: sessionId,
      synced: true,
    );
    MockAttendanceStore.recordedAttendance.add(record);

    return respondSuccess(
      options,
      handler,
      statusCode: 201,
      data: {
        'id': record.id,
        'employeeId': record.employeeId,
        'type': record.type.toTypeString(),
        'timestamp': record.timestamp.toIso8601String(),
        'latitude': record.latitude,
        'longitude': record.longitude,
        'sessionId': record.sessionId,
        'synced': true,
      },
    );
  }

  /// GET /admin/employees: Returns all employees (admin only).
  void _handleGetAdminEmployees(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final user = _getAuthenticatedUser(options);
    if (user == null) {
      return respondUnauthorized(options, handler);
    }
    if (user.role != 'admin') {
      return respondForbidden(
        options,
        handler,
        code: 'FORBIDDEN',
        message: 'Administrator privilege required.',
      );
    }

    final employees = DummyUsersStore.users
        .where((u) => u.role == 'employee')
        .map((u) => {
              'id': u.id,
              'employeeId': u.employeeId,
              'name': u.name,
              'email': u.email,
              'role': u.role,
              'department': 'Operations',
            })
        .toList();

    return respondSuccess(options, handler, data: employees);
  }

  /// GET /admin/attendance: Returns filtered attendance records with employee names (admin only).
  void _handleGetAdminAttendance(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final user = _getAuthenticatedUser(options);
    if (user == null) {
      return respondUnauthorized(options, handler);
    }
    if (user.role != 'admin') {
      return respondForbidden(
        options,
        handler,
        code: 'FORBIDDEN',
        message: 'Administrator privilege required.',
      );
    }

    final dateFilter = options.queryParameters['date'] as String?;
    final employeeIdFilter = options.queryParameters['employeeId'] as String?;

    var records = List<AttendanceRecord>.from(MockAttendanceStore.recordedAttendance);

    if (employeeIdFilter != null &&
        employeeIdFilter.isNotEmpty &&
        employeeIdFilter != 'ALL') {
      records = records.where((r) => r.employeeId == employeeIdFilter).toList();
    }

    if (dateFilter != null && dateFilter.isNotEmpty) {
      final parsedDate = DateTime.tryParse(dateFilter);
      if (parsedDate != null) {
        records = records.where((r) =>
            r.timestamp.year == parsedDate.year &&
            r.timestamp.month == parsedDate.month &&
            r.timestamp.day == parsedDate.day).toList();
      }
    }

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final enrichedRecords = records.map((r) {
      final emp = DummyUsersStore.findByIdentifier(r.employeeId);
      return {
        'id': r.id,
        'employeeId': r.employeeId,
        'employeeName': emp?.name ?? 'Employee ${r.employeeId}',
        'type': r.type.toTypeString(),
        'timestamp': r.timestamp.toIso8601String(),
        'latitude': r.latitude,
        'longitude': r.longitude,
        'sessionId': r.sessionId,
        'synced': r.synced,
      };
    }).toList();

    return respondSuccess(options, handler, data: enrichedRecords);
  }

  /// GET /admin/summary: Computes total employees, present today, and checked out today (admin only).
  void _handleGetAdminSummary(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final user = _getAuthenticatedUser(options);
    if (user == null) {
      return respondUnauthorized(options, handler);
    }
    if (user.role != 'admin') {
      return respondForbidden(
        options,
        handler,
        code: 'FORBIDDEN',
        message: 'Administrator privilege required.',
      );
    }

    final totalEmployees = DummyUsersStore.users.where((u) => u.role == 'employee').length;

    final now = DateTime.now();
    final todayRecords = MockAttendanceStore.recordedAttendance.where((r) =>
        r.timestamp.year == now.year &&
        r.timestamp.month == now.month &&
        r.timestamp.day == now.day).toList();

    // Sort today's records chronologically to find the latest action per employee
    todayRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final Map<String, AttendanceType> latestAction = {};
    for (final rec in todayRecords) {
      latestAction[rec.employeeId] = rec.type;
    }

    final presentCount =
        latestAction.values.where((t) => t == AttendanceType.checkIn).length;
    final checkedOutCount =
        latestAction.values.where((t) => t == AttendanceType.checkOut).length;

    return respondSuccess(
      options,
      handler,
      data: {
        'totalEmployees': totalEmployees,
        'presentToday': presentCount,
        'checkedOutToday': checkedOutCount,
      },
    );
  }

  // ===================== Authentication Helper =====================

  DummyUser? _getAuthenticatedUser(RequestOptions options) {
    final authHeader = options.headers['Authorization'] as String?;
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }

    final token = authHeader.substring(7);
    final parts = token.split('-');
    if (parts.length >= 3) {
      final userId = parts[2];
      return DummyUsersStore.findById(userId);
    }

    return DummyUsersStore.users.first;
  }

  // ===================== Standardized Response Helpers =====================

  void respondSuccess(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    required dynamic data,
    int statusCode = 200,
  }) {
    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: statusCode,
        data: {
          'success': true,
          'data': data,
        },
      ),
    );
  }

  void respondError(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    required int statusCode,
    required String code,
    required String message,
  }) {
    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode,
          data: {
            'success': false,
            'code': code,
            'message': message,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  void respondUnauthorized(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String code = 'UNAUTHORIZED',
    String message = 'Authentication required or invalid credentials',
  }) {
    respondError(
      options,
      handler,
      statusCode: 401,
      code: code,
      message: message,
    );
  }

  void respondForbidden(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String code = 'FORBIDDEN',
    String message = 'You do not have permission to perform this action',
  }) {
    respondError(
      options,
      handler,
      statusCode: 403,
      code: code,
      message: message,
    );
  }

  void respondNotFound(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String code = 'NOT_FOUND',
    String message = 'The requested resource was not found',
  }) {
    respondError(
      options,
      handler,
      statusCode: 404,
      code: code,
      message: message,
    );
  }

  void respondServerError(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String code = 'SERVER_ERROR',
    String message = 'Internal server error occurred',
  }) {
    respondError(
      options,
      handler,
      statusCode: 500,
      code: code,
      message: message,
    );
  }

  void respondTimeout(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String message = 'Connection timed out',
  }) {
    handler.reject(
      DioException(
        requestOptions: options,
        message: message,
        type: DioExceptionType.connectionTimeout,
      ),
    );
  }
}
