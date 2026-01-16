import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/models.dart';
import '../../core/utils/logger.dart';
import 'signaling_service.dart';

/// Service for handling WebRTC connections for screen sharing
/// Supports multiple simultaneous viewers
class WebRTCService {
  static const String _module = 'WebRTC';

  final SignalingService _signalingService;

  // For host: Map of viewer ID to their peer connection
  final Map<String, RTCPeerConnection> _viewerConnections = {};

  // For viewer: Single connection to host
  RTCPeerConnection? _hostConnection;

  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  final StreamController<WebRTCConnectionState> _connectionStateController =
      StreamController<WebRTCConnectionState>.broadcast();

  final StreamController<StreamingMetrics> _metricsController =
      StreamController<StreamingMetrics>.broadcast();

  final StreamController<int> _viewerCountController =
      StreamController<int>.broadcast();

  String? _localDeviceId;
  String? _remoteDeviceId; // Only used when we are a viewer
  StreamingQuality _quality = StreamingQuality.medium;
  bool _isHost = false;
  Timer? _metricsTimer;

  /// Stream of connection state changes
  Stream<WebRTCConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Stream of streaming metrics
  Stream<StreamingMetrics> get metricsStream => _metricsController.stream;

  /// Stream of viewer count changes (for host)
  Stream<int> get viewerCountStream => _viewerCountController.stream;

  /// Current connection state
  WebRTCConnectionState _connectionState = WebRTCConnectionState.disconnected;
  WebRTCConnectionState get connectionState => _connectionState;

  /// Whether we are the host (screen sharer)
  bool get isHost => _isHost;

  /// Current streaming quality
  StreamingQuality get quality => _quality;

  /// Number of connected viewers (for host)
  int get viewerCount => _viewerConnections.length;

  WebRTCService(this._signalingService);

  /// Get WebRTC configuration with STUN servers
  /// Note: TURN servers removed as free ones are unreliable
  Map<String, dynamic> get _configuration {
    return {
      'iceServers': <Map<String, dynamic>>[
        // Google STUN servers (free, reliable)
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
        {'urls': 'stun:stun3.l.google.com:19302'},
        {'urls': 'stun:stun4.l.google.com:19302'},

        // Twilio STUN (generally reliable)
        {'urls': 'stun:global.stun.twilio.com:3478'},
      ],
      'sdpSemantics': 'unified-plan',
      'iceTransportPolicy': 'all',
    };
  }

  /// Initialize the WebRTC service
  Future<void> initialize(String deviceId) async {
    _localDeviceId = deviceId;

    await localRenderer.initialize();
    await remoteRenderer.initialize();

    // Listen for signaling messages
    _signalingService.messageStream.listen(_handleSignalingMessage);

    AppLogger.info('WebRTC service initialized', _module);
  }

  /// Start sharing screen (as host) - supports multiple viewers
  Future<void> startScreenShare() async {
    _isHost = true;
    _updateConnectionState(WebRTCConnectionState.connecting);

    try {
      // Start screen capture
      _localStream = await _getScreenStream();

      if (_localStream != null) {
        localRenderer.srcObject = _localStream;

        _updateConnectionState(WebRTCConnectionState.ready);
        _startMetricsCollection();

        AppLogger.info('Screen sharing started - waiting for viewers', _module);
      } else {
        throw Exception('Failed to get screen stream');
      }
    } catch (e, stack) {
      AppLogger.error('Failed to start screen share', e, stack, _module);
      _updateConnectionState(WebRTCConnectionState.error);
      rethrow;
    }
  }

