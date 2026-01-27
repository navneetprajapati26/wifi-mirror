import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../models/music_sync_state.dart';

class MusicServerService {
  static const String _tag = 'MusicServerService';

  HttpServer? _server;
  String? _localIpAddress;
  int _port = AppConstants.musicPort;
  File? _currentFile;

  final List<WebSocketChannel> _clients = [];

  // Stream for UI to receive state updates from clients
  final _syncStateController = StreamController<MusicSyncState>.broadcast();
  Stream<MusicSyncState> get syncStateStream => _syncStateController.stream;

  // Keep track of current state
  MusicSyncState _currentState = MusicSyncState(
    type: MusicSyncType.pause,
    timestamp: DateTime.now().millisecondsSinceEpoch,
  );

  String? get ipAddress => _localIpAddress;
  int get port => _port;
  String? get fileName => _currentFile?.uri.pathSegments.last;

  // Return the direct audio URL that clients can use
  String? get musicUrl => (_localIpAddress != null)
      ? 'http://$_localIpAddress:$_port/${_currentFile?.uri.pathSegments.last}'
      : null;

  String? get wsUrl =>
      (_localIpAddress != null) ? 'ws://$_localIpAddress:$_port/ws' : null;

  Future<void> startServer(String musicFilePath) async {
    if (_server != null) {
      await stopServer();
    }

    final musicFile = File(musicFilePath);
    if (!await musicFile.exists()) {
      throw Exception('Music file not found');
    }

    _currentFile = musicFile;
    _localIpAddress = await _getLocalIpAddress();

    if (_localIpAddress == null) {
      throw Exception('Could not determine local IP');
    }

    final filename = musicFile.uri.pathSegments.last;

    // Static handler for serving the file
    // We serve the specific directory but only allow the specific file for security
    final staticHandler = createStaticHandler(
      musicFile.parent.path,
      listDirectories: false,
    );

    // Middleware to add CORS headers
    Handler corsMiddleware(Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    }

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsMiddleware)
        .addHandler((request) {
          if (request.url.path == 'ws') {
            return webSocketHandler(_handleWebSocket)(request);
          }

          // Serve the specific music file
          // Clients will access http://IP:PORT/filename.mp3
          if (request.url.path == filename) {
            return staticHandler(request);
          }

          // Health check / Info
          if (request.url.path == 'info') {
            return Response.ok(
              _currentState.toJsonString(),
              headers: {'content-type': 'application/json'},
            );
          }

          return Response.notFound('Not found');
        });

    // Try to bind to the fixed port, fallback if needed
    try {
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        _port,
        shared: true,
      );
    } catch (e) {
      AppLogger.warning('Port $_port busy, trying random...', _tag);
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        0,
        shared: true,
      );
      _port = _server!.port;
    }

    // Initialize state with filename
    _currentState = MusicSyncState(
      type: MusicSyncType.file_info,
      fileName: filename,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    AppLogger.info('Music Server started on $_localIpAddress:$_port', _tag);
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type',
    'Access-Control-Allow-Private-Network': 'true',
  };

  void _handleWebSocket(WebSocketChannel webSocket, String? protocol) {
    _clients.add(webSocket);
    AppLogger.info('New client connected. Total: ${_clients.length}', _tag);

    // 1. Always send File Info first so client knows what to play
    // (Even if _currentState is play/pause, it doesn't contain filename)
    if (fileName != null) {
      webSocket.sink.add(
        MusicSyncState(
          type: MusicSyncType.file_info,
          fileName: fileName, // Use the getter which pulls from _currentFile
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ).toJsonString(),
      );
    }

    // 2. Send Current Playback State (if we have moved past initial info)
    if (_currentState.type != MusicSyncType.file_info) {
      webSocket.sink.add(_currentState.toJsonString());
    }

    webSocket.stream.listen(
      (message) {
        try {
          final state = MusicSyncState.fromJsonString(message);
          // Rebroadcast to everyone else and update self
          _broadcastState(state, source: webSocket);
        } catch (e) {
          AppLogger.error('Error handling sync message', e, null, _tag);
        }
      },
      onDone: () {
        _clients.remove(webSocket);
        AppLogger.info('Client disconnected. Total: ${_clients.length}', _tag);
      },
    );
  }

  void _broadcastState(MusicSyncState state, {WebSocketChannel? source}) {
    _currentState = state;
    _syncStateController.add(state); // Update host UI

    for (final client in _clients) {
      if (client != source) {
        client.sink.add(state.toJsonString());
      }
    }
  }

  // Called by Host UI
  void broadcastState(MusicSyncState state) {
    _broadcastState(state);
  }

  Future<void> stopServer() async {
    for (final client in _clients) {
      client.sink.close();
    }
    _clients.clear();

    await _server?.close(force: true);
    _server = null;
    _currentFile = null;

    AppLogger.info('Music Server stopped', _tag);
  }

  /// Helper to get local IP
  Future<String?> _getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (interface.name.toLowerCase().contains('wlan') ||
                interface.name.toLowerCase().contains('wifi') ||
                interface.name.toLowerCase().contains('en0') ||
                interface.name.toLowerCase().contains('en1')) {
              return addr.address;
            }
          }
        }
      }
      // Fallback
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to get local IP', e, null, _tag);
    }
    return null;
  }
}
