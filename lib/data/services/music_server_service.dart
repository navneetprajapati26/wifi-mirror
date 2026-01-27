import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/utils/logger.dart';
import '../models/music_sync_state.dart';

class MusicServerService {
  static const String _tag = 'MusicServerService';
  
  HttpServer? _server;
  String? _localIpAddress;
  int _port = 0;
  File? _currentFile;
  
  final List<WebSocketChannel> _clients = [];
  
  // Stream for UI to receive state updates from clients
  final _syncStateController = StreamController<MusicSyncState>.broadcast();
  Stream<MusicSyncState> get syncStateStream => _syncStateController.stream;

  // Keep track of current state
  MusicSyncState _currentState = MusicSyncState(
    type: MusicSyncType.pause, 
    timestamp: DateTime.now().millisecondsSinceEpoch
  );

  String? get ipAddress => _localIpAddress;
  int get port => _port;
  String? get fileName => _currentFile?.uri.pathSegments.last;
  
  String? get musicUrl => (_localIpAddress != null && _port != 0 && fileName != null) 
      ? 'http://$_localIpAddress:$_port/$fileName' 
      : null;
      
  String? get wsUrl => (_localIpAddress != null && _port != 0)
      ? 'ws://$_localIpAddress:$_port/ws'
      : null;

  Future<void> startServer(String musicFilePath) async {
    if (_server != null) {
      await stopServer();
    }
    
    final musicFile = File(musicFilePath);
    _currentFile = musicFile;
    _localIpAddress = await _getLocalIpAddress();
    
    if (_localIpAddress == null) {
      throw Exception('Could not determine local IP');
    }

    final filename = musicFile.uri.pathSegments.last;
    
    // Create a static handler for the directory containing the file
    // Note: This exposes other files in the directory if the user knows the name
    // In a real production app, we would copy the file to a temp dir
    final staticHandler = createStaticHandler(
      musicFile.parent.path,
      listDirectories: false,
    );

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler((request) {
      if (request.url.path == 'ws') {
        return webSocketHandler(_handleWebSocket)(request);
      }
      
      // Only allow serving the specific file selected
      if (request.url.path == filename) {
        return staticHandler(request);
      }
      
      return Response.notFound('Not found');
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);
    _port = _server!.port;
    
    // Initialize state with filename
    _currentState = MusicSyncState(
      type: MusicSyncType.file_info,
      fileName: filename,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    AppLogger.info('Music Server started on $_localIpAddress:$_port', _tag);
  }

  void _handleWebSocket(WebSocketChannel webSocket, String? protocol) {
    _clients.add(webSocket);
    AppLogger.info('New client connected. Total: ${_clients.length}', _tag);
    
    // Send current state to new client
    webSocket.sink.add(_currentState.toJsonString());

    webSocket.stream.listen((message) {
      try {
        final state = MusicSyncState.fromJsonString(message);
        // Rebroadcast to everyone else and update self
        _broadcastState(state, source: webSocket);
      } catch (e) {
        AppLogger.error('Error handling sync message', e, null, _tag);
      }
    }, onDone: () {
      _clients.remove(webSocket);
      AppLogger.info('Client disconnected. Total: ${_clients.length}', _tag);
    });
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
