import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CategoryNavigation extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedKey;
  final ValueChanged<String> onCategorySelected;

  const CategoryNavigation({
    Key? key,
    required this.categories,
    required this.selectedKey,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.contentBackground,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          _NavigationArrow(
            icon: Icons.chevron_left,
            onPressed: () => _selectRelativeCategory(-1),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category['key'] == selectedKey;
                return _CategoryNavigationItem(
                  label: category['label'] as String,
                  icon: category['icon'] as IconData,
                  isSelected: isSelected,
                  onTap: () => onCategorySelected(category['key'] as String),
                );
              },
            ),
          ),
          _NavigationArrow(
            icon: Icons.chevron_right,
            onPressed: () => _selectRelativeCategory(1),
          ),
        ],
      ),
    );
  }

  void _selectRelativeCategory(int offset) {
    final selectedIndex = categories.indexWhere(
      (category) => category['key'] == selectedKey,
    );
    if (selectedIndex == -1 || categories.isEmpty) return;

    final nextIndex = (selectedIndex + offset).clamp(0, categories.length - 1);
    onCategorySelected(categories[nextIndex]['key'] as String);
  }
}

class _CategoryNavigationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryNavigationItem({
    required this.label,
    required this.icon,
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
            child: Icon(icon, color: Colors.white, size: 52),
          ),
        ),
      ),
    );
  }
}

class _NavigationArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavigationArrow({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.black87, size: 48),
      onPressed: onPressed,
      tooltip: 'Navegar entre categorias',
    );
  }
}