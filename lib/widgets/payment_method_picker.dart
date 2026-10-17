import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/wallet.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

/// Allowed booking payment methods from `POST /bookings/{id}/pay`.
class BookingPayMethods {
  BookingPayMethods._();

  static const wallet = 'wallet';
  static const cash = 'cash';
  static const upi = 'upi';
  static const card = 'card';
  static const netbanking = 'netbanking';
  static const gateway = 'gateway';

  static const online = {upi, card, netbanking, gateway};
  static const noRazorpay = {wallet, cash};

  static bool needsRazorpay(String method) => online.contains(method);

  static String normalize(String method) {
    final m = method.trim().toLowerCase();
    if (m == 'wallets') return wallet;
    return m;
  }

  /// Collapses UPI / card / netbanking into the single "online" choice.
  static String choiceOf(String method) {
    final m = normalize(method);
    if (online.contains(m)) return gateway;
    return m;
  }

  static String label(String method) {
    return switch (normalize(method)) {
      wallet => 'Wallet',
      cash => 'Cash',
      upi => 'UPI',
      card => 'Card',
      netbanking => 'Netbanking',
      gateway => 'Online',
      _ => method.toUpperCase(),
    };
  }
}

/// "Pay with" row that opens a bottom sheet with Online, Wallet and Cash.
/// Wallet and cash follow the admin payment settings.
class PaymentMethodPicker extends StatefulWidget {
  const PaymentMethodPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowCash = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool allowCash;

  @override
  State<PaymentMethodPicker> createState() => _PaymentMethodPickerState();
}

class _PaymentMethodPickerState extends State<PaymentMethodPicker> {
  bool _walletEnabled = true;
  bool _cashEnabled = true;
  double? _walletBalance;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final bookingApi = context.read<BookingApi>();
    final walletApi = context.read<WalletApi>();
    try {
      final config = await bookingApi.paymentConfig();
      if (!mounted) return;
      setState(() {
        _walletEnabled = config['enable_wallet_payments'] != false;
        _cashEnabled = config['enable_cash_payments'] != false;
      });
      _dropUnavailableChoice();
    } catch (_) {}
    try {
      final wallet = WalletModel.fromJson(await walletApi.me());
      if (mounted) setState(() => _walletBalance = wallet.balance);
    } catch (_) {}
  }

  void _dropUnavailableChoice() {
    final current = BookingPayMethods.choiceOf(widget.value);
    if (!_choices.any((c) => c.method == current)) {
      widget.onChanged(BookingPayMethods.gateway);
    }
  }

  String get _walletSubtitle {
    final balance = _walletBalance;
    if (balance == null) return 'Pay from wallet balance';
    return 'Balance ₹${balance.toStringAsFixed(balance == balance.roundToDouble() ? 0 : 2)}';
  }

  List<_PayChoice> get _choices => [
        const _PayChoice(
          BookingPayMethods.gateway,
          Icons.language_rounded,
          'Online',
          'UPI, Cards, Netbanking',
        ),
        if (_walletEnabled)
          _PayChoice(
            BookingPayMethods.wallet,
            Icons.account_balance_wallet_outlined,
            'KaamFast Wallet',
            _walletSubtitle,
          ),
        if (widget.allowCash && _cashEnabled)
          const _PayChoice(
            BookingPayMethods.cash,
            Icons.payments_outlined,
            'Cash',
            'Pay the partner in cash',
          ),
      ];

  _PayChoice get _selected {
    final current = BookingPayMethods.choiceOf(widget.value);
    final choices = _choices;
    return choices.firstWhere((c) => c.method == current, orElse: () => choices.first);
  }

  Future<void> _openSheet() async {
    final picked = await _showChoicesSheet(context, _choices, _selected.method);
    if (picked != null && picked != BookingPayMethods.choiceOf(widget.value)) {
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Material(
      color: AppColors.mist,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _openSheet,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(selected.icon, color: AppColors.navy, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pay with', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(
                      selected.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                  ],
                ),
              ),
              const Text(
                'Change',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentOrange),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.accentOrange),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standalone sheet for flows that pay an existing booking.
Future<String?> showPaymentMethodSheet(
  BuildContext context, {
  String current = BookingPayMethods.gateway,
  bool allowCash = true,
}) async {
  final bookingApi = context.read<BookingApi>();
  final walletApi = context.read<WalletApi>();
  var walletEnabled = true;
  var cashEnabled = true;
  String walletSubtitle = 'Pay from wallet balance';
  try {
    final config = await bookingApi.paymentConfig();
    walletEnabled = config['enable_wallet_payments'] != false;
    cashEnabled = config['enable_cash_payments'] != false;
  } catch (_) {}
  try {
    final balance = WalletModel.fromJson(await walletApi.me()).balance;
    walletSubtitle = 'Balance ₹${balance.toStringAsFixed(balance == balance.roundToDouble() ? 0 : 2)}';
  } catch (_) {}
  if (!context.mounted) return null;
  final choices = [
    const _PayChoice(BookingPayMethods.gateway, Icons.language_rounded, 'Online', 'UPI, Cards, Netbanking'),
    if (walletEnabled)
      _PayChoice(BookingPayMethods.wallet, Icons.account_balance_wallet_outlined, 'KaamFast Wallet', walletSubtitle),
    if (allowCash && cashEnabled)
      const _PayChoice(BookingPayMethods.cash, Icons.payments_outlined, 'Cash', 'Pay the partner in cash'),
  ];
  return _showChoicesSheet(context, choices, BookingPayMethods.choiceOf(current));
}

Future<String?> _showChoicesSheet(BuildContext context, List<_PayChoice> choices, String current) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose payment method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 14),
            for (final choice in choices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceTile(
                  choice: choice,
                  selected: choice.method == current,
                  onTap: () => Navigator.of(sheetContext).pop(choice.method),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.choice, required this.selected, required this.onTap});

  final _PayChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.sky : AppColors.mist,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.navy : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(choice.icon, color: AppColors.navy),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(choice.title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                  const SizedBox(height: 2),
                  Text(choice.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.navy : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayChoice {
  const _PayChoice(this.method, this.icon, this.title, this.subtitle);

  final String method;
  final IconData icon;
  final String title;
  final String subtitle;
}
