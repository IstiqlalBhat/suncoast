import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../shared/models/user_settings_model.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settingsAsync = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Decorative background
          Positioned(
            top: -40,
            right: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.deepForest.withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.passive.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),

          // Content
          settingsAsync.when(
            data: (settings) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Profile section with circle avatar ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      // Avatar with ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: c.deepForest,
                          child: Text(
                            (user?.email?.substring(0, 1) ?? '?')
                                .toUpperCase(),
                            style: TextStyle(
                              color: c.primaryLight,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.userMetadata?['name'] as String? ?? 'User',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
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
                const SizedBox(height: 28),

                // ── Appearance ──
                const _SectionTitle(title: 'Appearance'),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _ThemeModeTile(
                      currentMode: themeMode,
                      onChanged: (mode) =>
                          ref.read(themeModeProvider.notifier).setThemeMode(mode),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Security ──
                const _SectionTitle(title: AppStrings.security),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.face,
                      title: AppStrings.enableFaceId,
                      subtitle:
                          'Uses the same device preference as the login screen',
                      trailing: Switch(
                        value: settings.faceIdEnabled,
                        onChanged: (v) =>
                            _handleFaceIdToggle(context, ref, v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Speech Recognition ──
                const _SectionTitle(title: 'Speech Recognition'),
                const SizedBox(height: 8),
                RadioGroup<SttEngine>(
                  groupValue: settings.sttEngine,
                  onChanged: (engine) {
                    if (engine != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateSttEngine(engine);
                    }
                  },
                  child: _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.phone_iphone,
                        title: 'On-Device (Apple)',
                        subtitle: 'Private, no internet needed',
                        trailing: Radio<SttEngine>(value: SttEngine.device),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: c.divider,
                      ),
                      _SettingsTile(
                        icon: Icons.cloud_outlined,
                        title: 'Cloud (OpenAI Whisper)',
                        subtitle: 'Higher accuracy, requires internet',
                        trailing: Radio<SttEngine>(value: SttEngine.cloud),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Voice Output ──
                const _SectionTitle(title: AppStrings.voiceOutput),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.volume_up,
                      title: 'Voice Output',
                      subtitle: 'AI speaks responses aloud in chat mode',
                      trailing: Switch(
                        value: settings.voiceOutputEnabled,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .updateVoiceOutput(v),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: c.divider,
                    ),
                    _SettingsTile(
                      icon: Icons.record_voice_over,
                      title: 'Premium Voice',
                      subtitle: 'ElevenLabs real-time voice in chat mode',
                      trailing: Switch(
                        value: settings.elevenlabsEnabled,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .updateElevenlabs(v),
                      ),
                    ),
                    if (!settings.elevenlabsEnabled) ...[
                      Divider(
                        height: 1,
                        indent: 56,
                        color: c.divider,
                      ),
                      _SettingsTile(
                        icon: Icons.auto_awesome,
                        title: 'Premium Voice (OpenAI)',
                        subtitle: 'Higher quality AI voice for push-to-talk',
                        trailing: Switch(
                          value: settings.usePremiumTts,
                          onChanged: settings.voiceOutputEnabled
                              ? (v) => ref
                                    .read(settingsProvider.notifier)
                                    .updatePremiumTts(v)
                              : null,
                        ),
                      ),
                    ],
                    Divider(
                      height: 1,
                      indent: 56,
                      color: c.divider,
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
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .updateVoiceSpeed(v),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Confirmation ──
                const _SectionTitle(title: 'Confirmation Prompts'),
                const SizedBox(height: 8),
                RadioGroup<ConfirmationMode>(
                  groupValue: settings.confirmationMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateConfirmationMode(mode);
                    }
                  },
                  child: _SettingsGroup(
                    children: ConfirmationMode.values
                        .map(
                          (mode) => _SettingsTile(
                            icon: Icons.check_circle_outline,
                            title:
                                mode.name[0].toUpperCase() +
                                mode.name.substring(1),
                            trailing: Radio<ConfirmationMode>(value: mode),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Sign out (pill button) ──
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleSignOut(context, ref),
                    icon: Icon(Icons.logout, color: c.error),
                    label: Text(
                      AppStrings.signOut,
                      style: TextStyle(color: c.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXXL),
              ],
            ),
            loading: () => Center(
              child: CircularProgressIndicator(color: c.primary),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) {
    final c = context.colors;
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
            child: Text(
              AppStrings.signOut,
              style: TextStyle(color: c.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFaceIdToggle(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final message =
        await ref.read(settingsProvider.notifier).updateFaceId(enabled);
    if (message == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Section Title ────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.primary.withValues(alpha: 0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Settings Group (rounded container) ───────────────────────
// ═══════════════════════════════════════════════════════════════

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Settings Tile (with circular icon) ───────────────────────
// ═══════════════════════════════════════════════════════════════

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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Circular icon container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.deepForest.withValues(alpha: 0.6),
            ),
            child: Icon(icon, color: c.primaryLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Theme Mode Tile (3-option segmented control) ─────────────
// ═══════════════════════════════════════════════════════════════

class _ThemeModeTile extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeTile({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.deepForest.withValues(alpha: 0.6),
                ),
                child: Icon(Icons.palette_outlined, color: c.primaryLight, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                'Theme',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _ThemeOption(
                  icon: Icons.phone_iphone,
                  label: 'System',
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () => onChanged(ThemeMode.system),
                ),
                _ThemeOption(
                  icon: Icons.light_mode_outlined,
                  label: 'Light',
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () => onChanged(ThemeMode.light),
                ),
                _ThemeOption(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark',
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () => onChanged(ThemeMode.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? c.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? c.textPrimary : c.textTertiary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? c.textPrimary : c.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
