import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Quality Settings
          _buildSectionHeader(theme, 'Streaming Quality'),
          const SizedBox(height: 12),
          _buildQualitySelector(theme, colorScheme, settings, settingsNotifier),

          const SizedBox(height: 32),

          // Appearance
          _buildSectionHeader(theme, 'Appearance'),
          const SizedBox(height: 12),
          _buildSettingTile(
            theme,
            colorScheme,
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Use dark theme',
            trailing: Switch.adaptive(
              value: settings.isDarkMode,
              onChanged: (value) => settingsNotifier.setDarkMode(value),
            ),
          ),

          const SizedBox(height: 32),

          // Sharing Options
          _buildSectionHeader(theme, 'Sharing Options'),
          const SizedBox(height: 12),
          _buildSettingTile(
            theme,
            colorScheme,
            icon: Icons.mouse_rounded,
            title: 'Show Cursor',
            subtitle: 'Display cursor while sharing',
            trailing: Switch.adaptive(
              value: settings.showCursor,
              onChanged: (value) => settingsNotifier.setShowCursor(value),
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            theme,
            colorScheme,
            icon: Icons.link_rounded,
            title: 'Auto-Connect',
            subtitle: 'Automatically reconnect on network change',
            trailing: Switch.adaptive(
              value: settings.autoConnect,
              onChanged: (value) => settingsNotifier.setAutoConnect(value),
            ),
          ),

          const SizedBox(height: 32),

          // Device Info
          _buildSectionHeader(theme, 'Device'),
          const SizedBox(height: 12),
          _buildSettingTile(
            theme,
            colorScheme,
            icon: Icons.phone_android_rounded,
            title: 'Device Name',
            subtitle: settings.deviceName,
            onTap: () =>
                _showDeviceNameDialog(context, ref, settings.deviceName),
          ),

          const SizedBox(height: 32),

          // About
          _buildSectionHeader(theme, 'About'),
          const SizedBox(height: 12),
          _buildSettingTile(
            theme,
            colorScheme,
            icon: Icons.info_outline_rounded,
            title: 'WiFi Mirror',
            subtitle: 'Version 1.0.0',
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            theme,
            colorScheme,
            icon: Icons.code_rounded,
            title: 'Open Source Licenses',
            subtitle: 'View third-party licenses',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'WiFi Mirror',
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildQualitySelector(
    ThemeData theme,
    ColorScheme colorScheme,
    AppSettings settings,
    AppSettingsNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: StreamingQuality.values.map((quality) {
          final isSelected = settings.quality == quality;
          return Expanded(
            child: GestureDetector(
              onTap: () => notifier.setQuality(quality),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getQualityIcon(quality),
                      size: 24,
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quality.name.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quality.height}p',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Colors.white70
                            : colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getQualityIcon(StreamingQuality quality) {
    switch (quality) {
      case StreamingQuality.low:
        return Icons.sd_rounded;
      case StreamingQuality.medium:
        return Icons.hd_rounded;
      case StreamingQuality.high:
        return Icons.four_k_rounded;
    }
  }

  Widget _buildSettingTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  void _showDeviceNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter device name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(appSettingsProvider.notifier)
                    .setDeviceName(controller.text.trim());
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
