import 'package:connectivity_plus/connectivity_plus.dart';

/// A plain snapshot of the current connection, easy to fake in tests.
class NetworkStatus {
  const NetworkStatus({
    required this.onWifi,
    required this.onMobile,
    required this.online,
  });

  /// Wi-Fi, ethernet or VPN: treated as "unmetered enough" for auto-download.
  final bool onWifi;

  final bool onMobile;
  final bool online;

  /// Used when the platform channel is unavailable (tests, desktop): assume a
  /// connection that is not Wi-Fi, so nothing downloads without asking.
  static const unknown = NetworkStatus(onWifi: false, onMobile: false, online: true);
}

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<NetworkStatus> status() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final onWifi =
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet) ||
          results.contains(ConnectivityResult.vpn);
      final onMobile = results.contains(ConnectivityResult.mobile);
      final online = results.any(
        (result) => result != ConnectivityResult.none,
      );
      return NetworkStatus(onWifi: onWifi, onMobile: onMobile, online: online);
    } catch (_) {
      return NetworkStatus.unknown;
    }
  }
}
