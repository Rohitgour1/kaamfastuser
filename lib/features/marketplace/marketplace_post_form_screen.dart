import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/marketplace.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:provider/provider.dart';

class MarketplacePostFormScreen extends StatefulWidget {
  const MarketplacePostFormScreen({
    super.key,
    this.postId,
    this.initialType = 'sale',
  });

  final int? postId;
  final String initialType;

  @override
  State<MarketplacePostFormScreen> createState() =>
      _MarketplacePostFormScreenState();
}

class _MarketplacePostFormScreenState extends State<MarketplacePostFormScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _pincode = TextEditingController();

  MarketplaceConfig? _config;
  MarketplacePost? _existing;
  String _type = 'sale';
  String? _category;
  String? _condition;
  final _newImages = <XFile>[];
  bool _loading = true;
  bool _saving = false;

  bool get _isEdit => widget.postId != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _boot();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _city.dispose();
    _area.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      final api = context.read<MarketplaceApi>();
      final config = await api.config();
      MarketplacePost? existing;
      if (widget.postId != null) {
        existing = await api.show(widget.postId!);
      }
      if (!mounted) return;
      setState(() {
        _config = config;
        _existing = existing;
        if (existing != null) {
          _type = existing.type;
          _title.text = existing.title;
          _description.text = existing.description ?? '';
          _price.text = existing.price?.toString() ?? '';
          _city.text = existing.city ?? '';
          _area.text = existing.area ?? '';
          _pincode.text = existing.pincode ?? '';
          _category = existing.category;
          _condition = existing.condition;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _pickImages() async {
    final max = _config?.maxImages ?? 8;
    final remaining = max - _newImages.length - (_existing?.images.length ?? 0);
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Max $max images allowed')),
      );
      return;
    }
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked.isEmpty) return;
    setState(() {
      _newImages.addAll(picked.take(remaining));
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    final priceText = _price.text.trim();
    final price = priceText.isEmpty ? null : double.tryParse(priceText);
    if (priceText.isNotEmpty && price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = context.read<MarketplaceApi>();
      final paths = _newImages.map((e) => e.path).toList();
      MarketplacePost saved;
      if (_isEdit) {
        saved = await api.update(
          widget.postId!,
          title: title,
          description: _description.text.trim(),
          price: price,
          condition: _condition,
          category: _category,
          city: _city.text.trim(),
          area: _area.text.trim(),
          pincode: _pincode.text.trim(),
          imagePaths: paths,
        );
      } else {
        saved = await api.create(
          type: _type,
          title: title,
          description: _description.text.trim(),
          price: price,
          condition: _condition,
          category: _category,
          city: _city.text.trim(),
          area: _area.text.trim(),
          pincode: _pincode.text.trim(),
          imagePaths: paths,
        );
      }
      if (!mounted) return;
      context.go('/marketplace/posts/${saved.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSale = _type == 'sale';
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? 'Edit post'
            : (isSale ? 'Sell item' : 'Post request')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (!_isEdit)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'sale', label: Text('For sale')),
                      ButtonSegment(value: 'request', label: Text('Wanted')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (v) => setState(() => _type = v.first),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _title,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Used office chair',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _description,
                  maxLines: 4,
                  maxLength: 5000,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: isSale ? 'Price (₹)' : 'Budget (₹)',
                    hintText: 'Optional',
                  ),
                ),
                const SizedBox(height: 12),
                if ((_config?.categories ?? const []).isNotEmpty)
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Select category'),
                      ),
                      ..._config!.categories.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                if (isSale && (_config?.conditions ?? const []).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _condition,
                    decoration: const InputDecoration(labelText: 'Condition'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Select condition'),
                      ),
                      ..._config!.conditions.map(
                        (c) => DropdownMenuItem(
                          value: c['value'],
                          child: Text(c['label'] ?? c['value'] ?? ''),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _condition = v),
                  ),
                ],
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Photos',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (_existing?.images.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existing!.images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final img = _existing!.images[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            img.url,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 88,
                              height: 88,
                              color: AppColors.mist,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (_newImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _newImages.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final file = _newImages[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(file.path),
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _newImages.removeAt(index)),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Publish'),
                ),
              ],
            ),
    );
  }
}
