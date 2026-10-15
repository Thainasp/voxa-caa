import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/base_screen_layout.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 480 ? 20.0 : 32.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 42,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.contentBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                top: 42,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    96,
                    horizontalPadding,
                    20,
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: HomeNavigationBar(),
              ),
            ],
          );
        },
      ),
    );
  }
}
