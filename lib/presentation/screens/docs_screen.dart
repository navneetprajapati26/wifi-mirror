import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/router.dart';
import '../../core/utils/responsive.dart';

/// Documentation screen for web platform - shows all technical details
class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<_DocSection> _sections = [
    _DocSection(
      title: 'Overview',
      icon: Icons.info_outline_rounded,
      content: _overviewContent,
    ),
    _DocSection(
      title: 'Architecture',
      icon: Icons.architecture_rounded,
      content: _architectureContent,
    ),
    _DocSection(
      title: 'Network Discovery',
      icon: Icons.wifi_find_rounded,
      content: _networkDiscoveryContent,
    ),
    _DocSection(
      title: 'Signaling',
      icon: Icons.sync_alt_rounded,
      content: _signalingContent,
    ),
    _DocSection(
      title: 'WebRTC',
      icon: Icons.videocam_rounded,
      content: _webrtcContent,
    ),
    _DocSection(
      title: 'Web Server',
      icon: Icons.dns_rounded,
      content: _webServerContent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLargeScreen = context.isDesktopOrLarger;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme, colorScheme, isLargeScreen),

            // Tab Bar
            _buildTabBar(theme, colorScheme, isLargeScreen),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _sections.map((section) {
                  return _buildSectionContent(
                    section,
                    theme,
                    colorScheme,
                    isLargeScreen,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLargeScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 48 : 20,
        vertical: isLargeScreen ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Home',
          ),
          const SizedBox(width: 16),

          // Logo and title
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Documentation',
                  style:
                      (isLargeScreen
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Technical documentation and architecture details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // GitHub button
          if (isLargeScreen)
            OutlinedButton.icon(
              onPressed: () {
                launchUrl(Uri.parse('https://github.com/yourrepo/wifi-mirror'));
              },
              icon: const Icon(Icons.code_rounded, size: 18),
              label: const Text('View on GitHub'),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTabBar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLargeScreen,
  ) {
    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isLargeScreen ? 1200 : 800),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelPadding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 24 : 16,
            ),
            tabs: _sections.map((section) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(section.icon, size: 18),
                    const SizedBox(width: 8),
                    Text(section.title),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent(
    _DocSection section,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLargeScreen,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLargeScreen ? 48 : 20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isLargeScreen ? 900 : 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      section.icon,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    section.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Content
              ...section.content.map((item) {
                return _buildContentItem(
                  item,
                  theme,
                  colorScheme,
                  isLargeScreen,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentItem(
    _ContentItem item,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLargeScreen,
  ) {
    switch (item.type) {
      case _ContentType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            item.text,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case _ContentType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            item.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.7,
              color: colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
        );

      case _ContentType.code:
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  item.text,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy code',
                ),
              ),
            ],
          ),
        );

      case _ContentType.list:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.items!.map((listItem) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        listItem,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: colorScheme.onSurface.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );

      case _ContentType.table:
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: item.tableRows!.asMap().entries.map((entry) {
                final isHeader = entry.key == 0;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isHeader
                        ? colorScheme.surfaceContainerHighest
                        : Colors.transparent,
                  ),
                  children: entry.value.map((cell) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        cell,
                        style: isHeader
                            ? theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              )
                            : theme.textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        );

      case _ContentType.infoBox:
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
        );

      case _ContentType.diagram:
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                item.text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
            ),
          ),
        );
    }
  }
}

// Content Data Classes
class _DocSection {
  final String title;
  final IconData icon;
  final List<_ContentItem> content;

  _DocSection({required this.title, required this.icon, required this.content});
}

enum _ContentType { heading, paragraph, code, list, table, infoBox, diagram }

class _ContentItem {
  final _ContentType type;
  final String text;
  final List<String>? items;
  final List<List<String>>? tableRows;

  _ContentItem({
    required this.type,
    this.text = '',
    this.items,
    this.tableRows,
  });

