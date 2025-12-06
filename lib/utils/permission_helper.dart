import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestWiFiDirectPermissions() async {
    // Ask for all the things Nearby needs on Android 12+:
    // - Location (for Wi-Fi / BT discovery)
    // - Bluetooth scan / advertise / connect
    // - Nearby Wi-Fi devices (Android 13+)
    final permissions = <Permission>[
      Permission.location,
      Permission.locationWhenInUse,
      Permission.bluetooth,           // pre-Android 12
      Permission.bluetoothScan,       // Android 12+
      Permission.bluetoothAdvertise,  // Android 12+
      Permission.bluetoothConnect,    // Android 12+
      Permission.nearbyWifiDevices,   // Android 13+
    ];

    final statuses = await permissions.request();

    bool allGranted = true;
    for (final entry in statuses.entries) {
      final perm = entry.key;
      final status = entry.value;

      // Treat permanently denied / denied as failure
      if (!(status.isGranted || status.isLimited)) {
        allGranted = false;
        print('❌ Permission not granted: $perm -> $status');
      } else {
        print('✅ Permission granted: $perm');
      }
    }

    if (!allGranted) {
      print("⚠️ Not all WiFi Direct / Nearby permissions granted");
      return false;
    }

    print("✅ All WiFi Direct / Nearby permissions granted");
    return true;
  }

  static Future<bool> checkWiFiDirectPermissions() async {
    final locationOk = await Permission.location.isGranted;
    final btScanOk = await Permission.bluetoothScan.isGranted;
    final btAdvertiseOk = await Permission.bluetoothAdvertise.isGranted;
    final btConnectOk = await Permission.bluetoothConnect.isGranted;

    if (!locationOk || !btScanOk || !btAdvertiseOk || !btConnectOk) {
      return await requestWiFiDirectPermissions();
    }

    return true;
  }
}
