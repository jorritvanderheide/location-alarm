import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _channel = MethodChannel('nl.bw20.location_alarm/screen');

/// Whether the device has network connectivity.
/// Uses Android's ConnectivityManager (no network requests).
/// Checked on app start and refreshed on app resume.
final connectivityProvider = NotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);

class ConnectivityNotifier extends Notifier<bool> {
  @override
  bool build() {
    check();
    return true;
  }

  Future<void> check() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasInternet');
      state = result ?? false;
    } on MissingPluginException {
      state = true;
    }
  }
}
