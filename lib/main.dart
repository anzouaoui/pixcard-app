import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:pixcard/core/constants/app_constants.dart';
import 'package:pixcard/core/theme/app_theme.dart';
import 'package:pixcard/presentation/router/app_router.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = AppConstants.sentryDsn;
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      runApp(const ProviderScope(child: PixCardApp()));
    },
  );
}

class PixCardApp extends ConsumerWidget {
  const PixCardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
