import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';

class StarRatingBar extends StatelessWidget {
  const StarRatingBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            onPressed: !enabled || onChanged == null ? null : () => onChanged!(star),
            icon: Icon(
              star <= value ? Icons.star_rounded : Icons.star_border_rounded,
              color: star <= value ? const Color(0xFFF5B301) : AppColors.muted,
              size: size,
            ),
          ),
      ],
    );
  }
}

class ServiceRatingResult {
  const ServiceRatingResult({required this.rating, this.comment});

  final int rating;
  final String? comment;
}

Future<ServiceRatingResult?> askServiceRating(
  BuildContext context, {
  required String serviceName,
  String? partnerName,
}) async {
  var rating = 5;
  final comment = TextEditingController();
  final submitted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text(
              'Rate this service',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  partnerName == null || partnerName.isEmpty
                      ? 'How was $serviceName?'
                      : 'How was $serviceName with $partnerName?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 8),
                StarRatingBar(
                  value: rating,
                  onChanged: (value) => setLocal(() => rating = value),
                ),
                TextField(
                  controller: comment,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Comment (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );
  final text = comment.text.trim();
  comment.dispose();
  if (submitted != true) return null;
  return ServiceRatingResult(rating: rating, comment: text.isEmpty ? null : text);
}
