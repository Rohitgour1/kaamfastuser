import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<NotificationApi>().list();
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<NotificationApi>().markAllRead();
              await _load();
            },
            child: const Text('Read all'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No notifications yet')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final unread = item['read_at'] == null;
                  return Card(
                    color: unread ? AppColors.mist : Colors.white,
                    child: ListTile(
                      title: Text(
                        item['title']?.toString() ?? 'Update',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(item['body']?.toString() ?? ''),
                      onTap: () async {
                        final id = item['id'];
                        if (id is int)
                          await context.read<NotificationApi>().markRead(id);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
