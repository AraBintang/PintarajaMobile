// ============================================================
// PINTARAJA — APP ROUTER
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/auth_provider.dart';

import '../../features/splash/splash_screen.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';

import '../../features/settings/settings_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/writer/writer_screen.dart';
import '../../features/tools/tools_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/plan/plan_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',

      redirect: (context, state) {
        final isLoggedIn = auth.isLoggedIn;
        final isUnknown =
            auth.status == AuthStatus.unknown;

        final location = state.matchedLocation;

        final isSplash = location == '/splash';

        final isAuthRoute =
            location.startsWith('/auth');

        // ======================================================
        // AUTH STATUS MASIH UNKNOWN
        // ======================================================

        if (isUnknown) {
          if (isSplash) {
            return null;
          }

          return '/splash';
        }

        // ======================================================
        // SPLASH
        // ======================================================

        if (isSplash) {
          return isLoggedIn
              ? '/chat'
              : '/auth/login';
        }

        // ======================================================
        // BELUM LOGIN
        // ======================================================

        if (!isLoggedIn && !isAuthRoute) {
          return '/auth/login';
        }

        // ======================================================
        // SUDAH LOGIN
        //
        // JANGAN redirect dari halaman auth secara otomatis.
        // Login/Register screen akan mengatur popup dan
        // navigasi ke Chat sendiri setelah 3 detik.
        // ======================================================

        if (isLoggedIn && isAuthRoute) {
          return null;
        }

        return null;
      },

      refreshListenable: auth,

      routes: [
        // ======================================================
        // SPLASH
        // ======================================================

        GoRoute(
          path: '/splash',
          builder: (_, __) =>
              const SplashScreen(),
        ),

        // ======================================================
        // AUTH
        // ======================================================

        GoRoute(
          path: '/auth/login',
          builder: (_, __) =>
              const LoginScreen(),
        ),

        GoRoute(
          path: '/auth/register',
          builder: (_, __) =>
              const RegisterScreen(),
        ),

        GoRoute(
          path: '/auth/forgot-password',
          builder: (_, __) =>
              const ForgotPasswordScreen(),
        ),

        GoRoute(
          path: '/settings',
          builder: (
            context,
            state,
          ) {
            return const SettingsScreen();
          },
        ),

        // ======================================================
        // MAIN APP
        // ======================================================

        ShellRoute(
          builder: (
            context,
            state,
            child,
          ) {
            return MainShell(
              state: state,
              child: child,
            );
          },

          routes: [
            // --------------------------------------------------
            // CHAT
            // --------------------------------------------------

            GoRoute(
              path: '/chat',
              builder: (_, state) {
                final conversationId =
                    state.extra as int?;

                return ChatScreen(
                  conversationId:
                      conversationId,
                );
              },
            ),

            // --------------------------------------------------
            // HOME
            // --------------------------------------------------

            GoRoute(
              path: '/home',
              builder: (_, __) =>
                  const HomeScreen(),
            ),

            // --------------------------------------------------
            // WRITER
            // --------------------------------------------------

            GoRoute(
              path: '/writer',
              builder: (_, __) =>
                  const WriterScreen(),
            ),

            // --------------------------------------------------
            // TOOLS
            // --------------------------------------------------

            GoRoute(
              path: '/tools',
              builder: (_, __) =>
                  const ToolsScreen(),
            ),

            // --------------------------------------------------
            // PROFILE
            // --------------------------------------------------

            GoRoute(
              path: '/profile',
              builder: (_, __) =>
                  const ProfileScreen(),
            ),

            // --------------------------------------------------
            // SETTINGS
            // --------------------------------------------------

            GoRoute(
              path: '/settings',
              builder: (
                context,
                state,
              ) {
                return const SettingsScreen();
              },
            ),
          ],
        ),

        // ======================================================
        // PLANS
        // ======================================================

        GoRoute(
          path: '/plans',
          builder: (_, __) =>
              const PlanScreen(),
        ),
      ],
    );
  }
}

// ============================================================
// MAIN SHELL
// ============================================================

class MainShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const MainShell({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: child,
    );
  }
}