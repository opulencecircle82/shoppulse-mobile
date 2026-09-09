import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Requests location permission if needed, then returns the device's
  /// current high-accuracy GPS position.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are turned off. Enable Location/GPS in your '
        'phone settings, then try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Enable it for this app '
        'from your phone\'s Settings.',
      );
    }

    try {
      // Without a time limit, a weak/no GPS signal (indoors, cold start)
      // makes this hang indefinitely with no error and no feedback — it
      // just looks stuck. Fall back to the last known fix if a fresh one
      // times out, since a slightly-stale position still beats none.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw Exception(
        'Could not get a GPS fix in time. Move to an open area with a '
        'clear view of the sky and try again.',
      );
    }
  }
}
