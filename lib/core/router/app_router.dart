import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/session/presentation/screens/passive_listen_screen.dart';
import '../../features/session/presentation/screens/voice_chat_screen.dart';
import '../../features/session/presentation/screens/media_capture_screen.dart';
import '../../features/summary/presentation/screens/summary_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../shared/providers/auth_providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull ?? false;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main app shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(
            currentIndex: navigationShell.currentIndex,
            onTabChanged: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            child: navigationShell,
          );
        },
        branches: [
          // Tab 0: Activities (Dashboard)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Tab 1: History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),

          // Tab 2: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Session routes (full-screen, outside shell)
      GoRoute(
        path: '/session/:activityId/passive',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PassiveListenScreen(
          activityId: state.pathParameters['activityId']!,
        ),
      ),
      GoRoute(
        path: '/session/:activityId/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => VoiceChatScreen(
          activityId: state.pathParameters['activityId']!,
        ),
      ),
      GoRoute(
        path: '/session/:activityId/media',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MediaCaptureScreen(
          activityId: state.pathParameters['activityId']!,
        ),
      ),
      GoRoute(
        path: '/session/:activityId/summary',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SummaryScreen(
          activityId: state.pathParameters['activityId']!,
          sessionId: state.uri.queryParameters['sessionId'] ?? '',
        ),
      ),
    ],
  );
});
