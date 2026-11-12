import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../domain/entities/admin_attendance_record.dart';
import '../../domain/entities/employee.dart';
import '../../domain/usecases/get_attendance_records_usecase.dart';

class AdminEmployeeDetailPage extends StatefulWidget {
  final Employee employee;

  const AdminEmployeeDetailPage({super.key, required this.employee});

  @override
  State<AdminEmployeeDetailPage> createState() =>
      _AdminEmployeeDetailPageState();
}

class _AdminEmployeeDetailPageState extends State<AdminEmployeeDetailPage> {
  late Future<List<AdminAttendanceRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _loadEmployeeRecords();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee.name),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= ResponsiveBreakpoints.mobileMax;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 720 : double.infinity,
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _loadEmployeeRecords();
                  });
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Employee Info Card
                    _buildEmployeeCard(context),
                    const SizedBox(height: 20),
                    Text(
                      'Attendance Logs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<AdminAttendanceRecord>>(
                      future: _recordsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      size: 48, color: colorScheme.error),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Failed to load employee records: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: () {
                                      setState(() {
                                        _loadEmployeeRecords();
                                      });
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
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
                            final isCheckIn =
                                r.type == AttendanceType.checkIn;
                            final timeStr = DateFormat('hh:mm a, dd MMM yyyy')
                                .format(r.timestamp);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: colorScheme.outlineVariant),
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                widget.employee.name.isNotEmpty
                    ? widget.employee.name[0].toUpperCase()
                    : 'E',
                style: theme.textTheme.headlineMedium?.copyWith(
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
                    widget.employee.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.employee.employeeId} • ${widget.employee.department}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.employee.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
