import 'package:flutter/material.dart';
import 'package:life_power_client/presentation/pages/home/home_page.dart';
import 'package:life_power_client/presentation/pages/charge/charge_page.dart';
import 'package:life_power_client/presentation/pages/watchers/watchers_page.dart';
import 'package:life_power_client/presentation/pages/care/care_page.dart';
import 'package:life_power_client/presentation/pages/settings/settings_page.dart';
import 'package:life_power_client/presentation/pages/watchers/watcher_search_page.dart';
import 'package:life_power_client/presentation/pages/auth/login_page.dart';
import 'package:life_power_client/presentation/pages/auth/register_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case '/charge':
        return MaterialPageRoute(builder: (_) => const ChargePage());
      case '/watchers':
        return MaterialPageRoute(builder: (_) => const WatchersPage());
      case '/care':
        return MaterialPageRoute(builder: (_) => const CarePage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case '/watcher_search':
        return MaterialPageRoute(builder: (_) => const WatcherSearchPage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}
