import 'package:flutter/material.dart';
import 'package:perplexity/pages/home_pages.dart';
import 'package:perplexity/theme/colors.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor:AppColors.background,
      ),
      home: const HomePage()
    );
  }
}
