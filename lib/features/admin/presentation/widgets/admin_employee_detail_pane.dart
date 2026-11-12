import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../domain/entities/employee.dart';
import '../bloc/employee_detail/employee_detail_cubit.dart';
import '../bloc/employee_detail/employee_detail_state.dart';

class AdminEmployeeDetailPane extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onClose;

  const AdminEmployeeDetailPane({
    super.key,
    required this.employee,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('employee_detail_${employee.employeeId}'),
      create: (_) => sl<EmployeeDetailCubit>()..loadEmployeeRecords(employee.employeeId),
      child: _AdminEmployeeDetailView(employee: employee, onClose: onClose),
    );
  }
}

class _AdminEmployeeDetailView extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onClose;

  const _AdminEmployeeDetailView({
    required this.employee,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () => context.read<EmployeeDetailCubit>().loadEmployeeRecords(employee.employeeId),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (onClose != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close pane',
                onPressed: onClose,
              ),
            ),
          // Employee Info Card
          _buildEmployeeCard(context),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Logs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh logs',
                onPressed: () {
                  context.read<EmployeeDetailCubit>().loadEmployeeRecords(employee.employeeId);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<EmployeeDetailCubit, EmployeeDetailState>(
            builder: (context, state) {
              if (state is EmployeeDetailLoading || state is EmployeeDetailInitial) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is EmployeeDetailError) {
                return ErrorView.fromFailure(
                  failure: state.failure,
                  onRetry: () {
                    context.read<EmployeeDetailCubit>().loadEmployeeRecords(employee.employeeId);
                  },
                );
              }

              if (state is EmployeeDetailLoaded) {
                final records = state.records;
                if (records.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No attendance records found for this employee.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: records.map<Widget>((r) {
                    final isCheckIn = r.type == AttendanceType.checkIn;
                    final timeStr =
                        DateFormat('hh:mm a, dd MMM yyyy').format(r.timestamp);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCheckIn
                              ? colorScheme.primaryContainer
                              : colorScheme.secondaryContainer,
                          child: Icon(
                            isCheckIn
                                ? Icons.login_rounded
                                : Icons.logout_rounded,
                            color: isCheckIn
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSecondaryContainer,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          isCheckIn ? 'Check In' : 'Check Out',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$timeStr\nLat: ${r.latitude.toStringAsFixed(4)}, Lng: ${r.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials = employee.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${employee.employeeId} â€¢ ${employee.department}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRoleBadge(context, employee.role),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  employee.email,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
