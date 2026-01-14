import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// Service for WebRTC signaling between peers
class SignalingService {
  static const String _module = 'Signaling';

  ServerSocket? _server;
  Socket? _clientSocket;

  final Map<String, Socket> _connectedPeers = {};

  final StreamController<SignalingMessage> _messageController =
      StreamController<SignalingMessage>.broadcast();

  final StreamController<String> _peerConnectedController =
      StreamController<String>.broadcast();

  final StreamController<String> _peerDisconnectedController =
      StreamController<String>.broadcast();

  String? _localDeviceId;
  bool _isServer = false;
  bool _isRunning = false;

  /// Stream of incoming signaling messages
  Stream<SignalingMessage> get messageStream => _messageController.stream;

  /// Stream of peer connection events
  Stream<String> get peerConnectedStream => _peerConnectedController.stream;

  /// Stream of peer disconnection events
  Stream<String> get peerDisconnectedStream =>
      _peerDisconnectedController.stream;

  /// Whether the signaling service is running
  bool get isRunning => _isRunning;

  /// Whether we are the server (host)
  bool get isServer => _isServer;

  /// Number of connected peers
  int get connectedPeerCount => _connectedPeers.length;

  /// Initialize service with local device ID
  void initialize(String deviceId) {
    _localDeviceId = deviceId;
    AppLogger.info(
      'Signaling service initialized for device: $deviceId',
      _module,
    );
  }

  /// Start as server (for screen sharer / host)
  Future<void> startServer() async {
    if (_isRunning) {
      AppLogger.warning('Signaling service already running', _module);
      return;
    }

    try {
      _server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        AppConstants.signalingPort,
      );

      _isServer = true;
      _isRunning = true;

      _server!.listen(
        _handleClientConnection,
        onError: (error) {
          AppLogger.error('Server error', error, null, _module);
        },
        onDone: () {
          AppLogger.info('Server closed', _module);
        },
      );

      AppLogger.info(
        'Signaling server started on port ${AppConstants.signalingPort}',
        _module,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to start signaling server', e, stack, _module);
      _isRunning = false;
      rethrow;
    }
  }

  /// Handle incoming client connection
  void _handleClientConnection(Socket client) {
    final clientId = '${client.remoteAddress.address}:${client.remotePort}';
    AppLogger.info('Client connected: $clientId', _module);

    String buffer = '';

    client.listen(
      (data) {
        buffer += utf8.decode(data);
        _processBuffer(buffer, client, (remaining) => buffer = remaining);
      },
      onError: (error) {
        AppLogger.error('Client error: $clientId', error, null, _module);
        _handleClientDisconnect(clientId, client);
      },
      onDone: () {
        _handleClientDisconnect(clientId, client);
      },
    );
  }

  /// Process incoming data buffer
  void _processBuffer(
    String buffer,
    Socket socket,
    Function(String) updateBuffer,
  ) {
    // Messages are newline-delimited JSON
    while (buffer.contains('\n')) {
      final index = buffer.indexOf('\n');
      final messageStr = buffer.substring(0, index);
      buffer = buffer.substring(index + 1);

      try {
        final json = jsonDecode(messageStr);
        final message = SignalingMessage.fromJson(json);
        _handleMessage(message, socket);
      } catch (e) {
        AppLogger.error(
          'Failed to parse message: $messageStr',
          e,
          null,
          _module,
        );
      }
    }
    updateBuffer(buffer);
  }

  /// Handle incoming signaling message
  void _handleMessage(SignalingMessage message, Socket socket) {
    AppLogger.debug(
      'Received message: ${message.type} from ${message.senderId}',
      _module,
    );

    switch (message.type) {
      case SignalingType.joinRequest:
        // Register the peer
        _connectedPeers[message.senderId] = socket;
        _peerConnectedController.add(message.senderId);
        break;

      case SignalingType.disconnect:
        _connectedPeers.remove(message.senderId);
        _peerDisconnectedController.add(message.senderId);
        break;

      case SignalingType.ping:
        // Respond with pong
        sendMessage(
          SignalingMessage(
            type: SignalingType.pong,
            senderId: _localDeviceId!,
            targetId: message.senderId,
          ),
        );
        return;

      default:
        break;
    }

    // Forward message to listeners
    if (!_messageController.isClosed) {
      _messageController.add(message);
    }

    // If we're server and message has a target, forward it
    if (_isServer &&
        message.targetId != null &&
        message.targetId != _localDeviceId) {
      _forwardMessage(message);
    }
  }

