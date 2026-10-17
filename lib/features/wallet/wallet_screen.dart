import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/wallet.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/live_sync.dart';
import 'package:kaamfast/services/razorpay_checkout.dart';
import 'package:kaamfast/widgets/wallet_amount_sheet.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletModel? _wallet;
  WalletBankAccount? _bankAccount;
  List<WalletTxn> _txns = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  int _lastTick = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tick = context.watch<LiveSync>().tick;
    if (_lastTick != -1 && tick != _lastTick) {
      _load();
    }
    _lastTick = tick;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<WalletApi>();
      final wallet = WalletModel.fromJson(await api.me());
      WalletBankAccount? bankAccount;
      try {
        bankAccount = WalletBankAccount.fromJson(await api.bankAccount());
      } catch (_) {}
      final txns = (await api.transactions())
          .whereType<Map>()
          .map((e) => WalletTxn.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _bankAccount = bankAccount;
        _txns = txns;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _addMoney() async {
    final amount = await showAmountSheet(
      context,
      title: 'Add money',
      confirmLabel: 'Pay with Razorpay',
    );
    if (amount == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final api = context.read<WalletApi>();
      final user = context.read<AuthProvider>().user;
      final order = await api.topup(amount);
      final topupId = (order['id'] as num?)?.toInt();
      if (topupId == null) throw Exception('Could not start wallet top-up.');
      var key = order['razorpay_key']?.toString().trim() ?? '';
      if (key.isEmpty) {
        try {
          final config = await api.paymentConfig();
          key = config['key_id']?.toString().trim() ?? '';
        } catch (_) {}
      }
      if (key.isEmpty) {
        throw Exception(
          'Razorpay Key ID missing. Save it in Admin → Payments.',
        );
      }
      final mock = order['mock'] == true;
      final paid = await RazorpayCheckout().open(
        key: key,
        orderId: mock ? '' : (order['gateway_order_id']?.toString() ?? ''),
        amountPaise:
            (order['amount_paise'] as num?)?.toInt() ?? (amount * 100).round(),
        description: 'Wallet top-up',
        contact: user?.phone,
        email: user?.email,
      );
      await api.confirmTopup(topupId, paid);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wallet credited')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    if (_bankAccount?.configured != true) {
      final saved = await context.push<bool>('/wallet/payment-method');
      if (!mounted) return;
      if (saved == true) await _load();
      if (!mounted || _bankAccount?.configured != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save a payment method before withdrawing')),
        );
        return;
      }
    }
    final result = await showWithdrawSheet(context);
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<WalletApi>().withdraw(
        amount: result.amount,
        upiId: result.upi,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Withdrawal requested')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.navyDeep,
                              AppColors.navy,
                              AppColors.accentOrange,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available balance',
                              style: TextStyle(color: Color(0xFFFFE8D6)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${(_wallet?.balance ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _busy ? null : _addMoney,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.navy,
                                    ),
                                    child: const Text('Add money'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _busy ? null : _withdraw,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    child: const Text('Withdraw'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.line),
                        ),
                        leading: const Icon(Icons.account_balance_outlined),
                        title: const Text('Payment method'),
                        subtitle: Text(
                          _bankAccount?.subtitle ??
                              'Add bank account for withdrawals',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final saved = await context.push<bool>(
                            '/wallet/payment-method',
                          );
                          if (saved == true && mounted) await _load();
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Transactions',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_txns.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('No wallet activity yet')),
                        )
                      else
                        ..._txns.map(
                          (txn) => Card(
                            child: ListTile(
                              title: Text(txn.description ?? txn.direction),
                              subtitle: Text(txn.createdAt ?? ''),
                              trailing: Text(
                                '${txn.direction == 'credit' ? '+' : '-'}₹${txn.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: txn.direction == 'credit'
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (_busy)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
