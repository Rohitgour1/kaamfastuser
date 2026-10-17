import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kaamfast/core/theme/app_theme.dart';

/// Asks camera vs gallery, then returns the picked photo.
Future<XFile?> pickPhotoWithSource(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.navy),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.navy),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;
  return ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1600, maxHeight: 1600);
}

/// Dashed upload box that turns into a preview with change / remove.
class PhotoUploadBox extends StatelessWidget {
  const PhotoUploadBox({
    super.key,
    required this.photo,
    required this.onPick,
    required this.onRemove,
    this.title = 'Upload photo',
    this.subtitle = 'Optional · Tap to take a photo or choose from gallery',
    this.highlightError = false,
  });

  final XFile? photo;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final String title;
  final String subtitle;
  final bool highlightError;

  @override
  Widget build(BuildContext context) {
    final file = photo;
    if (file == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _DashedRectPainter(highlightError ? AppColors.danger : AppColors.navy.withValues(alpha: 0.35)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.sky,
                  child: Icon(Icons.cloud_upload_outlined, color: AppColors.navy, size: 26),
                ),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: highlightError ? AppColors.danger : AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(file.path), fit: BoxFit.cover),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  tooltip: 'Remove photo',
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: FilledButton.icon(
                onPressed: onPick,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => oldDelegate.color != color;
}
