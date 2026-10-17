import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/common/app_constants.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/l10n/l10n_ext.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/providers/locale_provider.dart';
import 'package:kaamfast/widgets/legal_links.dart';
import 'package:kaamfast/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthProvider>().user;
    final locale = context.watch<LocaleProvider>();
    final title = user?.hasName == true ? user!.displayName : 'user';
    final subtitle = user?.phoneLabel ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: ListTile(
                leading: ProfileAvatar(user: user, radius: 28),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(subtitle),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            icon: Icons.edit_outlined,
            title: l10n.editProfile,
            subtitle: l10n.editProfileSubtitle,
            onTap: () => context.push('/profile/edit'),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.language_rounded,
            title: l10n.language,
            subtitle: l10n.languageSubtitle(locale.displayName),
            onTap: () => context.push('/language?edit=1'),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/invite'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.inviteEarn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            l10n.inviteEarnSubtitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.location_on_outlined,
            title: l10n.savedAddresses,
            onTap: () => context.push('/addresses'),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.wallet,
            onTap: () => context.push('/wallet'),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.storefront_outlined,
            title: l10n.marketplace,
            subtitle: l10n.marketplaceSubtitle,
            onTap: () => context.push('/marketplace/sale'),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.inventory_2_outlined,
            title: l10n.myMarketplacePosts,
            onTap: () => context.push('/marketplace/mine'),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.chat_bubble_outline,
            title: l10n.marketplaceChats,
            onTap: () => context.push('/marketplace/chats'),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.lightbulb_outline,
            title: 'Suggest a service',
            subtitle: 'Request something we don’t offer yet',
            onTap: () => context.push('/service-requests'),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.support_agent,
            title: l10n.support,
            onTap: () => context.push('/support'),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.description_outlined,
            title: locale.isHindi ? 'नियम और शर्तें' : 'Terms & Conditions',
            onTap: () => openLegalUrl(context, AppConstants.termsUrl),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: locale.isHindi ? 'प्राइवेसी पॉलिसी' : 'Privacy Policy',
            onTap: () => openLegalUrl(context, AppConstants.privacyPolicyUrl),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
