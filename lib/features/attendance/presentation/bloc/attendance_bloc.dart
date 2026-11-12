import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/usecases/mark_attendance_usecase.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final LocationService locationService;
  final MarkAttendanceUsecase markAttendanceUsecase;

  AttendanceType _currentType = AttendanceType.checkIn;
  bool _isProcessing = false;

  AttendanceBloc({
    required this.locationService,
    required this.markAttendanceUsecase,
  }) : super(const AttendanceScanning()) {
    on<ModeChanged>(_onModeChanged);
    on<ScanReceived>(_onScanReceived);
    on<ResetAttendanceState>(_onResetAttendanceState);
  }

  void _onModeChanged(
    ModeChanged event,
    Emitter<AttendanceState> emit,
  ) {
    _currentType = event.type;
    emit(AttendanceScanning(type: _currentType));
  }

  void _onResetAttendanceState(
    ResetAttendanceState event,
    Emitter<AttendanceState> emit,
  ) {
    _isProcessing = false;
    emit(AttendanceScanning(type: _currentType));
  }

  Future<void> _onScanReceived(
    ScanReceived event,
    Emitter<AttendanceState> emit,
  ) async {
    // Guard against rapid duplicate scans
    if (_isProcessing) return;
    _isProcessing = true;

    emit(AttendanceProcessing(type: _currentType));

    // 1. Acquire device GPS coordinates
    final locationResult = await locationService.getCurrentPosition();

    await locationResult.fold(
      (locationFailure) async {
        _isProcessing = false;
        emit(AttendanceFailureState(
          code: locationFailure.code ?? 'LOCATION_ERROR',
          message: locationFailure.message,
          type: _currentType,
        ));
      },
      (position) async {
        // 2. Mark attendance with scanned payload + GPS
        final scanResult = await markAttendanceUsecase(
          MarkAttendanceParams(
            qrPayload: event.rawPayload,
            type: _currentType,
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );

        _isProcessing = false;

        scanResult.fold(
          (failure) {
            emit(AttendanceFailureState(
              code: failure.code ?? 'SCAN_FAILED',
              message: failure.message,
              type: _currentType,
            ));
          },
          (record) {
            emit(AttendanceSuccess(record: record));
          },
        );
      },
    );
  }
}
