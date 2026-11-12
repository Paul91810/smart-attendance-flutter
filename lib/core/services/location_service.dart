import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../error/failures.dart';
import '../error/result.dart';

class UserPosition {
  final double latitude;
  final double longitude;
  final double accuracy;

  const UserPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  @override
  String toString() => 'UserPosition($latitude, $longitude, Â±$accuracy m)';
}

abstract class LocationService {
  Future<Result<LocationFailure, UserPosition>> getCurrentPosition();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class LocationServiceImpl implements LocationService {
  @override
  Future<Result<LocationFailure, UserPosition>> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Result.failure(
          LocationFailure(
            'Location services are disabled. Please enable GPS in device settings.',
            code: 'LOCATION_DISABLED',
          ),
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Result.failure(
            LocationFailure(
              'Location permission denied. GPS is required for attendance validation.',
              code: 'LOCATION_PERMISSION_DENIED',
            ),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Result.failure(
          LocationFailure(
            'Location permission is permanently denied. Please grant location access in App Settings.',
            code: 'LOCATION_PERMISSION_PERMANENTLY_DENIED',
          ),
        );
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
        return Result.success(
          UserPosition(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
          ),
        );
      } catch (inner) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return Result.success(
            UserPosition(
              latitude: lastKnown.latitude,
              longitude: lastKnown.longitude,
              accuracy: lastKnown.accuracy,
            ),
          );
        }

        if (kDebugMode) {
          return const Result.success(
            UserPosition(latitude: 12.9716, longitude: 77.5946, accuracy: 10.0),
          );
        }

        if (inner is TimeoutException) {
          return const Result.failure(
            LocationFailure(
              'Location acquisition timed out. Please ensure you have GPS signal.',
              code: 'LOCATION_TIMEOUT',
            ),
          );
        }

        return Result.failure(
          LocationFailure(
            'Failed to acquire location: $inner',
            code: 'LOCATION_TIMEOUT',
          ),
        );
      }
    } catch (e) {
      return Result.failure(
        LocationFailure(
          'Unexpected error reading location: $e',
          code: 'LOCATION_ERROR',
        ),
      );
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
