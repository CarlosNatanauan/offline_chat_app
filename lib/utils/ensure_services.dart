// lib/utils/ensure_services.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:android_intent_plus/android_intent.dart';

/// Call this before doing anything that needs Bluetooth + Location.
/// Returns true if everything is ON and usable.
Future<bool> ensureBluetoothAndLocationOn(BuildContext context) async {
  final missing = <String>[];

  // ---- Check Location service + permission ----
  final locationOk = await _checkLocation();
  if (!locationOk) {
    missing.add('Location');
  }

  // ---- Check Bluetooth adapter state ----
  final bluetoothOk = await _checkBluetooth();
  if (!bluetoothOk) {
    missing.add('Bluetooth');
  }

  if (missing.isEmpty) {
    return true;
  }

  // Don't show dialog if context is not mounted
  if (!context.mounted) {
    return false;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(
                    isDark ? 0.28 : 0.10,
                  ),
                ),
                child: Icon(
                  Icons.wifi_tethering_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Nearby features are off',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Intro text
              Text(
                'Caflow needs these to find and be found by people '
                'in the same café:',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),

              // Requirements
              if (missing.contains('Bluetooth'))
                const _RequirementRow(
                  icon: Icons.bluetooth_rounded,
                  label: 'Bluetooth',
                  description: 'Turn on Bluetooth to discover nearby devices.',
                ),
              if (missing.contains('Location'))
                const _RequirementRow(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  description:
                      'Android requires Location to scan for Bluetooth devices.',
                ),

              const SizedBox(height: 12),

Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Use your phone's quick settings or system settings, "
    "then come back to this screen.",
    style: theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurface.withOpacity(0.7),
    ),
  ),
),


              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Maybe later'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      // 1) Location settings
                      if (missing.contains('Location')) {
                        await Geolocator.openLocationSettings();
                      }

                      // 2) Bluetooth – open system Bluetooth settings
                      if (missing.contains('Bluetooth')) {
                        await _openBluetoothSettings();
                      }

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: const Text('Open settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return false;
}

class _RequirementRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;

  const _RequirementRow({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(isDark ? 0.5 : 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Service checks ----

Future<bool> _checkLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  } catch (e) {
    print("⚠️ Location check error: $e");
    return false;
  }
}

Future<bool> _checkBluetooth() async {
  try {
    // ✅ FIX: Add timeout and catch errors to prevent system dialog
    final state = await FlutterBluePlus.adapterState.first.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {
        print("⚠️ Bluetooth state check timeout");
        return BluetoothAdapterState.unknown;
      },
    );
    
    return state == BluetoothAdapterState.on;
  } catch (e) {
    print("⚠️ Bluetooth check error: $e");
    // If we can't check, assume it's off to be safe
    return false;
  }
}

/// Open system Bluetooth settings on Android.
/// No-op on other platforms.
Future<void> _openBluetoothSettings() async {
  if (!Platform.isAndroid) return;

  try {
    const intent = AndroidIntent(
      action: 'android.settings.BLUETOOTH_SETTINGS',
    );
    await intent.launch();
  } catch (e) {
    print("⚠️ Could not open Bluetooth settings: $e");
  }
}