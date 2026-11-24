import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';

import 'package:permit_plans/bindings/auth_binding.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/constants/app_theme.dart';
import 'package:permit_plans/constants/get_app_routes.dart';
import 'package:permit_plans/services/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean URLs on web (/login instead of /#/login). No-op on mobile/desktop.
  usePathUrlStrategy();

  try {
    // 1) Backend first: AuthService reads Supabase.instance on creation.
    await SupabaseConfig.initialize();
    // 2) Register AuthService + AuthController before any route can ask for
    //    them (route guards and the auth pages call Get.find).
    AuthBinding().dependencies();
  } catch (error, stackTrace) {
    debugPrint('App start-up failed: $error\n$stackTrace');
    runApp(_StartupErrorApp(message: error.toString()));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'WorkBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // ------------------------------------------------
      // ROUTES
      // Do not also pass `home:` — it conflicts with the '/' route.
      // On web, a deep link (e.g. /client) overrides initialRoute and is
      // checked by the route guards.
      // ------------------------------------------------
      initialRoute: AppRoutes.splash,
      getPages: GetAppRoutes.pages,
      unknownRoute: GetAppRoutes.unknownRoute,
    );
  }
}

/// Minimal fallback so a bad configuration shows a message instead of a blank
/// screen.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'WorkBridge could not start',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
