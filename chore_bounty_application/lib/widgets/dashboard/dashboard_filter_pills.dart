import 'package:flutter/material.dart';

class DashboardFilterPills extends StatelessWidget {
  const DashboardFilterPills({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  static const List<String> filters = ['All', 'Available', 'My Tasks'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: filters.map((f) {
        final isSelected = selectedFilter.toLowerCase() == f.toLowerCase();

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: isSelected ? const Color(0xFF1B8354) : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () => onFilterChanged(f),
                borderRadius: BorderRadius.circular(22),
                splashColor: const Color(0xFF1B8354).withAlpha(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: isSelected ? const Color(0xFF1B8354) : Colors.transparent,
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

