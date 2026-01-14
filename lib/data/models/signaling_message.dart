/// WebRTC signaling message types and data structures
class SignalingMessage {
  final SignalingType type;
  final String senderId;
  final String? targetId;
  final dynamic payload;
  final DateTime timestamp;

  SignalingMessage({
    required this.type,
    required this.senderId,
    this.targetId,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'sender_id': senderId,
    'target_id': targetId,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: SignalingType.fromString(json['type'] as String),
      senderId: json['sender_id'] as String,
      targetId: json['target_id'] as String?,
      payload: json['payload'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Create an offer message
  factory SignalingMessage.offer({
    required String senderId,
    required String targetId,
    required Map<String, dynamic> sdp,
  }) => SignalingMessage(
    type: SignalingType.offer,
    senderId: senderId,
    targetId: targetId,
    payload: sdp,
  );

  /// Create an answer message
  factory SignalingMessage.answer({
    required String senderId,
    required String targetId,
    required Map<String, dynamic> sdp,
  }) => SignalingMessage(
    type: SignalingType.answer,
    senderId: senderId,
    targetId: targetId,
    payload: sdp,
  );

  /// Create an ICE candidate message
  factory SignalingMessage.iceCandidate({
    required String senderId,
    required String targetId,
    required Map<String, dynamic> candidate,
  }) => SignalingMessage(
    type: SignalingType.iceCandidate,
    senderId: senderId,
    targetId: targetId,
    payload: candidate,
  );

  /// Create a join request
  factory SignalingMessage.joinRequest({
    required String senderId,
    required String targetId,
    String? password,
  }) => SignalingMessage(
    type: SignalingType.joinRequest,
    senderId: senderId,
    targetId: targetId,
    payload: {'password': password},
  );

  /// Create a join response
  factory SignalingMessage.joinResponse({
    required String senderId,
    required String targetId,
    required bool accepted,
    String? reason,
  }) => SignalingMessage(
    type: SignalingType.joinResponse,
    senderId: senderId,
    targetId: targetId,
    payload: {'accepted': accepted, 'reason': reason},
  );

  /// Create a disconnect message
  factory SignalingMessage.disconnect({
    required String senderId,
    String? targetId,
  }) => SignalingMessage(
    type: SignalingType.disconnect,
    senderId: senderId,
    targetId: targetId,
  );

  @override
  String toString() =>
      'SignalingMessage(type: $type, from: $senderId, to: $targetId)';
}

/// Types of signaling messages
enum SignalingType {
  offer,
  answer,
  iceCandidate,
  joinRequest,
  joinResponse,
  disconnect,
  ping,
  pong,
  qualityChange,
  error,
  unknown;

  static SignalingType fromString(String value) {
    // Handle both camelCase and snake_case
    final normalized = value.replaceAll('_', '').toLowerCase();
    return SignalingType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => SignalingType.unknown,
    );
  }
}

/// Connection quality metrics
class StreamingMetrics {
  final double fps;
  final int latencyMs;
  final int bitrate;
  final double packetLoss;
  final int jitterMs;
  final DateTime timestamp;

  StreamingMetrics({
    required this.fps,
    required this.latencyMs,
    required this.bitrate,
    required this.packetLoss,
    required this.jitterMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Quality rating from 1-5 based on metrics
  int get qualityRating {
    if (latencyMs < 100 && fps >= 25 && packetLoss < 1) return 5;
    if (latencyMs < 200 && fps >= 20 && packetLoss < 3) return 4;
    if (latencyMs < 300 && fps >= 15 && packetLoss < 5) return 3;
    if (latencyMs < 500 && fps >= 10 && packetLoss < 10) return 2;
    return 1;
  }

  String get qualityLabel {
    switch (qualityRating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Good';
      case 3:
        return 'Fair';
      case 2:
        return 'Poor';
      default:
        return 'Bad';
    }
  }

  Map<String, dynamic> toJson() => {
    'fps': fps,
    'latency_ms': latencyMs,
    'bitrate': bitrate,
    'packet_loss': packetLoss,
    'jitter_ms': jitterMs,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StreamingMetrics.zero() => StreamingMetrics(
    fps: 0,
    latencyMs: 0,
    bitrate: 0,
    packetLoss: 0,
    jitterMs: 0,
  );

  @override
  String toString() =>
      'StreamingMetrics(fps: $fps, latency: ${latencyMs}ms, quality: $qualityLabel)';
}
