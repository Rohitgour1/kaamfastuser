import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/widgets/kaamzo_logo.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().bootstrap();
    });
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              clipBehavior: Clip.antiAlias,
              child: const KaamFastLogoMark(size: 168, borderRadius: 32),
            ),
            const SizedBox(height: 22),
            const Text(
              'Kaam Fast',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Har Kaam, Ek App.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(flex: 4),
            AnimatedBuilder(
              animation: _dots,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final phase = (_dots.value + i / 3) % 1.0;
                    final opacity =
                        0.35 +
                        (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.65;
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'LOADING EXPERIENCE',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
