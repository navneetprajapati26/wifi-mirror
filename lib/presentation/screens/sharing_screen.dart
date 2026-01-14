import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';

/// Screen displayed when sharing your screen
class SharingScreen extends ConsumerStatefulWidget {
  const SharingScreen({super.key});

  @override
  ConsumerState<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends ConsumerState<SharingScreen> {
  Timer? _durationTimer;
  Duration _sharingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startDurationTimer();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _sharingDuration += const Duration(seconds: 1);
      });
    });
  }

  Future<void> _stopSharing() async {
    await ref.read(screenSharingControllerProvider).stopSharing();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final webrtcService = ref.watch(webrtcServiceProvider);
    final metricsAsync = ref.watch(streamingMetricsProvider);
    final session = ref.watch(currentSessionProvider);
    final signalingService = ref.watch(signalingServiceProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _showStopDialog(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  const StatusIndicator(status: StatusType.sharing),
                  const Spacer(),
                  metricsAsync.when(
                    data: (metrics) =>
                        QualityIndicator(metrics: metrics, compact: true),
                    loading: () => const QualityIndicator(compact: true),
                    error: (_, __) => const QualityIndicator(compact: true),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Screen preview
            Expanded(
              child:
                  Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.success.withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              RTCVideoView(
                                webrtcService.localRenderer,
                                mirror: false,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitContain,
                              ),
                              // Sharing overlay
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                          .animate(onPlay: (c) => c.repeat())
                                          .fadeIn(duration: 500.ms)
                                          .then()
                                          .fadeOut(duration: 500.ms),
                                      const SizedBox(width: 8),
                                      Text(
                                        'LIVE',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
            ),

            // Stats and controls
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stats row
                  Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              theme,
                              Icons.timer_rounded,
                              'Duration',
                              _formatDuration(_sharingDuration),
                            ),
                            _buildDivider(colorScheme),
                            _buildStatItem(
                              theme,
                              Icons.people_rounded,
                              'Viewers',
                              '${signalingService.connectedPeerCount}',
                            ),
                            _buildDivider(colorScheme),
                            _buildStatItem(
                              theme,
                              Icons.hd_rounded,
                              'Quality',
                              session?.quality.displayName ?? 'Medium',
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // Quality metrics
                  metricsAsync
                      .when(
                        data: (metrics) => QualityIndicator(metrics: metrics),
                        loading: () => const QualityIndicator(),
                        error: (_, __) => const QualityIndicator(),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms),

                  const SizedBox(height: 24),

                  // Stop button
                  GradientButton(
                        text: 'Stop Sharing',
                        icon: Icons.stop_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        onPressed: _showStopDialog,
                        width: double.infinity,
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 500.ms)
                      .slideY(begin: 0.1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 50,
      color: colorScheme.surfaceContainerHigh,
    );
  }

  void _showStopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Sharing?'),
        content: const Text(
          'This will disconnect all viewers and stop sharing your screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _stopSharing();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}
