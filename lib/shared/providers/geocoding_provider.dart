import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/datasources/geocoding_datasource.dart';
import 'package:location_alarm/shared/data/models/geocoding_result.dart';
import 'package:location_alarm/shared/data/repositories/geocoding_repository.dart';
import 'package:location_alarm/shared/providers/connectivity_provider.dart';

sealed class GeocodingState {
  const GeocodingState();
}

final class GeocodingIdle extends GeocodingState {
  const GeocodingIdle();
}

final class GeocodingLoading extends GeocodingState {
  const GeocodingLoading();
}

final class GeocodingResults extends GeocodingState {
  const GeocodingResults(this.results);
  final List<GeocodingResult> results;
}

final class GeocodingError extends GeocodingState {
  const GeocodingError(this.message);
  final String message;
}

final geocodingRepositoryProvider = Provider<GeocodingRepository>((ref) {
  return GeocodingRepository(GeocodingDataSource());
});

final geocodingProvider = NotifierProvider<GeocodingNotifier, GeocodingState>(
  GeocodingNotifier.new,
);

class GeocodingNotifier extends Notifier<GeocodingState> {
  Timer? _debounce;
  int _searchId = 0;

  @override
  GeocodingState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const GeocodingIdle();
  }

  void search(String query, {LatLng? near}) {
    _debounce?.cancel();

    if (query.trim().length < 2) {
      state = const GeocodingIdle();
      return;
    }

    if (!ref.read(connectivityProvider)) {
      state = const GeocodingError('Search unavailable offline');
      return;
    }

    final id = ++_searchId;

    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = const GeocodingLoading();
      _performSearch(id, query, near);
    });
  }

  Future<void> _performSearch(int id, String query, LatLng? near) async {
    try {
      final repo = ref.read(geocodingRepositoryProvider);
      final results = await repo.search(query, near: near);
      if (id == _searchId) {
        state = GeocodingResults(results);
      }
    } catch (_) {
      if (id == _searchId) {
        state = const GeocodingError('Search unavailable');
      }
    }
  }

  void clear() {
    _debounce?.cancel();
    _searchId++;
    state = const GeocodingIdle();
  }
}
