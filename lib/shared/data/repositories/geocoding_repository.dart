import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/datasources/geocoding_datasource.dart';
import 'package:location_alarm/shared/data/models/geocoding_result.dart';

class GeocodingRepository {
  GeocodingRepository(this._dataSource);

  final GeocodingDataSource _dataSource;

  // Simple in-memory cache to avoid redundant requests.
  final Map<String, List<GeocodingResult>> _cache = {};
  static const _maxCacheSize = 50;

  Future<List<GeocodingResult>> search(String query, {LatLng? near}) async {
    final key = '${query.toLowerCase()}|${near?.latitude},${near?.longitude}';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final raw = await _dataSource.search(query, near: near);
      final results = raw.map(_parse).nonNulls.toList();

      if (_cache.length >= _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      _cache[key] = results;

      return results;
    } on Exception {
      return [];
    }
  }

  /// Reverse geocode a location into a place name.
  /// Detail level depends on [radius]: smaller radius → more detail.
  Future<String?> reverseGeocode(LatLng location, {double radius = 500}) async {
    try {
      final feature = await _dataSource.reverse(location);
      if (feature == null) return null;
      final props = feature['properties'] as Map<String, dynamic>?;
      if (props == null) return null;
      return _buildLocationName(props, radius);
    } on Exception {
      return null;
    }
  }

  /// Builds a location name with detail level based on radius.
  /// Small radius (< 500m): street + city
  /// Medium radius (500m–2km): neighborhood/city
  /// Large radius (> 2km): city only
  String? _buildLocationName(Map<String, dynamic> props, double radius) {
    final street = props['street'] as String?;
    final name = props['name'] as String?;
    final city = props['city'] as String?;
    final locality = props['locality'] as String?;
    final district = props['district'] as String?;
    final place = city ?? locality;

    if (radius < 500) {
      // Street-level detail
      if (street != null && street.isNotEmpty && place != null) {
        return '$street, $place';
      }
      if (name != null && name.isNotEmpty && place != null && name != place) {
        return '$name, $place';
      }
    } else if (radius <= 2000) {
      // Neighborhood/district level
      if (district != null && district.isNotEmpty && place != null) {
        return '$district, $place';
      }
    }

    // Fallback: city or name
    if (place != null && place.isNotEmpty) return place;
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  /// Parses a Photon GeoJSON feature into a [GeocodingResult].
  GeocodingResult? _parse(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final properties = feature['properties'] as Map<String, dynamic>?;
    if (geometry == null || properties == null) return null;

    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2) return null;
    final lon = (coords[0] as num?)?.toDouble();
    final lat = (coords[1] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final name = _buildDisplayName(properties);
    if (name.isEmpty) return null;

    return GeocodingResult(
      displayName: name,
      location: LatLng(lat, lon),
      type: properties['osm_value'] as String?,
    );
  }

  /// Builds a readable display name from Photon properties.
  String _buildDisplayName(Map<String, dynamic> props) {
    final parts = <String>[];

    final name = props['name'] as String?;
    if (name != null && name.isNotEmpty) parts.add(name);

    final street = props['street'] as String?;
    if (street != null && street.isNotEmpty && street != name) {
      parts.add(street);
    }

    final city = props['city'] as String?;
    if (city != null && city.isNotEmpty && city != name) parts.add(city);

    final state = props['state'] as String?;
    if (state != null && state.isNotEmpty && state != city) parts.add(state);

    final country = props['country'] as String?;
    if (country != null && country.isNotEmpty) parts.add(country);

    return parts.join(', ');
  }
}
