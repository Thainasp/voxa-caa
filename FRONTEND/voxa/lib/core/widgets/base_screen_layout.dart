import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BaseScreenLayout extends StatelessWidget {
  final Widget body;

  const BaseScreenLayout({Key? key, required this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.headerGreen,
      body: SafeArea(child: body),
    );
  }
}
