import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/employee.dart';

class AdminFilterBar extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedEmployeeId;
  final List<Employee> employees;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final VoidCallback onClear;

  const AdminFilterBar({
    super.key,
    required this.selectedDate,
    required this.selectedEmployeeId,
    required this.employees,
    required this.onDateChanged,
    required this.onEmployeeChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasActiveFilter = selectedDate != null ||
        (selectedEmployeeId != null && selectedEmployeeId != 'ALL');

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Date Filter
        ActionChip(
          avatar: Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: selectedDate != null
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          label: Text(
            selectedDate == null
                ? 'All Dates'
                : DateFormat('dd MMM yyyy').format(selectedDate!),
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2025),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
        ),

        // Employee Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
            color: colorScheme.surface,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedEmployeeId ?? 'ALL',
              icon: const Icon(Icons.arrow_drop_down_rounded),
              isDense: true,
              borderRadius: BorderRadius.circular(16),
              items: [
                const DropdownMenuItem(
                  value: 'ALL',
                  child: Text('All Employees'),
                ),
                ...employees.map(
                  (emp) => DropdownMenuItem(
                    value: emp.employeeId,
                    child: Text('${emp.name} (${emp.employeeId})'),
                  ),
                ),
              ],
              onChanged: onEmployeeChanged,
            ),
          ),
        ),

        // Clear Filters button
        if (hasActiveFilter)
          IconButton.filledTonal(
            icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
            tooltip: 'Clear filters',
            onPressed: onClear,
          ),
      ],
    );
  }
}
