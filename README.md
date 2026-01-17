# WiFi Mirror

**Cross-platform screen sharing application for local WiFi networks**

WiFi Mirror enables real-time screen sharing between devices connected to the same local network. Built with Flutter, it supports **Android**, **iOS**, **macOS**, **Windows**, **Linux**, and **Web** platforms with seamless peer-to-peer connectivity.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)
![Platforms](https://img.shields.io/badge/platforms-Android%20|%20iOS%20|%20macOS%20|%20Windows%20|%20Linux%20|%20Web-green)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Core Systems](#core-systems)
   - [Network Discovery Service](#1-network-discovery-service)
   - [Signaling Service](#2-signaling-service)
   - [WebRTC Service](#3-webrtc-service)
   - [Web Server Service](#4-web-server-service)
5. [Data Flow](#data-flow)
6. [Platform Differences](#platform-differences)
7. [Configuration & Constants](#configuration--constants)
8. [Dependencies](#dependencies)
9. [Getting Started](#getting-started)
10. [Build & Deployment](#build--deployment)

---

## Overview

WiFi Mirror allows users to:
- **Share their screen** to multiple simultaneous viewers on the same WiFi network
- **View screens** from other devices in real-time with WebRTC streaming
- **Automatically discover** devices using mDNS (Bonjour/Avahi)
- **Manually connect** via IP address when mDNS is not available (e.g., Web platform)
- **Access via web browser** by hosting a built-in web server

### Key Features

| Feature | Description |
|---------|-------------|
| **Multi-platform Support** | Works on Android, iOS, macOS, Windows, Linux, and Web |
| **Multi-viewer Support** | Host can stream to multiple viewers simultaneously |
| **Zero Configuration** | Auto-discovery via mDNS for native platforms |
| **Manual Connection** | IP-based connection for web browsers and cross-subnet scenarios |
| **Embedded Web Server** | Native host can serve web app for browser-based viewers |
| **Adaptive Quality** | Three quality presets: Low (720p), Medium (1080p), High (1440p) |

---

## Architecture

WiFi Mirror follows a **clean architecture** pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ HomeScreen  │  │SharingScreen│  │ViewingScreen│  + Widgets   │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                      Provider Layer (Riverpod)                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  State Management, Controllers, Service Providers          │  │
│  └───────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                        Data Layer                                │
│  ┌───────────────┐  ┌────────────────┐  ┌──────────────────┐   │
│  │   Services    │  │     Models     │  │  Platform Impls  │   │
│  │  (Business    │  │  (NetworkDevice│  │  (_io / _stub)   │   │
│  │   Logic)      │  │   Signaling,   │  │                  │   │
│  │               │  │   Session)     │  │                  │   │
│  └───────────────┘  └────────────────┘  └──────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                        Core Layer                                │
│  ┌───────────────┐  ┌────────────────┐  ┌──────────────────┐   │
│  │   Constants   │  │     Theme      │  │     Utilities    │   │
│  └───────────────┘  └────────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### State Management

The application uses **Flutter Riverpod** for state management, providing:
- Dependency injection for services
- Reactive state updates
- Clean separation between UI and business logic
- Automatic resource disposal

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants (ports, service types)
│   ├── theme/
│   │   └── app_theme.dart             # Light/Dark theme definitions
│   └── utils/
│       └── logger.dart                # Logging utility
├── data/
│   ├── models/
│   │   ├── models.dart                # Barrel export
│   │   ├── network_device.dart        # Device representation
│   │   ├── sharing_session.dart       # Session state model
│   │   └── signaling_message.dart     # WebRTC signaling messages
│   └── services/
│       ├── services.dart              # Barrel export with conditional imports
│       ├── network_discovery_service.dart      # mDNS discovery
│       ├── network_discovery_service_io.dart   # Native implementation
│       ├── network_discovery_service_stub.dart # Web stub
│       ├── signaling_service.dart              # WebRTC signaling
│       ├── signaling_service_io.dart           # Native TCP + WebSocket server
│       ├── signaling_service_stub.dart         # Web stub
│       ├── web_server_service.dart             # Embedded HTTP server
│       ├── web_server_service_stub.dart        # Web stub
│       └── webrtc_service.dart                 # WebRTC peer connections
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart           # Main screen with discovery
│   │   ├── sharing_screen.dart        # Host's sharing view
│   │   ├── viewing_screen.dart        # Viewer's streaming view
│   │   └── settings_screen.dart       # App settings
│   └── widgets/
│       ├── device_card.dart           # Discovered device display
│       ├── quick_connect_card.dart    # Web URL-based connection
│       ├── web_server_card.dart       # Web server status/control
│       ├── manual_connection_dialog.dart # Manual IP entry
│       └── ...                        # Other UI components
└── providers/
    ├── providers.dart                 # Riverpod providers & controllers
    └── router.dart                    # GoRouter configuration
```

---

## Core Systems

### 1. Network Discovery Service

**Files:** `network_discovery_service.dart`, `network_discovery_service_io.dart`, `network_discovery_service_stub.dart`

The Network Discovery Service enables automatic device discovery on the local network using **mDNS (Multicast DNS)**, also known as Bonjour (Apple) or Avahi (Linux).

#### How mDNS Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        Local WiFi Network                        │
│                                                                   │
│   ┌─────────────┐                          ┌─────────────┐       │
│   │   Host      │◄──── mDNS Multicast ────►│   Viewer    │       │
│   │  (Android)  │      224.0.0.251:5353    │   (macOS)   │       │
│   │             │                          │             │       │
│   │  Broadcast: │                          │  Discovery: │       │
│   │  _wifimirror│                          │  _wifimirror│       │
│   │  ._tcp      │                          │  ._tcp      │       │
│   └─────────────┘                          └─────────────┘       │
│                                                                   │
│   Service Type: _wifimirror._tcp                                 │
│   Port: 50123                                                     │
│   TXT Records: device_id, device_type, is_sharing, version       │
└─────────────────────────────────────────────────────────────────┘
```

#### Platform-Specific Implementation

| Platform | Library Used | Implementation |
|----------|--------------|----------------|
| **Android** | Bonsoir (NsdManager) | `network_discovery_service_io.dart` |
| **iOS** | Bonsoir (Bonjour) | `network_discovery_service_io.dart` |
| **macOS** | Bonsoir (Bonjour) | `network_discovery_service_io.dart` |
| **Windows** | Bonsoir (WinRT) | `network_discovery_service_io.dart` |
| **Linux** | Bonsoir (Avahi) | `network_discovery_service_io.dart` |
| **Web** | Not supported | `network_discovery_service_stub.dart` |

#### Key Operations

**Broadcasting (Host):**
```dart
await discoveryService.startBroadcast(isSharing: true);
// Creates mDNS service with:
// - Service Name: Device Name (e.g., "Pixel 7")
// - Service Type: _wifimirror._tcp
// - Port: 50123
// - TXT Records: {device_id, device_type, is_sharing, version}
```

**Discovery (Viewer):**
```dart
await discoveryService.startDiscovery();
// Listens for mDNS services of type _wifimirror._tcp
// Resolves IP addresses and creates NetworkDevice objects
```

#### NetworkDevice Model

```dart
class NetworkDevice {
  final String id;           // Unique device identifier
  final String name;         // User-friendly device name
  final String ipAddress;    // Resolved IP address
  final int port;            // Service port (50123)
  final DeviceType deviceType; // android, ios, macos, windows, linux, web
  final bool isSharing;      // Whether device is actively sharing
  final DateTime discoveredAt;
  final Map<String, String> metadata;
}
```

#### Web Platform Limitations

Since web browsers cannot use mDNS, the Web platform provides:
- **Manual Connection Dialog**: User enters host IP and port
- **Quick Connect URL**: Deep linking via `/connect?host=IP&port=PORT`
- **Stub Implementation**: Returns no-op functions that gracefully fail

---

### 2. Signaling Service

**Files:** `signaling_service.dart`, `signaling_service_io.dart`, `signaling_service_stub.dart`

The Signaling Service handles **WebRTC session negotiation** between peers. It exchanges SDP offers/answers and ICE candidates required to establish peer-to-peer connections.

#### Dual Transport Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOST DEVICE                              │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                Signaling Service                          │   │
│   │                                                           │   │
│   │   ┌───────────────────┐    ┌───────────────────┐        │   │
│   │   │   TCP Server      │    │  WebSocket Server │        │   │
│   │   │   Port: 50124     │    │   Port: 50125     │        │   │
│   │   │                   │    │                   │        │   │
│   │   │ For native clients │    │ For web clients   │        │   │
│   │   └─────────┬─────────┘    └─────────┬─────────┘        │   │
│   │             │                       │                    │   │
│   │             ▼                       ▼                    │   │
│   │   ┌─────────────────────────────────────────┐           │   │
│   │   │         Message Router                   │           │   │
│   │   │   (Forwards to correct peer)             │           │   │
│   │   └─────────────────────────────────────────┘           │   │
│   └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                    │                           │
                    ▼                           ▼
        ┌───────────────────┐       ┌───────────────────┐
        │  Native Viewer    │       │   Web Viewer      │
        │  (TCP Socket)     │       │   (WebSocket)     │
        └───────────────────┘       └───────────────────┘
```

#### Signaling Message Types

```dart
enum SignalingType {
  offer,         // SDP offer from host
  answer,        // SDP answer from viewer
  iceCandidate,  // ICE connectivity candidate
  joinRequest,   // Viewer requesting to join session
  joinResponse,  // Host accepting/rejecting viewer
  disconnect,    // Peer disconnection notification
  ping,          // Keep-alive ping
  pong,          // Keep-alive response
  qualityChange, // Quality setting change
  error,         // Error notification
}
```

#### Message Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    WebRTC Session Setup                          │
│                                                                   │
│    VIEWER                        HOST                            │
│      │                             │                              │
│      │──── joinRequest ──────────►│                              │
│      │                             │                              │
│      │◄─── joinResponse ──────────│                              │
│      │                             │                              │
│      │◄─── offer (SDP) ───────────│                              │
│      │                             │                              │
│      │──── answer (SDP) ─────────►│                              │
│      │                             │                              │
│      │◄─── iceCandidate ─────────►│  (bidirectional,            │
│      │◄─── iceCandidate ─────────►│   multiple candidates)       │
│      │                             │                              │
│      │         [WebRTC Connected]  │                              │
│      │◄════ VIDEO STREAM ═════════│                              │
│      │                             │                              │
└─────────────────────────────────────────────────────────────────┘
```

#### Platform Transport Selection

| Client Platform | Transport | Port |
|-----------------|-----------|------|
| Android | TCP Socket | 50124 |
| iOS | TCP Socket | 50124 |
| macOS | TCP Socket | 50124 |
| Windows | TCP Socket | 50124 |
| Linux | TCP Socket | 50124 |
| Web | WebSocket | 50125 |

#### Message Serialization

Messages are JSON-encoded and newline-delimited for TCP:

```json
{"type":"offer","sender_id":"device123","target_id":"viewer456","payload":{"sdp":"v=0...","type":"offer"},"timestamp":"2024-01-17T12:00:00Z"}\n
```

For WebSocket, messages are sent as plain JSON without newline delimiters.

---

### 3. WebRTC Service

**File:** `webrtc_service.dart`

The WebRTC Service manages **peer-to-peer video streaming** using the WebRTC protocol. It supports **multiple simultaneous viewers** connected to a single host.

#### Host Architecture (Multi-Viewer Support)

```
┌─────────────────────────────────────────────────────────────────┐
│                      HOST DEVICE                                 │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                  Local Screen Capture                     │   │
│   │                  (MediaStream)                            │   │
│   └──────────────────────┬──────────────────────────────────┘   │
│                          │                                       │
│                          ▼                                       │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │               WebRTC Service                              │   │
│   │                                                           │   │
│   │   ┌─────────────────────────────────────────────────┐   │   │
│   │   │        _viewerConnections (Map)                  │   │   │
│   │   │                                                   │   │   │
│   │   │  "viewer1" ──► RTCPeerConnection ──► Viewer 1    │   │   │
│   │   │  "viewer2" ──► RTCPeerConnection ──► Viewer 2    │   │   │
│   │   │  "viewer3" ──► RTCPeerConnection ──► Viewer 3    │   │   │
│   │   │        ...                                        │   │   │
│   │   └─────────────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

#### Viewer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     VIEWER DEVICE                                │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │               WebRTC Service                              │   │
│   │                                                           │   │
│   │   _hostConnection (RTCPeerConnection)                     │   │
│   │          │                                                │   │
│   │          ▼                                                │   │
│   │   ┌─────────────────────────────────────────┐            │   │
│   │   │  Remote MediaStream                       │            │   │
│   │   │  (Video from Host)                        │            │   │
│   │   └─────────────────────────────────────────┘            │   │
│   │          │                                                │   │
│   │          ▼                                                │   │
│   │   ┌─────────────────────────────────────────┐            │   │
│   │   │  RTCVideoRenderer                         │            │   │
│   │   │  (Display in UI)                          │            │   │
│   │   └─────────────────────────────────────────┘            │   │
│   └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

#### ICE (Interactive Connectivity Establishment)

WebRTC uses ICE to find the best path between peers:

```
┌─────────────────────────────────────────────────────────────────┐
│                       ICE Candidate Types                        │
│                                                                   │
│   ┌─────────────────┐     Most direct, lowest latency            │
│   │      HOST       │     typ host: Direct LAN connection        │
│   └─────────────────┘                                            │
│            │                                                      │
│            ▼                                                      │
│   ┌─────────────────┐     Uses STUN to discover public IP        │
│   │  SRFLX (STUN)   │     typ srflx: Server-reflexive candidate  │
│   └─────────────────┘                                            │
│            │                                                      │
│            ▼                                                      │
│   ┌─────────────────┐     Relayed through TURN server            │
│   │  RELAY (TURN)   │     typ relay: Last resort (not used)      │
│   └─────────────────┘                                            │
│                                                                   │
│   STUN Servers Used:                                             │
│   - stun.l.google.com:19302 (Google)                             │
│   - stun1-4.l.google.com:19302                                   │
│   - global.stun.twilio.com:3478 (Twilio)                         │
└─────────────────────────────────────────────────────────────────┘
```

#### Connection States

```dart
enum WebRTCConnectionState {
  disconnected,   // No connection
  connecting,     // Setting up peer connection
  ready,          // Host: Screen capture ready, waiting for viewers
  connected,      // Successfully streaming
  reconnecting,   // Connection interrupted, attempting recovery
  error,          // Connection failed
}
```

#### Streaming Quality Presets

| Quality | Resolution | Frame Rate | Bitrate |
|---------|------------|------------|---------|
| Low | 1280×720 (720p) | 30 fps | 1 Mbps |
| Medium | 1920×1080 (1080p) | 30 fps | 4 Mbps |
| High | 2560×1440 (1440p) | 60 fps | 10 Mbps |

#### Screen Capture Process

**Android:**
1. Start foreground service (required for MediaProjection)
2. Request `getDisplayMedia()` permission
3. User selects screen/app to share
4. Capture MediaStream

**macOS:**
1. Ensure Screen Recording permission in System Preferences
2. Request `getDisplayMedia()`
3. Capture MediaStream

**Web (Viewer only):**
- Cannot host (no screen capture without user interaction)
- Can receive and display remote streams

---

### 4. Web Server Service

**Files:** `web_server_service.dart`, `web_server_service_stub.dart`

The Web Server Service provides a **built-in HTTP server** that serves the Flutter web app to browsers on the local network. This enables users without the native app to view screen shares directly in their browser.

#### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      HOST DEVICE (Native)                        │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                 Web Server Service                        │   │
│   │                                                           │   │
│   │   ┌─────────────────────────────────────────────────┐   │   │
│   │   │            HTTP Server                            │   │   │
│   │   │         Bound to: 0.0.0.0:8080                   │   │   │
│   │   │                                                   │   │   │
│   │   │   Serves:                                         │   │   │
│   │   │   ├── index.html                                  │   │   │
│   │   │   ├── main.dart.js                               │   │   │
│   │   │   ├── flutter_service_worker.js                  │   │   │
│   │   │   ├── assets/*                                   │   │   │
│   │   │   └── canvaskit/*                                │   │   │
│   │   └─────────────────────────────────────────────────┘   │   │
│   │                                                           │   │
│   │   Web App Files Location:                                 │   │
│   │   assets/web_app/ (bundled in native app)                 │   │
│   │                                                           │   │
│   │   Extracted to:                                           │   │
│   │   <temp_dir>/web_app_server/                             │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ HTTP (Port 8080)
                           ▼
              ┌────────────────────────┐
              │     Web Browser        │
              │ http://192.168.1.5:8080│
              └────────────────────────┘
```

#### Startup Process

1. **Get Local IP Address**
   - Scans network interfaces for WiFi/Ethernet
   - Prefers interfaces named `wlan*`, `wifi*`, `en0`, `en1`
   - Falls back to first non-loopback IPv4

2. **Extract Web App Files**
   - Reads `assets/web_app/web_app_manifest.txt`
   - Copies all listed files to temp directory
   - Verifies `index.html` exists

3. **Start HTTP Server**
   - Binds to `0.0.0.0` on port 8080
   - If port busy, tries 8081, 8082... up to 8089
   - Enables CORS for local network access

4. **Serve Requests**
   - Maps URL paths to files
   - Returns appropriate MIME types
   - Falls back to `index.html` for SPA routing

#### MIME Type Handling

```dart
// Extension to MIME type mapping
'.html' → 'text/html'
'.css'  → 'text/css'
'.js'   → 'application/javascript'
'.json' → 'application/json'
'.png'  → 'image/png'
'.wasm' → 'application/wasm'
'.woff2'→ 'font/woff2'
// ... and more
```

#### WebServerStatus Model

```dart
class WebServerStatus {
  final bool isRunning;      // Server active state
  final String? url;         // Full URL (http://IP:PORT)
  final String? ipAddress;   // Local IP address
  final int port;            // Bound port
  final String? error;       // Error message if failed
}
```

---

## Data Flow

### Complete Session Flow (Host to Viewer)

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPLETE CONNECTION FLOW                      │
│                                                                   │
│  HOST                                    VIEWER                  │
│    │                                        │                     │
│    │ 1. Start Sharing                       │                     │
│    ├──────────────────────►                 │                     │
│    │ • Start screen capture                 │                     │
│    │ • Start mDNS broadcast                 │                     │
│    │ • Start TCP signaling server           │                     │
│    │ • Start WebSocket server               │                     │
│    │ • Start HTTP web server                │                     │
│    │                                        │                     │
│    │ 2. Discover/Connect                    │                     │
│    │                 ◄──────────────────────┤                     │
│    │                   mDNS discovery       │                     │
│    │                   or manual IP entry   │                     │
│    │                                        │                     │
│    │ 3. Signaling (TCP or WebSocket)        │                     │
│    │◄─────── joinRequest ──────────────────│                     │
│    │                                        │                     │
│    │──────── joinResponse ────────────────►│                     │
│    │                                        │                     │
│    │──────── offer (SDP) ────────────────►│                     │
│    │                                        │                     │
│    │◄─────── answer (SDP) ─────────────────│                     │
│    │                                        │                     │
│    │◄──────► ICE Candidates ──────────────►│                     │
│    │         (bidirectional)                │                     │
│    │                                        │                     │
│    │ 4. WebRTC Media Stream                 │                     │
│    │═══════════════════════════════════════►│                     │
│    │         Peer-to-peer video             │                     │
│    │                                        │                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Platform Differences

| Feature | Android | iOS | macOS | Windows | Linux | Web |
|---------|---------|-----|-------|---------|-------|-----|
| **Host Screen Capture** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **View Streams** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **mDNS Discovery** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **mDNS Broadcasting** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Signaling Transport** | TCP | TCP | TCP | TCP | TCP | WebSocket |
| **Web Server (Host)** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Foreground Service** | Required | N/A | N/A | N/A | N/A | N/A |

### Conditional Imports Pattern

The codebase uses Dart's conditional imports to handle platform differences:

```dart
// Main service file
import 'service_stub.dart'
    if (dart.library.io) 'service_io.dart'
    as platform_impl;

// platform_impl.ServicePlatform is:
// - service_io.dart on native (Android, iOS, macOS, etc.)
// - service_stub.dart on web (provides no-op implementations)
```

---

## Configuration & Constants

**File:** `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  // Network Service Discovery
  static const String serviceType = '_wifimirror._tcp';
  static const String serviceName = 'WiFiMirror';
  static const int servicePort = 50123;

  // WebRTC Signaling
  static const int signalingPort = 50124;  // TCP
  // WebSocket port = signalingPort + 1 = 50125

  // Connection Timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration discoveryTimeout = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 3);

  // Max Retry Attempts
  static const int maxReconnectAttempts = 5;
}
```

### Port Allocation

| Port | Protocol | Purpose |
|------|----------|---------|
| 50123 | TCP | mDNS service registration |
| 50124 | TCP | Signaling server (native clients) |
| 50125 | WebSocket | Signaling server (web clients) |
| 8080+ | HTTP | Web server (embedded web app) |

---

## Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.6.1 | State management |
| `bonsoir` | ^6.0.0 | mDNS discovery and broadcasting |
| `flutter_webrtc` | ^0.12.8 | WebRTC peer connections |
| `web_socket_channel` | ^3.0.2 | WebSocket support for web platform |
| `go_router` | ^14.6.2 | Navigation and deep linking |

### Platform Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| `device_info_plus` | ^11.4.0 | Device information |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `path_provider` | ^2.1.5 | Temp directory access |
| `wakelock_plus` | ^1.2.10 | Keep screen awake |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.10+
- For Android: Android Studio with NDK
- For iOS/macOS: Xcode with command line tools
- For Windows: Visual Studio with C++ workload

### Installation

```bash
# Clone the repository
git clone https://github.com/yourrepo/wifi-mirror.git
cd wifi-mirror

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Required Permissions

**Android:**
- `INTERNET` - Network access
- `FOREGROUND_SERVICE` - Screen capture
- `FOREGROUND_SERVICE_MEDIA_PROJECTION` - Media projection

**iOS/macOS:**
- Screen Recording permission (System Preferences)
- Local Network access

---

## Build & Deployment

### Build Web App for Embedding

```bash
# Run the build script to create embeddable web app
./build_and_copy_web.sh
```

This script:
1. Builds the Flutter web app
2. Copies output to `assets/web_app/`
3. Generates `web_app_manifest.txt`

### Build Native Apps

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

### Deploy to GitHub Pages

```bash
./deploy_web.sh
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