  factory _ContentItem.heading(String text) =>
      _ContentItem(type: _ContentType.heading, text: text);

  factory _ContentItem.paragraph(String text) =>
      _ContentItem(type: _ContentType.paragraph, text: text);

  factory _ContentItem.code(String text) =>
      _ContentItem(type: _ContentType.code, text: text);

  factory _ContentItem.list(List<String> items) =>
      _ContentItem(type: _ContentType.list, items: items);

  factory _ContentItem.table(List<List<String>> rows) =>
      _ContentItem(type: _ContentType.table, tableRows: rows);

  factory _ContentItem.infoBox(String text) =>
      _ContentItem(type: _ContentType.infoBox, text: text);

  factory _ContentItem.diagram(String text) =>
      _ContentItem(type: _ContentType.diagram, text: text);
}

// ===================== CONTENT DATA =====================

final List<_ContentItem> _overviewContent = [
  _ContentItem.paragraph(
    'WiFi Mirror is a cross-platform screen sharing application designed for local WiFi networks. '
    'It enables real-time screen sharing between devices connected to the same network using '
    'WebRTC technology for peer-to-peer video streaming.',
  ),
  _ContentItem.heading('Key Features'),
  _ContentItem.list([
    'Multi-platform Support: Android, iOS, macOS, Windows, Linux, and Web',
    'Multi-viewer Support: Host can stream to multiple viewers simultaneously',
    'Zero Configuration: Auto-discovery via mDNS for native platforms',
    'Manual Connection: IP-based connection for web browsers',
    'Embedded Web Server: Native hosts can serve web app for browser viewers',
    'Adaptive Quality: Three presets - Low (720p), Medium (1080p), High (1440p)',
  ]),
  _ContentItem.heading('Technology Stack'),
  _ContentItem.table([
    ['Component', 'Technology'],
    ['Framework', 'Flutter 3.10+'],
    ['State Management', 'Riverpod'],
    ['Network Discovery', 'Bonsoir (mDNS)'],
    ['Video Streaming', 'WebRTC (flutter_webrtc)'],
    ['Signaling', 'TCP Socket + WebSocket'],
    ['Routing', 'GoRouter'],
  ]),
  _ContentItem.heading('How It Works'),
  _ContentItem.paragraph(
    '1. The host device starts screen capture and broadcasts its presence on the network.\n'
    '2. Viewer devices discover the host via mDNS or connect manually via IP address.\n'
    '3. WebRTC signaling establishes a peer-to-peer connection.\n'
    '4. Video streams directly from host to viewer with minimal latency.',
  ),
];

final List<_ContentItem> _architectureContent = [
  _ContentItem.paragraph(
    'WiFi Mirror follows a clean architecture pattern with clear separation of concerns. '
    'The application is divided into layers, each with specific responsibilities.',
  ),
  _ContentItem.heading('Layer Diagram'),
  _ContentItem.diagram(
    '''┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ HomeScreen  │  │SharingScreen│  │ViewingScreen│     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
├─────────────────────────────────────────────────────────┤
│                  Provider Layer (Riverpod)               │
│  ┌───────────────────────────────────────────────────┐ │
│  │  State Management, Controllers, Service Providers  │ │
│  └───────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│                      Data Layer                          │
│  ┌───────────────┐  ┌────────────────┐  ┌────────────┐ │
│  │   Services    │  │     Models     │  │  Platform  │ │
│  │  (Business    │  │  (NetworkDevice│  │   Impls    │ │
│  │   Logic)      │  │   Signaling)   │  │ (_io/_stub)│ │
│  └───────────────┘  └────────────────┘  └────────────┘ │
├─────────────────────────────────────────────────────────┤
│                      Core Layer                          │
│  ┌───────────────┐  ┌────────────────┐  ┌────────────┐ │
│  │   Constants   │  │     Theme      │  │  Utilities │ │
│  └───────────────┘  └────────────────┘  └────────────┘ │
└─────────────────────────────────────────────────────────┘''',
  ),
  _ContentItem.heading('Project Structure'),
  _ContentItem.code('''lib/
├── main.dart                    # App entry point
├── core/
│   ├── constants/               # App-wide constants
│   ├── theme/                   # Light/Dark themes
│   └── utils/                   # Utilities (logger, responsive)
├── data/
│   ├── models/                  # Data models
│   └── services/                # Business logic services
├── presentation/
│   ├── screens/                 # UI screens
│   └── widgets/                 # Reusable widgets
└── providers/
    ├── providers.dart           # Riverpod providers
    └── router.dart              # GoRouter configuration'''),
  _ContentItem.heading('Conditional Imports'),
  _ContentItem.paragraph(
    'The codebase uses Dart\'s conditional imports to handle platform differences. '
    'Native platforms use *_io.dart files while web uses *_stub.dart files.',
  ),
  _ContentItem.code('''// Main service file
import 'service_stub.dart'
    if (dart.library.io) 'service_io.dart'
    as platform_impl;

// platform_impl provides:
// - service_io.dart on native platforms
// - service_stub.dart on web (no-op implementations)'''),
];

