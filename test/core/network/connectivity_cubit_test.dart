import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/network/connectivity_cubit.dart';
import 'package:smart_attendance/core/network/mock_attendance_store.dart';
import 'package:smart_attendance/core/network/network_info.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<bool> connectivityController;

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    connectivityController = StreamController<bool>.broadcast();
    MockAttendanceStore.simulateOffline = false;

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkInfo.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() {
    connectivityController.close();
    MockAttendanceStore.simulateOffline = false;
  });

  group('ConnectivityCubit', () {
    test('initial state has online status', () {
      final cubit = ConnectivityCubit(networkInfo: mockNetworkInfo);
      expect(cubit.state.status, ConnectivityStatus.online);
      expect(cubit.state.isOnline, isTrue);
      expect(cubit.state.isOffline, isFalse);
      expect(cubit.state.isSimulated, isFalse);
    });

    blocTest<ConnectivityCubit, ConnectivityState>(
      'toggles simulated offline state',
      build: () => ConnectivityCubit(networkInfo: mockNetworkInfo),
      act: (cubit) => cubit.toggleSimulateOffline(),
      expect: () => [
        const ConnectivityState(
          status: ConnectivityStatus.offline,
          isSimulated: true,
        ),
      ],
    );

    blocTest<ConnectivityCubit, ConnectivityState>(
      'sets simulated offline to false after true',
      build: () => ConnectivityCubit(networkInfo: mockNetworkInfo),
      act: (cubit) {
        cubit.setSimulateOffline(true);
        cubit.setSimulateOffline(false);
      },
      expect: () => [
        const ConnectivityState(
          status: ConnectivityStatus.offline,
          isSimulated: true,
        ),
        const ConnectivityState(
          status: ConnectivityStatus.online,
          isSimulated: false,
        ),
      ],
    );

    blocTest<ConnectivityCubit, ConnectivityState>(
      'reacts to real network connectivity drop',
      build: () => ConnectivityCubit(networkInfo: mockNetworkInfo),
      act: (cubit) async {
        // Wait for _init to register listener
        await Future<void>.delayed(const Duration(milliseconds: 50));
        connectivityController.add(false);
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ConnectivityState(
          status: ConnectivityStatus.offline,
          isSimulated: false,
        ),
      ],
    );
  });
}

