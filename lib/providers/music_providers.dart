import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../data/models/music_sync_state.dart';
import '../data/services/services.dart';
import '../core/utils/logger.dart';
import '../core/constants/app_constants.dart';

// --- Providers ---

final musicServerServiceProvider = Provider((ref) => MusicServerService());

final audioPlayerProvider = Provider.autoDispose((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

final musicControllerProvider =
    StateNotifierProvider<MusicController, MusicSessionState>((ref) {
      return MusicController(
        ref.watch(musicServerServiceProvider),
        ref.watch(audioPlayerProvider),
      );
    });

// --- State Models ---

enum MusicRole { none, host, listener }

class MusicSessionState {
  final MusicRole role;
  final bool isConnected;
  final String? currentTrackName;
  final String? shareUrl;
  final MusicSyncState syncState;
  final bool isBuffering;

  MusicSessionState({
    this.role = MusicRole.none,
    this.isConnected = false,
    this.currentTrackName,
    this.shareUrl,
    required this.syncState,
    this.isBuffering = false,
  });

  MusicSessionState copyWith({
    MusicRole? role,
    bool? isConnected,
    String? currentTrackName,
    String? shareUrl,
    MusicSyncState? syncState,
    bool? isBuffering,
  }) {
    return MusicSessionState(
      role: role ?? this.role,
      isConnected: isConnected ?? this.isConnected,
      currentTrackName: currentTrackName ?? this.currentTrackName,
      shareUrl: shareUrl ?? this.shareUrl,
      syncState: syncState ?? this.syncState,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }
}

// --- Controller ---

class MusicController extends StateNotifier<MusicSessionState> {
  static const String _tag = 'MusicController';

  final MusicServerService _serverService;
  final AudioPlayer _player;

  WebSocketChannel? _clientChannel;
  StreamSubscription? _playerSubscription;
  StreamSubscription? _serverStateSubscription;

  bool _isRemoteUpdate = false;
  Timer? _syncTimer;

  MusicController(this._serverService, this._player)
    : super(
        MusicSessionState(
          syncState: MusicSyncState(type: MusicSyncType.pause, timestamp: 0),
        ),
      ) {
    _initPlayerListeners();
  }

  void _initPlayerListeners() {
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.buffering) {
        if (!state.playing) {
          // update buffering state
        }
      }

      if (_isRemoteUpdate) return;

      final isPlaying = state.playing;
      final processingState = state.processingState;

      if (processingState == ProcessingState.ready ||
          processingState == ProcessingState.buffering) {
        if (isPlaying != state.playing) {
          // Handle local play/pause toggle if needed, usually handled by play/pause methods
        }
      }
    });

    // We mainly want to intercept Play/Pause/Seek calls from UI
    // But since UI calls controller methods, we can broadcast there.
    // However, we should also watch for completion.
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        pause(); // Reset
        seek(Duration.zero);
      }
    });
  }

  // --- Host Actions ---

  Future<void> startHosting(String filePath) async {
    try {
      await _serverService.startServer(filePath);

      // Load file locally
      await _player.setFilePath(filePath);

      // Start server state listener
      _serverStateSubscription = _serverService.syncStateStream.listen((state) {
        _applySyncState(state);
      });

      state = state.copyWith(
        role: MusicRole.host,
        isConnected: true,
        currentTrackName: _serverService.fileName,
        shareUrl: _serverService.musicUrl,
      );

      // Start periodic sync to keep time aligned
      _startSyncTimer();
    } catch (e) {
      AppLogger.error('Failed to start hosting', e, null, _tag);
      stopSession();
    }
  }

  // --- Client Actions ---

  Future<void> joinSession(String input) async {
    try {
      final port = AppConstants.musicPort;
      String hostIp = input;

      // If user pasted a full URL (e.g. from the web app address bar), extract the IP
      if (input.startsWith('http') || input.startsWith('ws')) {
        final uri = Uri.parse(input);
        hostIp = uri.host;
      }

      final wsUrl = 'ws://$hostIp:$port/ws';

      AppLogger.info('Connecting to WS: $wsUrl', _tag);

      _clientChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      state = state.copyWith(
        role: MusicRole.listener,
        isConnected: true,
        shareUrl: hostIp, // Just show IP so they can tell others
      );

      // Listen to incoming messages
      _clientChannel!.stream.listen(
        (message) {
          try {
            final syncState = MusicSyncState.fromJsonString(message);

            if (syncState.type == MusicSyncType.file_info) {
              state = state.copyWith(currentTrackName: syncState.fileName);
              // Construct audio URL
              final audioUrl = 'http://$hostIp:$port/${syncState.fileName}';

              // Verify we are playing correct file
              // Note: just_audio might not allow checking current src easily against this URL string
              // But we can reset if needed.
              if (_player.audioSource == null) {
                AppLogger.info('Setting audio source: $audioUrl', _tag);
                _player.setUrl(audioUrl).then((_) {
                  // Attempt to sync if we have state
                  _applySyncState(state.syncState);
                });
              } else {
                // Check if we should switch? For now assume valid.
              }
            } else {
              _applySyncState(syncState);
            }
          } catch (e) {
            AppLogger.error('Client Parse Error', e, null, _tag);
          }
        },
        onError: (e) {
          AppLogger.error('WS Error', e, null, _tag);
          stopSession();
        },
        onDone: () {
          stopSession();
        },
      );
    } catch (e) {
      AppLogger.error('Failed to join session', e, null, _tag);
      stopSession();
    }
  }

  // --- Common Actions (Host & Client) ---

  void play() {
    final newState = MusicSyncState(
      type: MusicSyncType.play,
      position: _player.position,
      isPlaying: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _broadcast(newState);
    // Apply locally immediately for responsiveness
    _player.play();
    state = state.copyWith(syncState: newState);
  }

  void pause() {
    final newState = MusicSyncState(
      type: MusicSyncType.pause,
      position: _player.position,
      isPlaying: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _broadcast(newState);
    _player.pause();
    state = state.copyWith(syncState: newState);
  }

  void seek(Duration position) {
    final newState = MusicSyncState(
      type: MusicSyncType.seek,
      position: position,
      isPlaying: _player.playing,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _broadcast(newState);
    _player.seek(position); // Optimistic UI
    state = state.copyWith(syncState: newState);
  }

  void _broadcast(MusicSyncState syncState) {
    if (state.role == MusicRole.host) {
      _serverService.broadcastState(syncState);
    } else if (state.role == MusicRole.listener && _clientChannel != null) {
      _clientChannel!.sink.add(syncState.toJsonString());
    }
  }

  void _applySyncState(MusicSyncState syncState) async {
    _isRemoteUpdate = true;
    state = state.copyWith(syncState: syncState);

    try {
      // Calculate target time with drift compensation
      int targetMs = syncState.position.inMilliseconds;

      if (syncState.isPlaying) {
        final drift =
            DateTime.now().millisecondsSinceEpoch - syncState.timestamp;
        // Cap drift to avoid wild jumps from old messages
        if (drift > 0 && drift < 2000) {
          targetMs += drift;
        }
      }

      final currentMs = _player.position.inMilliseconds;
      final diff = (targetMs - currentMs).abs();

      // Determine if we need to seek
      // If diff is large (> 250ms), or if it's an explicit Seek command
      if (syncState.type == MusicSyncType.seek || diff > 250) {
        await _player.seek(Duration(milliseconds: targetMs));
      }

      if (syncState.isPlaying) {
        if (!_player.playing) _player.play();
      } else {
        if (_player.playing) _player.pause();
      }
    } finally {
      // Small delay to allow player state to settle before listening to local events again
      await Future.delayed(const Duration(milliseconds: 100));
      _isRemoteUpdate = false;
    }
  }

  void _startSyncTimer() {
    // Periodically send sync packets if playing
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_player.playing && state.role == MusicRole.host) {
        final syncState = MusicSyncState(
          type: MusicSyncType.sync,
          position: _player.position,
          isPlaying: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        _broadcast(syncState);
      }
    });
  }

  void stopSession() async {
    _syncTimer?.cancel();
    _serverStateSubscription?.cancel();

    if (state.role == MusicRole.host) {
      await _serverService.stopServer();
    } else {
      _clientChannel?.sink.close();
      _clientChannel = null;
    }

    await _player.stop();
    state = MusicSessionState(
      syncState: MusicSyncState(type: MusicSyncType.pause, timestamp: 0),
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _serverStateSubscription?.cancel();
    _playerSubscription?.cancel();
    super.dispose();
  }
}
