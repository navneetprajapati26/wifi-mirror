import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Animated pulsing dot indicator for connection status
class StatusIndicator extends StatefulWidget {
  final StatusType status;
  final double size;
  final bool showLabel;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
    this.showLabel = true,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.status.shouldAnimate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status.shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.status.color.withOpacity(_animation.value),
                // boxShadow removed for flat design
              ),
            );
          },
        ),
        if (widget.showLabel) ...[
          const SizedBox(width: 8),
          Text(
            widget.status.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: widget.status.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

enum StatusType {
  connected,
  connecting,
  sharing,
  viewing,
  disconnected,
  error;

  Color get color {
    switch (this) {
      case StatusType.connected:
      case StatusType.sharing:
        return AppTheme.success;
      case StatusType.connecting:
      case StatusType.viewing:
        return AppTheme.info;
      case StatusType.disconnected:
        return Colors.grey;
      case StatusType.error:
        return AppTheme.error;
    }
  }

  String get label {
    switch (this) {
      case StatusType.connected:
        return 'Connected';
      case StatusType.connecting:
        return 'Connecting...';
      case StatusType.sharing:
        return 'Sharing';
      case StatusType.viewing:
        return 'Viewing';
      case StatusType.disconnected:
        return 'Disconnected';
      case StatusType.error:
        return 'Error';
    }
  }

  bool get shouldAnimate {
    switch (this) {
      case StatusType.connecting:
      case StatusType.sharing:
      case StatusType.viewing:
        return true;
      default:
        return false;
    }
  }
}
