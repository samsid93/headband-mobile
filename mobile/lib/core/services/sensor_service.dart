import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  final Function(double, double, double) onData;

  SensorService({required this.onData});

  void start() {
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      onData(event.x, event.y, event.z);
    });
  }

  void stop() {
    _accelSubscription?.cancel();
  }
}
