import 'package:flutter/material.dart';
import 'package:offline_chat_app/models/caflow_models.dart';
import 'package:offline_chat_app/services/wifi_direct_service.dart';

typedef DeviceTapCallback = void Function(CaflowDevice device);
typedef VoidCallback = void Function();

/// Top banner showing what Caflow is currently doing on the nearby screen.
class NearbyStatusBanner extends StatelessWidget {
  final ConnectionStatus status;
  final VoidCallback? onFixTap;

  const NearbyStatusBanner({
    super.key,
    required this.status,
    this.onFixTap,
  });

  @override
  Widget build(BuildContext context) {
    String statusText = 'Getting ready…';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.hourglass_empty;
    String? actionLabel;

    switch (status) {
      case ConnectionStatus.ready:
      case ConnectionStatus.discovering:
      case ConnectionStatus.advertising:
        statusText = 'Looking for people in this café…';
        statusColor = Colors.blue;
        statusIcon = Icons.wifi_tethering;
        break;
      case ConnectionStatus.connecting:
        statusText = 'Connecting to this person…';
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case ConnectionStatus.connected:
        statusText = 'Connected to a nearby phone';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ConnectionStatus.error:
        statusText = 'Having trouble finding nearby phones.';
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        actionLabel = 'Fix';
        break;
      case ConnectionStatus.permissionDenied:
        statusText = 'Caflow needs permission to find people near you.';
        statusColor = Colors.red;
        statusIcon = Icons.block;
        actionLabel = 'Allow';
        break;
      default:
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            statusColor.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withOpacity(0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 18, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (actionLabel != null && onFixTap != null)
            TextButton(
              onPressed: onFixTap,
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NearbyEmptyState extends StatelessWidget {
  final ConnectionStatus status;
  final VoidCallback? onFixSettings;

  const NearbyEmptyState({
    super.key,
    required this.status,
    this.onFixSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isSearching = status == ConnectionStatus.discovering ||
        status == ConnectionStatus.advertising ||
        status == ConnectionStatus.ready;

    final titleText = isSearching
        ? 'Looking for Caflow users nearby…'
        : 'No nearby Caflow users yet';

    // 🔹 Updated helper text: no “friends”, more like “others in this café”.
    final helperText = isSearching
        ? 'Anyone in this café who opens Caflow and taps '
          '“Enter nearby room” will appear here automatically.'
        : 'If you think others are using Caflow:\n'
          '• Their Wi-Fi should be ON (chip only)\n'
          '• Their Bluetooth should be ON\n'
          '• Location should be enabled\n'
          '• They should be on this Caflow screen\n'
          '• They should accept the permission prompts';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.08),
              ),
              child: Icon(
                Icons.wifi_tethering,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: cs.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              helperText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onBackground.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (isSearching)
              const CircularProgressIndicator()
            else if (onFixSettings != null)
              FilledButton.icon(
                onPressed: onFixSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Check device settings'),
              ),
          ],
        ),
      ),
    );
  }
}


class NearbyDeviceList extends StatelessWidget {
  final List<CaflowDevice> devices;
  final DeviceTapCallback onDeviceTap;

  const NearbyDeviceList({
    super.key,
    required this.devices,
    required this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person,
                color: cs.primary,
                size: 24,
              ),
            ),
            title: Text(
              device.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_tethering,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Nearby • Tap to chat',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            trailing: FilledButton.icon(
              onPressed: () => onDeviceTap(device),
              icon: const Icon(Icons.chat_bubble, size: 18),
              label: const Text('Chat'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
