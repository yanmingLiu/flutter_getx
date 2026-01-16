import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class Aether {
  static final Aether instance = Aether._();

  final _connectivity = Connectivity();

  final ValueNotifier<List<ConnectivityResult>> statusNotifier = ValueNotifier(
    [],
  );

  Aether._() {
    _check();
    _connectivity.onConnectivityChanged.listen((r) => statusNotifier.value = r);
  }

  List<ConnectivityResult> get status => statusNotifier.value;

  bool get isConnected =>
      status.isNotEmpty && !status.contains(ConnectivityResult.none);
  bool get isVpn => status.contains(ConnectivityResult.vpn);

  Future<void> _check() async {
    statusNotifier.value = await _connectivity.checkConnectivity();
  }

  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await _check();
    if (isConnected) return true;

    try {
      await _connectivity.onConnectivityChanged
          .firstWhere(
            (results) =>
                results.isNotEmpty &&
                !results.contains(ConnectivityResult.none),
          )
          .timeout(timeout);

      await _check();
      return true;
    } catch (_) {
      return false;
    }
  }
}
