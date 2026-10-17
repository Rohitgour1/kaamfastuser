import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/common/app_constants.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    String digits = AppConstants.supportWhatsApp.replaceAll(RegExp(r'\D'), '');
    final api = context.read<SupportApi>();
    try {
      final config = await api.config();
      final fromApi = '${config['whatsapp'] ?? ''}'.replaceAll(RegExp(r'\D'), '');
      if (fromApi.isNotEmpty && !RegExp(r'^0+$').hasMatch(fromApi)) {
        digits = fromApi;
      }
    } catch (_) {}

    if (digits.length == 10) digits = '91$digits';
    if (digits.isEmpty || RegExp(r'^0+$').hasMatch(digits)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp number is not configured yet.')),
        );
      }
      return;
    }

    final text = Uri.encodeComponent('Hi Kaam Fast Support, I need help.');
    final uris = [
      Uri.parse('whatsapp://send?phone=$digits&text=$text'),
      Uri.parse('https://wa.me/$digits?text=$text'),
    ];

    Object? lastError;
    for (final uri in uris) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (e) {
        lastError = e;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lastError != null ? '$lastError' : 'Could not open WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'How can we help?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose one option to reach Kaam Fast support.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          _SupportOptionCard(
            icon: Icons.chat_bubble_outline,
            title: 'Chat with admin',
            subtitle: 'Message our team inside the app.',
            onTap: () => context.push('/support/chat'),
          ),
          const SizedBox(height: 12),
          _SupportOptionCard(
            icon: Icons.message_outlined,
            title: 'WhatsApp',
            subtitle: 'Continue the conversation on WhatsApp.',
            onTap: () => _openWhatsApp(context),
          ),
          const SizedBox(height: 12),
          _SupportOptionCard(
            icon: Icons.confirmation_number_outlined,
            title: 'Support ticket',
            subtitle: 'Raise an issue for an order or general help.',
            onTap: () => context.push('/support/ticket'),
          ),
        ],
      ),
    );
  }
}

class _SupportOptionCard extends StatelessWidget {
  const _SupportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.navy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
