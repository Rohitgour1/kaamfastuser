import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/wallet.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final _holder = TextEditingController();
  final _number = TextEditingController();
  final _ifsc = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await context.read<WalletApi>().bankAccount();
      final account = WalletBankAccount.fromJson(raw);
      if (!mounted) return;
      _holder.text = account.accountHolderName ?? '';
      _number.text = account.accountNumber ?? '';
      _ifsc.text = account.ifsc ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final name = _holder.text.trim();
    final number = _number.text.replaceAll(RegExp(r'\s'), '');
    final ifsc = _ifsc.text.trim().toUpperCase();

    if (name.length < 2) {
      _toast('Enter account holder name');
      return;
    }
    if (!RegExp(r'^[0-9]{9,18}$').hasMatch(number)) {
      _toast('Enter a valid 9–18 digit account number');
      return;
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      _toast('Enter a valid IFSC code');
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<WalletApi>().updateBankAccount(
        accountHolderName: name,
        accountNumber: number,
        ifscCode: ifsc,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment method saved')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _toast('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment method')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Bank account for wallet withdrawals',
                  style: TextStyle(color: AppColors.muted),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _holder,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Account holder name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(18),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Account number',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ifsc,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saving ? null : _save(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(11),
                    _UpperCaseFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'IFSC code',
                    hintText: 'SBIN0001234',
                    prefixIcon: Icon(Icons.qr_code_2_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save payment method'),
                ),
              ],
            ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
