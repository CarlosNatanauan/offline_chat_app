// screens/customer/sub/chat/widgets/connection_banner.dart
import 'package:flutter/material.dart';
import 'package:offline_chat_app/services/wifi_direct_service.dart';

class ConnectionBanner extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionBanner({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ConnectionStatus.connected) {
      return const SizedBox.shrink();
    }

    final config = _getStatusConfig(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: config.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            config.icon,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              config.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connecting:
        return _StatusConfig(
          color: Colors.blue,
          icon: Icons.sync_rounded,
          message: 'Connecting...',
        );
      case ConnectionStatus.disconnected:
        return _StatusConfig(
          color: Colors.orange.shade700,
          icon: Icons.warning_rounded,
          message: 'Connection lost',
        );
      case ConnectionStatus.error:
        return _StatusConfig(
          color: Colors.red.shade700,
          icon: Icons.error_outline_rounded,
          message: 'Connection error',
        );
      default:
        return _StatusConfig(
          color: Colors.grey,
          icon: Icons.info_outline_rounded,
          message: 'Not connected',
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String message;

  _StatusConfig({
    required this.color,
    required this.icon,
    required this.message,
  });
}