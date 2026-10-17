import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaamfast/common/app_constants.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteEarnScreen extends StatefulWidget {
  const InviteEarnScreen({super.key});

  @override
  State<InviteEarnScreen> createState() => _InviteEarnScreenState();
}

class _InviteEarnScreenState extends State<InviteEarnScreen> {
  Map<String, dynamic>? _summary;
  double _balance = 0;
  List<Map<String, dynamic>> _rewards = [];

  String get _code {
    final fromApi = _summary?['referral_code']?.toString().trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return context.read<AuthProvider>().user?.referralCode?.trim() ?? '';
  }

  String get _inviteText {
    return 'Join ${AppConstants.appName} with my invite code $_code. '
        '${AppConstants.appTagline} https://kaamfast.com';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats() async {
    try {
      final api = context.read<ReferralApi>();
      final summary = await api.summary();
      var balance = 0.0;
      var rewards = <Map<String, dynamic>>[];
      try {
        final wallet = await api.wallet();
        balance = (wallet['balance'] as num?)?.toDouble() ??
            double.tryParse('${wallet['balance']}') ??
            0;
      } catch (_) {}
      try {
        rewards = await api.rewards();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _balance = balance;
        _rewards = rewards;
      });
    } catch (_) {}
  }

  Future<void> _copyCode() async {
    if (_code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied')));
  }

  Future<void> _shareWhatsApp() async {
    if (_code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code is not ready yet')),
      );
      return;
    }
    final text = Uri.encodeComponent(_inviteText);
    final uris = [
      Uri.parse('whatsapp://send?text=$text'),
      Uri.parse('https://wa.me/?text=$text'),
    ];
    for (final uri in uris) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    await _copyCode();
  }

  String _pct(dynamic value) {
    if (value is num) return value.toString();
    return double.tryParse('$value')?.toString() ?? '0';
  }

  ButtonStyle get _rowButtonStyle => FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  ButtonStyle get _rowOutlineStyle => OutlinedButton.styleFrom(
        minimumSize: const Size(88, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  @override
  Widget build(BuildContext context) {
    final levels = _summary?['levels'] is List ? List.from(_summary!['levels'] as List) : const [];
    final invited = _summary?['direct_referrals'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Invite & Earn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite friends, earn on every order',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Share your code. When they book, you get referral rewards in your wallet.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YOUR CODE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              _code.isEmpty ? '—' : _code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _copyCode,
                        icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: _rowButtonStyle,
                  onPressed: _shareWhatsApp,
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('Invite via WhatsApp'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: _rowOutlineStyle,
                onPressed: _copyCode,
                child: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _stat('Invited', '$invited')),
              const SizedBox(width: 10),
              Expanded(child: _stat('Earned', '₹${_balance.toStringAsFixed(0)}')),
            ],
          ),
          if (levels.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('How you earn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (final raw in levels)
              if (raw is Map)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.sky,
                          foregroundColor: AppColors.navy,
                          child: Text(
                            '${raw['level'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            raw['name']?.toString() ?? 'Level ${raw['level']}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${_pct(raw['percentage'])}%',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (_rewards.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Recent rewards', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (final row in _rewards.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '₹${row['reward_amount'] ?? 0}  ·  ${'${row['status'] ?? 'reward'}'.replaceAll('_', ' ')}',
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.navy)),
        ],
      ),
    );
  }
}
