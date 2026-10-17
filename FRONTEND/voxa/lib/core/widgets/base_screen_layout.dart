import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voxa/core/widgets/app_colors.dart';

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
      backgroundColor: AppColors.contentBackground,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(color: AppColors.headerGreen),
          ),
          SafeArea(top: false, bottom: false, child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (appBar != null) return appBar;

    final pageTitle = title;
    if (pageTitle == null) return null;

    return AppBar(
      toolbarHeight: 76,
      backgroundColor: AppColors.headerGreen,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(top: 14.0, left: 8.0),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.titleColor,
            size: 26,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 14.0),
        child: Text(
          pageTitle,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.titleColor,
          ),
        ),
      ),
    );
  }
}
