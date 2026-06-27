import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/topic_chip.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user.dart';
import '../../../services/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _modeLabel(NotificationMode m) {
    switch (m) {
      case NotificationMode.instant:
        return 'Instant';
      case NotificationMode.dailyDigest:
        return 'Daily digest';
      case NotificationMode.weeklyDigest:
        return 'Weekly digest';
      case NotificationMode.silent:
        return 'Silent';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _SectionTitle('NOTIFICATIONS'),
          ...NotificationMode.values.map((m) => RadioListTile<NotificationMode>(
                value: m,
                groupValue: user?.notificationMode ?? NotificationMode.dailyDigest,
                onChanged: (mode) {
                  if (mode != null) {
                    ref
                        .read(currentUserProvider.notifier)
                        .setNotificationMode(mode);
                  }
                },
                title: Text(_modeLabel(m)),
                activeColor: AppColors.brandPrimary,
              )),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('APPEARANCE'),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (m) => ref.read(themeModeProvider.notifier).state = m!,
            title: const Text('System default'),
            activeColor: AppColors.brandPrimary,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (m) => ref.read(themeModeProvider.notifier).state = m!,
            title: const Text('Light'),
            activeColor: AppColors.brandPrimary,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (m) => ref.read(themeModeProvider.notifier).state = m!,
            title: const Text('Dark'),
            activeColor: AppColors.brandPrimary,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('YOUR INTERESTS'),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Interests.all.map((i) {
                final selected = user?.interests.contains(i) ?? false;
                return TopicChip(
                  label: i,
                  selected: selected,
                  onTap: () {
                    final current =
                        List<String>.from(user?.interests ?? const []);
                    if (selected) {
                      current.remove(i);
                    } else {
                      current.add(i);
                    }
                    ref
                        .read(currentUserProvider.notifier)
                        .setInterests(current);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('ABOUT'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                _AboutRow(label: 'Version', value: AppConstants.appVersion),
                const Divider(height: 24),
                const _AboutRow(label: 'Privacy Policy', value: '→'),
                const Divider(height: 24),
                const _AboutRow(label: 'Terms of Service', value: '→'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
