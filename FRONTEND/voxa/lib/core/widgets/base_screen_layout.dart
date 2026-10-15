import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class BaseScreenLayout extends StatelessWidget {
  final Widget body;
  final String? title;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  const BaseScreenLayout({
    super.key,
    required this.body,
    this.title,
    this.appBar,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.headerGreen,
      appBar: _buildAppBar(),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (appBar != null) return appBar;

    final pageTitle = title;
    if (pageTitle == null) return null;

    return AppBar(
      title: Text(pageTitle, style: const TextStyle(color: Colors.black)),
      centerTitle: true,
      backgroundColor: AppColors.headerGreen,
      foregroundColor: Colors.black,
      elevation: 0,
    );
  }
}