  /// Forward message to target peer
  void _forwardMessage(SignalingMessage message) {
    final targetSocket = _connectedPeers[message.targetId];
    if (targetSocket != null) {
      _sendToSocket(targetSocket, message);
    } else {
      AppLogger.warning(
        'Cannot forward message, target not found: ${message.targetId}',
        _module,
      );
    }
  }

  /// Handle client disconnect
  void _handleClientDisconnect(String clientId, Socket client) {
    // Find the device ID for this socket
    String? deviceId;
    _connectedPeers.forEach((id, socket) {
      if (socket == client) {
        deviceId = id;
      }
    });

    if (deviceId != null) {
      _connectedPeers.remove(deviceId);
      _peerDisconnectedController.add(deviceId!);
      AppLogger.info('Client disconnected: $deviceId', _module);
    }

    try {
      client.close();
    } catch (_) {}
  }

  /// Connect to a server (for viewer / client)
  Future<void> connectToServer(String host, int port) async {
    if (_isRunning) {
      AppLogger.warning('Already connected', _module);
      return;
    }

    try {
      _clientSocket = await Socket.connect(
        host,
        port,
        timeout: AppConstants.connectionTimeout,
      );

      _isServer = false;
      _isRunning = true;

      String buffer = '';

      _clientSocket!.listen(
        (data) {
          buffer += utf8.decode(data);
          _processBuffer(
            buffer,
            _clientSocket!,
            (remaining) => buffer = remaining,
          );
        },
        onError: (error) {
          AppLogger.error('Connection error', error, null, _module);
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      // Send join request
      sendMessage(
        SignalingMessage.joinRequest(
          senderId: _localDeviceId!,
          targetId: 'server',
        ),
      );

      AppLogger.info('Connected to signaling server at $host:$port', _module);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to connect to signaling server',
        e,
        stack,
        _module,
      );
      _isRunning = false;
      rethrow;
    }
  }

  /// Handle disconnection
  void _handleDisconnect() {
    AppLogger.info('Disconnected from server', _module);
    _isRunning = false;
    _clientSocket = null;
  }

  /// Send a signaling message
  void sendMessage(SignalingMessage message) {
    if (!_isRunning) {
      AppLogger.warning('Cannot send message, service not running', _module);
      return;
    }

    if (_isServer) {
      // Send to specific target or broadcast
      if (message.targetId != null) {
        final targetSocket = _connectedPeers[message.targetId];
        if (targetSocket != null) {
          _sendToSocket(targetSocket, message);
        }
      } else {
        // Broadcast to all connected peers
        for (final socket in _connectedPeers.values) {
          _sendToSocket(socket, message);
        }
      }
    } else {
      // Send to server
      if (_clientSocket != null) {
        _sendToSocket(_clientSocket!, message);
      }
    }
  }

  /// Send message to socket
  void _sendToSocket(Socket socket, SignalingMessage message) {
    try {
      final jsonStr = jsonEncode(message.toJson());
      socket.write('$jsonStr\n');
      AppLogger.debug(
        'Sent message: ${message.type} to ${message.targetId ?? 'all'}',
        _module,
      );
    } catch (e) {
      AppLogger.error('Failed to send message', e, null, _module);
    }
  }

  /// Stop the signaling service
  Future<void> stop() async {
    if (!_isRunning) return;

    // Send disconnect to peers
    if (_localDeviceId != null) {
      sendMessage(SignalingMessage.disconnect(senderId: _localDeviceId!));
    }

    // Close all peer connections
    for (final socket in _connectedPeers.values) {
      try {
        await socket.close();
      } catch (_) {}
    }
    _connectedPeers.clear();

    // Close server or client socket
    if (_isServer && _server != null) {
      await _server!.close();
      _server = null;
    }

    if (_clientSocket != null) {
      await _clientSocket!.close();
      _clientSocket = null;
    }

    _isRunning = false;
    _isServer = false;

    AppLogger.info('Signaling service stopped', _module);
  }

  /// Clean up resources
  Future<void> dispose() async {
    await stop();
    await _messageController.close();
    await _peerConnectedController.close();
    await _peerDisconnectedController.close();
    AppLogger.info('Signaling service disposed', _module);
  }
}
