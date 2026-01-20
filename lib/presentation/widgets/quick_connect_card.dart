import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/logger.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../providers/router.dart';

// Conditional import for web URL access
import 'quick_connect_card_stub.dart'
    if (dart.library.html) 'quick_connect_card_web.dart'
    as url_helper;

/// Card that shows when user opens a URL with connection parameters
/// Only visible on web platform when URL contains host and port
class QuickConnectCard extends ConsumerStatefulWidget {
  const QuickConnectCard({super.key});

  @override
  ConsumerState<QuickConnectCard> createState() => _QuickConnectCardState();
}

class _QuickConnectCardState extends ConsumerState<QuickConnectCard> {
  bool _isConnecting = false;
  String? _error;
  bool _isDismissed = false;
  String? _hostIp;
  int? _port;

  @override
  void initState() {
    super.initState();
    _parseUrlParams();
  }

  void _parseUrlParams() {
    if (!kIsWeb) return;

    try {
      // Get URL params from browser
      final params = url_helper.getUrlParams();
      final host = params['host'];
      final portStr = params['port'];

      AppLogger.info(
        'QuickConnectCard: URL params - host=$host, port=$portStr',
        'QuickConnectCard',
      );

      if (host != null && host.isNotEmpty) {
        setState(() {
          _hostIp = host;
          _port = int.tryParse(portStr ?? '50124') ?? 50124;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to parse URL params',
        e,
        null,
        'QuickConnectCard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show on web platform
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    // Check if dismissed
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    // Only show if we have a host IP
    if (_hostIp == null || _hostIp!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final port = _port ?? 50124;

    return Container(
          margin: const EdgeInsets.only(left: 0, right: 0, bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.link_rounded,
                          color: theme.colorScheme.onSecondaryContainer,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Connect',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Connection details from shared link',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Close button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isDismissed = true;
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Connection details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(
                          0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // IP Address row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.computer,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IP Address',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _hostIp!,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Divider(color: colorScheme.outline.withOpacity(0.1)),
                        const SizedBox(height: 12),

                        // Port row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.settings_ethernet,
                                color: theme.colorScheme.onSecondaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Port',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    port.toString(),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.secondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Connect button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isConnecting
                          ? null
                          : () => _connect(_hostIp!, port),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isConnecting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cast_connected_rounded, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Connect to Screen',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0)
        .shimmer(
          delay: 500.ms,
          duration: 1500.ms,
          color: theme.colorScheme.primary.withOpacity(0.1),
        );
  }

  Future<void> _connect(String hostIp, int port) async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      // Create a network device from the connection params
      final device = NetworkDevice(
        name: 'Host ($hostIp)',
        ipAddress: hostIp,
        port: port,
        deviceType: DeviceType.unknown,
        isSharing: true,
      );

      // Connect to the session
      await ref.read(screenSharingControllerProvider).connectToSession(device);

      if (mounted) {
        // Navigate to viewing screen
        context.push(AppRoutes.view, extra: device);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = e.toString();
        });
      }
    }
  }
}
