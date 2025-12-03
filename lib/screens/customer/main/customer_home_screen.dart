// screens/customer/customer_home_screen.dart
import 'package:flutter/material.dart';
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
        title: const Text('Chat in this café'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header / hero
              Text(
                'Chat with people nearby',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Caflow links phones directly, like walkie-talkies.\n'
                'No mobile data, no café Wi-Fi needed for messages.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onBackground.withOpacity(0.7),
                  height: 1.4,
                ),
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
                    label: 'Wi-Fi ON (chip only)',
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
                    label: 'No internet needed',
                    color: cs.secondary,
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Android asks for Wi-Fi, Bluetooth and Location so it can find nearby phones. '
                'Caflow does not use these to go online — only to discover people around you.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onBackground.withOpacity(0.6),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // How it works card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: cs.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
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
                            'How Caflow works',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StepRow(
                        number: '1',
                        text:
                            'Everyone in the café opens Caflow and taps “Enter nearby room”.',
                      ),
                      const SizedBox(height: 6),
                      _StepRow(
                        number: '2',
                        text:
                            'Caflow uses your phone’s Wi-Fi / Bluetooth to spot other phones nearby '
                            '(a direct device-to-device link, called Wi-Fi Direct).',
                      ),
                      const SizedBox(height: 6),
                      _StepRow(
                        number: '3',
                        text:
                            'You pick someone from the nearby list and start chatting. '
                            'Messages travel only between the phones in this café.',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Messages never go through the internet or a cloud server — '
                        'they only hop directly between nearby phones.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.7),
                          height: 1.4,
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

                  // 👇 Ask the user for a display name instead of Guest###
                  final displayName = await _askForDisplayName(context);
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
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Enter nearby room'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

/// Dialog helper – ask for a display name
Future<String?> _askForDisplayName(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Pick a name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This is the name people in this café will see.\n'
              'You can use a nickname or something simple like “Table 4, window”.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Your display name',
                hintText: 'e.g. Aya, Table 4, Blue hoodie',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
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
      backgroundColor: color.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            color: cs.primary.withOpacity(0.1),
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
