import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class MarkAttendanceParams extends Equatable {
  final String qrPayload;
  final AttendanceType type;
  final double latitude;
  final double longitude;

  const MarkAttendanceParams({
    required this.qrPayload,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [qrPayload, type, latitude, longitude];
}

class MarkAttendanceUsecase {
  final AttendanceRepository _repository;

  const MarkAttendanceUsecase(this._repository);

  Future<Result<Failure, AttendanceRecord>> call(MarkAttendanceParams params) {
    if (params.qrPayload.trim().isEmpty) {
      return Future.value(
        const Result.failure(
          QrValidationFailure(
            'QR code payload cannot be empty.',
            code: 'INVALID_QR',
          ),
        ),
      );
    }

    return _repository.markAttendance(
      qrPayload: params.qrPayload,
      type: params.type,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

