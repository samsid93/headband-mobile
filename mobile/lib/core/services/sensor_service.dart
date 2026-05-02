import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class SensorService {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  final Function(double, double, double) onTilt;

  SensorService({required this.onTilt});

  void start() {
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      onTilt(event.x, event.y, event.z);
    });
  }

  void stop() {
    _gyroSubscription?.cancel();
  }
}
