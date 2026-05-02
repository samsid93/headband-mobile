import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestGamePermissions() async {
    // Request both mic (for voice) and sensor/motion (for tilt)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.sensors, // iOS/Android sensor access
    ].request();

    return statuses[Permission.microphone]!.isGranted && 
           statuses[Permission.sensors]!.isGranted;
  }
}
