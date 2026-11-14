import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tipo de rede disponível no momento.
enum NetworkStatus { offline, wifi, mobile }

/// Observa a rede do aparelho. A sincronização só roda em [NetworkStatus.wifi]
/// (Correções, item 3: "não suportada com dados móveis").
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<NetworkStatus> get changes =>
      _connectivity.onConnectivityChanged.map(statusFromResults).distinct();

  Future<NetworkStatus> current() async =>
      statusFromResults(await _connectivity.checkConnectivity());

  @visibleForTesting
  static NetworkStatus statusFromResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return NetworkStatus.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkStatus.mobile;
    }
    return NetworkStatus.offline;
  }
}
