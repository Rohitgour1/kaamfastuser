import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/widgets/kaamzo_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const prefKey = 'onboarding_done';

  Future<void> _finish(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);
    if (!context.mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const KaamFastLogoMark(size: 36, withBackground: true),
                  const SizedBox(width: 10),
                  Text(
                    l10n.appName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFE8D6), Color(0xFFFFC48A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _IllustIcon(
                            Icons.local_laundry_service_rounded,
                            l10n.onboardingLaundry,
                          ),
                          _IllustIcon(
                            Icons.auto_awesome_rounded,
                            l10n.onboardingQuality,
                          ),
                          _IllustIcon(
                            Icons.inventory_2_rounded,
                            l10n.onboardingDelivery,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      l10n.onboardingTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.onboardingSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(flex: 2),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _finish(context),
                        child: Text(l10n.getStarted),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustIcon extends StatelessWidget {
  const _IllustIcon(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: AppColors.navy, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}
