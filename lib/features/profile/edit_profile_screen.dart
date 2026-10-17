import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/user.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  File? _photo;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name.text = user?.name ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked == null || !mounted) return;

    setState(() {
      _photo = File(picked.path);
      _uploadingPhoto = true;
    });
    try {
      final raw = await context.read<ProfileApi>().uploadAvatar(picked.path);
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(UserModel.fromJson(raw));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final email = _email.text.trim();
      final raw = await context.read<ProfileApi>().update(
        name: _name.text.trim(),
        email: email.isEmpty ? null : email,
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(UserModel.fromJson(raw));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ProfileAvatar(
                      user: user,
                      file: _photo,
                      radius: 48,
                      showEditBadge: true,
                      onTap: _uploadingPhoto ? null : _pickPhoto,
                    ),
                    if (_uploadingPhoto)
                      const SizedBox(
                        width: 96,
                        height: 96,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _uploadingPhoto ? null : _pickPhoto,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Change photo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Your name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Phone cannot be changed: ${user?.phoneLabel ?? ''}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save profile'),
          ),
        ],
      ),
    );
  }
}
