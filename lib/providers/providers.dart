import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';
import '../core/utils/logger.dart';

/// Provider for NetworkDiscoveryService
final networkDiscoveryServiceProvider = Provider<NetworkDiscoveryService>((
  ref,
) {
  final service = NetworkDiscoveryService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for SignalingService
final signalingServiceProvider = Provider<SignalingService>((ref) {
  final service = SignalingService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for WebRTCService
final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  final signalingService = ref.watch(signalingServiceProvider);
  final service = WebRTCService(signalingService);
  ref.onDispose(() => service.dispose());
  return service;
});

/// State for app initialization
final appInitializedProvider = FutureProvider<bool>((ref) async {
  final discoveryService = ref.read(networkDiscoveryServiceProvider);

  try {
    await discoveryService.initialize();
    return true;
  } catch (e) {
    AppLogger.error('Failed to initialize app', e);
    return false;
  }
});

/// Provider for discovered devices
final discoveredDevicesProvider =
    StateNotifierProvider<DiscoveredDevicesNotifier, List<NetworkDevice>>((
      ref,
    ) {
      final discoveryService = ref.watch(networkDiscoveryServiceProvider);
      return DiscoveredDevicesNotifier(discoveryService);
    });

class DiscoveredDevicesNotifier extends StateNotifier<List<NetworkDevice>> {
  final NetworkDiscoveryService _discoveryService;
  StreamSubscription? _subscription;

  DiscoveredDevicesNotifier(this._discoveryService) : super([]) {
    _subscription = _discoveryService.devicesStream.listen((devices) {
      state = devices;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for discovery state
final isDiscoveringProvider = StateProvider<bool>((ref) => false);

/// Provider to control device discovery
final discoveryControllerProvider = Provider<DiscoveryController>((ref) {
  return DiscoveryController(ref);
});

class DiscoveryController {
  final Ref _ref;

  DiscoveryController(this._ref);

  Future<void> startDiscovery() async {
    final service = _ref.read(networkDiscoveryServiceProvider);
    await service.startDiscovery();
    await service.startBroadcast();
    _ref.read(isDiscoveringProvider.notifier).state = true;
  }

  Future<void> stopDiscovery() async {
    final service = _ref.read(networkDiscoveryServiceProvider);
    await service.stopDiscovery();
    await service.stopBroadcast();
    _ref.read(isDiscoveringProvider.notifier).state = false;
  }
}

/// App settings state
class AppSettings {
  final StreamingQuality quality;
  final bool isDarkMode;
  final String deviceName;
  final bool autoConnect;
  final bool showCursor;

  const AppSettings({
    this.quality = StreamingQuality.medium,
    this.isDarkMode = true,
    this.deviceName = 'My Device',
    this.autoConnect = false,
    this.showCursor = true,
  });

  AppSettings copyWith({
    StreamingQuality? quality,
    bool? isDarkMode,
    String? deviceName,
    bool? autoConnect,
    bool? showCursor,
  }) {
    return AppSettings(
      quality: quality ?? this.quality,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      deviceName: deviceName ?? this.deviceName,
      autoConnect: autoConnect ?? this.autoConnect,
      showCursor: showCursor ?? this.showCursor,
    );
  }
}

/// Provider for app settings
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      return AppSettingsNotifier();
    });

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());

  void setQuality(StreamingQuality quality) {
    state = state.copyWith(quality: quality);
  }

  void setDarkMode(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
  }

  void setDeviceName(String name) {
    state = state.copyWith(deviceName: name);
  }

  void setAutoConnect(bool auto) {
    state = state.copyWith(autoConnect: auto);
  }

  void setShowCursor(bool show) {
    state = state.copyWith(showCursor: show);
  }
}

/// Sharing state
enum SharingState { idle, preparing, sharing, stopping, error }

/// Provider for current sharing state
final sharingStateProvider = StateProvider<SharingState>(
  (ref) => SharingState.idle,
);

/// Provider for current session
final currentSessionProvider = StateProvider<SharingSession?>((ref) => null);

/// Provider for connection state
final connectionStateProvider = StreamProvider<WebRTCConnectionState>((ref) {
  final webrtcService = ref.watch(webrtcServiceProvider);
  return webrtcService.connectionStateStream;
});

/// Provider for streaming metrics
final streamingMetricsProvider = StreamProvider<StreamingMetrics>((ref) {
  final webrtcService = ref.watch(webrtcServiceProvider);
  return webrtcService.metricsStream;
});

/// Main screen sharing controller
final screenSharingControllerProvider = Provider<ScreenSharingController>((
  ref,
) {
  return ScreenSharingController(ref);
});

class ScreenSharingController {
  final Ref _ref;

  ScreenSharingController(this._ref);

  /// Start sharing screen
  Future<void> startSharing() async {
    final webrtcService = _ref.read(webrtcServiceProvider);
    final signalingService = _ref.read(signalingServiceProvider);
    final discoveryService = _ref.read(networkDiscoveryServiceProvider);

    _ref.read(sharingStateProvider.notifier).state = SharingState.preparing;

    try {
      // Initialize services with device ID
      final localDevice = discoveryService.getLocalDevice();
      if (localDevice == null) {
        throw Exception('Local device not initialized');
      }

      signalingService.initialize(localDevice.id);
      await webrtcService.initialize(localDevice.id);

      // Start signaling server
      await signalingService.startServer();

      // Start screen capture
      await webrtcService.startScreenShare();

      // Update broadcast to indicate we're sharing
      await discoveryService.updateBroadcast(isSharing: true);

      // Create session
      final session = SharingSession(
        sessionId: localDevice.id,
        hostDeviceId: localDevice.id,
        hostDeviceName: localDevice.name,
        startedAt: DateTime.now(),
        quality: _ref.read(appSettingsProvider).quality,
        status: SessionStatus.streaming,
      );

      _ref.read(currentSessionProvider.notifier).state = session;
      _ref.read(sharingStateProvider.notifier).state = SharingState.sharing;

      AppLogger.info('Screen sharing started', 'Controller');
    } catch (e, stack) {
      AppLogger.error('Failed to start sharing', e, stack, 'Controller');
      _ref.read(sharingStateProvider.notifier).state = SharingState.error;
      rethrow;
    }
  }

  /// Stop sharing screen
  Future<void> stopSharing() async {
    final webrtcService = _ref.read(webrtcServiceProvider);
    final signalingService = _ref.read(signalingServiceProvider);
    final discoveryService = _ref.read(networkDiscoveryServiceProvider);

    _ref.read(sharingStateProvider.notifier).state = SharingState.stopping;

    try {
      await webrtcService.stop();
      await signalingService.stop();
      await discoveryService.updateBroadcast(isSharing: false);

      _ref.read(currentSessionProvider.notifier).state = null;
      _ref.read(sharingStateProvider.notifier).state = SharingState.idle;

      AppLogger.info('Screen sharing stopped', 'Controller');
    } catch (e, stack) {
      AppLogger.error('Failed to stop sharing', e, stack, 'Controller');
      _ref.read(sharingStateProvider.notifier).state = SharingState.error;
    }
  }

  /// Connect to a sharing session (as viewer)
  Future<void> connectToSession(NetworkDevice device) async {
    final webrtcService = _ref.read(webrtcServiceProvider);
    final signalingService = _ref.read(signalingServiceProvider);
    final discoveryService = _ref.read(networkDiscoveryServiceProvider);

    try {
      // Initialize services
      final localDevice = discoveryService.getLocalDevice();
      if (localDevice == null) {
        throw Exception('Local device not initialized');
      }

      signalingService.initialize(localDevice.id);
      await webrtcService.initialize(localDevice.id);

      // Connect to host's signaling server
      await signalingService.connectToServer(
        device.ipAddress,
        device.port + 1, // Signaling port is service port + 1
      );

      // Connect WebRTC
      await webrtcService.connectToHost(device.id);

      // Create viewing session
      final session = SharingSession(
        sessionId: device.id,
        hostDeviceId: device.id,
        hostDeviceName: device.name,
        startedAt: DateTime.now(),
        quality: _ref.read(appSettingsProvider).quality,
        status: SessionStatus.streaming,
      );

      _ref.read(currentSessionProvider.notifier).state = session;

      AppLogger.info('Connected to session: ${device.name}', 'Controller');
    } catch (e, stack) {
      AppLogger.error('Failed to connect to session', e, stack, 'Controller');
      rethrow;
    }
  }

  /// Disconnect from viewing session
  Future<void> disconnect() async {
    final webrtcService = _ref.read(webrtcServiceProvider);
    final signalingService = _ref.read(signalingServiceProvider);

    await webrtcService.stop();
    await signalingService.stop();

    _ref.read(currentSessionProvider.notifier).state = null;

    AppLogger.info('Disconnected from session', 'Controller');
  }
}
