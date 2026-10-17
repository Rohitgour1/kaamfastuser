import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/providers/locale_provider.dart';
import 'package:kaamfast/widgets/legal_links.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  bool _busy = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidPhone)),
      );
      return;
    }
    if (!_acceptedTerms) {
      final hi = context.read<LocaleProvider>().isHindi;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hi
                ? 'आगे बढ़ने के लिए नियम और शर्तें और प्राइवेसी पॉलिसी स्वीकार करें।'
                : 'Please accept the Terms & Conditions and Privacy Policy to continue.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await context.read<AuthProvider>().sendOtp(phone);
      if (!mounted) return;
      final debugOtp = result['debug_otp']?.toString();
      final qp = <String, String>{'phone': phone};
      if (debugOtp != null) qp['debug_otp'] = debugOtp;
      context.go(Uri(path: '/otp', queryParameters: qp).toString());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.navyDeep,
                      AppColors.navy,
                      AppColors.accentOrange,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.loginHeadline,
                      style: const TextStyle(
                        color: Color(0xFFFFE8D6),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.continueWithPhone,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                context.watch<LocaleProvider>().isHindi
                    ? 'अपना नंबर डालें। लॉगिन या नया अकाउंट बनाने के लिए OTP भेजा जाएगा।'
                    : 'Enter your number. We will send an OTP to log you in or create your account.',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: l10n.phoneHint,
                  prefixText: '+91  ',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TermsConsent(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v),
              ),
              const SizedBox(height: 16),
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
                    : Text(l10n.sendOtp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
