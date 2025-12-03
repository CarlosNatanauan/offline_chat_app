/*
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _handled = false; // so we only handle the first scan

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan café QR'),
      ),
      body: Stack(
        children: [
          // Camera + scanner
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              _handled = true;

              final barcodes = capture.barcodes;
              final barcode = barcodes.isNotEmpty ? barcodes.first : null;
              final String? rawValue = barcode?.rawValue;

              if (rawValue != null) {
                // For now, just return the raw string to previous screen
                Navigator.of(context).pop(rawValue);
              } else {
                // If something went wrong, allow another scan
                _handled = false;
              }
            },
          ),

          // Simple dark overlay + frame
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    // dim background
                    Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    // cutout center (just visual, not real cutout)
                    Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    // bottom text
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 40,
                          left: 24,
                          right: 24,
                        ),
                        child: Text(
                          'Point your camera at the café’s official QR code.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/