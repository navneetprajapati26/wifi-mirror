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

  const WebServerCard({super.key, this.isLargeScreen = false});

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
        gradient: status.isRunning
            ? LinearGradient(
                colors: [
                  const Color(0xFF059669).withOpacity(0.15),
                  const Color(0xFF10B981).withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  colorScheme.surfaceContainerHigh.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.isRunning
              ? const Color(0xFF10B981).withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: status.isRunning
                ? const Color(0xFF10B981).withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
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
            gradient: status.isRunning
                ? const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: status.isRunning
                    ? const Color(0xFF10B981).withOpacity(0.4)
                    : const Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
        gradient: status.isRunning
            ? null
            : const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
        color: status.isRunning ? theme.colorScheme.errorContainer : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: !status.isRunning
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
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
                color: status.isRunning
                    ? theme.colorScheme.onErrorContainer
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  /// Get the auto-connect URL with host parameter
  String _getAutoConnectUrl(WebServerStatus status) {
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
        color: colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.link,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Connect Link',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Opens app & connects automatically',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
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
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Share this link - they\'ll auto-connect to your screen!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF059669),
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
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.copy, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                'Copy',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF10B981),
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
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
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
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
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
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
