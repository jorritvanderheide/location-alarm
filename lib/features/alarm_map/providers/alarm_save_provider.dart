import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_service/providers/alarm_service_provider.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';
import 'package:location_alarm/shared/providers/geocoding_provider.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';
import 'package:location_alarm/shared/providers/location_settings_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final alarmSaveProvider = NotifierProvider<AlarmSaveNotifier, AlarmSaveState>(
  AlarmSaveNotifier.new,
);

// -- State --

sealed class AlarmSaveState {
  const AlarmSaveState();
}

final class AlarmSaveIdle extends AlarmSaveState {
  const AlarmSaveIdle();
}

final class AlarmSaveBusy extends AlarmSaveState {
  const AlarmSaveBusy();
}

/// Provider pauses, UI should show rationale dialog and call [AlarmSaveNotifier.confirmStep].
final class AlarmSaveNeedsConfirmation extends AlarmSaveState {
  const AlarmSaveNeedsConfirmation(this.step);
  final SaveConfirmationStep step;
}

sealed class SaveConfirmationStep {
  const SaveConfirmationStep();
}

final class BackgroundLocationRationale extends SaveConfirmationStep {
  const BackgroundLocationRationale();
}

final class BatteryOptimizationRationale extends SaveConfirmationStep {
  const BatteryOptimizationRationale();
}

final class InsideRadiusWarning extends SaveConfirmationStep {
  const InsideRadiusWarning();
}

/// Provider pauses, UI should capture map thumbnail and call [AlarmSaveNotifier.provideThumbnail].
final class AlarmSaveNeedsThumbnail extends AlarmSaveState {
  const AlarmSaveNeedsThumbnail();
}

final class AlarmSaveNotificationDenied extends AlarmSaveState {
  const AlarmSaveNotificationDenied();
}

final class AlarmSaved extends AlarmSaveState {
  const AlarmSaved(this.message);
  final String message;
}

final class AlarmSaveFailed extends AlarmSaveState {
  const AlarmSaveFailed(this.message);
  final String message;
}

// -- Notifier --

class AlarmSaveNotifier extends Notifier<AlarmSaveState> {
  // Stored between async steps.
  int? _alarmId;
  String _name = '';
  LatLng? _location;
  double _radius = 500;
  Uint8List? _thumbnail;

  @override
  AlarmSaveState build() => const AlarmSaveIdle();

  void reset() => state = const AlarmSaveIdle();

  /// Start the save flow.
  Future<void> save({
    required int? alarmId,
    required String name,
    required LatLng location,
    required double radius,
  }) async {
    if (state is! AlarmSaveIdle) return;
    _alarmId = alarmId;
    _name = name;
    _location = location;
    _radius = radius;
    _thumbnail = null;

    state = const AlarmSaveBusy();

    // Step 1: Foreground location.
    final fgStatus = await Permission.locationWhenInUse.status;
    if (!fgStatus.isGranted) {
      await ref.read(locationPermissionProvider.notifier).request();
      if (ref.read(locationPermissionProvider) != PermissionStatus.granted) {
        state = const AlarmSaveFailed('Location permission required');
        return;
      }
    }

    // Step 2: Background location — needs rationale dialog.
    if (!(await Permission.locationAlways.status).isGranted) {
      state = const AlarmSaveNeedsConfirmation(BackgroundLocationRationale());
      return;
    }

    await _continueAfterBackground();
  }

  /// Called by UI after background location rationale dialog.
  Future<void> confirmStep(bool confirmed) async {
    if (state is! AlarmSaveNeedsConfirmation) return;
    final step = (state as AlarmSaveNeedsConfirmation).step;

    state = const AlarmSaveBusy();

    switch (step) {
      case BackgroundLocationRationale():
        if (!confirmed) {
          state = const AlarmSaveFailed(
            'Background location required to save alarm',
          );
          return;
        }
        final granted = await ref
            .read(locationPermissionProvider.notifier)
            .requestBackground();
        if (!granted) {
          state = const AlarmSaveFailed(
            'Background location required to save alarm',
          );
          return;
        }
        await _continueAfterBackground();

      case BatteryOptimizationRationale():
        if (confirmed) {
          await ref
              .read(locationPermissionProvider.notifier)
              .requestBatteryOptimization();
        }
        await _continueAfterBattery();

      case InsideRadiusWarning():
        if (!confirmed) {
          state = const AlarmSaveIdle();
          return;
        }
        await _continueAfterInsideRadius();
    }
  }

