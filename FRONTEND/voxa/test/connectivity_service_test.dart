import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxa/core/services/connectivity_service.dart';

void main() {
  test('Ethernet não é tratada como Wi-Fi', () {
    expect(
      ConnectivityService.statusFromResults([ConnectivityResult.ethernet]),
      NetworkStatus.offline,
    );
  });

  test('somente Wi-Fi permite sincronização', () {
    expect(
      ConnectivityService.statusFromResults([ConnectivityResult.wifi]),
      NetworkStatus.wifi,
    );
  });
}
