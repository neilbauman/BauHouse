import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../core/subscription/subscription_provider.dart';
import '../../core/supabase/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: BauColours.cream,
      appBar: AppBar(
        title: const Text('Settings', style: BauTypography.headline3),
        backgroundColor: BauColours.cream,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BauSpacing.lg),
          children: [
            // Subscription section
            _SectionHeader(title: 'Membership'),
            const SizedBox(height: BauSpacing.sm),
            _SubscriptionTile(isPremium: subState.isPremium),
            const SizedBox(height: BauSpacing.xl),

            // Account section
            _SectionHeader(title: 'Account'),
            const SizedBox(height: BauSpacing.sm),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About BauHouse',
              onTap: () => _showAbout(context),
            ),
            _SettingsTile(
              icon: Icons.article_outlined,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () {},
            ),
            const SizedBox(height: BauSpacing.xl),

            // Debug section (development only)
            _SectionHeader(title: 'Debug'),
            const SizedBox(height: BauSpacing.sm),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'BauHouse',
      applicationVersion: '0.1.0',
      applicationLegalese:
          'Build Your Corner of Something Real.\n\n© 2026 BauHouse',
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: BauTypography.label,
    );
  }
}

class _SubscriptionTile extends ConsumerWidget {
  final bool isPremium;
  const _SubscriptionTile({required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: BauColours.surface,
        borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
        border: Border.all(color: BauColours.gridLine),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BauSpacing.md,
          vertical: BauSpacing.sm,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPremium
                ? BauColours.sage.withValues(alpha: 0.15)
                : BauColours.blueprintBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPremium ? Icons.home_work : Icons.home_outlined,
            color: isPremium ? BauColours.sage : BauColours.blueprintBlue,
            size: 20,
          ),
        ),
        title: Text(
          isPremium ? 'Full Resident' : 'Visitor',
          style: BauTypography.headline3,
        ),
        subtitle: Text(
          isPremium
              ? 'You have full access to all BauHouse features.'
              : 'Upgrade for streak shields, no ads, and more.',
          style: BauTypography.bodySmall,
        ),
        trailing: isPremium
            ? null
            : const Icon(Icons.chevron_right, color: BauColours.midGrey),
        onTap: isPremium
            ? null
            : () => context.pushNamed('paywall', queryParameters: {
                'context': 'settings',
              }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: BauSpacing.xs),
      decoration: BoxDecoration(
        color: BauColours.surface,
        borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
        border: Border.all(color: BauColours.gridLine),
      ),
      child: ListTile(
        leading: Icon(icon, color: BauColours.midGrey, size: 20),
        title: Text(title, style: BauTypography.body),
        trailing:
            const Icon(Icons.chevron_right, color: BauColours.midGrey, size: 20),
        onTap: onTap,
      ),
    );
  }
}
