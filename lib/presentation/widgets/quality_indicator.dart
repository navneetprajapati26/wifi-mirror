import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../core/theme/app_theme.dart';

/// Widget for displaying streaming quality metrics
class QualityIndicator extends StatelessWidget {
  final StreamingMetrics? metrics;
  final bool compact;

  const QualityIndicator({super.key, this.metrics, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (metrics == null) {
      return _buildPlaceholder(theme);
    }

    final rating = metrics!.qualityRating;
    final color = _getQualityColor(rating);

    if (compact) {
      return _buildCompact(theme, color);
    }

    return _buildFull(theme, color);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_cellular_alt_rounded,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          Text(
            'Connecting...',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(ThemeData theme, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSignalBars(color),
          const SizedBox(width: 8),
          Text(
            '${metrics!.fps.toInt()} FPS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(ThemeData theme, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSignalBars(color),
              const SizedBox(width: 12),
              Text(
                metrics!.qualityLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${metrics!.fps.toInt()} FPS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricItem(
                theme,
                Icons.speed_rounded,
                'Latency',
                '${metrics!.latencyMs}ms',
              ),
              const SizedBox(width: 24),
              _buildMetricItem(
                theme,
                Icons.data_usage_rounded,
                'Bitrate',
                _formatBitrate(metrics!.bitrate),
              ),
              const SizedBox(width: 24),
              _buildMetricItem(
                theme,
                Icons.warning_rounded,
                'Packet Loss',
                '${metrics!.packetLoss.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBars(Color color) {
    final rating = metrics?.qualityRating ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (index) {
        final isActive = index < rating;
        return Container(
          width: 3,
          height: 6 + (index * 3).toDouble(),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Color _getQualityColor(int rating) {
    if (rating >= 4) return AppTheme.success;
    if (rating >= 3) return AppTheme.warning;
    return AppTheme.error;
  }

  String _formatBitrate(int bitrate) {
    if (bitrate >= 1000000) {
      return '${(bitrate / 1000000).toStringAsFixed(1)} Mbps';
    } else if (bitrate >= 1000) {
      return '${(bitrate / 1000).toStringAsFixed(0)} Kbps';
    }
    return '$bitrate bps';
  }
}
