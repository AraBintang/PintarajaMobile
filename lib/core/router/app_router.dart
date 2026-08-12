// ============================================================
// APP ROUTER — GoRouter Navigation
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
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
        final isUnknown = auth.status == AuthStatus.unknown;
        final isSplash = state.matchedLocation == '/splash';
        final isAuth = state.matchedLocation.startsWith('/auth');

        if (isUnknown) return '/splash';
        if (isSplash) {
          return isLoggedIn ? '/home' : '/auth/login';
        }
        if (!isLoggedIn && !isAuth) return '/auth/login';
        if (isLoggedIn && isAuth) return '/home';

        return null;
      },
      refreshListenable: auth,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),

        // ── Auth routes ─────────────────────────────────────
        GoRoute(
          path: '/auth/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (_, __) => const RegisterScreen(),
        ),

        // ── Main shell (dengan bottom nav) ──────────────────
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(child: child, state: state);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const HomeScreen(),
            ),
            GoRoute(
              path: '/chat',
              builder: (_, state) {
                final convId = state.extra as int?;
                return ChatScreen(conversationId: convId);
              },
            ),
            GoRoute(
              path: '/writer',
              builder: (_, __) => const WriterScreen(),
            ),
            GoRoute(
              path: '/tools',
              builder: (_, __) => const ToolsScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),

        // ── Plan screen (full screen) ────────────────────────
        GoRoute(
          path: '/plans',
          builder: (_, __) => const PlanScreen(),
        ),
      ],
    );
  }
}

// ── Main Shell dengan Bottom Navigation ───────────────────────
class MainShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const MainShell({super.key, required this.child, required this.state});

  int _currentIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/chat')) return 1;
    if (location.startsWith('/writer')) return 2;
    if (location.startsWith('/tools')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(state.matchedLocation);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/home');
              case 1: context.go('/chat');
              case 2: context.go('/writer');
              case 3: context.go('/tools');
              case 4: context.go('/profile');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_outlined),
              activeIcon: Icon(Icons.edit),
              label: 'Writer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apps_outlined),
              activeIcon: Icon(Icons.apps),
              label: 'Tools',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
