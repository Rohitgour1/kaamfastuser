import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/l10n/app_localizations.dart';
import 'package:kaamfast/providers/locale_provider.dart';
import 'package:kaamfast/widgets/kaamzo_logo.dart';
import 'package:provider/provider.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  static const selectedPrefKey = LocaleProvider.selectedPrefKey;

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  String? _pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = context.read<LocaleProvider>().locale.languageCode;
      setState(() => _pending = current);
    });
  }

  Future<void> _confirm() async {
    final code = _pending ?? 'en';
    await context.read<LocaleProvider>().setLocale(Locale(code));
    if (!mounted) return;
    if (widget.fromSettings) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
      return;
    }
    // Let router decide: onboarding → login → home
    context.go('/splash');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = _pending ?? 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.fromSettings
          ? AppBar(title: Text(l10n.language))
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.fromSettings) ...[
                const SizedBox(height: 12),
                const Row(
                  children: [
                    KaamFastLogoMark(size: 40, withBackground: true),
                    SizedBox(width: 12),
                    Text(
                      'Kaam Fast',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
              ] else
                const SizedBox(height: 8),
              Text(
                l10n.chooseLanguage,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.chooseLanguageSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _LanguageCard(
                title: 'English',
                subtitle: 'Continue in English',
                selected: selected == 'en',
                onTap: () => setState(() => _pending = 'en'),
              ),
              const SizedBox(height: 12),
              _LanguageCard(
                title: 'हिन्दी',
                subtitle: 'हिन्दी में जारी रखें',
                selected: selected == 'hi',
                onTap: () => setState(() => _pending = 'hi'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _confirm,
                child: Text(
                  widget.fromSettings ? l10n.save : l10n.continueLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.sky : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.accentOrange : AppColors.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.accentOrange : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
