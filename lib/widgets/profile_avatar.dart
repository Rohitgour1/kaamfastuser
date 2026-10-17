import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/models/user.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.user,
    this.file,
    this.radius = 32,
    this.onTap,
    this.showEditBadge = false,
  });

  final UserModel? user;
  final File? file;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    final url = user?.photoUrl;
    final letter = user?.hasName == true
        ? user!.displayName[0].toUpperCase()
        : 'U';
    ImageProvider? image;
    if (file != null) {
      image = FileImage(file!);
    } else if (url != null) {
      image = NetworkImage(url);
    }

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy.withValues(alpha: 0.1),
      backgroundImage: image,
      child: image == null
          ? Text(
              letter,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.7,
              ),
            )
          : null,
    );

    final stacked = showEditBadge
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ],
          )
        : avatar;

    if (onTap == null) return stacked;
    return InkWell(onTap: onTap, customBorder: const CircleBorder(), child: stacked);
  }
}
