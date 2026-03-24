import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:there_yet/features/alarm_service/providers/alarm_service_provider.dart';
import 'package:there_yet/shared/data/geo_utils.dart';
import 'package:there_yet/shared/data/models/alarm.dart';
import 'package:there_yet/shared/providers/alarm_repository_provider.dart';
import 'package:there_yet/shared/providers/location_permission_provider.dart';
import 'package:there_yet/shared/providers/location_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final alarmActivationProvider =
    NotifierProvider<AlarmActivationNotifier, AlarmActivationState>(
      AlarmActivationNotifier.new,
    );

final class AlarmActivationState {
  const AlarmActivationState({
    this.activatingIds = const {},
    this.lastEvent = const AlarmActivationIdle(),
  });

  final Set<int> activatingIds;
  final AlarmActivationEvent lastEvent;

  AlarmActivationState copyWith({
    Set<int>? activatingIds,
    AlarmActivationEvent? lastEvent,
  }) => AlarmActivationState(
    activatingIds: activatingIds ?? this.activatingIds,
    lastEvent: lastEvent ?? this.lastEvent,
  );
}

sealed class AlarmActivationEvent {
  const AlarmActivationEvent();
}

final class AlarmActivationIdle extends AlarmActivationEvent {
  const AlarmActivationIdle();
}

final class AlarmDeactivated extends AlarmActivationEvent {
  const AlarmDeactivated(this.alarmName);
  final String alarmName;
}

final class AlarmActivated extends AlarmActivationEvent {
  const AlarmActivated(this.alarmName, this.distance);
  final String alarmName;
  final double distance;
}

final class AlarmActivationNeedsForeground extends AlarmActivationEvent {
  const AlarmActivationNeedsForeground();
}

/// UI should show the background location rationale dialog,
/// then call [AlarmActivationNotifier.continueWithBackground].
final class AlarmActivationNeedsBackgroundRationale
    extends AlarmActivationEvent {
  const AlarmActivationNeedsBackgroundRationale(this.alarmId);
  final int alarmId;
}

/// UI should show the battery optimization rationale dialog,
/// then call [AlarmActivationNotifier.continueWithBattery].
final class AlarmActivationNeedsBatteryRationale extends AlarmActivationEvent {
  const AlarmActivationNeedsBatteryRationale(this.alarmId);
  final int alarmId;
}

final class AlarmActivationNotificationDenied extends AlarmActivationEvent {
  const AlarmActivationNotificationDenied();
}

final class AlarmActivationInsideRadius extends AlarmActivationEvent {
  const AlarmActivationInsideRadius(this.alarmName, this.distance, this.radius);
  final String alarmName;
  final double distance;
  final double radius;
}

final class AlarmActivationGpsDisabled extends AlarmActivationEvent {
  const AlarmActivationGpsDisabled();
}

final class AlarmActivationError extends AlarmActivationEvent {
  const AlarmActivationError(this.message);
  final String message;
}

class AlarmActivationNotifier extends Notifier<AlarmActivationState> {
  // Stored between async steps for multi-step flows, keyed by alarm ID.
  final Map<int, AlarmData> _pendingAlarms = {};

  @override
  AlarmActivationState build() => const AlarmActivationState();

  void consumeEvent() {
    state = state.copyWith(lastEvent: const AlarmActivationIdle());
  }

  bool isActivating(int id) => state.activatingIds.contains(id);

  Future<void> deactivate(AlarmData alarm) async {
    final id = alarm.id!;
    final name = alarm.name.isEmpty ? 'Alarm #$id' : alarm.name;

    final ids = {...state.activatingIds}..remove(id);
    state = AlarmActivationState(
      activatingIds: ids,
      lastEvent: AlarmDeactivated(name),
    );

    await ref.read(alarmRepositoryProvider).toggleActive(id, active: false);
  }

