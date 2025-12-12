// lib/widgets/filter_chips.dart

import 'package:flutter/material.dart';

enum FilterType { all, income, expense }

class FilterChips extends StatelessWidget {
  final FilterType current;
  final ValueChanged<FilterType> onChange;

  const FilterChips({super.key, required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildChip(
            label: "All",
            selected: current == FilterType.all,
            color: Colors.indigo,
            onTap: () => onChange(FilterType.all),
          ),
          const SizedBox(width: 12),
          _buildChip(
            label: "Income",
            selected: current == FilterType.income,
            color: Colors.green,
            onTap: () => onChange(FilterType.income),
          ),
          const SizedBox(width: 12),
          _buildChip(
            label: "Expense",
            selected: current == FilterType.expense,
            color: Colors.red,
            onTap: () => onChange(FilterType.expense),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.white : color,
        ),
      ),
      selected: selected,
      selectedColor: color,
      checkmarkColor: Colors.white,
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      onSelected: (_) => onTap(),
    );
  }
}
