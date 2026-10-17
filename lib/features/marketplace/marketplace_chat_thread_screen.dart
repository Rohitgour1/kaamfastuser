import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/models/marketplace.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/live_sync.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketplaceChatThreadScreen extends StatefulWidget {
  const MarketplaceChatThreadScreen({super.key, required this.chatId});

  final int chatId;

  @override
  State<MarketplaceChatThreadScreen> createState() =>
      _MarketplaceChatThreadScreenState();
}

class _MarketplaceChatThreadScreenState
    extends State<MarketplaceChatThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <MarketplaceMessage>[];
  MarketplaceChat? _chat;
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;
  LiveSync? _live;
  int _lastPushTick = 0;
  double? _offerAmount;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _pollNew());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final live = context.read<LiveSync>();
    if (!identical(_live, live)) {
      _live?.removeListener(_onLive);
      _live = live;
      _lastPushTick = live.pushTick;
      _live!.addListener(_onLive);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _live?.removeListener(_onLive);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onLive() {
    final live = _live;
    if (live == null || live.pushTick == _lastPushTick) return;
    _lastPushTick = live.pushTick;
    if (live.lastData['type'] != 'marketplace.chat') return;
    final chatId = int.tryParse(live.lastData['chat_id'] ?? '');
    if (chatId != widget.chatId) return;
    _pollNew();
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) setState(() => _loading = true);
    try {
      final result =
          await context.read<MarketplaceApi>().chatThread(widget.chatId);
      if (!mounted) return;
      setState(() {
        _chat = result.chat;
        _messages
          ..clear()
          ..addAll(result.messages);
        _loading = false;
      });
      _jumpToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _pollNew() async {
    if (!mounted || _messages.isEmpty) {
      if (_messages.isEmpty && !_loading) await _load();
      return;
    }
    final maxId = _messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
    try {
      final result = await context.read<MarketplaceApi>().chatThread(
            widget.chatId,
            afterId: maxId,
          );
      if (!mounted || result.messages.isEmpty) return;
      setState(() {
        _chat = result.chat;
        for (final msg in result.messages) {
          if (_messages.every((m) => m.id != msg.id)) {
            _messages.add(msg);
          }
        }
      });
      _jumpToEnd();
    } catch (_) {}
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    await _sendText(_input.text.trim(), clearInput: true);
  }

  Future<void> _sendText(String text, {bool clearInput = false}) async {
    final body = text.trim();
    if (body.isEmpty || _sending) return;
    if (_chat?.isClosed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This chat is closed')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final msg = await context
          .read<MarketplaceApi>()
          .sendMessage(widget.chatId, body);
      if (clearInput) _input.clear();
      if (!mounted) return;
      setState(() {
        if (msg.id == 0 || _messages.every((m) => m.id != msg.id)) {
          _messages.add(msg);
        }
      });
      _jumpToEnd();
      await _pollNew();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool get _isSellerSide {
    final chat = _chat;
    final post = chat?.post;
    if (chat == null) return false;
    if (chat.isOwner) return true;
    if (post?.isMine == true) return true;
    final myId = context.read<AuthProvider>().user?.id;
    if (myId != null && post?.user?.id == myId) return true;
    return false;
  }

  List<_QuickReply> _quickReplies() {
    final chat = _chat;
    final post = chat?.post;
    if (chat == null || post == null) return const [];

    final l10n = context.l10n;
    final isSeller = _isSellerSide;
    final isSale = post.isSale;

    if (isSeller && isSale) {
      return [
        _QuickReply(label: l10n.qrYesAvailable, message: l10n.qrYesAvailableMsg),
        _QuickReply(label: l10n.makeAnOffer, message: '', isOffer: true),
        _QuickReply(label: l10n.qrYourBestOffer, message: l10n.qrYourBestOfferMsg),
        _QuickReply(label: l10n.qrCanMeetSeller, message: l10n.qrCanMeetSellerMsg),
        _QuickReply(label: l10n.qrPriceNegotiable, message: l10n.qrPriceNegotiableMsg),
        _QuickReply(label: l10n.qrPriceFirm, message: l10n.qrPriceFirmMsg),
        _QuickReply(label: l10n.qrWhereToMeet, message: l10n.qrWhereToMeetMsg),
        _QuickReply(label: l10n.qrSoldAlready, message: l10n.qrSoldAlreadyMsg),
      ];
    }

    if (isSeller && !isSale) {
      return [
        _QuickReply(label: l10n.qrStillNeededYes, message: l10n.qrStillNeededYesMsg),
        _QuickReply(label: l10n.makeAnOffer, message: '', isOffer: true),
        _QuickReply(label: l10n.qrYourPrice, message: l10n.qrYourPriceMsg),
        _QuickReply(label: l10n.qrCanWeMeet, message: l10n.qrCanMeetSellerMsg),
        _QuickReply(label: l10n.qrSharePhotos, message: l10n.qrSharePhotosMsg),
        _QuickReply(label: l10n.qrCondition, message: l10n.qrConditionMsg),
        _QuickReply(label: l10n.qrNotNeeded, message: l10n.qrNotNeededMsg),
      ];
    }

    if (isSale) {
      return [
        _QuickReply(label: l10n.qrIsItAvailable, message: l10n.qrIsItAvailableMsg),
        _QuickReply(label: l10n.makeAnOffer, message: '', isOffer: true),
        _QuickReply(label: l10n.qrCanWeMeet, message: l10n.qrCanWeMeetMsg),
        _QuickReply(label: l10n.qrFinalPrice, message: l10n.qrFinalPriceMsg),
        _QuickReply(label: l10n.qrCondition, message: l10n.qrConditionMsg),
        _QuickReply(label: l10n.qrWhereToSee, message: l10n.qrWhereToSeeMsg),
      ];
    }

    return [
      _QuickReply(label: l10n.qrIHaveThis, message: l10n.qrIHaveThisMsg),
      _QuickReply(label: l10n.makeAnOffer, message: '', isOffer: true),
      _QuickReply(label: l10n.qrStillNeeded, message: l10n.qrStillNeededMsg),
      _QuickReply(label: l10n.qrCanWeMeet, message: l10n.qrCanWeMeetMsg),
      _QuickReply(label: l10n.qrBudgetFlexible, message: l10n.qrBudgetFlexibleMsg),
    ];
  }

  double _baseOfferPrice() {
    final listed = _chat?.post?.price;
    if (listed != null && listed > 0) return listed;
    return _offerAmount ?? 1000;
  }

  String _formatInr(double amount) {
    if (amount % 1 == 0) return amount.toStringAsFixed(0);
    return amount.toStringAsFixed(2);
  }

  Future<void> _openOfferSheet() async {
    var amount = _offerAmount ?? _baseOfferPrice();
    final listed = _chat?.post?.price;
    final l10n = context.l10n;

    final confirmed = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void bump(double factor) {
              final next = (amount * factor).roundToDouble();
              setSheet(() => amount = next < 1 ? 1 : next);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.makeAnOffer,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  if (listed != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.listedAt(_formatInr(listed)),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton.filled(
                        onPressed: () => bump(0.9),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.mist,
                          foregroundColor: AppColors.navy,
                        ),
                        icon: const Icon(Icons.remove),
                        tooltip: l10n.decrease10,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '₹${_formatInr(amount)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentOrange,
                              ),
                            ),
                            Text(
                              l10n.tapToChangeBy10,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => bump(1.1),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add),
                        tooltip: l10n.increase10,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        label: Text(l10n.decrease10),
                        onPressed: () => bump(0.9),
                      ),
                      ActionChip(
                        label: Text(l10n.increase10),
                        onPressed: () => bump(1.1),
                      ),
                      if (listed != null)
                        ActionChip(
                          label: Text(l10n.listedPrice),
                          onPressed: () => setSheet(() => amount = listed),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, amount),
                    child: Text(l10n.sendOffer(_formatInr(amount))),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == null || !mounted) return;
    setState(() => _offerAmount = confirmed);
    final msg = _isSellerSide
        ? l10n.offerMessageSeller(_formatInr(confirmed))
        : l10n.offerMessageBuyer(_formatInr(confirmed));
    await _sendText(msg);
  }

  Future<void> _onQuickReply(_QuickReply reply) async {
    if (reply.isOffer) {
      await _openOfferSheet();
      return;
    }
    await _sendText(reply.message);
  }

  Future<void> _call() async {
    final phone = _chat?.otherUser?.phone?.trim();
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _closeChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close chat?'),
        content: const Text('You will not be able to send more messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<MarketplaceApi>().closeChat(widget.chatId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    final phone = chat?.otherUser?.phone?.trim();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chat?.otherUser?.displayName ?? 'Chat',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if (chat?.post?.title != null)
              Text(
                chat!.post!.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (phone != null && phone.isNotEmpty)
            IconButton(
              tooltip: 'Call',
              onPressed: _call,
              icon: const Icon(Icons.call_outlined),
            ),
          if (chat != null && !chat.isClosed)
            IconButton(
              tooltip: 'Close chat',
              onPressed: _closeChat,
              icon: const Icon(Icons.lock_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            context.l10n.sayHello,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final m = _messages[index];
                            return Align(
                              alignment: m.isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * 0.78,
                                ),
                                decoration: BoxDecoration(
                                  color: m.isMine
                                      ? AppColors.navy
                                      : AppColors.mist,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  m.body,
                                  style: TextStyle(
                                    color: m.isMine
                                        ? Colors.white
                                        : AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (chat?.isClosed == true)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      context.l10n.chatClosed,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_sending)
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                              itemCount: _quickReplies().length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final reply = _quickReplies()[index];
                                return ActionChip(
                                  label: Text(reply.label),
                                  backgroundColor: reply.isOffer
                                      ? AppColors.sky
                                      : AppColors.mist,
                                  side: BorderSide(
                                    color: reply.isOffer
                                        ? AppColors.accentOrange
                                            .withValues(alpha: 0.35)
                                        : AppColors.line,
                                  ),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: reply.isOffer
                                        ? AppColors.lavenderText
                                        : AppColors.ink,
                                  ),
                                  onPressed: () => _onQuickReply(reply),
                                );
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _input,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) =>
                                      _sending ? null : _send(),
                                  decoration: InputDecoration(
                                    hintText: context.l10n.typeAMessage,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _sending ? null : _send,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.navy,
                                ),
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _QuickReply {
  const _QuickReply({
    required this.label,
    required this.message,
    this.isOffer = false,
  });

  final String label;
  final String message;
  final bool isOffer;
}
