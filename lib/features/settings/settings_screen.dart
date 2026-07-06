import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/config/app_config.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Central settings hub — links to privacy, data, account, and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.s5,
            vertical: tokens.s4,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: tokens.headlineLarge),
                SizedBox(height: tokens.s5),

                // -- Account section --
                _SectionHeader(title: 'Account', tokens: tokens),
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'Name, goals, experience level',
                  onTap: () => context.go('/profile'),
                ),
                SizedBox(height: tokens.s3),

                // -- Privacy section --
                _SectionHeader(title: 'Privacy', tokens: tokens),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How we collect and use your data',
                  onTap: () => context.go('/privacy-policy'),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'Your agreement with TransformFit',
                  onTap: () => context.go('/terms'),
                ),
                SizedBox(height: tokens.s3),

                // -- Data section --
                _SectionHeader(title: 'Data', tokens: tokens),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Export Data',
                  subtitle: 'Download all your data as JSON',
                  onTap: () => context.go('/data-export'),
                ),
                _SettingsTile(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  subtitle: 'Permanently remove your data',
                  onTap: () => _showDeleteConfirmation(context),
                  isDestructive: true,
                ),
                SizedBox(height: tokens.s3),

                // -- Notifications section --
                _SectionHeader(title: 'Notifications', tokens: tokens),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Workout reminders and coach prompts',
                  onTap: () {
                    // TODO(M3): Implement notification settings screen
                  },
                ),
                SizedBox(height: tokens.s3),

                // -- About section --
                _SectionHeader(title: 'About', tokens: tokens),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: AppConfig.appVersion,
                  onTap: null,
                ),
                SizedBox(height: tokens.s7),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DigitalAtelierTokens2.surface,
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO(M3): Implement actual account deletion via Supabase
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deletion will be implemented with Supabase integration.',
                  ),
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: DigitalAtelierTokens.errorText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.tokens});

  final String title;
  final DigitalAtelierExtension tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.s2, top: tokens.s1),
      child: Text(
        title.toUpperCase(),
        style: tokens.dataLabel.copyWith(
          color: DigitalAtelierTokens.accentOrange,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DigitalAtelierExtension>()!;
    final titleColor = isDestructive
        ? DigitalAtelierTokens.errorText
        : DigitalAtelierTokens.textPrimary;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.s2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DigitalAtelierTokens2.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.s3,
              vertical: tokens.s3,
            ),
            decoration: BoxDecoration(
              color: DigitalAtelierTokens2.surface,
              borderRadius:
                  BorderRadius.circular(DigitalAtelierTokens2.radiusMd),
              border: Border.all(color: DigitalAtelierTokens2.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(icon, color: titleColor, size: 22),
                SizedBox(width: tokens.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: tokens.titleMedium.copyWith(color: titleColor)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: tokens.bodySmall),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: tokens.bodySmall.color,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
