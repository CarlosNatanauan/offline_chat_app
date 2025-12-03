// utils/permission_helper.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestWiFiDirectPermissions() async {
    // Request location permission (required for WiFi Direct discovery)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();

    bool allGranted = statuses.values.every((status) => 
      status.isGranted || status.isLimited
    );

    if (!allGranted) {
      print("⚠️ Not all permissions granted");
      return false;
    }

    print("✅ All WiFi Direct permissions granted");
    return true;
  }

  static Future<bool> checkWiFiDirectPermissions() async {
    bool locationGranted = await Permission.location.isGranted;
    
    if (!locationGranted) {
      return await requestWiFiDirectPermissions();
    }

    return true;
  }
}