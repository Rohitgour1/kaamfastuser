import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/user.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _referral = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name.text = user?.name ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty && !_looksLikeEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email or leave it empty')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final code = _referral.text.trim();
      if (code.isNotEmpty) {
        await context.read<ReferralApi>().apply(code);
      }
      final raw = await context.read<ProfileApi>().update(
        name: name,
        email: email.isEmpty ? null : email,
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(UserModel.fromJson(raw));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final phone = user?.phoneLabel ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const Text(
              'Tell us a bit about you',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your phone is already verified. Name is required to book services.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Phone (verified)',
                prefixIcon: Icon(Icons.phone_outlined),
                suffixIcon: Icon(Icons.verified, color: AppColors.success),
              ),
              child: Text(
                phone,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referral,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _busy ? null : _submit(),
              decoration: const InputDecoration(
                labelText: 'Referral code (optional)',
                prefixIcon: Icon(Icons.card_giftcard_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
