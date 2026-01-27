import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/music_sync_state.dart';
import '../../core/utils/logger.dart';

class MusicServerService {
  static const String _tag = 'MusicServerServiceStub';
  
  final _syncStateController = StreamController<MusicSyncState>.broadcast();
  Stream<MusicSyncState> get syncStateStream => _syncStateController.stream;

  String? get ipAddress => null;
  int get port => 0;
  String? get fileName => null;
  String? get musicUrl => null;
  String? get wsUrl => null;

  Future<void> startServer(String musicFilePath) async {
    AppLogger.error('Cannot start Music Server on Web', null, null, _tag);
  }

  void broadcastState(MusicSyncState state) {
    // No-op
  }

  Future<void> stopServer() async {
    // No-op
  }
}
