import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';

Future<double?> showAmountSheet(
  BuildContext context, {
  required String title,
  String hint = 'Amount (₹)',
  String confirmLabel = 'Continue',
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _AmountSheet(title: title, hint: hint, confirmLabel: confirmLabel),
  );
}

Future<({double amount, String upi})?> showWithdrawSheet(BuildContext context) {
  return showModalBottomSheet<({double amount, String upi})>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _WithdrawSheet(),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.hint,
    required this.confirmLabel,
  });

  final String title;
  final String hint;
  final String confirmLabel;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: widget.hint),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(_amount.text.trim());
              if (value == null || value < 1) return;
              Navigator.pop(context, value);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amount = TextEditingController();
  final _upi = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _upi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Withdraw',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'Payout uses your saved bank account. UPI ID is required.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount (₹)'),
            autofocus: true,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _upi,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              hintText: 'name@ybl',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(_amount.text.trim());
              final upi = _upi.text.trim();
              if (value == null || value < 1) return;
              if (!RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(upi)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid UPI ID, like name@ybl')),
                );
                return;
              }
              Navigator.pop(context, (amount: value, upi: upi));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Request withdrawal'),
          ),
        ],
      ),
    );
  }
}
