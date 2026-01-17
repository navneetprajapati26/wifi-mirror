import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../providers/router.dart';
import '../widgets/widgets.dart';

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
        context.push(AppRoutes.share);
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
        context.push(AppRoutes.view, extra: device);
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

    final isLargeScreen = context.isDesktopOrLarger;
    final isVeryLargeScreen = context.isLargeDesktop;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isVeryLargeScreen
                  ? 1400
                  : (isLargeScreen ? 1100 : double.infinity),
            ),
            child: CustomScrollView(
              slivers: [
                // App Bar
                _buildAppBar(
                  theme,
                  colorScheme,
                  isDiscovering,
                  isDiscoverySupported,
                  isLargeScreen,
                ),

                // Main content
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 48 : 20,
                    vertical: isLargeScreen ? 32 : 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Web Platform: Quick Connect Card first (shows when URL has params)
                      if (kIsWeb) ...const [QuickConnectCard()],

                      // Cards section - horizontal on large screens
                      if (isLargeScreen)
                        _buildDesktopCardsRow(theme)
                      else
                        _buildMobileCards(theme),

                      SizedBox(height: isLargeScreen ? 32 : 24),

                      // Web Platform Notice
                      if (kIsWeb) ...[
                        _buildWebPlatformNotice(theme, isLargeScreen)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        SizedBox(height: isLargeScreen ? 32 : 24),

                        // Features List (Web only)
                        _buildFeaturesSection(theme, isLargeScreen)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 100.ms)
                            .slideY(begin: 0.1, end: 0),
                        SizedBox(height: isLargeScreen ? 32 : 24),
                      ],

                      // Available Screens Section
                      _buildAvailableScreensHeader(
                            theme,
                            devices.length,
                            isLargeScreen,
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideY(begin: 0.1, end: 0),

                      SizedBox(height: isLargeScreen ? 24 : 16),

                      // Device List or Empty State
                      if (devices.isEmpty)
                        _buildEmptyState(
                          theme,
                          isDiscovering,
                          isDiscoverySupported,
                          isLargeScreen,
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms)
                      else
                        _buildDeviceGrid(devices, isLargeScreen),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDiscovering,
    bool isDiscoverySupported,
    bool isLargeScreen,
  ) {
    return SliverAppBar(
      expandedHeight: isLargeScreen ? 100 : 80,
      floating: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLargeScreen ? 10 : 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.cast_rounded,
              color: Colors.white,
              size: isLargeScreen ? 28 : 24,
            ),
          ),
          SizedBox(width: isLargeScreen ? 16 : 12),
          Text(
            'WiFi Mirror',
            style:
                (isLargeScreen
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (kIsWeb) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'WEB',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (isDiscoverySupported)
          _buildActionButton(
            icon: Icons.refresh_rounded,
            onTap: _startDiscovery,
            isAnimating: isDiscovering,
            isLargeScreen: isLargeScreen,
          ),
        SizedBox(width: isLargeScreen ? 8 : 4),
        _buildActionButton(
          icon: Icons.settings_rounded,
          onTap: () {
            context.push(AppRoutes.settings);
          },
          isLargeScreen: isLargeScreen,
        ),
        SizedBox(width: isLargeScreen ? 24 : 12),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isAnimating = false,
    required bool isLargeScreen,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isLargeScreen ? 12 : 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          ),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 500),
            turns: isAnimating ? 1 : 0,
            child: Icon(
              icon,
              size: isLargeScreen ? 22 : 20,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCardsRow(ThemeData theme) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Share Card (if not web)
            if (!kIsWeb)
              Expanded(
                child: _buildShareCard(theme, true)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.1, end: 0),
              ),
            if (!kIsWeb) const SizedBox(width: 24),
            // Manual Connection Card
            Expanded(
              child:
                  (kIsWeb
                          ? _buildManualConnectionCard(theme, true)
                          : _buildManualConnectionCard(theme, true))
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 50.ms)
                      .slideX(begin: 0.1, end: 0),
            ),
          ],
        ),
        // Web Server Card (only on native platforms)
        if (!kIsWeb) ...[
          const SizedBox(height: 24),
          const WebServerCard(isLargeScreen: true),
        ],
      ],
    );
  }

  Widget _buildMobileCards(ThemeData theme) {
    return Column(
      children: [
        // Share My Screen Card (hidden on web)
        if (!kIsWeb)
          _buildShareCard(
            theme,
            false,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        // Manual Connection Card
        if (kIsWeb)
          _buildManualConnectionCard(
            theme,
            false,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0)
        else
          _buildManualConnectionSmallCard(theme)
              .animate()
              .fadeIn(duration: 400.ms, delay: 50.ms)
              .slideY(begin: 0.1, end: 0),

        // Web Server Card (only on native platforms)
        if (!kIsWeb) const WebServerCard(isLargeScreen: false),
      ],
    );
  }

  Widget _buildWebPlatformNotice(ThemeData theme, bool isLargeScreen) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.4),
            colorScheme.primaryContainer.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: isLargeScreen
          ? _buildDesktopWebNotice(theme, colorScheme)
          : _buildMobileWebNotice(theme, colorScheme),
    );
  }

  Widget _buildDesktopWebNotice(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.language_rounded,
            color: colorScheme.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Running on Web Browser',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use manual connection to view shared screens. For screen sharing, download the native app for your platform.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const WebInstructionsDialog(),
            );
          },
          icon: const Icon(Icons.help_outline_rounded, size: 18),
          label: const Text('Help'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const DownloadAppsDialog(),
            );
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Download Apps'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileWebNotice(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.language_rounded,
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
                    'Use manual connection to view shared screens.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const WebInstructionsDialog(),
                  );
                },
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: const Text('Connection Help'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DownloadAppsDialog(),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Apps'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualConnectionCard(ThemeData theme, bool isLargeScreen) {
    final colorScheme = theme.colorScheme;
    final padding = isLargeScreen ? 28.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF06B6D4).withOpacity(0.15),
            const Color(0xFF0EA5E9).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(isLargeScreen ? 28 : 24),
        border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isLargeScreen ? 18 : 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(isLargeScreen ? 18 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.link_rounded,
                  color: Colors.white,
                  size: isLargeScreen ? 36 : 32,
                ),
              ),
              SizedBox(width: isLargeScreen ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect Manually',
                      style:
                          (isLargeScreen
                                  ? theme.textTheme.headlineSmall
                                  : theme.textTheme.titleLarge)
                              ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: isLargeScreen ? 6 : 4),
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
          SizedBox(height: isLargeScreen ? 28 : 24),
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

  Widget _buildManualConnectionSmallCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showManualConnectionDialog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        ),
      ),
    );
  }

  Widget _buildShareCard(ThemeData theme, bool isLargeScreen) {
    final padding = isLargeScreen ? 28.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.15),
            const Color(0xFF4F46E5).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(isLargeScreen ? 28 : 24),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.25)),
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
                    padding: EdgeInsets.all(isLargeScreen ? 18 : 16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(
                        isLargeScreen ? 18 : 16,
                      ),
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
                    child: Icon(
                      Icons.screen_share_rounded,
                      color: Colors.white,
                      size: isLargeScreen ? 36 : 32,
                    ),
                  );
                },
              ),
              SizedBox(width: isLargeScreen ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share My Screen',
                      style:
                          (isLargeScreen
                                  ? theme.textTheme.headlineSmall
                                  : theme.textTheme.titleLarge)
                              ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: isLargeScreen ? 6 : 4),
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
          SizedBox(height: isLargeScreen ? 28 : 24),
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

  Widget _buildAvailableScreensHeader(
    ThemeData theme,
    int count,
    bool isLargeScreen,
  ) {
    return Row(
      children: [
        Text(
          'Available Screens',
          style:
              (isLargeScreen
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(width: isLargeScreen ? 16 : 12),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 14 : 10,
            vertical: isLargeScreen ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 12),
          ),
          child: Text(
            count.toString(),
            style:
                (isLargeScreen
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
          ),
        ),
        const Spacer(),
        // Manual connection button
        isLargeScreen
            ? FilledButton.tonal(
                onPressed: _showManualConnectionDialog,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Add Device'),
                  ],
                ),
              )
            : TextButton.icon(
                onPressed: _showManualConnectionDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Manually'),
              ),
      ],
    );
  }

  Widget _buildDeviceGrid(List<NetworkDevice> devices, bool isLargeScreen) {
    if (isLargeScreen) {
      // Grid layout for large screens
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 900 ? 3 : 2;
          final spacing = 16.0;
          final itemWidth =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: devices.asMap().entries.map((entry) {
              final index = entry.key;
              final device = entry.value;
              return SizedBox(
                width: itemWidth,
                child:
                    DeviceCard(
                          device: device,
                          onTap: () => _connectToDevice(device),
                        )
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: Duration(milliseconds: 200 + (index * 80)),
                        )
                        .slideY(begin: 0.1, end: 0),
              );
            }).toList(),
          );
        },
      );
    }

    // Column layout for mobile
    return Column(
      children: devices.asMap().entries.map((entry) {
        final index = entry.key;
        final device = entry.value;
        return DeviceCard(device: device, onTap: () => _connectToDevice(device))
            .animate()
            .fadeIn(
              duration: 400.ms,
              delay: Duration(milliseconds: 200 + (index * 100)),
            )
            .slideX(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    bool isDiscovering,
    bool isDiscoverySupported,
    bool isLargeScreen,
  ) {
    final verticalPadding = isLargeScreen ? 80.0 : 60.0;
    final horizontalPadding = isLargeScreen ? 48.0 : 24.0;
    final iconSize = isLargeScreen ? 56.0 : 48.0;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(isLargeScreen ? 28 : 24),
        border: Border.all(color: theme.colorScheme.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
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
              size: iconSize,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          SizedBox(height: isLargeScreen ? 32 : 24),
          Text(
            isDiscovering
                ? 'Scanning for devices...'
                : (isDiscoverySupported
                      ? 'No devices found'
                      : 'Manual connection required'),
            style:
                (isLargeScreen
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: isLargeScreen ? 12 : 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isLargeScreen ? 400 : 280),
            child: Text(
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
          ),
          if (!isDiscovering) ...[
            SizedBox(height: isLargeScreen ? 32 : 24),
            if (isDiscoverySupported)
              OutlinedButton.icon(
                onPressed: _startDiscovery,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Scan Again'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 28 : 20,
                    vertical: isLargeScreen ? 14 : 12,
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: _showManualConnectionDialog,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Connect Manually'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 28 : 20,
                    vertical: isLargeScreen ? 14 : 12,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(ThemeData theme, bool isLargeScreen) {
    final colorScheme = theme.colorScheme;

    final features = [
      _FeatureItem(
        icon: Icons.devices_rounded,
        title: 'Multi-Platform',
        description: 'Works on Android, iOS, macOS, Windows, Linux & Web',
        color: const Color(0xFF7C3AED),
      ),
      _FeatureItem(
        icon: Icons.people_rounded,
        title: 'Multi-Viewer',
        description: 'Share your screen to multiple viewers at once',
        color: const Color(0xFF06B6D4),
      ),
      _FeatureItem(
        icon: Icons.wifi_rounded,
        title: 'Auto-Discovery',
        description: 'Automatically find devices on your local network',
        color: const Color(0xFF10B981),
      ),
      _FeatureItem(
        icon: Icons.high_quality_rounded,
        title: 'HD Quality',
        description: 'Stream up to 1440p at 60fps on local network',
        color: const Color(0xFFF59E0B),
      ),
      _FeatureItem(
        icon: Icons.lock_rounded,
        title: 'Local Only',
        description: 'All traffic stays on your local WiFi network',
        color: const Color(0xFFEF4444),
      ),
      _FeatureItem(
        icon: Icons.flash_on_rounded,
        title: 'Low Latency',
        description: 'WebRTC peer-to-peer for minimal delay',
        color: const Color(0xFF3B82F6),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with documentation link
        Row(
          children: [
            Text(
              'Features',
              style:
                  (isLargeScreen
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.titleMedium)
                      ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.docs),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Documentation'),
            ),
          ],
        ),
        SizedBox(height: isLargeScreen ? 20 : 16),

        // Features grid
        if (isLargeScreen)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: features.map((feature) {
              return SizedBox(
                width: 280,
                child: _buildFeatureCard(feature, theme, colorScheme, true),
              );
            }).toList(),
          )
        else
          Column(
            children: features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFeatureCard(feature, theme, colorScheme, false),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFeatureCard(
    _FeatureItem feature,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLargeScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: isLargeScreen ? 24 : 20,
            ),
          ),
          SizedBox(width: isLargeScreen ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
