import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_unsynced_records_usecase.dart';
import '../../../domain/usecases/sync_attendance_usecase.dart';

abstract class SyncState extends Equatable {
  final int pendingCount;
  const SyncState({this.pendingCount = 0});

  @override
  List<Object?> get props => [pendingCount];
}

class SyncIdle extends SyncState {
  const SyncIdle({super.pendingCount});
}

class SyncInProgress extends SyncState {
  const SyncInProgress({super.pendingCount});
}

class SyncSuccess extends SyncState {
  final int syncedCount;
  const SyncSuccess({required this.syncedCount, required int remainingPending})
      : super(pendingCount: remainingPending);

  @override
  List<Object?> get props => [syncedCount, pendingCount];
}

class SyncFailure extends SyncState {
  final String message;
  const SyncFailure({required this.message, super.pendingCount});

  @override
  List<Object?> get props => [message, pendingCount];
}

class SyncCubit extends Cubit<SyncState> {
  final SyncAttendanceUsecase syncAttendanceUsecase;
  final GetUnsyncedRecordsUsecase getUnsyncedRecordsUsecase;

  SyncCubit({
    required this.syncAttendanceUsecase,
    required this.getUnsyncedRecordsUsecase,
  }) : super(const SyncIdle()) {
    checkPendingCount();
  }

  Future<void> checkPendingCount() async {
    final result = await getUnsyncedRecordsUsecase();
    result.fold(
      (_) => null,
      (records) => emit(SyncIdle(pendingCount: records.length)),
    );
  }

  Future<void> syncRecords() async {
    final checkResult = await getUnsyncedRecordsUsecase();
    final currentCount = checkResult.fold((_) => 0, (r) => r.length);
    if (currentCount == 0) {
      emit(const SyncIdle(pendingCount: 0));
      return;
    }

    emit(SyncInProgress(pendingCount: currentCount));

    final result = await syncAttendanceUsecase();
    await result.fold(
      (failure) async {
        final recheck = await getUnsyncedRecordsUsecase();
        final count = recheck.fold((_) => currentCount, (r) => r.length);
        emit(SyncFailure(message: failure.message, pendingCount: count));
      },
      (syncedCount) async {
        final recheck = await getUnsyncedRecordsUsecase();
        final remaining = recheck.fold((_) => 0, (r) => r.length);
        emit(SyncSuccess(
          syncedCount: syncedCount,
          remainingPending: remaining,
        ));
      },
    );
  }
}