final List<_ContentItem> _networkDiscoveryContent = [
  _ContentItem.paragraph(
    'Network Discovery enables automatic device discovery on the local network using '
    'mDNS (Multicast DNS), also known as Bonjour (Apple) or Avahi (Linux).',
  ),
  _ContentItem.heading('How mDNS Works'),
  _ContentItem.diagram('''┌────────────────────────────────────────────────────┐
│               Local WiFi Network                    │
│                                                      │
│   ┌─────────┐                      ┌─────────┐     │
│   │  Host   │◄── mDNS Multicast ──►│ Viewer  │     │
│   │(Android)│   224.0.0.251:5353   │ (macOS) │     │
│   │         │                      │         │     │
│   │Broadcast│                      │Discovery│     │
│   │_wifimirror._tcp                │         │     │
│   └─────────┘                      └─────────┘     │
│                                                      │
│   Service Type: _wifimirror._tcp                    │
│   Port: 50123                                        │
│   TXT Records: device_id, device_type, is_sharing   │
└────────────────────────────────────────────────────┘'''),
  _ContentItem.heading('Platform Support'),
  _ContentItem.table([
    ['Platform', 'Library', 'Support'],
    ['Android', 'Bonsoir (NsdManager)', '✅ Full'],
    ['iOS', 'Bonsoir (Bonjour)', '✅ Full'],
    ['macOS', 'Bonsoir (Bonjour)', '✅ Full'],
    ['Windows', 'Bonsoir (WinRT)', '✅ Full'],
    ['Linux', 'Bonsoir (Avahi)', '✅ Full'],
    ['Web', 'Not available', '❌ Manual only'],
  ]),
  _ContentItem.infoBox(
    'Web browsers cannot use mDNS. Web users must connect manually '
    'by entering the host\'s IP address and port.',
  ),
  _ContentItem.heading('Broadcasting (Host Side)'),
  _ContentItem.code('''await discoveryService.startBroadcast(isSharing: true);

// Creates mDNS service with:
// - Service Name: Device Name (e.g., "Pixel 7")
// - Service Type: _wifimirror._tcp
// - Port: 50123
// - TXT Records: {device_id, device_type, is_sharing, version}'''),
  _ContentItem.heading('Discovery (Viewer Side)'),
  _ContentItem.code('''await discoveryService.startDiscovery();

// Listens for mDNS services of type _wifimirror._tcp
// Resolves IP addresses and creates NetworkDevice objects'''),
];

