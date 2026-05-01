import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

enum TiltDirection { none, correct, skip }

class SensorService {
  static const double threshold = 4.5;
  static const int cooldownMs = 1100;
  
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime _lastAction = DateTime.now();

  void startListening(Function(TiltDirection) onTilt, {Function(double)? onRawY}) {
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (onRawY != null) onRawY(event.y);

      final now = DateTime.now();
      if (now.difference(_lastAction).inMilliseconds < cooldownMs) return;

      // In landscape, Y-axis represents the tilt toward sky/floor
      if (event.y < -threshold) {
        _lastAction = now;
        onTilt(TiltDirection.correct);
      } else if (event.y > threshold) {
        _lastAction = now;
        onTilt(TiltDirection.skip);
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
