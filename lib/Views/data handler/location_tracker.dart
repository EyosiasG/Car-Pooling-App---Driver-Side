import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationTracker {
  late Position _previousPosition;
  late Timer _timer;
  double _totalDistance = 0;
  final Duration _intervalDuration = const Duration(seconds: 30);

  void startTracking() {
    Geolocator.getPositionStream().listen((Position position) {
      if (_previousPosition != null) {
        double distance = Geolocator.distanceBetween(
          _previousPosition.latitude,
          _previousPosition.longitude,
          position.latitude,
          position.longitude,
        );
        _totalDistance += distance;
      }
      _previousPosition = position;
    });

    _timer = Timer.periodic(_intervalDuration, (Timer t) {
      print('Total distance covered: $_totalDistance meters');
    });
  }

  void stopTracking() {
    _timer.cancel();
  }
}