final List<_ContentItem> _signalingContent = [
  _ContentItem.paragraph(
    'The Signaling Service handles WebRTC session negotiation between peers. '
    'It exchanges SDP offers/answers and ICE candidates required to establish peer-to-peer connections.',
  ),
  _ContentItem.heading('Dual Transport Architecture'),
  _ContentItem.diagram(
    '''┌───────────────────────────────────────────────────────┐
│                    HOST DEVICE                         │
│                                                         │
│   ┌─────────────────────────────────────────────────┐ │
│   │              Signaling Service                   │ │
│   │                                                   │ │
│   │   ┌─────────────────┐    ┌─────────────────┐   │ │
│   │   │   TCP Server    │    │ WebSocket Server│   │ │
│   │   │   Port: 50124   │    │   Port: 50125   │   │ │
│   │   │                 │    │                 │   │ │
│   │   │ Native clients  │    │  Web clients    │   │ │
│   │   └────────┬────────┘    └────────┬────────┘   │ │
│   │            │                      │            │ │
│   │            ▼                      ▼            │ │
│   │   ┌─────────────────────────────────────┐     │ │
│   │   │         Message Router               │     │ │
│   │   └─────────────────────────────────────┘     │ │
│   └─────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────┘
                  │                    │
                  ▼                    ▼
        ┌───────────────┐    ┌───────────────┐
        │ Native Viewer │    │  Web Viewer   │
        │  (TCP Socket) │    │  (WebSocket)  │
        └───────────────┘    └───────────────┘''',
  ),
  _ContentItem.heading('Message Types'),
  _ContentItem.table([
    ['Type', 'Description'],
    ['offer', 'SDP offer from host'],
    ['answer', 'SDP answer from viewer'],
    ['iceCandidate', 'ICE connectivity candidate'],
    ['joinRequest', 'Viewer requesting to join session'],
    ['joinResponse', 'Host accepting/rejecting viewer'],
    ['disconnect', 'Peer disconnection notification'],
  ]),
  _ContentItem.heading('Connection Flow'),
  _ContentItem.diagram('''    VIEWER                        HOST
      │                             │
      │──── joinRequest ──────────►│
      │                             │
      │◄─── joinResponse ──────────│
      │                             │
      │◄─── offer (SDP) ───────────│
      │                             │
      │──── answer (SDP) ─────────►│
      │                             │
      │◄─── iceCandidate ─────────►│  (bidirectional)
      │                             │
      │      [WebRTC Connected]     │
      │◄════ VIDEO STREAM ═════════│'''),
  _ContentItem.heading('Port Allocation'),
  _ContentItem.table([
    ['Port', 'Protocol', 'Purpose'],
    ['50123', 'TCP', 'mDNS service registration'],
    ['50124', 'TCP', 'Signaling (native clients)'],
    ['50125', 'WebSocket', 'Signaling (web clients)'],
    ['8080+', 'HTTP', 'Web server (embedded web app)'],
  ]),
];

