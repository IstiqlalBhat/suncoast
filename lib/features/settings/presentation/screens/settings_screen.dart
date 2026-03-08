import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/user_settings_model.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            // Profile section
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      (user?.email?.substring(0, 1) ?? '?').toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.userMetadata?['name'] as String? ?? 'User',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Security
            _SectionTitle(title: AppStrings.security),
            _SettingsTile(
              icon: Icons.face,
              title: AppStrings.enableFaceId,
              trailing: Switch(
                value: settings.faceIdEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).updateFaceId(v),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Voice
            _SectionTitle(title: AppStrings.voiceOutput),
            _SettingsTile(
              icon: Icons.volume_up,
              title: 'Voice Output',
              trailing: Switch(
                value: settings.voiceOutputEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).updateVoiceOutput(v),
              ),
            ),
            _SettingsTile(
              icon: Icons.auto_awesome,
              title: 'Premium Voice (ElevenLabs)',
              subtitle: 'Higher quality AI voice',
              trailing: Switch(
                value: settings.usePremiumTts,
                onChanged: settings.voiceOutputEnabled
                    ? (v) =>
                        ref.read(settingsProvider.notifier).updatePremiumTts(v)
                    : null,
              ),
            ),
            _SettingsTile(
              icon: Icons.speed,
              title: 'Voice Speed',
              subtitle: '${settings.voiceSpeed.toStringAsFixed(1)}x',
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: settings.voiceSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).updateVoiceSpeed(v),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Confirmation
            _SectionTitle(title: 'Confirmation Prompts'),
            ...ConfirmationMode.values.map(
              (mode) => _SettingsTile(
                icon: Icons.check_circle_outline,
                title: mode.name[0].toUpperCase() + mode.name.substring(1),
                trailing: Radio<ConfirmationMode>(
                  value: mode,
                  groupValue: settings.confirmationMode,
                  onChanged: (v) {
                    if (v != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateConfirmationMode(v);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXL),

            // Sign out
            OutlinedButton.icon(
              onPressed: () => _handleSignOut(context, ref),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                AppStrings.signOut,
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXXL),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.signOut),
        content: const Text(AppStrings.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              AppStrings.signOut,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.paddingS,
        left: AppDimensions.paddingXS,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary, size: 22),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: subtitle != null
            ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: 2,
        ),
      ),
    );
  }
}
