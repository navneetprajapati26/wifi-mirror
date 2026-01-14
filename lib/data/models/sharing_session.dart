/// Represents a screen sharing session
class SharingSession {
  final String sessionId;
  final String hostDeviceId;
  final String hostDeviceName;
  final DateTime startedAt;
  final StreamingQuality quality;
  final bool isPasswordProtected;
  final List<String> viewerIds;
  final SessionStatus status;
  final String? password;

  SharingSession({
    required this.sessionId,
    required this.hostDeviceId,
    required this.hostDeviceName,
    required this.startedAt,
    required this.quality,
    this.isPasswordProtected = false,
    this.viewerIds = const [],
    this.status = SessionStatus.initializing,
    this.password,
  });

  /// Number of connected viewers
  int get viewerCount => viewerIds.length;

  /// Session duration
  Duration get duration => DateTime.now().difference(startedAt);

  /// Creates a copy with updated fields
  SharingSession copyWith({
    StreamingQuality? quality,
    List<String>? viewerIds,
    SessionStatus? status,
    String? password,
    bool? isPasswordProtected,
  }) {
    return SharingSession(
      sessionId: sessionId,
      hostDeviceId: hostDeviceId,
      hostDeviceName: hostDeviceName,
      startedAt: startedAt,
      quality: quality ?? this.quality,
      isPasswordProtected: isPasswordProtected ?? this.isPasswordProtected,
      viewerIds: viewerIds ?? this.viewerIds,
      status: status ?? this.status,
      password: password ?? this.password,
    );
  }

  /// Adds a viewer to the session
  SharingSession addViewer(String viewerId) {
    if (viewerIds.contains(viewerId)) return this;
    return copyWith(viewerIds: [...viewerIds, viewerId]);
  }

  /// Removes a viewer from the session
  SharingSession removeViewer(String viewerId) {
    return copyWith(
      viewerIds: viewerIds.where((id) => id != viewerId).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'host_device_id': hostDeviceId,
    'host_device_name': hostDeviceName,
    'started_at': startedAt.toIso8601String(),
    'quality': quality.name,
    'is_password_protected': isPasswordProtected,
    'viewer_count': viewerCount,
    'status': status.name,
  };

  factory SharingSession.fromJson(Map<String, dynamic> json) {
    return SharingSession(
      sessionId: json['session_id'] as String,
      hostDeviceId: json['host_device_id'] as String,
      hostDeviceName: json['host_device_name'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      quality: StreamingQuality.fromString(json['quality'] as String),
      isPasswordProtected: json['is_password_protected'] as bool? ?? false,
      viewerIds: (json['viewer_ids'] as List<dynamic>?)?.cast<String>() ?? [],
      status: SessionStatus.fromString(json['status'] as String),
    );
  }

  @override
  String toString() =>
      'SharingSession(id: $sessionId, host: $hostDeviceName, viewers: $viewerCount, status: $status)';
}

/// Session status
enum SessionStatus {
  initializing,
  ready,
  streaming,
  paused,
  reconnecting,
  ended,
  error;

  static SessionStatus fromString(String value) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => SessionStatus.error,
    );
  }

  bool get isActive =>
      this == streaming || this == paused || this == reconnecting;
}

/// Streaming quality levels
enum StreamingQuality {
  low,
  medium,
  high;

  static StreamingQuality fromString(String value) {
    return StreamingQuality.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => StreamingQuality.medium,
    );
  }

  String get displayName {
    switch (this) {
      case StreamingQuality.low:
        return 'Low (720p)';
      case StreamingQuality.medium:
        return 'Medium (1080p)';
      case StreamingQuality.high:
        return 'High (1440p)';
    }
  }

  int get width {
    switch (this) {
      case StreamingQuality.low:
        return 1280;
      case StreamingQuality.medium:
        return 1920;
      case StreamingQuality.high:
        return 2560;
    }
  }

  int get height {
    switch (this) {
      case StreamingQuality.low:
        return 720;
      case StreamingQuality.medium:
        return 1080;
      case StreamingQuality.high:
        return 1440;
    }
  }

  int get frameRate {
    switch (this) {
      case StreamingQuality.low:
        return 30;
      case StreamingQuality.medium:
        return 30;
      case StreamingQuality.high:
        return 60;
    }
  }

  int get bitrate {
    switch (this) {
      case StreamingQuality.low:
        return 1000000; // 1 Mbps
      case StreamingQuality.medium:
        return 4000000; // 4 Mbps
      case StreamingQuality.high:
        return 10000000; // 10 Mbps
    }
  }
}
