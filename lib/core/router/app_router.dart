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
import '../../features/auth/new_password_screen.dart';

import '../../features/settings/settings_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/writer/writer_screen.dart';
import '../../features/tools/tools_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shared/widgets/app_sidebar_drawer.dart';
import '../../features/plan/plan_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',

      redirect: (context, state) {
        final isLoggedIn =
            auth.isLoggedIn;

        final isUnknown =
            auth.status ==
                AuthStatus.unknown;

        final location =
            state.matchedLocation;

        final isSplash =
            location == '/splash';

        // ======================================================
        // RESET PASSWORD
        //
        // Jangan redirect halaman reset password ke login/chat.
        // Route ini harus bisa dibuka walaupun user belum login.
        // ======================================================

        final isResetPassword =
            location ==
                '/reset-password' ||
            location ==
                '/auth/new-password';

        if (isResetPassword) {
          return null;
        }

        // ======================================================
        // AUTH ROUTE
        // ======================================================

        final isAuthRoute =
            location.startsWith('/auth');

        // ======================================================
        // AUTH STATUS UNKNOWN
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

        if (!isLoggedIn &&
            !isAuthRoute) {
          return '/auth/login';
        }

        // ======================================================
        // SUDAH LOGIN + AUTH ROUTE
        // ======================================================

        if (isLoggedIn &&
            isAuthRoute) {
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

        // ======================================================
        // RESET PASSWORD
        //
        // Format:
        //
        // /reset-password
        //   ?email=user@email.com
        //   &token=xxxxx
        //
        // Contoh:
        //
        // https://pintaraja.com/reset-password
        //     ?email=test@example.com
        //     &token=TEST_TOKEN
        // ======================================================

        GoRoute(
          path: '/reset-password',
          builder: (_, state) {
            final email =
                state.uri.queryParameters[
                    'email'];

            final token =
                state.uri.queryParameters[
                    'token'];

            if (email == null ||
                email.isEmpty ||
                token == null ||
                token.isEmpty) {
              return const _InvalidResetLinkScreen();
            }

            return NewPasswordScreen(
              email: email,
              token: token,
            );
          },
        ),

        // ======================================================
        // INTERNAL RESET PASSWORD
        //
        // Tetap dipertahankan karena bisa digunakan
        // oleh flow internal aplikasi.
        // ======================================================

        GoRoute(
          path: '/auth/new-password',
          builder: (_, state) {
            final email =
                state.uri.queryParameters[
                    'email'];

            final token =
                state.uri.queryParameters[
                    'token'];

            if (email == null ||
                email.isEmpty ||
                token == null ||
                token.isEmpty) {
              return const _InvalidResetLinkScreen();
            }

            return NewPasswordScreen(
              email: email,
              token: token,
            );
          },
        ),

        // ======================================================
        // MAIN APP SHELL
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
              builder: (_, __) =>
                  const SettingsScreen(),
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
      drawer: const AppSidebarDrawer(),
      body: child,
    );
  }
}

// ============================================================
// INVALID RESET LINK
// ============================================================

class _InvalidResetLinkScreen
    extends StatelessWidget {
  const _InvalidResetLinkScreen();

  @override
  Widget build(
    BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
        ),
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.link_off_rounded,
                size: 56,
              ),

              const SizedBox(
                height: 16,
              ),

              const Text(
                'Link reset password tidak valid.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Silakan minta link reset password baru.',
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 20,
              ),

              ElevatedButton(
                onPressed: () {
                  context.go(
                    '/auth/forgot-password',
                  );
                },
                child: const Text(
                  'Minta link baru',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}