  Future<void> _continueAfterBackground() async {
    // Step 3: Notification permission.
    final notifGranted = await ref
        .read(locationPermissionProvider.notifier)
        .requestNotification();
    if (!notifGranted) {
      // Warn but don't block — emit event and continue.
      state = const AlarmSaveNotificationDenied();
      // Brief pause so UI can show snackbar before we continue.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    // Step 4: Battery optimization.
    if (!(await Permission.ignoreBatteryOptimizations.isGranted)) {
      state = const AlarmSaveNeedsConfirmation(BatteryOptimizationRationale());
      return;
    }

    await _continueAfterBattery();
  }

  Future<void> _continueAfterBattery() async {
    // Step 5: Request thumbnail from UI.
    state = const AlarmSaveNeedsThumbnail();
  }

  /// Called by UI after capturing the map thumbnail.
  Future<void> provideThumbnail(Uint8List? thumbnail) async {
    _thumbnail = thumbnail;
    state = const AlarmSaveBusy();

    // Step 6: Check if inside radius.
    final position = ref.read(locationProvider).whenData((p) => p).value;
    final hasLocationLock = position != null;
    final isInsideRadius =
        hasLocationLock &&
        distanceInMeters(
              LatLng(position.latitude, position.longitude),
              _location!,
            ) <=
            _radius;

    final triggerInside = ref.read(triggerInsideRadiusProvider);
    if (isInsideRadius && !triggerInside) {
      state = const AlarmSaveNeedsConfirmation(InsideRadiusWarning());
      return;
    }

    await _writeAlarm(
      active: hasLocationLock && !(isInsideRadius && !triggerInside),
      hasLocationLock: hasLocationLock,
      isInsideRadius: isInsideRadius,
    );
  }

  Future<void> _continueAfterInsideRadius() async {
    await _writeAlarm(
      active: false,
      hasLocationLock: true,
      isInsideRadius: true,
    );
  }

  Future<void> _writeAlarm({
    required bool active,
    required bool hasLocationLock,
    required bool isInsideRadius,
  }) async {
    state = const AlarmSaveBusy();

    try {
      // Reverse geocode for location name.
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final locationName =
          await geocodingRepo.reverseGeocode(_location!, radius: _radius) ?? '';
      final alarmName = _name.isEmpty ? locationName : _name;

      final alarm = AlarmData(
        id: _alarmId,
        name: alarmName,
        location: _location!,
        active: active,
        radius: _radius,
        locationName: locationName,
      );

      // Save thumbnail.
      if (_thumbnail != null && _alarmId != null) {
        try {
          await AlarmThumbnail.save(_alarmId!, _thumbnail!);
        } on Exception {
          // non-critical
        }
      }

      final repo = ref.read(alarmRepositoryProvider);
      final savedId = await repo.save(alarm);
      AlarmServiceNotifier.refresh();

      if (_thumbnail != null && _alarmId == null) {
        try {
          await AlarmThumbnail.save(savedId, _thumbnail!);
        } on Exception {
          // non-critical
        }
      }

      final label = _name.isEmpty ? 'Alarm' : _name;
      final String message;
      if (!hasLocationLock) {
        message = '$label saved (inactive — no GPS lock)';
      } else if (isInsideRadius) {
        message = '$label saved (inactive)';
      } else {
        message = '$label saved';
      }

      state = AlarmSaved(message);
    } on Exception catch (e) {
      state = AlarmSaveFailed('Save failed: $e');
    }
  }
}
