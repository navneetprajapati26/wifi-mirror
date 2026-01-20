import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// Dialog showing instructions for web users when connection issues occur
class WebInstructionsDialog extends StatelessWidget {
  const WebInstructionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.security_rounded,
                            color: AppTheme.warning,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connection Troubleshooting',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'If URL is not working, follow these steps',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Instructions
                    _buildInstructionStep(
                      theme,
                      stepNumber: 1,
                      title: 'Click the Security Icon',
                      description:
                          'Click the "Not Secure" or Lock icon in the address bar (left of the URL).',
                      icon: Icons.lock_outline_rounded,
                    ),

                    _buildInstructionStep(
                      theme,
                      stepNumber: 2,
                      title: 'Open Site Settings',
                      description:
                          'Click "Site Settings" from the dropdown menu.',
                      icon: Icons.settings_rounded,
                    ),

                    _buildInstructionStep(
                      theme,
                      stepNumber: 3,
                      title: 'Find Insecure Content',
                      description:
                          'Scroll down to find "Insecure content" option.',
                      icon: Icons.find_in_page_rounded,
                    ),

                    _buildInstructionStep(
                      theme,
                      stepNumber: 4,
                      title: 'Allow Insecure Content',
                      description:
                          'Change it from "Block (default)" to "Allow".',
                      icon: Icons.toggle_on_rounded,
                      isHighlighted: true,
                    ),

                    _buildInstructionStep(
                      theme,
                      stepNumber: 5,
                      title: 'Reload the Page',
                      description: 'Reload the page and try connecting again.',
                      icon: Icons.refresh_rounded,
                      isLast: true,
                    ),

                    const SizedBox(height: 20),

                    // Why this is needed
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This is required because the app uses WebSocket connections over local network which browsers treat as "insecure" by default.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Got it'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 200.ms,
        );
  }

  Widget _buildInstructionStep(
    ThemeData theme, {
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    bool isHighlighted = false,
    bool isLast = false,
  }) {
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number with line
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppTheme.success
                        : colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isHighlighted
                            ? Colors.white
                            : colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppTheme.success.withOpacity(0.1)
                      : colorScheme.surfaceContainerHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: isHighlighted
                      ? Border.all(color: AppTheme.success.withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: isHighlighted
                          ? AppTheme.success
                          : colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }
}
