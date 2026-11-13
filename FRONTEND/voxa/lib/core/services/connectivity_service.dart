import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Tipo de rede disponível no momento.
enum NetworkStatus { offline, wifi, mobile }

/// Observa a rede do aparelho. A sincronização só roda em [NetworkStatus.wifi]
/// (Correções, item 3: "não suportada com dados móveis").
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<NetworkStatus> get changes =>
      _connectivity.onConnectivityChanged.map(_toStatus).distinct();

  Future<NetworkStatus> current() async =>
      _toStatus(await _connectivity.checkConnectivity());

  static NetworkStatus _toStatus(List<ConnectivityResult> results) {
    // Cabo de rede conta como Wi-Fi (sem custo de dados móveis).
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return NetworkStatus.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkStatus.mobile;
    }
    return NetworkStatus.offline;
  }
}
