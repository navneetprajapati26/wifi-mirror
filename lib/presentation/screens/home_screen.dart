import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';
import 'sharing_screen.dart';
import 'viewing_screen.dart';
import 'settings_screen.dart';

/// Main home screen with device discovery and sharing options
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isStartingShare = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Start discovery when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDiscovery();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    try {
      await ref.read(discoveryControllerProvider).startDiscovery();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start discovery: $e')),
        );
      }
    }
  }

  Future<void> _startSharing() async {
    if (kIsWeb) {
      // Web cannot share screen, only view
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Screen sharing is not available on web. You can only view shared screens.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isStartingShare = true);

    try {
      await ref.read(screenSharingControllerProvider).startSharing();
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SharingScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start sharing: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingShare = false);
      }
    }
  }

  Future<void> _connectToDevice(NetworkDevice device) async {
    try {
      await ref.read(screenSharingControllerProvider).connectToSession(device);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ViewingScreen(hostDevice: device)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showManualConnectionDialog() async {
    final device = await showDialog<NetworkDevice>(
      context: context,
      builder: (context) => const ManualConnectionDialog(),
    );

    if (device != null) {
      // Add the device to discovered devices
      ref.read(networkDiscoveryServiceProvider).addManualDevice(device);
      // Connect to it
      await _connectToDevice(device);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final devices = ref.watch(discoveredDevicesProvider);
    final isDiscovering = ref.watch(isDiscoveringProvider);
    final discoveryService = ref.watch(networkDiscoveryServiceProvider);
    final isDiscoverySupported = discoveryService.isDiscoverySupported;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 80,
              floating: true,
              backgroundColor: colorScheme.surface,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cast_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'WiFi Mirror',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'WEB',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (isDiscoverySupported)
                  IconButton(
                    onPressed: _startDiscovery,
                    icon: AnimatedRotation(
                      duration: const Duration(milliseconds: 500),
                      turns: isDiscovering ? 1 : 0,
                      child: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Main content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Web Platform Notice
                  if (kIsWeb) ...[
                    _buildWebPlatformNotice(theme)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),
                  ],

                  // Share My Screen Card (hidden on web)
                  if (!kIsWeb)
                    _buildShareCard(theme)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                  // Manual Connection Card - show on web always, on other platforms as alternative
                  if (kIsWeb)
                    _buildManualConnectionCard(theme)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0)
                  else
                    _buildManualConnectionSmallCard(theme)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 50.ms)
                        .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  // Available Screens Section
                  _buildAvailableScreensHeader(theme, devices.length)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 16),

                  // Device List or Empty State
                  if (devices.isEmpty)
                    _buildEmptyState(
                      theme,
                      isDiscovering,
                      isDiscoverySupported,
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms)
                  else
                    ...devices.asMap().entries.map((entry) {
                      final index = entry.key;
                      final device = entry.value;
                      return DeviceCard(
                            device: device,
                            onTap: () => _connectToDevice(device),
                          )
                          .animate()
                          .fadeIn(
                            duration: 400.ms,
                            delay: Duration(milliseconds: 200 + (index * 100)),
                          )
                          .slideX(begin: 0.1, end: 0);
                    }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPlatformNotice(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Running on Web',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatic device discovery is not available. Use manual connection to view shared screens.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualConnectionCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF06B6D4).withOpacity(0.15),
            const Color(0xFF0EA5E9).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect Manually',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter the IP address of a device sharing its screen',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Enter Connection Details',
            icon: Icons.add_link_rounded,
            onPressed: _showManualConnectionDialog,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  /// Compact manual connection card for non-web platforms
  Widget _buildManualConnectionSmallCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: _showManualConnectionDialog,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_link_rounded,
                color: Color(0xFF06B6D4),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect Manually',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Enter IP address to connect to a shared screen',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.15),
            const Color(0xFF4F46E5).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7C3AED,
                          ).withOpacity(0.3 + (_pulseController.value * 0.2)),
                          blurRadius: 20 + (_pulseController.value * 10),
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.screen_share_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share My Screen',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Let others view your screen in real-time',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Start Sharing',
            icon: Icons.play_arrow_rounded,
            onPressed: _isStartingShare ? null : _startSharing,
            isLoading: _isStartingShare,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableScreensHeader(ThemeData theme, int count) {
    return Row(
      children: [
        Text(
          'Available Screens',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        // Manual connection button - available on all platforms
        TextButton.icon(
          onPressed: _showManualConnectionDialog,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Manually'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    bool isDiscovering,
    bool isDiscoverySupported,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDiscovering
                  ? Icons.radar_rounded
                  : (isDiscoverySupported
                        ? Icons.devices_rounded
                        : Icons.cloud_off_rounded),
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isDiscovering
                ? 'Scanning for devices...'
                : (isDiscoverySupported
                      ? 'No devices found'
                      : 'Manual connection required'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isDiscovering
                ? 'Looking for devices sharing their screen on this network'
                : (isDiscoverySupported
                      ? 'Make sure other devices are connected to the same WiFi network'
                      : 'Enter the IP address and port of a device sharing its screen'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (!isDiscovering) ...[
            const SizedBox(height: 24),
            if (isDiscoverySupported)
              OutlinedButton.icon(
                onPressed: _startDiscovery,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Scan Again'),
              )
            else
              FilledButton.icon(
                onPressed: _showManualConnectionDialog,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Connect Manually'),
              ),
          ],
        ],
      ),
    );
  }
}