final List<_ContentItem> _webrtcContent = [
  _ContentItem.paragraph(
    'The WebRTC Service manages peer-to-peer video streaming using the WebRTC protocol. '
    'It supports multiple simultaneous viewers connected to a single host.',
  ),
  _ContentItem.heading('Multi-Viewer Architecture'),
  _ContentItem.diagram(
    '''┌─────────────────────────────────────────────────────────┐
│                     HOST DEVICE                          │
│                                                           │
│   ┌─────────────────────────────────────────────────┐   │
│   │              Local Screen Capture                 │   │
│   │                  (MediaStream)                    │   │
│   └──────────────────────┬──────────────────────────┘   │
│                          │                               │
│                          ▼                               │
│   ┌─────────────────────────────────────────────────┐   │
│   │              WebRTC Service                       │   │
│   │                                                   │   │
│   │   ┌─────────────────────────────────────────┐   │   │
│   │   │      _viewerConnections (Map)            │   │   │
│   │   │                                          │   │   │
│   │   │  "viewer1" ──► RTCPeerConnection        │   │   │
│   │   │  "viewer2" ──► RTCPeerConnection        │   │   │
│   │   │  "viewer3" ──► RTCPeerConnection        │   │   │
│   │   └─────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘''',
  ),
  _ContentItem.heading('ICE Candidates'),
  _ContentItem.paragraph(
    'WebRTC uses ICE (Interactive Connectivity Establishment) to find '
    'the best path between peers:',
  ),
  _ContentItem.list([
    'HOST: Direct LAN connection (lowest latency)',
    'SRFLX (STUN): Server-reflexive candidate using STUN server',
    'RELAY (TURN): Relayed through TURN server (not used in this app)',
  ]),
  _ContentItem.heading('STUN Servers'),
  _ContentItem.code('''// Google STUN servers (free, reliable)
stun:stun.l.google.com:19302
stun:stun1.l.google.com:19302
stun:stun2.l.google.com:19302

// Twilio STUN
stun:global.stun.twilio.com:3478'''),
  _ContentItem.heading('Quality Presets'),
  _ContentItem.table([
    ['Quality', 'Resolution', 'Frame Rate', 'Bitrate'],
    ['Low', '1280×720 (720p)', '30 fps', '1 Mbps'],
    ['Medium', '1920×1080 (1080p)', '30 fps', '4 Mbps'],
    ['High', '2560×1440 (1440p)', '60 fps', '10 Mbps'],
  ]),
  _ContentItem.heading('Connection States'),
  _ContentItem.code('''enum WebRTCConnectionState {
  disconnected,   // No connection
  connecting,     // Setting up peer connection
  ready,          // Host: Screen capture ready
  connected,      // Successfully streaming
  reconnecting,   // Connection interrupted
  error,          // Connection failed
}'''),
];

final List<_ContentItem> _webServerContent = [
  _ContentItem.paragraph(
    'The Web Server Service provides a built-in HTTP server that serves the Flutter web app '
    'to browsers on the local network. This enables users without the native app to view '
    'screen shares directly in their browser.',
  ),
  _ContentItem.heading('Architecture'),
  _ContentItem.diagram(
    '''┌─────────────────────────────────────────────────────────┐
│                 HOST DEVICE (Native)                     │
│                                                           │
│   ┌─────────────────────────────────────────────────┐   │
│   │              Web Server Service                   │   │
│   │                                                   │   │
│   │   ┌─────────────────────────────────────────┐   │   │
│   │   │           HTTP Server                     │   │   │
│   │   │        Bound to: 0.0.0.0:8080            │   │   │
│   │   │                                          │   │   │
│   │   │   Serves:                                │   │   │
│   │   │   ├── index.html                         │   │   │
│   │   │   ├── main.dart.js                       │   │   │
│   │   │   ├── flutter_service_worker.js          │   │   │
│   │   │   └── assets/*                           │   │   │
│   │   └─────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────┘
                           │
                           │ HTTP (Port 8080)
                           ▼
              ┌────────────────────────┐
              │     Web Browser        │
              │ http://192.168.1.5:8080│
              └────────────────────────┘''',
  ),
  _ContentItem.heading('Startup Process'),
  _ContentItem.list([
    'Get Local IP Address: Scans network interfaces for WiFi/Ethernet',
    'Extract Web App Files: Copies bundled web app to temp directory',
    'Start HTTP Server: Binds to 0.0.0.0 on port 8080 (auto-increment if busy)',
    'Serve Requests: Maps URLs to files with correct MIME types',
  ]),
  _ContentItem.heading('MIME Types'),
  _ContentItem.code(''''.html' → 'text/html'
'.css'  → 'text/css'
'.js'   → 'application/javascript'
'.json' → 'application/json'
'.wasm' → 'application/wasm'
'.png'  → 'image/png'
'.woff2'→ 'font/woff2'''),
  _ContentItem.infoBox(
    'The web server is only available on native platforms (Android, iOS, macOS, Windows, Linux). '
    'Web browsers cannot run an HTTP server.',
  ),
  _ContentItem.heading('Usage'),
  _ContentItem.paragraph(
    'When screen sharing is active, the host can enable the web server. Viewers can then '
    'open the provided URL in any browser on the same network to view the shared screen.',
  ),
];