  /// Get screen capture stream
  Future<MediaStream?> _getScreenStream() async {
    try {
      if (Platform.isAndroid) {
        try {
          const channel = MethodChannel('com.wifimirror/service');
          await channel.invokeMethod('startForegroundService');
          AppLogger.info('Started Android foreground service', _module);
        } on PlatformException catch (e) {
          if (e.code == 'PERMISSION_DENIED') {
            AppLogger.warning('User denied screen capture permission', _module);
            rethrow;
          }
          AppLogger.error(
            'Failed to start foreground service',
            e,
            null,
            _module,
          );
          rethrow;
        }
      }

      final stream = await navigator.mediaDevices.getDisplayMedia({
        'video': {
          'width': {'ideal': _quality.width},
          'height': {'ideal': _quality.height},
          'frameRate': {'ideal': _quality.frameRate},
        },
        'audio': false,
      });

      AppLogger.info('Got screen stream: ${stream.id}', _module);
      return stream;
    } catch (e) {
      AppLogger.error('Failed to get screen stream', e, null, _module);

      if (Platform.isAndroid) {
        try {
          const channel = MethodChannel('com.wifimirror/service');
          await channel.invokeMethod('stopForegroundService');
        } catch (_) {}
      }

      // Fallback: try getUserMedia (for testing)
      try {
        final stream = await navigator.mediaDevices.getUserMedia({
          'video': {
            'width': {'ideal': _quality.width},
            'height': {'ideal': _quality.height},
            'frameRate': {'ideal': _quality.frameRate},
          },
          'audio': false,
        });
        AppLogger.info('Using camera as fallback for screen share', _module);
        return stream;
      } catch (e2) {
        AppLogger.error('Fallback also failed', e2, null, _module);
        return null;
      }
    }
  }

  /// Connect to a screen share session (as viewer)
  Future<void> connectToHost(String hostDeviceId) async {
    _isHost = false;
    _remoteDeviceId = hostDeviceId;
    _updateConnectionState(WebRTCConnectionState.connecting);

    try {
      _hostConnection = await _createPeerConnectionAsViewer();
      AppLogger.info('Connecting to host: $hostDeviceId', _module);
    } catch (e, stack) {
      AppLogger.error('Failed to connect to host', e, stack, _module);
      _updateConnectionState(WebRTCConnectionState.error);
      rethrow;
    }
  }

