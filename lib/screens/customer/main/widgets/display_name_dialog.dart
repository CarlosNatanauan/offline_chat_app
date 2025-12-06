// screens/customer/widgets/display_name_dialog.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// Shows a dialog asking the user for a display name.
/// Returns the chosen name, or null if the user cancels.
Future<String?> showDisplayNameDialog(BuildContext context) async {
  final controller = TextEditingController();
  final random = Random();

  // Bigger bank of short, mysterious suggestions (no table numbers)
  const allSuggestions = <String>[
    'Latte Plot',
    'Covert Croissant',
    'Quiet Wi-Fi',
    'Espresso Enigma',
    'Decaf Mystery',
    'Window Whisper',
    'Pastry Plot',
    'Incognito Cappuccino',
    'Mug of Secrets',
    'Chai Side Quest',
    'Coffee Cryptid',
    'Low-Key Latte',
    'Silent Espresso',
    'Notebook Ghost',
    'Secret Side-Eye',
    'Croissant Code',
    'Midnight Mocha',
    'Latte Mirage',
    'Café Enigma',
    'Wi-Fi Phantom',
    'Steam Signal',
    'Whispered Refill',
    'Espresso Shadow',
    'Quiet Refraction',
  ];

  String? errorText;
  List<String> visibleSuggestions = [];

  String randomSuggestion() {
    return allSuggestions[random.nextInt(allSuggestions.length)];
  }

  List<String> pickRandomSuggestions() {
    final list = List<String>.from(allSuggestions);
    list.shuffle(random);
    return list.take(6).toList();
  }

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;

          // Initialize visible suggestions once
          if (visibleSuggestions.isEmpty) {
            visibleSuggestions = pickRandomSuggestions();
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.person_outline_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick a display name',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'This is how people in this café will see you.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You can keep it casual, mysterious, or a little silly.\n'
                    'Avoid real names if you want to stay low-key.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here are some ideas, but it’s even better if the name comes from you.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: cs.onSurface.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Fun ideas',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            visibleSuggestions = pickRandomSuggestions();
                          });
                        },
                        icon: const Icon(Icons.shuffle_rounded, size: 16),
                        label: const Text(
                          'Shuffle ideas',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: visibleSuggestions.map((s) {
                      return ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        onPressed: () {
                          setState(() {
                            controller.text = s;
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: s.length),
                            );
                            errorText = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          maxLength: 20,
                          decoration: InputDecoration(
                            labelText: 'Your display name',
                            hintText: randomSuggestion(),
                            border: const OutlineInputBorder(),
                            errorText: errorText,
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Roll a random idea',
                        child: IconButton(
                          onPressed: () {
                            final suggestion = randomSuggestion();
                            setState(() {
                              controller.text = suggestion;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: suggestion.length),
                              );
                              errorText = null;
                            });
                          },
                          icon: const Icon(Icons.casino_rounded),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) {
                    setState(() {
                      errorText = 'Pick something so people know it\'s you.';
                    });
                    return;
                  }
                  Navigator.pop(ctx, text);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    },
  );
}
