import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final locationPermissionProvider =
    NotifierProvider<LocationPermissionNotifier, PermissionStatus>(
      LocationPermissionNotifier.new,
    );

class LocationPermissionNotifier extends Notifier<PermissionStatus> {
  @override
  PermissionStatus build() => PermissionStatus.denied;

  Future<void> check() async {
    state = await Permission.locationWhenInUse.status;
  }

  Future<void> request() async {
    state = await Permission.locationWhenInUse.request();
  }

  Future<void> requestBackground() async {
    final foreground = await Permission.locationWhenInUse.status;
    if (!foreground.isGranted) {
      state = await Permission.locationWhenInUse.request();
      if (!state.isGranted) return;
    }
    await Permission.locationAlways.request();
  }

  Future<void> requestNotification() async {
    await Permission.notification.request();
  }
}
