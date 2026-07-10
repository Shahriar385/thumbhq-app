import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_model.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/pending/pending_screen.dart';
import '../screens/project/project_detail_screen.dart';
import '../screens/team/team_screen.dart';
import '../screens/client/client_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/kicked/kicked_screen.dart';
import 'auth_provider.dart';

final routeObserver = RouteObserver<ModalRoute<void>>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    observers: [routeObserver],
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final user = currentUser.value;
      final location = state.matchedLocation;

      // Not logged in → go to login
      if (!isLoggedIn) {
        if (location != '/login') return '/login';
        return null;
      }

      // Logged in but user doc not loaded yet → stay put
      if (user == null) return null;

      // Logged in, on login page → redirect based on role
      if (location == '/login') {
        if (user.isPending) return '/pending';
        return '/dashboard';
      }

      // Kamla user trying to access anything other than kicked
      if (user.isKamla && location != '/kicked') {
        return '/kicked';
      }

      // Non-kamla user on kicked page -> go to dashboard (or pending)
      if (!user.isKamla && location == '/kicked') {
        if (user.isPending) return '/pending';
        return '/dashboard';
      }

      // Pending user trying to access anything other than pending
      if (user.isPending && location != '/pending') {
        return '/pending';
      }

      // Non-pending user on pending page → go to dashboard
      if (!user.isPending && location == '/pending') {
        return '/dashboard';
      }

      // Non-manager trying to access manager-only pages
      if (!user.isManager && (location == '/team' || location == '/clients' || location == '/analytics')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: '/kicked',
        builder: (context, state) => const KickedScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/team',
        builder: (context, state) => const TeamScreen(),
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: projectId);
        },
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Page not found')),
    ),
  );
});
