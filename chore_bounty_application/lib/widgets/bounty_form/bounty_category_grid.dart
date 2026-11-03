import 'package:flutter/material.dart';
import 'bounty_category_icons.dart';

class BountyCategoryGrid extends StatelessWidget {
  const BountyCategoryGrid({
    super.key,
    required this.selectedCategory,
    required this.onSelect,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelect;

  static const List<String> categories = [
    'Cleaning',
    'Laundry',
    'Kitchen',
    'Groceries',
    'Maintenance',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCategoryCard(categories[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard(categories[1])),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard(categories[2])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCategoryCard(categories[3])),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard(categories[4])),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard(categories[5])),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String name) {
    final isSelected = selectedCategory.toLowerCase() == name.toLowerCase();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onSelect(name),
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF1B8354).withAlpha(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 98,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF1B8354) : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.5,
            ),
            color: isSelected ? const Color(0xFFF7FDF9) : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryIconWidget(
                category: name,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1B8354) : const Color(0xFF475569),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

