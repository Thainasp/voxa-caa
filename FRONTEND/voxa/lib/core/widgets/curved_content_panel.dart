import 'package:flutter/material.dart';

import 'package:voxa/core/widgets/app_colors.dart';

class CurvedContentPanel extends StatelessWidget {
  final Widget child;
  final double panelTop;
  final double? scrollTop;
  final double contentTopPadding;
  final double contentBottomPadding;
  final double? maxContentWidth;
  final Widget? topOverlay;
  final double overlayTop;

  const CurvedContentPanel({
    super.key,
    required this.child,
    this.panelTop = 42,
    this.scrollTop,
    this.contentTopPadding = 96,
    this.contentBottomPadding = 20,
    this.maxContentWidth,
    this.topOverlay,
    this.overlayTop = 8,
  });

  @override
  Widget build(BuildContext context) {
    final scrollTopInset = scrollTop ?? panelTop;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 480
        ? 20.0
        : 32.0;
    final content = maxContentWidth == null
        ? child
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth!),
            child: child,
          );
    final overlay = topOverlay;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: panelTop,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.contentBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
          ),
        ),
        Positioned.fill(
          top: scrollTopInset,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              contentTopPadding,
              horizontalPadding,
              contentBottomPadding,
            ),
            child: Center(child: content),
          ),
        ),
        if (overlay != null)
          Positioned(
            top: overlayTop,
            left: 0,
            right: 0,
            child: Center(child: overlay),
          ),
      ],
    );
  }
}
