/*
import 'package:flutter/material.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Shop Owner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            Text(
              'Bring Caflow to your café',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Register your coffee shop to create a verified Caflow space.\n\n'
              'Once approved, you’ll receive your official QR code that guests can scan '
              'to join a local, offline-only chat in your café.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.75),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            /// Small info card (matches Customer screen aesthetic)
            Card(
              color: theme.colorScheme.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your QR code is unique to your café and includes a secure Caflow signature.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to login/register when ready
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Log in / Register (coming soon)',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/