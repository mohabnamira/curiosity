import 'package:flutter/material.dart';
import 'package:perplexity/widgets/side_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideBar(),
          Column(
            children: [],
          ),
        ],
      ),
    );
  }
}
