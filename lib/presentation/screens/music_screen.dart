import 'package:flutter/foundation.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/music_providers.dart';

import '../../core/constants/app_constants.dart';

import '../widgets/widgets.dart';

class MusicScreen extends ConsumerStatefulWidget {
  final String? initialHost;

  const MusicScreen({super.key, this.initialHost});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialHost != null) {
      _ipController.text = widget.initialHost!;
      // Optional: Auto-connect if desired, or just prepopulate
      // WidgetsBinding.instance.addPostFrameCallback((_) => _joinSession());
    }
  }

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
        // Determine if running on web to warn/block or use bytes?
        // Stub suggests native only for hosting for now.
        final path = result.files.single.path!;
        await ref.read(musicControllerProvider.notifier).startHosting(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _joinSession() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    await ref.read(musicControllerProvider.notifier).joinSession(ip);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _ipController.text = data!.text!.trim();
      });
      // Optionally auto-join if it looks valid?
      // _joinSession();
    }
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
            if (state.role != MusicRole.none) {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Leave Party?'),
                  content: const Text('This will stop the music for everyone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(musicControllerProvider.notifier)
                            .stopSession();
                        Navigator.pop(c);
                        context.pop();
                      },
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              );
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: state.isConnected
          ? _buildPlayer(context, state)
          : _buildLanding(context),
    );
  }

  Widget _buildLanding(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Music Party',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Listen to music together in perfect sync.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Web Server Card (if not on web, to allow sharing the app/web-client)
              if (!kIsWeb) ...[
                const WebServerCard(),
                const SizedBox(height: 32),
              ],

              // Host Button
              if (!kIsWeb) ...[
                GradientButton(
                  text: 'Host a Party (Pick Music)',
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: _pickAndHostMusic,
                  width: double.infinity,
                ),

                const SizedBox(height: 32),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 32),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "To host music, please use the native WiFi Mirror app on Android or iOS.",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Join Section - Enhanced Card UI
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Existing Party',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          labelText: 'Host IP Address',
                          hintText: 'e.g. 192.168.1.5',
                          prefixIcon: const Icon(Icons.link_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.content_paste_rounded),
                            tooltip: 'Paste',
                            onPressed: _pasteFromClipboard,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        onSubmitted: (_) => _joinSession(),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _joinSession,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Connect & Join'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context, MusicSessionState state) {
    final theme = Theme.of(context);
    final controller = ref.read(musicControllerProvider.notifier);
    final position = state.syncState.position;
    final isPlaying = state.syncState.isPlaying;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
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
                      ),
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                  max:
                      (ref.read(audioPlayerProvider).duration?.inSeconds.toDouble() ??
                          100) +
                      1.0,
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
                      onPressed: () =>
                          controller.seek(position - const Duration(seconds: 10)),
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
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        ),
                        color: theme.colorScheme.onPrimary,
                        iconSize: 48,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: () =>
                          controller.seek(position + const Duration(seconds: 10)),
                      icon: const Icon(Icons.forward_10),
                      iconSize: 32,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Web Server Control & Share
                if (state.role == MusicRole.host) ...[
                  const SizedBox(height: 16),
                  WebServerCard(
                    linkTitle: 'Music Party Link',
                    linkSubtitle: 'Share this link to let others join instantly!',
                    linkGenerator: (status) {
                      if (status.ipAddress != null) {
                        final musicPort = AppConstants.musicPort;
                        // Construct the smart link: http://IP:8080/music?host=IP&port=MUSIC_PORT
                        return '${status.url}/music?host=${status.ipAddress}&port=$musicPort';
                      }
                      return status.url ?? '';
                    },
                  ),
                ],
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
