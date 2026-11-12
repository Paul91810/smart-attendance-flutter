import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'mock_attendance_store.dart';
import 'network_info.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;
  final bool isSimulated;

  const ConnectivityState({
    required this.status,
    this.isSimulated = false,
  });

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;

  @override
  List<Object?> get props => [status, isSimulated];
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final NetworkInfo networkInfo;
  StreamSubscription<bool>? _subscription;
  bool _initialized = false;

  ConnectivityCubit({required this.networkInfo})
      : super(const ConnectivityState(status: ConnectivityStatus.online)) {
    _init();
  }

  Future<void> _init() async {
    final connected = await networkInfo.isConnected;
    if (_initialized || isClosed) return;
    _initialized = true;

    final newState = ConnectivityState(
      status: connected ? ConnectivityStatus.online : ConnectivityStatus.offline,
      isSimulated: MockAttendanceStore.simulateOffline,
    );
    if (newState != state) {
      emit(newState);
    }

    _subscription = networkInfo.onConnectivityChanged.listen((isConnected) {
      if (!MockAttendanceStore.simulateOffline) {
        final nextStatus = isConnected
            ? ConnectivityStatus.online
            : ConnectivityStatus.offline;
        final nextState = ConnectivityState(
          status: nextStatus,
          isSimulated: false,
        );
        if (nextState != state) {
          emit(nextState);
        }
      }
    });
  }

  Future<void> checkConnectivity() async {
    _initialized = true;
    final connected = await networkInfo.isConnected;
    emit(ConnectivityState(
      status: connected ? ConnectivityStatus.online : ConnectivityStatus.offline,
      isSimulated: MockAttendanceStore.simulateOffline,
    ));
  }

  void toggleSimulateOffline() {
    _initialized = true;
    final newSimulated = !MockAttendanceStore.simulateOffline;
    MockAttendanceStore.simulateOffline = newSimulated;
    emit(ConnectivityState(
      status: newSimulated ? ConnectivityStatus.offline : ConnectivityStatus.online,
      isSimulated: newSimulated,
    ));
  }

  void setSimulateOffline(bool simulated) {
    _initialized = true;
    MockAttendanceStore.simulateOffline = simulated;
    emit(ConnectivityState(
      status: simulated ? ConnectivityStatus.offline : ConnectivityStatus.online,
      isSimulated: simulated,
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
