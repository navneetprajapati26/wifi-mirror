import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/viewing_screen.dart';
import '../presentation/screens/sharing_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../data/models/models.dart';

/// Route paths
class AppRoutes {
  static const String home = '/';
  static const String connect = '/connect';
  static const String view = '/view';
  static const String share = '/share';
  static const String settings = '/settings';
}

/// GoRouter configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      // Home screen
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Connect route - just shows HomeScreen (QuickConnectCard will read URL params)
      // Example: /connect?host=192.168.1.5&port=54321
      GoRoute(
        path: AppRoutes.connect,
        name: 'connect',
        builder: (context, state) => const HomeScreen(),
      ),

      // Viewing screen (used after connection)
      GoRoute(
        path: AppRoutes.view,
        name: 'view',
        builder: (context, state) {
          final device = state.extra as NetworkDevice?;
          if (device == null) {
            return const HomeScreen();
          }
          return ViewingScreen(hostDevice: device);
        },
      ),

      // Sharing screen
      GoRoute(
        path: AppRoutes.share,
        name: 'share',
        builder: (context, state) => const SharingScreen(),
      ),

      // Settings screen
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
