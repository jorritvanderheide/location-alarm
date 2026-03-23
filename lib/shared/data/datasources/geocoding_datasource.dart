import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Fetches geocoding results from a Photon API instance (OSM-based,
/// designed for search-as-you-type with fuzzy/partial matching).
class GeocodingDataSource {
  GeocodingDataSource({
    this.baseUrl = 'https://photon.komoot.io',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const _headers = {'User-Agent': 'LocationAlarm/1.0 (Android)'};

  Future<List<Map<String, dynamic>>> search(
    String query, {
    LatLng? near,
  }) async {
    if (query.trim().length < 2) return [];

    final params = <String, String>{'q': query.trim(), 'limit': '5'};

    if (near != null) {
      params['lat'] = '${near.latitude}';
      params['lon'] = '${near.longitude}';
      params['zoom'] = '12';
      params['location_bias_scale'] = '0.1';
    }

    final uri = Uri.parse('$baseUrl/api').replace(queryParameters: params);
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    final features = decoded['features'];
    if (features is! List) return [];
    return features.cast<Map<String, dynamic>>();
  }

  /// Reverse geocode a coordinate into a place description.
  Future<Map<String, dynamic>?> reverse(LatLng location) async {
    final uri = Uri.parse('$baseUrl/reverse').replace(
      queryParameters: {
        'lat': '${location.latitude}',
        'lon': '${location.longitude}',
      },
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final features = decoded['features'];
    if (features is! List || features.isEmpty) return null;
    return features[0] as Map<String, dynamic>;
  }
}
