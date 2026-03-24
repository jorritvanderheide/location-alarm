import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:there_yet/shared/providers/alarm_repository_provider.dart';

final alarmFormProvider =
    NotifierProvider.family<AlarmFormNotifier, AlarmFormState, int?>(
      AlarmFormNotifier.new,
    );

final class AlarmFormState {
  const AlarmFormState({
    this.alarmId,
    this.name = '',
    this.location,
    this.radius = 500,
    this.isLoaded = false,
    this.loadError = false,
    this.initialName = '',
    this.initialLocation,
    this.initialRadius = 500,
  });

  final int? alarmId;
  final String name;
  final LatLng? location;
  final double radius;
  final bool isLoaded;
  final bool loadError;
  final String initialName;
  final LatLng? initialLocation;
  final double initialRadius;

  bool get isNew => alarmId == null;

  bool get hasUnsavedChanges =>
      isLoaded &&
      (name != initialName ||
          location != initialLocation ||
          radius != initialRadius);

  bool get canSave => location != null && hasUnsavedChanges;

  AlarmFormState copyWith({
    int? alarmId,
    String? name,
    LatLng? location,
    double? radius,
    bool? isLoaded,
    bool? loadError,
    String? initialName,
    LatLng? initialLocation,
    double? initialRadius,
  }) => AlarmFormState(
    alarmId: alarmId ?? this.alarmId,
    name: name ?? this.name,
    location: location ?? this.location,
    radius: radius ?? this.radius,
    isLoaded: isLoaded ?? this.isLoaded,
    loadError: loadError ?? this.loadError,
    initialName: initialName ?? this.initialName,
    initialLocation: initialLocation ?? this.initialLocation,
    initialRadius: initialRadius ?? this.initialRadius,
  );
}

class AlarmFormNotifier extends Notifier<AlarmFormState> {
  AlarmFormNotifier(this.alarmId);

  final int? alarmId;

  @override
  AlarmFormState build() {
    if (alarmId != null) {
      _loadAlarm(alarmId!);
      return AlarmFormState(alarmId: alarmId);
    }
    return const AlarmFormState(isLoaded: true);
  }

  Future<void> _loadAlarm(int id) async {
    try {
      final alarm = await ref.read(alarmRepositoryProvider).getById(id);
      if (alarm == null) {
        state = state.copyWith(loadError: true);
        return;
      }
      state = AlarmFormState(
        alarmId: id,
        name: alarm.name,
        location: alarm.location,
        radius: alarm.radius,
        isLoaded: true,
        initialName: alarm.name,
        initialLocation: alarm.location,
        initialRadius: alarm.radius,
      );
    } on Exception {
      state = state.copyWith(loadError: true);
    }
  }

  void setName(String value) => state = state.copyWith(name: value);

  void setLocation(LatLng value) => state = state.copyWith(location: value);

  void setRadius(double value) => state = state.copyWith(radius: value);

  /// Mark current values as saved (resets dirty tracking).
  void markSaved() {
    state = state.copyWith(
      initialName: state.name,
      initialLocation: state.location,
      initialRadius: state.radius,
    );
  }
}