  Future<void> activate(AlarmData alarm) async {
    final id = alarm.id!;
    if (state.activatingIds.contains(id)) return;

    _pendingAlarms[id] = alarm;
    state = state.copyWith(activatingIds: {...state.activatingIds, id});

    final fgStatus = await Permission.locationWhenInUse.status;
    if (!fgStatus.isGranted) {
      await ref.read(locationPermissionProvider.notifier).request();
      if (ref.read(locationPermissionProvider) != PermissionStatus.granted) {
        _finish(id, const AlarmActivationNeedsForeground());
        return;
      }
    }

    if (!(await Permission.locationAlways.status).isGranted) {
      state = state.copyWith(
        lastEvent: AlarmActivationNeedsBackgroundRationale(id),
      );
      // UI will call continueWithBackground() after showing the dialog.
      return;
    }

    await _continueAfterPermissions(alarm);
  }

  /// Called by the UI after the background location rationale dialog.
  Future<void> continueWithBackground(int alarmId, bool confirmed) async {
    final alarm = _pendingAlarms[alarmId];
    if (alarm == null) return;

    if (!confirmed) {
      _finish(
        alarm.id!,
        const AlarmActivationError('Background location required'),
      );
      return;
    }

    final granted = await ref
        .read(locationPermissionProvider.notifier)
        .requestBackground();
    if (!granted) {
      _finish(
        alarm.id!,
        const AlarmActivationError('Background location required'),
      );
      return;
    }

    await _continueAfterPermissions(alarm);
  }

  Future<void> _continueAfterPermissions(AlarmData alarm) async {
    final id = alarm.id!;
    if (!state.activatingIds.contains(id)) return;

    final notifGranted = await ref
        .read(locationPermissionProvider.notifier)
        .requestNotification();
    if (!notifGranted) {
      state = state.copyWith(
        lastEvent: const AlarmActivationNotificationDenied(),
      );
      // Don't return; continue activation.
    }

    if (!(await Permission.ignoreBatteryOptimizations.isGranted)) {
      state = state.copyWith(
        lastEvent: AlarmActivationNeedsBatteryRationale(id),
      );
      // UI will call continueWithBattery() after showing the dialog.
      return;
    }

    await _continueAfterBattery(alarm);
  }

  /// Called by the UI after the battery optimization rationale dialog.
  Future<void> continueWithBattery(int alarmId, bool confirmed) async {
    final alarm = _pendingAlarms[alarmId];
    if (alarm == null) return;

    if (confirmed) {
      await ref
          .read(locationPermissionProvider.notifier)
          .requestBatteryOptimization();
    }

    await _continueAfterBattery(alarm);
  }

  Future<void> _continueAfterBattery(AlarmData alarm) async {
    final id = alarm.id!;
    if (!state.activatingIds.contains(id)) return;

    try {
      // Use pre-warmed position if available, otherwise request a fresh fix.
      final cachedPos = ref.read(bestPositionProvider);
      final LatLng currentLatLng;
      if (cachedPos != null) {
        currentLatLng = cachedPos;
      } else {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        if (!state.activatingIds.contains(id)) return;
        currentLatLng = LatLng(position.latitude, position.longitude);
      }
      final distance = distanceInMeters(currentLatLng, alarm.location);
      final name = alarm.name.isEmpty ? 'Alarm #$id' : alarm.name;
      if (distance <= alarm.radius) {
        _finish(id, AlarmActivationInsideRadius(name, distance, alarm.radius));
        return;
      }

      await ref.read(alarmRepositoryProvider).toggleActive(id, active: true);
      AlarmServiceNotifier.refresh();

      _finish(id, AlarmActivated(name, distance));
    } on LocationServiceDisabledException {
      _finish(id, const AlarmActivationGpsDisabled());
    } on Exception catch (e) {
      _finish(id, AlarmActivationError(e.toString()));
    }
  }

  void _finish(int id, AlarmActivationEvent event) {
    _pendingAlarms.remove(id);
    final ids = {...state.activatingIds}..remove(id);
    state = AlarmActivationState(activatingIds: ids, lastEvent: event);
  }
}
