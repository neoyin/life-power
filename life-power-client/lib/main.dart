import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/router.dart';
import 'package:life_power_client/core/theme.dart';
import 'package:life_power_client/presentation/providers/locale_provider.dart';
import 'package:step_logger/step_logger.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request notification permission for Android 13+
  await Permission.notification.request();
  
  // Initialize StepLogger plugin
  await StepLogger.initialize();
  
  runApp(
    const ProviderScope(
      child: LifePowerApp(),
    ),
  );
}

class LifePowerApp extends ConsumerWidget {
  const LifePowerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'LifePower',
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/login',
    );
  }
}