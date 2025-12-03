import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'customer/main/customer_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      // Faster rotation
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surfaceVariant.withOpacity(0.25),
              cs.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                /// Brand area (top) – small pill + Caflow + accent line
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const SizedBox(height: 12),
                    Text(
                      'CAFLOW',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 64,
                      height: 3,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                /// Short title + hint (no full explanation here)
                Center(
                  child: Text(
                    'A conversation made for this café.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Open Caflow on both phones and connect directly—no internet,\n no cloud, just the people nearby.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onBackground.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// Logo hero with rotating orbit
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 260),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 28,
                            offset: const Offset(0, 22),
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ],
                        border: Border.all(
                          color: cs.primary.withOpacity(0.08),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Stack(
  alignment: Alignment.center,
  children: [
    // Main logo
    Image.asset(
      'assets/images/offine_chat_app_logo_no_bg.png',
      fit: BoxFit.contain,
    ),

    // Dot 1 – rotates CLOCKWISE
    AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        const radius = 90.0;
        final angle = _orbitController.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(
            radius * math.cos(angle),
            radius * math.sin(angle),
          ),
          child: child,
        );
      },
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: cs.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.45),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    ),

    // Dot 2 – rotates COUNTER-CLOCKWISE
    AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        const radius = 90.0;
        // Reverse rotation by subtracting the angle
        final angle = -_orbitController.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(
            radius * math.cos(angle),
            radius * math.sin(angle),
          ),
          child: child,
        );
      },
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: cs.secondary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cs.secondary.withOpacity(0.35),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    ),
  ],
)

                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// Single CTA (kept simple)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerHomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Start in this café',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
