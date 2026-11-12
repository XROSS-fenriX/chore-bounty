import 'package:flutter/material.dart';

class DashboardFilterPills extends StatelessWidget {
  const DashboardFilterPills({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.filters = defaultFilters,
    this.scrollable = false,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final List<String> filters;
  final bool scrollable;

  static const List<String> defaultFilters = ['All', 'Available', 'My Tasks'];

  Widget _buildPill(String label) {
    final isSelected = selectedFilter.toLowerCase() == label.toLowerCase();

    final Color bgColor;
    final Color textColor;
    final BoxBorder? border;

    if (scrollable) {
      bgColor = isSelected ? const Color(0xFF1B8354) : Colors.white;
      textColor = isSelected ? Colors.white : const Color(0xFF64748B);
      border = Border.all(
        color: isSelected ? const Color(0xFF1B8354) : const Color(0xFFE2E8F0),
        width: 1.2,
      );
    } else {
      bgColor = isSelected ? const Color(0xFF1B8354) : Colors.transparent;
      textColor = isSelected ? Colors.white : const Color(0xFF64748B);
      border = null;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => onFilterChanged(label),
        borderRadius: BorderRadius.circular(22),
        splashColor: const Color(0xFF1B8354).withAlpha(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          padding: scrollable
              ? const EdgeInsets.symmetric(horizontal: 14)
              : EdgeInsets.zero,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: bgColor,
            border: border,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.asMap().entries.map((entry) {
            final isLast = entry.key == filters.length - 1;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: _buildPill(entry.value),
            );
          }).toList(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      child: Row(
        children: filters.map((f) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _buildPill(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}
