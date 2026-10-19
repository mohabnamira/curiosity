import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curiosity/pages/home_page.dart';
import 'package:curiosity/providers/settings_provider.dart';
import 'package:curiosity/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  const MyCustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return MaterialApp(
      title: 'Curiosity',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MyCustomScrollBehavior(),
      theme: AppTheme.buildTheme(
        accent: settings.accentColor,
      ),
      home: const HomePage(),
    );
  }
}