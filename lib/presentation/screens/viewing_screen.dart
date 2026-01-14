import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/webrtc_service.dart' show WebRTCConnectionState;
import '../../providers/providers.dart';
import '../widgets/widgets.dart';

/// Screen displayed when viewing another device's screen
class ViewingScreen extends ConsumerStatefulWidget {
  final NetworkDevice hostDevice;

  const ViewingScreen({super.key, required this.hostDevice});

  @override
  ConsumerState<ViewingScreen> createState() => _ViewingScreenState();
}

class _ViewingScreenState extends ConsumerState<ViewingScreen> {
  bool _isFullscreen = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _disconnect() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await ref.read(screenSharingControllerProvider).disconnect();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final webrtcService = ref.watch(webrtcServiceProvider);
    final connectionState = ref.watch(connectionStateProvider);
    final metricsAsync = ref.watch(streamingMetricsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Remote video
            connectionState.when(
              data: (state) {
                if (state == WebRTCConnectionState.connected) {
                  return RTCVideoView(
                    webrtcService.remoteRenderer,
                    mirror: false,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ).animate().fadeIn(duration: 500.ms);
                }
                return _buildConnectingState(theme);
              },
              loading: () => _buildConnectingState(theme),
              error: (error, _) => _buildErrorState(theme, error),
            ),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _disconnect,
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.hostDevice.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.hostDevice.deviceType.displayName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            metricsAsync.when(
                              data: (metrics) => QualityIndicator(
                                metrics: metrics,
                                compact: true,
                              ),
                              loading: () =>
                                  const QualityIndicator(compact: true),
                              error: (_, __) =>
                                  const QualityIndicator(compact: true),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Bottom controls
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlButton(
                              icon: Icons.screenshot_monitor_rounded,
                              label: 'Screenshot',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Screenshot saved!'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 24),
                            _buildControlButton(
                              icon: _isFullscreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                              label: _isFullscreen ? 'Exit' : 'Fullscreen',
                              onTap: _toggleFullscreen,
                              isPrimary: true,
                            ),
                            const SizedBox(width: 24),
                            _buildControlButton(
                              icon: Icons.call_end_rounded,
                              label: 'Disconnect',
                              onTap: _disconnect,
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Connection indicator
            if (!_showControls)
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const StatusIndicator(
                      status: StatusType.viewing,
                      size: 8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1500.ms,
                color: AppTheme.success.withOpacity(0.3),
              ),
          const SizedBox(height: 24),
          Text(
            'Connecting to ${widget.hostDevice.name}...',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Establishing secure connection',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Connection Failed',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _disconnect, child: const Text('Go Back')),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    Color backgroundColor;
    Color iconColor;

    if (isDestructive) {
      backgroundColor = AppTheme.error.withOpacity(0.2);
      iconColor = AppTheme.error;
    } else if (isPrimary) {
      backgroundColor = Colors.white.withOpacity(0.2);
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.white.withOpacity(0.1);
      iconColor = Colors.white70;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: isPrimary
                  ? Border.all(color: Colors.white.withOpacity(0.3), width: 2)
                  : null,
            ),
            child: Icon(icon, size: isPrimary ? 28 : 24, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
