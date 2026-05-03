import 'package:geolocator/geolocator.dart';

/// Service class for handling location and proximity detection.
///
/// Manages user location tracking and proximity calculations
/// for the AR scavenger hunt experience.
class LocationService {
  static const double PROXIMITY_RADIUS_METERS = 20.0;

  /// Checks if the app has location permission.
  ///
  /// Returns true if permission is granted, false otherwise.
  Future<bool> checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Requests location permission from the user.
  ///
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Gets the current user position.
  ///
  /// Throws an exception if permission is not granted or location
  /// service is unavailable.
  Future<Position> getCurrentPosition() async {
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw LocationServiceException('Location permission not granted');
    }

    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      throw LocationServiceException('Location service is disabled');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  /// Streams the user's current position with updates.
  ///
  /// Emits position updates every 1000ms with high accuracy.
  /// Returns a stream that can be used for real-time location tracking.
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: Duration(milliseconds: 1000),
      ),
    );
  }

  /// Calculates distance between two coordinates in meters.
  ///
  /// Uses the Haversine formula for accurate distance calculation
  /// over spherical distances.
  double calculateDistance({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
  }) {
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      targetLat,
      targetLng,
    );
  }

  /// Checks if the user is within proximity of a target location.
  ///
  /// Returns true if the distance is within PROXIMITY_RADIUS_METERS (20m).
  bool isWithinProximity({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
  }) {
    final distance = calculateDistance(
      userLat: userLat,
      userLng: userLng,
      targetLat: targetLat,
      targetLng: targetLng,
    );
    return distance <= PROXIMITY_RADIUS_METERS;
  }

  /// Opens the system location settings.
  ///
  /// Useful for prompting users to enable location services.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

/// Custom exception for location-related errors.
class LocationServiceException implements Exception {
  final String message;

  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
