// screens/customer/customer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:offline_chat_app/screens/customer/main/widgets/display_name_dialog.dart';
import 'package:offline_chat_app/screens/customer/sub/nearby/nearby_users_screen.dart';
import 'package:offline_chat_app/utils/ensure_services.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Caflow in this café',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Offline chat with people around you',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          cs.primaryContainer.withOpacity(0.9),
                          cs.primaryContainer.withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 32,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat with people nearby',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Caflow links phones directly, like walkie-talkies.\n'
                          'No mobile data. No café Wi-Fi login. Just nearby chat.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onBackground.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Requirements row
              Text(
                'Before you start',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RequirementChip(
                    icon: Icons.wifi,
                    label: 'Wi-Fi switch ON',
                    color: cs.primary,
                  ),
                  _RequirementChip(
                    icon: Icons.bluetooth,
                    label: 'Bluetooth ON',
                    color: cs.primary,
                  ),
                  _RequirementChip(
                    icon: Icons.location_on,
                    label: 'Location ON',
                    color: cs.primary,
                  ),
                  _RequirementChip(
                    icon: Icons.cloud_off,
                    label: 'Works without internet',
                    color: cs.secondary,
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Android uses Wi-Fi, Bluetooth, and Location to let your phone spot '
                'other phones close by. Caflow only uses them for discovery — '
                'not to send anything online.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onBackground.withOpacity(0.6),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // How it works card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
                color: cs.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_cafe_rounded,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'How Caflow works in a café',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _StepRow(
                        number: '1',
                        text:
                            'People in this café open Caflow and tap “Enter nearby room”.',
                      ),
                      const SizedBox(height: 6),
                      _StepRow(
                        number: '2',
                        text:
                            'Your phone uses Wi-Fi Direct and Bluetooth to discover phones sitting nearby — a direct device-to-device link.',
                      ),
                      const SizedBox(height: 6),
                      _StepRow(
                        number: '3',
                        text:
                            'You pick a name from the list and start chatting. Messages move only between the phones in this room.',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Messages don’t go through café Wi-Fi, mobile data, or any cloud server — '
                                'they stay between nearby phones.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Main action button
              ElevatedButton.icon(
                onPressed: () async {
                  // Make sure Bluetooth & Location are enabled before connecting
                  final ok = await ensureBluetoothAndLocationOn(context);
                  if (!ok) return;

                  // Ask the user for a display name instead of Guest###
                  final displayName = await showDisplayNameDialog(context);
                  if (displayName == null || displayName.trim().isEmpty) {
                    return; // user cancelled or left it empty
                  }

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NearbyUsersScreenWiFi(
                          userName: displayName.trim(),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.wifi_tethering_rounded),
                label: const Text('Enter nearby room'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Small privacy / clarification text
              Text(
                'Caflow uses your device’s Wi-Fi, Bluetooth, and Location\n'
                'to discover people sitting near you. It does not send\n'
                'your messages to the internet or store them online.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onBackground.withOpacity(0.6),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RequirementChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
