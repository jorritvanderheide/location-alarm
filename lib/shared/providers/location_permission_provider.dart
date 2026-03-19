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
}
