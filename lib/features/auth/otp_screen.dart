import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/widgets/otp_boxes.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone, this.debugOtp});

  final String phone;
  final String? debugOtp;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _code = '';
  bool _busy = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _code = widget.debugOtp?.replaceAll(RegExp(r'\D'), '') ?? '';
  }

  Future<void> _verify([String? value]) async {
    final otp = (value ?? _code).trim();
    if (otp.length != 6 || _busy) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().verifyOtp(widget.phone, otp);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await context.read<AuthProvider>().sendOtp(widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent again')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter 6-digit OTP',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Code sent to +91 ${widget.phone}',
                style: const TextStyle(color: AppColors.muted),
              ),
              // if (widget.debugOtp != null) ...[
              //   const SizedBox(height: 8),
              //   Text(
              //     'Dev OTP: ${widget.debugOtp}',
              //     style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700),
              //   ),
              // ],
              const SizedBox(height: 28),
              OtpBoxes(
                initialValue: widget.debugOtp,
                onChanged: (code) => setState(() => _code = code),
                onCompleted: _verify,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? 'Sending…' : 'Resend OTP'),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _busy || _code.length != 6 ? null : _verify,
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
      ),
    );
  }
}
