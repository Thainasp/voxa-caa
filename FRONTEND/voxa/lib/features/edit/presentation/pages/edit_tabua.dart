import 'package:flutter/material.dart';

import 'package:voxa/core/widgets/app_colors.dart';

import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';

class Edit_pesquisa extends StatelessWidget {
  const Edit_pesquisa({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: AppBar(
        title: const Text(
          'Escolha qual quer editar',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: AppColors.headerGreen,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const CurvedContentPanel(child: SizedBox.shrink()),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }
}
