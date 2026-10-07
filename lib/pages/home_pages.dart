import 'package:flutter/material.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/search_section.dart';
import 'package:curiosity/widgets/side_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  get padding => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideBar(),
          Expanded(
            child: Column(
              children: [
                Expanded(child: const SearchSection()),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("© 2024 curiosity AI, Inc. All rights reserved.",
                         style: TextStyle(color: AppColors.footerGrey, fontSize: 14),
                         ),
                        )
                      ],
                    )
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
