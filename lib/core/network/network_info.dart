import 'package:connectivity_plus/connectivity_plus.dart';
import 'mock_attendance_store.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    if (MockAttendanceStore.simulateOffline) {
      return false;
    }
    final results = await connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map((results) {
      if (MockAttendanceStore.simulateOffline) {
        return false;
      }
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    });
  }
}
