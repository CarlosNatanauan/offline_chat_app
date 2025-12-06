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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String statusText = 'Getting ready…';
    String? statusSubText;
    Color statusColor = cs.outline;
    IconData statusIcon = Icons.hourglass_empty;
    String? actionLabel;

    switch (status) {
      case ConnectionStatus.ready:
      case ConnectionStatus.discovering:
      case ConnectionStatus.advertising:
        statusText = 'Scanning the café for phones…';
        statusSubText = 'Anyone who opens Caflow will appear in the list below.';
        statusColor = cs.primary;
        statusIcon = Icons.wifi_tethering_rounded;
        break;
      case ConnectionStatus.connecting:
        statusText = 'Connecting to this person…';
        statusSubText = 'Keep both phones on this screen while we link them.';
        statusColor = cs.tertiary;
        statusIcon = Icons.sync_rounded;
        break;
      case ConnectionStatus.connected:
        statusText = 'Linked to a nearby phone';
        statusSubText = 'You can start an offline chat from the list below.';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case ConnectionStatus.error:
        statusText = 'Having trouble finding nearby phones.';
        statusSubText = 'Check Wi-Fi, Bluetooth, and Location, then try again.';
        statusColor = cs.error;
        statusIcon = Icons.error_outline_rounded;
        actionLabel = 'Fix';
        break;
      case ConnectionStatus.permissionDenied:
        statusText = 'Caflow needs nearby permissions.';
        statusSubText = 'Android blocks discovery without Location access.';
        statusColor = cs.error;
        statusIcon = Icons.block_rounded;
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
            statusColor.withOpacity(0.12),
            statusColor.withOpacity(0.04),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withOpacity(0.22),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(statusIcon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (statusSubText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    statusSubText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onFixTap != null) ...[
            const SizedBox(width: 8),
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
        ? 'No one has popped up yet'
        : 'No nearby Caflow users right now';

final helperText = isSearching
    ? 'If someone in this café opens Caflow and taps “Enter nearby room”, '
        'their name will appear here automatically.'
    : 'If you’re trying to connect with someone:\n'
        '• Ask them to open Caflow and stay on this nearby screen\n'
        '• Both of you should keep Wi-Fi and Bluetooth ON\n'
        '• Location needs to be ON for discovery\n'
        '• Say yes to any permission pop-ups';


    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.14),
                    cs.primary.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.radar_rounded,
                size: 52,
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
                color: cs.onBackground.withOpacity(0.75),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (isSearching) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Listening for phones nearby…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onBackground.withOpacity(0.6),
                ),
              ),
            ] else if (onFixSettings != null)
              FilledButton.icon(
                onPressed: onFixSettings,
                icon: const Icon(Icons.settings_rounded),
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
        final initial = device.name.isNotEmpty
            ? device.name.characters.first.toUpperCase()
            : '?';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onDeviceTap(device),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withOpacity(0.18),
                        cs.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_tethering_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Nearby • tap to start an offline chat',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: FilledButton.icon(
                  onPressed: () => onDeviceTap(device),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text('Chat'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
