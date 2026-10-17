import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/module.dart';
import 'package:kaamfast/models/service_request.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class ServiceRequestsScreen extends StatefulWidget {
  const ServiceRequestsScreen({super.key});

  @override
  State<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  final _items = <ServiceRequestItem>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<ServiceRequestApi>().list();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      case 'reviewed':
        return AppColors.accentOrange;
      case 'closed':
        return AppColors.muted;
      default:
        return AppColors.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service suggestions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/service-requests/new');
          if (created == true && mounted) _load();
        },
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Suggest'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(child: Text(_error!)),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    )
                  : _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 80),
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 56,
                              color: AppColors.muted,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No suggestions yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tell us which service you need in your area. We’ll review and try to add it.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () async {
                                final created = await context.push<bool>(
                                  '/service-requests/new',
                                );
                                if (created == true && mounted) _load();
                              },
                              child: const Text('Suggest a service'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.line),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  item.module?.name,
                                  item.city,
                                  item.displayStatus,
                                ]
                                    .whereType<String>()
                                    .where((e) => e.trim().isNotEmpty)
                                    .join(' · '),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(item.status)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.displayStatus,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(item.status),
                                  ),
                                ),
                              ),
                              onTap: () => context.push(
                                '/service-requests/${item.id}',
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}

class ServiceRequestFormScreen extends StatefulWidget {
  const ServiceRequestFormScreen({super.key});

  @override
  State<ServiceRequestFormScreen> createState() =>
      _ServiceRequestFormScreenState();
}

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _pincode = TextEditingController();

  List<ServiceModule> _modules = const [];
  int? _moduleId;
  bool _loadingModules = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.read<LocationProvider>().displayLabel;
      if (loc.isNotEmpty && !loc.toLowerCase().contains('select')) {
        // Best-effort: put label into city/area fields if empty.
        if (_city.text.isEmpty) {
          final parts = loc.split(',').map((e) => e.trim()).toList();
          if (parts.isNotEmpty) _area.text = parts.first;
          if (parts.length > 1) _city.text = parts[1];
        }
      }
      _loadModules();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    _area.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _loadModules() async {
    try {
      final modules = await context.read<ModuleService>().list();
      if (!mounted) return;
      setState(() {
        _modules = modules;
        _loadingModules = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingModules = false);
    }
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a service title')),
      );
      return;
    }
    if (title.length > 160) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must be under 160 characters')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<ServiceRequestApi>().create(
            title: title,
            description: _description.text.trim(),
            serviceModuleId: _moduleId,
            city: _city.text.trim(),
            area: _area.text.trim(),
            pincode: _pincode.text.trim(),
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thanks!'),
          content: const Text(
            'We’ll review this suggestion and get back to you.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suggest a service')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'Missing a service?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tell us what you need. Our team will review and may add it to Kaam Fast.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _title,
            maxLength: 160,
            decoration: const InputDecoration(
              labelText: 'Service title *',
              hintText: 'e.g. AC Repair',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Details (optional)',
              alignLabelWithHint: true,
              hintText: 'What exactly do you need?',
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingModules)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (_modules.isNotEmpty)
            DropdownButtonFormField<int?>(
              // ignore: deprecated_member_use
              value: _moduleId,
              decoration: const InputDecoration(
                labelText: 'Related module (optional)',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None / Other'),
                ),
                ..._modules.map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _moduleId = v),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'City'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _area,
            decoration: const InputDecoration(labelText: 'Area'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pincode,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pincode'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit suggestion'),
          ),
        ],
      ),
    );
  }
}

class ServiceRequestDetailScreen extends StatefulWidget {
  const ServiceRequestDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<ServiceRequestDetailScreen> createState() =>
      _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState
    extends State<ServiceRequestDetailScreen> {
  ServiceRequestItem? _item;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await context.read<ServiceRequestApi>().show(widget.id);
      if (!mounted) return;
      setState(() {
        _item = item;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      appBar: AppBar(title: const Text('Suggestion')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || item == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error ?? 'Not found'),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${item.displayStatus}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (item.module?.name != null) ...[
                      const SizedBox(height: 6),
                      Text('Module: ${item.module!.name}'),
                    ],
                    if ([item.area, item.city, item.pincode]
                        .whereType<String>()
                        .any((e) => e.trim().isNotEmpty)) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          item.area,
                          item.city,
                          item.pincode,
                        ]
                            .whereType<String>()
                            .where((e) => e.trim().isNotEmpty)
                            .join(', '),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                    if (item.description != null &&
                        item.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Details',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(item.description!),
                    ],
                    if (item.showAdminNotes) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Admin notes',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(item.adminNotes!),
                    ],
                  ],
                ),
    );
  }
}
