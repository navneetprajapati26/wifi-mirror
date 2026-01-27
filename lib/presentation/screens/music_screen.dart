
import 'package:flutter/foundation.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/music_providers.dart';

import '../widgets/widgets.dart';

class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _pickAndHostMusic() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        final path = result.files.single.path!;
        await ref.read(musicControllerProvider.notifier).startHosting(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _joinSession() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    // assume standard port? No, need full URL or IP + standard port
    // Host exposes full URL. User enters http://... or just IP?
    // Let's assume user enters just IP for convenience, and we append port/path.
    // BUT port is random in current implementation.
    // I should change server to use FIXED PORT for music or ask user to enter full URL.
    // Better: Helper copies full URL to clipboard. Listener pastes it.
    
    // Auto-fix URL if missing http
    String url = ip;
    if (!url.startsWith('http')) {
      url = 'http://$url';
    }
    
    await ref.read(musicControllerProvider.notifier).joinSession(url);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Music Party'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            // If hosting, maybe ask confirmation?
            if (state.role != MusicRole.none) {
               showDialog(context: context, builder: (c) => AlertDialog(
                 title: const Text('Leave Party?'),
                 content: const Text('This will stop the music for everyone.'),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                   TextButton(onPressed: () {
                     ref.read(musicControllerProvider.notifier).stopSession();
                     Navigator.pop(c);
                     context.pop();
                   }, child: const Text('Leave')),
                 ],
               ));
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: state.isConnected ? _buildPlayer(context, state) : _buildLanding(context),
    );
  }

  Widget _buildLanding(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Music Party',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Listen to music together in perfect sync.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Host Button
            if (!kIsWeb) ...[
              GradientButton(
                text: 'Host a Party (Pick Music)',
                icon: Icons.add_circle_outline_rounded,
                onPressed: _pickAndHostMusic,
                width: double.infinity,
              ),
              
              const SizedBox(height: 32),
              const Row(children: [
                Expanded(child: Divider()), 
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("OR")), 
                Expanded(child: Divider())
              ]),
              const SizedBox(height: 32),
            ] else ...[
               const Text("Hosting is only available on native Viewers.", textAlign: TextAlign.center),
               const SizedBox(height: 16),
            ],

            // Join Section
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Paste Party Link',
                hintText: 'http://192.168.x.x:port/song.mp3',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _joinSession,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Join Party'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context, MusicSessionState state) {
    final theme = Theme.of(context);
    final controller = ref.read(musicControllerProvider.notifier);
    final position = state.syncState.position;
    final isPlaying = state.syncState.isPlaying;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album Art Placeholder
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Icon(
              Icons.music_note_rounded,
              size: 100,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Track Info
          Text(
            state.currentTrackName ?? 'Unknown Track',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: state.role == MusicRole.host 
                  ? theme.colorScheme.primaryContainer 
                  : theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              state.role == MusicRole.host ? 'HOST' : 'LISTENER',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Seeking (Read Only for listeners? No, requested: anyone can control)
          // Slider isn't perfect for sync but let's try
          Slider(
            value: position.inSeconds.toDouble(),
            // We need duration. Just_audio provider gives duration but it's not in sync state.
            // Assuming we don't know duration yet or just arbitrarily high max?
            // Correct approach: Host should broadcast Duration too.
            // For now, let's just make it visually functional but maybe buggy max?
            // Actually, just_audio on client side WILL know duration once loaded.
            max:  (ref.read(audioPlayerProvider).duration?.inSeconds.toDouble() ?? 100) + 1.0, 
            onChanged: (val) {
               controller.seek(Duration(seconds: val.toInt()));
            },
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position)),
              StreamBuilder<Duration?>(
                stream: ref.read(audioPlayerProvider).durationStream,
                builder: (context, snapshot) {
                  return Text(_formatDuration(snapshot.data ?? Duration.zero));
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => controller.seek(position - const Duration(seconds: 10)),
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
              ),
              const SizedBox(width: 24),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: isPlaying ? controller.pause : controller.play,
                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  color: theme.colorScheme.onPrimary,
                  iconSize: 48,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () => controller.seek(position + const Duration(seconds: 10)),
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Share Link (Host only)
          if (state.role == MusicRole.host && state.shareUrl != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share Link', style: theme.textTheme.labelSmall),
                        Text(state.shareUrl!, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: state.shareUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
