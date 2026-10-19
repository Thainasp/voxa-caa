import 'package:flutter/material.dart';

import 'package:voxa/core/widgets/app_colors.dart';

class CategoryNavigation extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedKey;
  final ValueChanged<String> onCategorySelected;
  final double height;
  final double iconSize;

  const CategoryNavigation({
    super.key,
    required this.categories,
    required this.selectedKey,
    required this.onCategorySelected,
    this.height = 96,
    this.iconSize = 52,
  });

  @override
  State<CategoryNavigation> createState() => _CategoryNavigationState();
}

class _CategoryNavigationState extends State<CategoryNavigation> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.contentBackground,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          _NavigationArrow(
            icon: Icons.chevron_left,
            tooltip: 'Mostrar categorias anteriores',
            onPressed: () => _scrollCategories(-1),
          ),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: widget.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final isSelected = category['key'] == widget.selectedKey;
                return _CategoryNavigationItem(
                  label: category['label'] as String,
                  icon: category['icon'] as IconData,
                  iconSize: widget.iconSize,
                  isSelected: isSelected,
                  onTap: () =>
                      widget.onCategorySelected(category['key'] as String),
                );
              },
            ),
          ),
          _NavigationArrow(
            icon: Icons.chevron_right,
            tooltip: 'Mostrar próximas categorias',
            onPressed: () => _scrollCategories(1),
          ),
        ],
      ),
    );
  }

  void _scrollCategories(int direction) {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final target =
        (position.pixels + direction * position.viewportDimension * 0.8)
            .clamp(0.0, position.maxScrollExtent)
            .toDouble();

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

class _CategoryNavigationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryNavigationItem({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.categoryBlue,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class _NavigationArrow extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _NavigationArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.black87, size: 48),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}
