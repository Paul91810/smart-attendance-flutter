import 'package:connectivity_plus/connectivity_plus.dart';

/// Contract for checking internet connectivity.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementation using connectivity_plus.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final results = await connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
