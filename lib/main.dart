// ============================================================
// PINTARAJA APP — ENTRY POINT
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'data/providers/auth_provider.dart';
import 'data/providers/chat_provider.dart';
import 'data/providers/plan_provider.dart';

import 'data/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await StorageService.init();

  runApp(const PintaRajaApp());
}

// ============================================================
// APP
// ============================================================

class PintaRajaApp extends StatefulWidget {
  const PintaRajaApp({super.key});

  @override
  State<PintaRajaApp> createState() =>
      _PintaRajaAppState();
}

class _PintaRajaAppState
    extends State<PintaRajaApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _authProvider = AuthProvider();

    _router = AppRouter.router(
      _authProvider,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _authProvider.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: _authProvider,
        ),

        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(),
        ),

        ChangeNotifierProvider<PlanProvider>(
          create: (_) => PlanProvider(),
        ),
      ],

      child: MaterialApp.router(
        title: 'PintarAja',
        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,

        routerConfig: _router,
      ),
    );
  }
}