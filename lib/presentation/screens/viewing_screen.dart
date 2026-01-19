import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/models.dart';
import '../../data/services/webrtc_service.dart' show WebRTCConnectionState;
import '../../providers/providers.dart';
import '../widgets/widgets.dart';

// Conditional import for web fullscreen functionality
import 'viewing_screen_web.dart'
    if (dart.library.io) 'viewing_screen_native.dart'
    as fullscreen_helper;

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

  /// Check if fullscreen button should be shown
  /// Always show on web (fullscreen is the primary immersive experience)
  /// Hidden on very large native screens since they're already in a large viewport
  bool _shouldShowFullscreenButton(BuildContext context) {
    if (kIsWeb) {
      return true; // Always show on web - it's the main way to go fullscreen
    }
    return !context.isLargeDesktop; // Hide on very large native screens
  }

  void _toggleFullscreen() async {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (kIsWeb) {
      // Use web-specific fullscreen API
      fullscreen_helper.toggleFullscreen(_isFullscreen);
    } else {
      // Use native platform fullscreen
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
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _disconnect() async {
    // Exit fullscreen on disconnect
    if (_isFullscreen) {
      if (kIsWeb) {
        fullscreen_helper.toggleFullscreen(false);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    }

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
    // For web: use fullscreen state to determine layout styling
    // For native: use responsive breakpoints
    final isLargeScreen = kIsWeb ? _isFullscreen : context.isDesktopOrLarger;
    final showFullscreenBtn = _shouldShowFullscreenButton(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Remote video - full screen for web, responsive for native
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // On web: always use full available space for consistent experience
                  // On native: center content on large screens
                  maxWidth: kIsWeb
                      ? double.infinity
                      : (isLargeScreen ? context.screenWidth * 0.9 : double.infinity),
                  maxHeight: kIsWeb
                      ? double.infinity
                      : (isLargeScreen ? context.screenHeight * 0.85 : double.infinity),
                ),
                // On web: skip AspectRatio to fill screen (RTCVideoView handles aspect internally)
                // On native: use AspectRatio for proper layout
                child: kIsWeb
                    ? _buildVideoContent(
                        connectionState,
                        webrtcService,
                        theme,
                        isLargeScreen,
                      )
                    : AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: isLargeScreen
                              ? BorderRadius.circular(16)
                              : BorderRadius.zero,
                          child: _buildVideoContent(
                            connectionState,
                            webrtcService,
                            theme,
                            isLargeScreen,
                          ),
                        ),
                      ),
              ),
            ),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildControlsOverlay(
                theme,
                metricsAsync,
                isLargeScreen,
                showFullscreenBtn,
              ),
            ),

            // Connection indicator (when controls hidden)
            if (!_showControls)
              Positioned(
                top: isLargeScreen ? 24 : 16,
                right: isLargeScreen ? 24 : 16,
                child: SafeArea(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 16 : 12,
                      vertical: isLargeScreen ? 10 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StatusIndicator(
                          status: StatusType.viewing,
                          size: 8,
                        ),
                        if (isLargeScreen) ...[
                          const SizedBox(width: 8),
                          Text(
                            widget.hostDevice.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the video content widget with proper styling for web/native
  Widget _buildVideoContent(
    AsyncValue<WebRTCConnectionState> connectionState,
    dynamic webrtcService,
    ThemeData theme,
    bool isLargeScreen,
  ) {
    return connectionState.when(
      data: (state) {
        if (state == WebRTCConnectionState.connected) {
          return Container(
            // Full size container for web, decorated for native large screens
            width: kIsWeb ? double.infinity : null,
            height: kIsWeb ? double.infinity : null,
            decoration: (!kIsWeb && isLargeScreen)
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: RTCVideoView(
              webrtcService.remoteRenderer,
              mirror: false,
              // Always use Contain to show full screen content without cropping
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ).animate().fadeIn(duration: 500.ms),
          );
        }
        return _buildConnectingState(theme, isLargeScreen);
      },
      loading: () => _buildConnectingState(theme, isLargeScreen),
      error: (error, _) => _buildErrorState(theme, error, isLargeScreen),
    );
  }

  Widget _buildControlsOverlay(
    ThemeData theme,
    AsyncValue metricsAsync,
    bool isLargeScreen,
    bool showFullscreenBtn,
  ) {
    final horizontalPadding = isLargeScreen ? 32.0 : 16.0;
    final verticalPadding = isLargeScreen ? 24.0 : 16.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(isLargeScreen ? 0.7 : 0.6),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(isLargeScreen ? 0.7 : 0.6),
          ],
          stops: const [0.0, 0.15, 0.85, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(
              theme,
              metricsAsync,
              horizontalPadding,
              verticalPadding,
              isLargeScreen,
            ),
            const Spacer(),
            // Bottom controls
            _buildBottomControls(
              theme,
              horizontalPadding,
              verticalPadding,
              isLargeScreen,
              showFullscreenBtn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    ThemeData theme,
    AsyncValue metricsAsync,
    double horizontalPadding,
    double verticalPadding,
    bool isLargeScreen,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        children: [
          // Back button - larger on desktop
          _buildIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: _disconnect,
            size: isLargeScreen ? 48 : 40,
            iconSize: isLargeScreen ? 24 : 20,
          ),
          SizedBox(width: isLargeScreen ? 16 : 8),
          // Device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hostDevice.name,
                  style:
                      (isLargeScreen
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.titleMedium)
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.hostDevice.deviceType.displayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    if (kIsWeb && isLargeScreen) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Quality indicator
          metricsAsync.when(
            data: (metrics) =>
                QualityIndicator(metrics: metrics, compact: !isLargeScreen),
            loading: () => QualityIndicator(compact: !isLargeScreen),
            error: (_, __) => QualityIndicator(compact: !isLargeScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    ThemeData theme,
    double horizontalPadding,
    double verticalPadding,
    bool isLargeScreen,
    bool showFullscreenBtn,
  ) {
    final buttonSpacing = isLargeScreen ? 32.0 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: isLargeScreen
          ? _buildDesktopBottomControls(theme, buttonSpacing, showFullscreenBtn)
          : _buildMobileBottomControls(theme, buttonSpacing, showFullscreenBtn),
    );
  }

  Widget _buildDesktopBottomControls(
    ThemeData theme,
    double spacing,
    bool showFullscreenBtn,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDesktopControlButton(
            icon: Icons.screenshot_monitor_rounded,
            label: 'Screenshot',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Screenshot saved!')),
              );
            },
          ),
          if (showFullscreenBtn) ...[
            SizedBox(width: spacing),
            _buildDesktopControlButton(
              icon: _isFullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              label: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
              onTap: _toggleFullscreen,
              isPrimary: true,
            ),
          ],
          SizedBox(width: spacing),
          _buildDesktopControlButton(
            icon: Icons.call_end_rounded,
            label: 'Disconnect',
            onTap: _disconnect,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomControls(
    ThemeData theme,
    double spacing,
    bool showFullscreenBtn,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.screenshot_monitor_rounded,
          label: 'Screenshot',
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Screenshot saved!')));
          },
        ),
        if (showFullscreenBtn) ...[
          SizedBox(width: spacing),
          _buildControlButton(
            icon: _isFullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            label: _isFullscreen ? 'Exit' : 'Fullscreen',
            onTap: _toggleFullscreen,
            isPrimary: true,
          ),
        ],
        SizedBox(width: spacing),
        _buildControlButton(
          icon: Icons.call_end_rounded,
          label: 'Disconnect',
          onTap: _disconnect,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 40,
    double iconSize = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }

  Widget _buildDesktopControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    Color backgroundColor;
    Color textColor;

    if (isDestructive) {
      backgroundColor = AppTheme.error.withOpacity(0.2);
      textColor = AppTheme.error;
    } else if (isPrimary) {
      backgroundColor = Colors.white.withOpacity(0.2);
      textColor = Colors.white;
    } else {
      backgroundColor = Colors.white.withOpacity(0.1);
      textColor = Colors.white70;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingState(ThemeData theme, bool isLargeScreen) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
                width: isLargeScreen ? 80 : 60,
                height: isLargeScreen ? 80 : 60,
                child: CircularProgressIndicator(
                  strokeWidth: isLargeScreen ? 4 : 3,
                  color: Colors.white,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1500.ms,
                color: AppTheme.success.withOpacity(0.3),
              ),
          SizedBox(height: isLargeScreen ? 32 : 24),
          Text(
            'Connecting to ${widget.hostDevice.name}...',
            style:
                (isLargeScreen
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.titleMedium)
                    ?.copyWith(color: Colors.white),
          ),
          SizedBox(height: isLargeScreen ? 12 : 8),
          Text(
            'Establishing secure connection',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error, bool isLargeScreen) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isLargeScreen ? 500 : 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isLargeScreen ? 56 : 48,
                color: AppTheme.error,
              ),
            ),
            SizedBox(height: isLargeScreen ? 32 : 24),
            Text(
              'Connection Failed',
              style:
                  (isLargeScreen
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.titleLarge)
                      ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
            ),
            SizedBox(height: isLargeScreen ? 12 : 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLargeScreen ? 32 : 24),
            FilledButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 32 : 24,
                  vertical: isLargeScreen ? 16 : 12,
                ),
              ),
            ),
          ],
        ),
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
