import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/core/services/location_service.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/features/attendance/domain/usecases/mark_attendance_usecase.dart';
import 'package:smart_attendance/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:smart_attendance/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:smart_attendance/features/attendance/presentation/bloc/attendance_state.dart';

class MockLocationService extends Mock implements LocationService {}

class MockMarkAttendanceUsecase extends Mock implements MarkAttendanceUsecase {}

void main() {
  late MockLocationService mockLocationService;
  late MockMarkAttendanceUsecase mockMarkAttendanceUsecase;

  setUpAll(() {
    registerFallbackValue(
      const MarkAttendanceParams(
        qrPayload: '',
        type: AttendanceType.checkIn,
        latitude: 0,
        longitude: 0,
      ),
    );
  });

  setUp(() {
    mockLocationService = MockLocationService();
    mockMarkAttendanceUsecase = MockMarkAttendanceUsecase();
  });

  const testPosition = UserPosition(
    latitude: 12.9716,
    longitude: 77.5946,
    accuracy: 10.0,
  );

  final testRecord = AttendanceRecord(
    id: 1,
    employeeId: 'EMP001',
    type: AttendanceType.checkIn,
    timestamp: DateTime.now(),
    latitude: 12.9716,
    longitude: 77.5946,
    sessionId: 'SES-001',
    synced: true,
  );

  test('initial state is AttendanceScanning with checkIn mode', () {
    final bloc = AttendanceBloc(
      locationService: mockLocationService,
      markAttendanceUsecase: mockMarkAttendanceUsecase,
    );
    expect(bloc.state, const AttendanceScanning(type: AttendanceType.checkIn));
    bloc.close();
  });

  blocTest<AttendanceBloc, AttendanceState>(
    'ModeChanged updates state to selected mode',
    build: () => AttendanceBloc(
      locationService: mockLocationService,
      markAttendanceUsecase: mockMarkAttendanceUsecase,
    ),
    act: (bloc) => bloc.add(const ModeChanged(AttendanceType.checkOut)),
    expect: () => [
      const AttendanceScanning(type: AttendanceType.checkOut),
    ],
  );

  blocTest<AttendanceBloc, AttendanceState>(
    'ScanReceived emits [AttendanceProcessing, AttendanceFailureState] when location disabled',
    build: () {
      when(() => mockLocationService.getCurrentPosition()).thenAnswer(
        (_) async => const Result.failure(
          LocationFailure(
            'GPS disabled',
            code: 'LOCATION_DISABLED',
          ),
        ),
      );
      return AttendanceBloc(
        locationService: mockLocationService,
        markAttendanceUsecase: mockMarkAttendanceUsecase,
      );
    },
    act: (bloc) => bloc.add(const ScanReceived('{"valid":"payload"}')),
    expect: () => [
      const AttendanceProcessing(type: AttendanceType.checkIn),
      const AttendanceFailureState(
        code: 'LOCATION_DISABLED',
        message: 'GPS disabled',
        type: AttendanceType.checkIn,
      ),
    ],
  );

  blocTest<AttendanceBloc, AttendanceState>(
    'ScanReceived emits [AttendanceProcessing, AttendanceSuccess] on valid GPS and payload',
    build: () {
      when(() => mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => const Result.success(testPosition));
      when(() => mockMarkAttendanceUsecase(any()))
          .thenAnswer((_) async => Result.success(testRecord));
      return AttendanceBloc(
        locationService: mockLocationService,
        markAttendanceUsecase: mockMarkAttendanceUsecase,
      );
    },
    act: (bloc) => bloc.add(const ScanReceived('{"valid":"payload"}')),
    expect: () => [
      const AttendanceProcessing(type: AttendanceType.checkIn),
      AttendanceSuccess(record: testRecord),
    ],
  );

  blocTest<AttendanceBloc, AttendanceState>(
    'ScanReceived emits [AttendanceProcessing, AttendanceFailureState] on validation failure',
    build: () {
      when(() => mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => const Result.success(testPosition));
      when(() => mockMarkAttendanceUsecase(any())).thenAnswer(
        (_) async => const Result.failure(
          QrValidationFailure('QR expired', code: 'QR_EXPIRED'),
        ),
      );
      return AttendanceBloc(
        locationService: mockLocationService,
        markAttendanceUsecase: mockMarkAttendanceUsecase,
      );
    },
    act: (bloc) => bloc.add(const ScanReceived('{"expired":"payload"}')),
    expect: () => [
      const AttendanceProcessing(type: AttendanceType.checkIn),
      const AttendanceFailureState(
        code: 'QR_EXPIRED',
        message: 'QR expired',
        type: AttendanceType.checkIn,
      ),
    ],
  );

  blocTest<AttendanceBloc, AttendanceState>(
    'ResetAttendanceState returns state to AttendanceScanning',
    build: () => AttendanceBloc(
      locationService: mockLocationService,
      markAttendanceUsecase: mockMarkAttendanceUsecase,
    ),
    seed: () => AttendanceSuccess(record: testRecord),
    act: (bloc) => bloc.add(const ResetAttendanceState()),
    expect: () => [
      const AttendanceScanning(type: AttendanceType.checkIn),
    ],
  );
}

