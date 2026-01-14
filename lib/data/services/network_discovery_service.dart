import 'dart:async';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// Service for discovering and advertising devices on the local network using mDNS
class NetworkDiscoveryService {
  static const String _module = 'NetworkDiscovery';

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  final StreamController<List<NetworkDevice>> _devicesController =
      StreamController<List<NetworkDevice>>.broadcast();

  final Map<String, NetworkDevice> _discoveredDevices = {};

  String? _localDeviceId;
  String? _localDeviceName;
  DeviceType? _localDeviceType;
  bool _isSharing = false;
  bool _isBroadcasting = false;
  bool _isDiscovering = false;

  /// Stream of discovered devices
  Stream<List<NetworkDevice>> get devicesStream => _devicesController.stream;

  /// Current list of discovered devices
  List<NetworkDevice> get discoveredDevices =>
      _discoveredDevices.values.toList();

  /// Whether service discovery is running
  bool get isDiscovering => _isDiscovering;

  /// Whether we are broadcasting our service
  bool get isBroadcasting => _isBroadcasting;

  /// Initialize the service
  Future<void> initialize() async {
    AppLogger.info('Initializing network discovery service', _module);
    await _initializeDeviceInfo();
  }

  /// Get device information
  Future<void> _initializeDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        _localDeviceName = info.model;
        _localDeviceType = DeviceType.android;
        _localDeviceId = info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        _localDeviceName = info.name;
        _localDeviceType = DeviceType.ios;
        _localDeviceId = info.identifierForVendor;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        _localDeviceName = info.computerName;
        _localDeviceType = DeviceType.macos;
        _localDeviceId = info.systemGUID;
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        _localDeviceName = info.computerName;
        _localDeviceType = DeviceType.windows;
        _localDeviceId = info.deviceId;
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        _localDeviceName = info.prettyName;
        _localDeviceType = DeviceType.linux;
        _localDeviceId = info.machineId;
      }

      AppLogger.info(
        'Device info: $_localDeviceName (${_localDeviceType?.name})',
        _module,
      );
    } catch (e) {
      AppLogger.error('Failed to get device info', e, null, _module);
      _localDeviceName = 'Unknown Device';
      _localDeviceType = DeviceType.unknown;
      _localDeviceId = 'unknown-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Start broadcasting our service on the network
  Future<void> startBroadcast({bool isSharing = false}) async {
    if (_isBroadcasting) {
      AppLogger.warning('Broadcast already running', _module);
      return;
    }

    _isSharing = isSharing;

    try {
      final service = BonsoirService(
        name: _localDeviceName ?? 'WiFi Mirror Device',
        type: AppConstants.serviceType,
        port: AppConstants.servicePort,
        attributes: {
          'device_id': _localDeviceId ?? '',
          'device_type': _localDeviceType?.name ?? 'unknown',
          'is_sharing': _isSharing.toString(),
          'version': AppConstants.appVersion,
        },
      );

      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.initialize();
      await _broadcast!.start();
      _isBroadcasting = true;

      AppLogger.info('Started broadcasting service: ${service.name}', _module);
    } catch (e, stack) {
      AppLogger.error('Failed to start broadcast', e, stack, _module);
      _isBroadcasting = false;
      rethrow;
    }
  }

  /// Stop broadcasting our service
  Future<void> stopBroadcast() async {
    if (!_isBroadcasting || _broadcast == null) return;

    try {
      await _broadcast!.stop();
      _broadcast = null;
      _isBroadcasting = false;
      AppLogger.info('Stopped broadcasting', _module);
    } catch (e, stack) {
      AppLogger.error('Failed to stop broadcast', e, stack, _module);
    }
  }

  /// Update broadcast status (e.g., when sharing state changes)
  Future<void> updateBroadcast({required bool isSharing}) async {
    if (_isSharing == isSharing) return;

    _isSharing = isSharing;
    if (_isBroadcasting) {
      // Restart broadcast with new attributes
      await stopBroadcast();
      await startBroadcast(isSharing: isSharing);
    }
  }

  /// Start discovering devices on the network
  Future<void> startDiscovery() async {
    if (_isDiscovering) {
      AppLogger.warning('Discovery already running', _module);
      return;
    }

    try {
      _discoveredDevices.clear();
      _discovery = BonsoirDiscovery(type: AppConstants.serviceType);
      await _discovery!.initialize();

      _discovery!.eventStream!.listen((event) {
        _handleDiscoveryEvent(event);
      });

      await _discovery!.start();
      _isDiscovering = true;

      AppLogger.info('Started device discovery', _module);
    } catch (e, stack) {
      AppLogger.error('Failed to start discovery', e, stack, _module);
      _isDiscovering = false;
      rethrow;
    }
  }

  /// Handle discovery events using pattern matching (Bonsoir 6.0 API)
  void _handleDiscoveryEvent(BonsoirDiscoveryEvent event) {
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent():
        AppLogger.debug('Service found: ${event.service.name}', _module);
        // Resolve the service to get IP address
        event.service.resolve(_discovery!.serviceResolver);
        break;

      case BonsoirDiscoveryServiceResolvedEvent():
        _handleServiceResolved(event.service);
        break;

      // Add handling for updated events
      case BonsoirDiscoveryServiceUpdatedEvent():
        AppLogger.debug('Service updated: ${event.service.name}', _module);
        // The service might already be resolved, so we handle it as resolved
        _handleServiceResolved(event.service);
        break;

      case BonsoirDiscoveryServiceLostEvent():
        _handleServiceLost(event.service);
        break;

      default:
        AppLogger.debug('Discovery event: $event', _module);
        break;
    }
  }

  /// Handle when a service is fully resolved
  void _handleServiceResolved(BonsoirService service) {
    // Skip our own device
    final deviceId = service.attributes['device_id'];
    if (deviceId == _localDeviceId) {
      AppLogger.debug('Ignoring own device', _module);
      return;
    }

    // In Bonsoir 6.0, after resolution, BonsoirService has a 'host' property
    // that contains the IP address/hostname of the resolved service.
    final String ipAddress = service.host ?? '';

    final device = NetworkDevice.fromServiceInfo(
      name: service.name,
      ip: ipAddress,
      port: service.port,
      txtRecords: service.attributes,
    );

    _discoveredDevices[device.id] = device;
    _notifyDevicesChanged();

    AppLogger.info(
      'Resolved device: ${device.name} (${device.ipAddress}:${device.port})',
      _module,
    );
  }

  /// Handle when a service is lost
  void _handleServiceLost(BonsoirService service) {
    final deviceId = service.attributes['device_id'];
    if (deviceId != null && _discoveredDevices.containsKey(deviceId)) {
      _discoveredDevices.remove(deviceId);
      _notifyDevicesChanged();
      AppLogger.info('Service lost: ${service.name}', _module);
    }
  }

  /// Stop discovering devices
  Future<void> stopDiscovery() async {
    if (!_isDiscovering || _discovery == null) return;

    try {
      await _discovery!.stop();
      _discovery = null;
      _isDiscovering = false;
      AppLogger.info('Stopped discovery', _module);
    } catch (e, stack) {
      AppLogger.error('Failed to stop discovery', e, stack, _module);
    }
  }

  /// Notify listeners of device changes
  void _notifyDevicesChanged() {
    if (!_devicesController.isClosed) {
      _devicesController.add(discoveredDevices);
    }
  }

  /// Get local device info
  NetworkDevice? getLocalDevice() {
    if (_localDeviceId == null) return null;

    return NetworkDevice(
      id: _localDeviceId!,
      name: _localDeviceName ?? 'This Device',
      ipAddress: '', // Will be filled when broadcasting
      port: AppConstants.servicePort,
      deviceType: _localDeviceType ?? DeviceType.unknown,
      isSharing: _isSharing,
    );
  }

  /// Clean up resources
  Future<void> dispose() async {
    await stopDiscovery();
    await stopBroadcast();
    await _devicesController.close();
    AppLogger.info('Disposed network discovery service', _module);
  }
}
