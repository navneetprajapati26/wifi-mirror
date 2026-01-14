/// Application-wide constants for WiFi Mirror
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'WiFi Mirror';
  static const String appVersion = '1.0.0';

  // Network Service Discovery
  static const String serviceType = '_wifimirror._tcp';
  static const String serviceName = 'WiFiMirror';
  static const int servicePort = 50123;

  // WebRTC Signaling
  static const int signalingPort = 50124;

  // Streaming Quality Presets for Local Network
  static const Map<String, StreamingQuality> qualityPresets = {
    'low': StreamingQuality(
      width: 1280,
      height: 720,
      frameRate: 30,
      bitrate: 1000000, // 1 Mbps
    ),
    'medium': StreamingQuality(
      width: 1920,
      height: 1080,
      frameRate: 30,
      bitrate: 4000000, // 4 Mbps
    ),
    'high': StreamingQuality(
      width: 2560,
      height: 1440,
      frameRate: 60,
      bitrate: 10000000, // 10 Mbps
    ),
  };

  // Connection Timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration discoveryTimeout = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 3);

  // Max Retry Attempts
  static const int maxReconnectAttempts = 5;

  // Buffer Sizes
  static const int signalBufferSize = 4096;
}

/// Streaming quality configuration
class StreamingQuality {
  final int width;
  final int height;
  final int frameRate;
  final int bitrate;

  const StreamingQuality({
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitrate,
  });

  String get displayName {
    if (height <= 360) return 'Low (360p)';
    if (height <= 720) return 'Medium (720p)';
    if (height <= 1080) return 'High (1080p)';
    return 'Ultra (1440p+)';
  }

  Map<String, dynamic> toMap() => {
    'width': width,
    'height': height,
    'frameRate': frameRate,
    'bitrate': bitrate,
  };
}
