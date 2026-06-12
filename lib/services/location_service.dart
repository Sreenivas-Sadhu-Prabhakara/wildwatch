import 'package:geolocator/geolocator.dart';

import '../models/report.dart';

/// Result of a location request, distinguishing the failure reasons so the UI
/// can guide the user (enable GPS vs grant permission vs open settings).
class LocationResult {
  LocationResult._({this.point, this.error});

  final GeoPoint? point;
  final String? error;

  bool get ok => point != null;

  factory LocationResult.success(GeoPoint p) => LocationResult._(point: p);
  factory LocationResult.failure(String message) =>
      LocationResult._(error: message);
}

/// Thin wrapper over geolocator: checks services + permissions, then returns a
/// single fix. Coordinates work offline, which matters for rural field use.
class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.failure(
        'Location services are off. Turn on GPS/location and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return LocationResult.failure(
        'Location permission denied. You can still set the pin on the map.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationResult.failure(
        'Location permission is permanently denied. Enable it in Settings, '
        'or set the pin on the map manually.',
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationResult.success(
        GeoPoint(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
        ),
      );
    } catch (e) {
      return LocationResult.failure('Could not get a location fix: $e');
    }
  }
}