  /// Create peer connection for a viewer (host side) - for multi-viewer support
  Future<RTCPeerConnection> _createPeerConnectionForViewer(
    String viewerId,
  ) async {
    final pc = await createPeerConnection(_configuration);

    // Set up event handlers for this viewer's connection
    pc.onIceCandidate = (candidate) =>
        _handleIceCandidateForViewer(viewerId, candidate);
    pc.onIceConnectionState = (state) =>
        _handleIceConnectionStateForViewer(viewerId, state);
    pc.onConnectionState = (state) =>
        _handleConnectionStateForViewer(viewerId, state);

    pc.onIceGatheringState = (RTCIceGatheringState state) {
      AppLogger.info('ICE gathering state for $viewerId: $state', _module);
    };

    // Add local stream tracks to this connection
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        final sender = await pc.addTrack(track, _localStream!);
        if (track.kind == 'video') {
          await _setVideoQualityOnSender(sender);
        }
      }
    }

    AppLogger.info('Created peer connection for viewer: $viewerId', _module);
    return pc;
  }

  /// Create peer connection when WE are the viewer (connecting to a host)
  Future<RTCPeerConnection> _createPeerConnectionAsViewer() async {
    final pc = await createPeerConnection(_configuration);

    pc.onIceCandidate = _handleIceCandidateAsViewer;
    pc.onIceConnectionState = _handleIceConnectionStateAsViewer;
    pc.onConnectionState = _handleConnectionStateAsViewer;
    pc.onTrack = _handleTrack;

    pc.onIceGatheringState = (RTCIceGatheringState state) {
      AppLogger.info('ICE gathering state: $state', _module);
    };

    AppLogger.info('Created peer connection as viewer', _module);
    return pc;
  }

  // ==================== HOST SIDE HANDLERS ====================

  /// Handle ICE candidate for a specific viewer (host side)
  void _handleIceCandidateForViewer(
    String viewerId,
    RTCIceCandidate candidate,
  ) {
    final candidateType = _parseCandidateType(candidate.candidate ?? '');
    AppLogger.info('ICE candidate for $viewerId: type=$candidateType', _module);

    _signalingService.sendMessage(
      SignalingMessage.iceCandidate(
        senderId: _localDeviceId!,
        targetId: viewerId,
        candidate: candidate.toMap(),
      ),
    );
  }

  /// Handle ICE connection state for a specific viewer (host side)
  void _handleIceConnectionStateForViewer(
    String viewerId,
    RTCIceConnectionState state,
  ) {
    AppLogger.info('ICE state for viewer $viewerId: $state', _module);

    if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      AppLogger.info('Viewer $viewerId connected!', _module);
      _updateConnectionState(WebRTCConnectionState.connected);
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
        state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
      AppLogger.warning('Viewer $viewerId disconnected', _module);
      _removeViewer(viewerId);
    }
  }

  /// Handle connection state for a specific viewer (host side)
  void _handleConnectionStateForViewer(
    String viewerId,
    RTCPeerConnectionState state,
  ) {
    AppLogger.info('Connection state for viewer $viewerId: $state', _module);

    if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      _removeViewer(viewerId);
    }
  }

  /// Remove a viewer connection
  Future<void> _removeViewer(String viewerId) async {
    final pc = _viewerConnections.remove(viewerId);
    if (pc != null) {
      await pc.close();
      AppLogger.info(
        'Removed viewer: $viewerId (${_viewerConnections.length} remaining)',
        _module,
      );
      _notifyViewerCountChanged();
    }
  }

  // ==================== VIEWER SIDE HANDLERS ====================

  /// Handle ICE candidate when we are the viewer
  void _handleIceCandidateAsViewer(RTCIceCandidate candidate) {
    final candidateType = _parseCandidateType(candidate.candidate ?? '');
    AppLogger.info('ICE candidate: type=$candidateType', _module);

    if (_remoteDeviceId != null) {
      _signalingService.sendMessage(
        SignalingMessage.iceCandidate(
          senderId: _localDeviceId!,
          targetId: _remoteDeviceId!,
          candidate: candidate.toMap(),
        ),
      );
    }
  }

  /// Handle ICE connection state when we are the viewer
  void _handleIceConnectionStateAsViewer(RTCIceConnectionState state) {
    AppLogger.info('ICE connection state: $state', _module);

    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        AppLogger.info('Connected to host!', _module);
        _updateConnectionState(WebRTCConnectionState.connected);
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        _updateConnectionState(WebRTCConnectionState.reconnecting);
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        AppLogger.error('ICE connection failed', null, null, _module);
        _updateConnectionState(WebRTCConnectionState.error);
        break;
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        _updateConnectionState(WebRTCConnectionState.disconnected);
        break;
      default:
        break;
    }
  }

  /// Handle connection state when we are the viewer
  void _handleConnectionStateAsViewer(RTCPeerConnectionState state) {
    AppLogger.info('Peer connection state: $state', _module);

    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _updateConnectionState(WebRTCConnectionState.connected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _updateConnectionState(WebRTCConnectionState.error);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _updateConnectionState(WebRTCConnectionState.disconnected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        _updateConnectionState(WebRTCConnectionState.reconnecting);
        break;
      default:
        break;
    }
  }

  /// Handle incoming track (remote stream) - viewer side
  void _handleTrack(RTCTrackEvent event) {
    AppLogger.info(
      'Track received: kind=${event.track.kind}, streams=${event.streams.length}',
      _module,
    );

    if (event.streams.isNotEmpty) {
      _remoteStream = event.streams[0];
      remoteRenderer.srcObject = _remoteStream;
      _startMetricsCollection();

      AppLogger.info(
        'Remote stream attached: id=${_remoteStream?.id}',
        _module,
      );
    }
  }

  // ==================== SIGNALING MESSAGE HANDLING ====================

  /// Handle incoming signaling message
  Future<void> _handleSignalingMessage(SignalingMessage message) async {
    // Ignore messages not for us
    if (message.targetId != null &&
        message.targetId != _localDeviceId &&
        message.targetId != 'server') {
      return;
    }

    switch (message.type) {
      case SignalingType.joinRequest:
        if (_isHost) {
          await _handleViewerJoin(message.senderId);
        }
        break;

      case SignalingType.offer:
        await _handleOffer(message);
        break;

      case SignalingType.answer:
        await _handleAnswer(message);
        break;

      case SignalingType.iceCandidate:
        await _handleRemoteIceCandidate(message);
        break;

      case SignalingType.disconnect:
        if (_isHost) {
          await _removeViewer(message.senderId);
        } else if (message.senderId == _remoteDeviceId) {
          await stop();
        }
        break;

      default:
        break;
    }
  }

  /// Handle viewer joining (host side) - NOW SUPPORTS MULTIPLE VIEWERS
  Future<void> _handleViewerJoin(String viewerId) async {
    // Check if this viewer is already connected
    if (_viewerConnections.containsKey(viewerId)) {
      AppLogger.warning(
        'Viewer $viewerId already connected, ignoring duplicate',
        _module,
      );
      return;
    }

    AppLogger.info('New viewer joining: $viewerId', _module);

    // Create a new peer connection for this viewer
    final pc = await _createPeerConnectionForViewer(viewerId);
    _viewerConnections[viewerId] = pc;

    // Send join response
    _signalingService.sendMessage(
      SignalingMessage.joinResponse(
        senderId: _localDeviceId!,
        targetId: viewerId,
        accepted: true,
      ),
    );

    // Create and send offer to this specific viewer
    await _createAndSendOfferToViewer(viewerId, pc);

    _notifyViewerCountChanged();
    AppLogger.info(
      'Viewer $viewerId joined (total: ${_viewerConnections.length})',
      _module,
    );
  }

  /// Create and send SDP offer to a specific viewer
  Future<void> _createAndSendOfferToViewer(
    String viewerId,
    RTCPeerConnection pc,
  ) async {
    try {
      final offer = await pc.createOffer({
        'offerToReceiveVideo': false,
        'offerToReceiveAudio': false,
      });

      await pc.setLocalDescription(offer);

      _signalingService.sendMessage(
        SignalingMessage.offer(
          senderId: _localDeviceId!,
          targetId: viewerId,
          sdp: offer.toMap(),
        ),
      );

      AppLogger.info('Sent offer to viewer: $viewerId', _module);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to create offer for $viewerId',
        e,
        stack,
        _module,
      );
    }
  }

  /// Handle incoming offer (viewer side)
  Future<void> _handleOffer(SignalingMessage message) async {
    if (_hostConnection == null) return;

    try {
      _remoteDeviceId = message.senderId;

      final sdp = RTCSessionDescription(
        message.payload['sdp'] as String,
        message.payload['type'] as String,
      );

      await _hostConnection!.setRemoteDescription(sdp);

      final answer = await _hostConnection!.createAnswer();
      await _hostConnection!.setLocalDescription(answer);

      _signalingService.sendMessage(
        SignalingMessage.answer(
          senderId: _localDeviceId!,
          targetId: message.senderId,
          sdp: answer.toMap(),
        ),
      );

      AppLogger.info('Sent answer to host: ${message.senderId}', _module);
    } catch (e, stack) {
      AppLogger.error('Failed to handle offer', e, stack, _module);
    }
  }

  /// Handle incoming answer (host side) - NOW ROUTES TO CORRECT VIEWER
  Future<void> _handleAnswer(SignalingMessage message) async {
    final viewerId = message.senderId;
    final pc = _viewerConnections[viewerId];

    if (pc == null) {
      AppLogger.warning(
        'Received answer from unknown viewer: $viewerId',
        _module,
      );
      return;
    }

    try {
      final sdp = RTCSessionDescription(
        message.payload['sdp'] as String,
        message.payload['type'] as String,
      );

      await pc.setRemoteDescription(sdp);
      AppLogger.info('Set remote description for viewer: $viewerId', _module);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to handle answer from $viewerId',
        e,
        stack,
        _module,
      );
    }
  }

  /// Handle incoming ICE candidate - ROUTES TO CORRECT CONNECTION
  Future<void> _handleRemoteIceCandidate(SignalingMessage message) async {
    RTCPeerConnection? pc;

    if (_isHost) {
      pc = _viewerConnections[message.senderId];
    } else {
      pc = _hostConnection;
    }

    if (pc == null) {
      AppLogger.warning(
        'Received ICE candidate but no connection for: ${message.senderId}',
        _module,
      );
      return;
    }

    try {
      final candidateMap = message.payload as Map<String, dynamic>;
      final candidateType = _parseCandidateType(
        candidateMap['candidate'] as String? ?? '',
      );

      final candidate = RTCIceCandidate(
        candidateMap['candidate'] as String?,
        candidateMap['sdpMid'] as String?,
        candidateMap['sdpMLineIndex'] as int?,
      );

      await pc.addCandidate(candidate);
      AppLogger.info(
        'Added ICE candidate: type=$candidateType, from=${message.senderId}',
        _module,
      );
    } catch (e) {
      AppLogger.error('Failed to add ICE candidate', e, null, _module);
    }
  }

  // ==================== UTILITY METHODS ====================

  String _parseCandidateType(String candidateStr) {
    if (candidateStr.contains('typ host')) return 'host';
    if (candidateStr.contains('typ srflx')) return 'srflx (STUN)';
    if (candidateStr.contains('typ relay')) return 'relay (TURN)';
    if (candidateStr.contains('typ prflx')) return 'prflx';
    return 'unknown';
  }

  void _updateConnectionState(WebRTCConnectionState state) {
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  void _notifyViewerCountChanged() {
    if (!_viewerCountController.isClosed) {
      _viewerCountController.add(_viewerConnections.length);
    }
  }

  void _startMetricsCollection() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _collectMetrics();
    });
  }

  Future<void> _collectMetrics() async {
    // Get stats from first viewer connection (for host) or host connection (for viewer)
    RTCPeerConnection? pc;
    if (_isHost && _viewerConnections.isNotEmpty) {
      pc = _viewerConnections.values.first;
    } else if (!_isHost) {
      pc = _hostConnection;
    }

    if (pc == null) return;

    try {
      final stats = await pc.getStats();

      double fps = 0;
      int latency = 0;
      int bitrate = 0;
      double packetLoss = 0;
      int jitter = 0;

      for (final report in stats) {
        final values = report.values;

        if (report.type == 'inbound-rtp' || report.type == 'outbound-rtp') {
          fps = (values['framesPerSecond'] as num?)?.toDouble() ?? fps;
          bitrate =
              (values['bytesReceived'] as num?)?.toInt() ??
              (values['bytesSent'] as num?)?.toInt() ??
              bitrate;
        }

        if (report.type == 'candidate-pair' && values['state'] == 'succeeded') {
          latency = ((values['currentRoundTripTime'] as num?) ?? 0 * 1000)
              .toInt();
        }

        if (report.type == 'remote-inbound-rtp') {
          packetLoss = (values['packetsLost'] as num?)?.toDouble() ?? 0;
          jitter = ((values['jitter'] as num?) ?? 0 * 1000).toInt();
        }
      }

      final metrics = StreamingMetrics(
        fps: fps,
        latencyMs: latency,
        bitrate: bitrate,
        packetLoss: packetLoss,
        jitterMs: jitter,
      );

      if (!_metricsController.isClosed) {
        _metricsController.add(metrics);
      }
    } catch (e) {
      AppLogger.error('Failed to collect metrics', e, null, _module);
    }
  }

  Future<void> setQuality(StreamingQuality newQuality) async {
    if (_quality == newQuality) return;

    _quality = newQuality;
    AppLogger.info('Quality changed to: ${newQuality.displayName}', _module);

    // Update bitrate for all viewer connections
    for (final pc in _viewerConnections.values) {
      final senders = await pc.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'video') {
          await _setVideoQualityOnSender(sender);
        }
      }
    }
  }

  Future<void> _setVideoQualityOnSender(RTCRtpSender sender) async {
    try {
      final parameters = sender.parameters;
      if (parameters.encodings != null && parameters.encodings!.isNotEmpty) {
        for (final encoding in parameters.encodings!) {
          encoding.maxBitrate = _quality.bitrate;
        }
        await sender.setParameters(parameters);
        AppLogger.info('Set video bitrate to ${_quality.bitrate} bps', _module);
      }
    } catch (e) {
      AppLogger.error('Failed to set video quality', e, null, _module);
    }
  }

  /// Stop screen sharing / viewing
  Future<void> stop() async {
    _metricsTimer?.cancel();

    // Stop local stream
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    // Stop remote stream
    if (_remoteStream != null) {
      await _remoteStream!.dispose();
      _remoteStream = null;
    }

    // Close all viewer connections (host side)
    for (final pc in _viewerConnections.values) {
      await pc.close();
    }
    _viewerConnections.clear();

    // Close host connection (viewer side)
    if (_hostConnection != null) {
      await _hostConnection!.close();
      _hostConnection = null;
    }

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;

    _updateConnectionState(WebRTCConnectionState.disconnected);
    _remoteDeviceId = null;

    // Stop foreground service on Android
    if (Platform.isAndroid && _isHost) {
      try {
        const channel = MethodChannel('com.wifimirror/service');
        await channel.invokeMethod('stopForegroundService');
      } catch (e) {
        AppLogger.error('Failed to stop foreground service', e, null, _module);
      }
    }

    AppLogger.info('WebRTC stopped', _module);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    await _connectionStateController.close();
    await _metricsController.close();
    await _viewerCountController.close();
    AppLogger.info('WebRTC service disposed', _module);
  }
}

/// WebRTC Connection states
enum WebRTCConnectionState {
  disconnected,
  connecting,
  ready,
  connected,
  reconnecting,
  error,
}
