import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class HomeNavigationBar extends StatelessWidget {
  final VoidCallback? onHomePressed;

  const HomeNavigationBar({super.key, this.onHomePressed});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: AppColors.contentBackground,
      child: SizedBox(
        height: 64 + bottomInset,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: const Color(0xFFDFF7E2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 64,
              height: 64 + bottomInset,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Center(
                  child: IconButton(
                    style: const ButtonStyle(
                      overlayColor: WidgetStatePropertyAll(Colors.transparent),
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                    ),
                    icon: const Icon(Icons.home, size: 26),
                    color: AppColors.selectedCategoryGreen,
                    tooltip: 'Início',
                    onPressed:
                        onHomePressed ?? () => _returnToPreviousPage(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _returnToPreviousPage(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
