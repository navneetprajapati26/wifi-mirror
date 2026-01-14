import 'package:uuid/uuid.dart';

/// Represents a device discovered on the local network
class NetworkDevice {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final DeviceType deviceType;
  final bool isSharing;
  final DateTime discoveredAt;
  final Map<String, String> metadata;

  NetworkDevice({
    String? id,
    required this.name,
    required this.ipAddress,
    required this.port,
    this.deviceType = DeviceType.unknown,
    this.isSharing = false,
    DateTime? discoveredAt,
    this.metadata = const {},
  }) : id = id ?? const Uuid().v4(),
       discoveredAt = discoveredAt ?? DateTime.now();

  /// Creates a copy with updated fields
  NetworkDevice copyWith({
    String? name,
    String? ipAddress,
    int? port,
    DeviceType? deviceType,
    bool? isSharing,
    Map<String, String>? metadata,
  }) {
    return NetworkDevice(
      id: id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      deviceType: deviceType ?? this.deviceType,
      isSharing: isSharing ?? this.isSharing,
      discoveredAt: discoveredAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates from mDNS service attributes
  factory NetworkDevice.fromServiceInfo({
    required String name,
    required String ip,
    required int port,
    Map<String, String>? txtRecords,
  }) {
    final deviceTypeStr = txtRecords?['device_type'] ?? 'unknown';
    final isSharing = txtRecords?['is_sharing'] == 'true';

    return NetworkDevice(
      id: txtRecords?['device_id'] ?? const Uuid().v4(),
      name: name,
      ipAddress: ip,
      port: port,
      deviceType: DeviceType.fromString(deviceTypeStr),
      isSharing: isSharing,
      metadata: txtRecords ?? {},
    );
  }

  /// Converts to mDNS TXT records
  Map<String, String> toTxtRecords() => {
    'device_id': id,
    'device_type': deviceType.name,
    'is_sharing': isSharing.toString(),
    ...metadata,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NetworkDevice(id: $id, name: $name, ip: $ipAddress:$port, sharing: $isSharing)';
}

/// Types of devices that can be discovered
enum DeviceType {
  android,
  ios,
  windows,
  macos,
  linux,
  unknown;

  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => DeviceType.unknown,
    );
  }

  String get displayName {
    switch (this) {
      case DeviceType.android:
        return 'Android';
      case DeviceType.ios:
        return 'iOS';
      case DeviceType.windows:
        return 'Windows';
      case DeviceType.macos:
        return 'macOS';
      case DeviceType.linux:
        return 'Linux';
      case DeviceType.unknown:
        return 'Unknown';
    }
  }

  String get icon {
    switch (this) {
      case DeviceType.android:
        return '🤖';
      case DeviceType.ios:
        return '📱';
      case DeviceType.windows:
        return '💻';
      case DeviceType.macos:
        return '🍎';
      case DeviceType.linux:
        return '🐧';
      case DeviceType.unknown:
        return '❓';
    }
  }
}
