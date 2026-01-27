import 'dart:convert';

enum MusicSyncType { play, pause, seek, sync, file_info }

class MusicSyncState {
  final MusicSyncType type;
  final Duration position;
  final bool isPlaying;
  final int timestamp; // Unix timestamp of when the event happened
  final String? fileName; // Optional, for initial sync

  MusicSyncState({
    required this.type,
    this.position = Duration.zero,
    this.isPlaying = false,
    required this.timestamp,
    this.fileName,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'position': position.inMilliseconds,
    'isPlaying': isPlaying,
    'timestamp': timestamp,
    if (fileName != null) 'fileName': fileName,
  };

  factory MusicSyncState.fromJson(Map<String, dynamic> json) {
    return MusicSyncState(
      type: MusicSyncType.values.firstWhere(
        (e) => e.name == json['type'], 
        orElse: () => MusicSyncType.sync
      ),
      position: Duration(milliseconds: json['position'] ?? 0),
      isPlaying: json['isPlaying'] ?? false,
      timestamp: json['timestamp'] ?? 0,
      fileName: json['fileName'],
    );
  }
  
  String toJsonString() => jsonEncode(toJson());
  
  static MusicSyncState fromJsonString(String source) => 
      MusicSyncState.fromJson(jsonDecode(source));
}
