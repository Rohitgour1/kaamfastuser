import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _chat = TextEditingController();
  final _scroll = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _booted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _chat.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_booted) setState(() => _loading = true);
    try {
      final api = context.read<SupportApi>();
      final chat = await api.chat();
      await api.markChatRead();
      if (!mounted) return;
      setState(() {
        _messages = chat['messages'] is List ? chat['messages'] as List : [];
        _loading = false;
        _booted = true;
      });
      _jumpToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _sendChat() async {
    if (_chat.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<SupportApi>().sendChat(_chat.text.trim());
      _chat.clear();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with admin')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _messages.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'No messages yet. Say hello to start.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final m = _messages[index];
                              if (m is! Map) return const SizedBox.shrink();
                              final mine = '${m['sender_type']}' == 'user';
                              final text = '${m['body'] ?? m['message'] ?? ''}';
                              return Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mine ? AppColors.navy : AppColors.mist,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: mine ? Colors.white : AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chat,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sending ? null : _sendChat(),
                      decoration: const InputDecoration(hintText: 'Type a message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendChat,
                    style: IconButton.styleFrom(backgroundColor: AppColors.navy),
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
