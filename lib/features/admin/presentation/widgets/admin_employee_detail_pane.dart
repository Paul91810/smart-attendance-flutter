import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../domain/entities/admin_attendance_record.dart';
import '../../domain/entities/employee.dart';
import '../../domain/usecases/get_attendance_records_usecase.dart';

/// Reusable employee detail pane used in both the full-page detail screen
/// and the expanded tablet master-detail layout.
class AdminEmployeeDetailPane extends StatefulWidget {
  final Employee employee;
  final VoidCallback? onClose;

  const AdminEmployeeDetailPane({
    super.key,
    required this.employee,
    this.onClose,
  });

  @override
  State<AdminEmployeeDetailPane> createState() => _AdminEmployeeDetailPaneState();
}

class _AdminEmployeeDetailPaneState extends State<AdminEmployeeDetailPane> {
  late Future<List<AdminAttendanceRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _loadEmployeeRecords();
  }

  @override
  void didUpdateWidget(covariant AdminEmployeeDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employee.employeeId != widget.employee.employeeId) {
      _loadEmployeeRecords();
    }
  }

  void _loadEmployeeRecords() {
    _recordsFuture = sl<GetAttendanceRecordsUsecase>()
        .call(employeeId: widget.employee.employeeId)
        .then((result) => result.fold(
              (failure) => throw Exception(failure.message),
              (records) => records,
            ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadEmployeeRecords();
        });
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (widget.onClose != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close pane',
                onPressed: widget.onClose,
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
                  setState(() {
                    _loadEmployeeRecords();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AdminAttendanceRecord>>(
            future: _recordsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return ErrorView(
                  title: 'Failed to load logs',
                  message: snapshot.error.toString(),
                  onRetry: () {
                    setState(() {
                      _loadEmployeeRecords();
                    });
                  },
                );
              }

              final records = snapshot.data ?? [];
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
                children: records.map((r) {
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final emp = widget.employee;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    emp.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${emp.employeeId} • ${emp.department}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRoleBadge(context, emp.role),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  emp.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
