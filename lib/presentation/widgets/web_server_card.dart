import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/services.dart';
import '../../providers/providers.dart';

/// Card widget for web server control
/// Allows starting/stopping the local web server to share the app
class WebServerCard extends ConsumerStatefulWidget {
  final bool isLargeScreen;
  final String Function(WebServerStatus)? linkGenerator;
  final String? linkTitle;
  final String? linkSubtitle;

  const WebServerCard({
    super.key,
    this.isLargeScreen = false,
    this.linkGenerator,
    this.linkTitle,
    this.linkSubtitle,
  });

  @override
  ConsumerState<WebServerCard> createState() => _WebServerCardState();
}

class _WebServerCardState extends ConsumerState<WebServerCard> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    // Don't show on web platform
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final webServerService = ref.watch(webServerServiceProvider);
    final status = webServerService.status;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isLargeScreen ? 0 : 0,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: status.isRunning
            ? theme.colorScheme.primaryContainer.withOpacity(0.2)
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.isRunning
              ? theme.colorScheme.primary
              : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isLoading ? null : _toggleServer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, status),
                if (status.isRunning && status.url != null) ...[
                  const SizedBox(height: 16),
                  _buildUrlSection(theme, colorScheme, status),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorSection(theme),
                ],
                if (status.error != null && !status.isRunning) ...[
                  const SizedBox(height: 12),
                  _buildStatusError(theme, status.error!),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeader(ThemeData theme, WebServerStatus status) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: status.isRunning
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            status.isRunning ? Icons.wifi_tethering : Icons.public,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Web Access',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status.isRunning
                    ? 'Server running • Tap to stop'
                    : 'Share app via local WiFi',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        _buildToggleButton(theme, status),
      ],
    );
  }

  Widget _buildToggleButton(ThemeData theme, WebServerStatus status) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: status.isRunning
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  status.isRunning
                      ? theme.colorScheme.onErrorContainer
                      : Colors.white,
                ),
              ),
            )
          : Text(
              status.isRunning ? 'Stop' : 'Start',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  /// Get the auto-connect URL with host parameter
  String _getAutoConnectUrl(WebServerStatus status) {
    if (widget.linkGenerator != null) {
      return widget.linkGenerator!(status);
    }

    if (status.ipAddress == null) return status.url ?? '';
    // The default signaling port is service port + 1
    final signalingPort = AppConstants.servicePort;
    return '${status.url}/connect?host=${status.ipAddress}&port=$signalingPort';
  }

  Widget _buildUrlSection(
    ThemeData theme,
    ColorScheme colorScheme,
    WebServerStatus status,
  ) {
    final autoConnectUrl = _getAutoConnectUrl(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.link,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.linkTitle ?? 'Quick-Connect Link',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.linkSubtitle ?? 'Opens app & connects quickly',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              _buildCopyButton(theme, autoConnectUrl),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              autoConnectUrl,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Info row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Share this link - they\'ll quick-connect to your screen!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildCopyButton(ThemeData theme, String url) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _copyToClipboard(url),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy, size: 14, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 6),
              Text(
                'Copy',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusError(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber, color: AppTheme.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleServer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final webServerService = ref.read(webServerServiceProvider);

      if (webServerService.status.isRunning) {
        await webServerService.stopServer();
      } else {
        final success = await webServerService.startServer();
        if (!success && mounted) {
          setState(() {
            _error = webServerService.status.error ?? 'Failed to start server';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Link copied to clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
