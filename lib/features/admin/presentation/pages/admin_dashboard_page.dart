import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/employee.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../bloc/admin_dashboard_event.dart';
import '../bloc/admin_dashboard_state.dart';
import '../widgets/admin_attendance_tile.dart';
import '../widgets/admin_employee_detail_pane.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/summary_card.dart';
import 'admin_employee_detail_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Employee? _selectedEmployee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              context
                  .read<AdminDashboardBloc>()
                  .add(const RefreshAdminDashboard());
            },
          ),
        ],
      ),
      body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
        builder: (context, state) {
          if (state is AdminDashboardInitial ||
              state is AdminDashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminDashboardFailure) {
            return ErrorView(
              title: 'Failed to Load Dashboard',
              message: state.message,
              onRetry: () {
                context
                    .read<AdminDashboardBloc>()
                    .add(const LoadAdminDashboard());
              },
            );
          }

          if (state is AdminDashboardLoaded) {
            return _buildLoadedDashboard(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadedDashboard(
    BuildContext context,
    AdminDashboardLoaded state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isExpanded = constraints.maxWidth >= ResponsiveBreakpoints.mediumMax;
        final isWide = constraints.maxWidth >= ResponsiveBreakpoints.mobileMax;

        if (isExpanded) {
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<AdminDashboardBloc>()
                  .add(const RefreshAdminDashboard());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  // KPI Summary Cards across top (4 columns)
                  _buildSummaryGrid(context, state, true),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Split Master - Detail Layout
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Master Feed (flex: 5)
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Live Attendance Feed',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (state.isFiltering)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              AdminFilterBar(
                                selectedDate: state.selectedDate,
                                selectedEmployeeId: state.selectedEmployeeId,
                                employees: state.employees,
                                onDateChanged: (date) {
                                  context
                                      .read<AdminDashboardBloc>()
                                      .add(AdminDateFilterChanged(date));
                                },
                                onEmployeeChanged: (empId) {
                                  context
                                      .read<AdminDashboardBloc>()
                                      .add(AdminEmployeeFilterChanged(empId));
                                },
                                onClear: () {
                                  context
                                      .read<AdminDashboardBloc>()
                                      .add(const ClearAdminFilters());
                                },
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: state.records.isEmpty
                                    ? _buildEmptyAttendance(context, colorScheme)
                                    : ListView.builder(
                                        itemCount: state.records.length,
                                        itemBuilder: (context, index) {
                                          final record = state.records[index];
                                          final emp = state.employees
                                                  .where((e) => e.employeeId == record.employeeId)
                                                  .firstOrNull ??
                                              (state.employees.isNotEmpty
                                                  ? state.employees.first
                                                  : Employee(
                                                      id: record.employeeId,
                                                      employeeId: record.employeeId,
                                                      name: record.employeeName,
                                                      email: '${record.employeeId.toLowerCase()}@smartattendance.com',
                                                      role: 'employee',
                                                      department: 'General',
                                                    ));
                                          final isSelected = _selectedEmployee?.employeeId ==
                                              record.employeeId;

                                          return AdminAttendanceTile(
                                            record: record,
                                            isSelected: isSelected,
                                            onTap: () {
                                              setState(() {
                                                _selectedEmployee = emp;
                                              });
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const VerticalDivider(width: 1),
                        const SizedBox(width: 16),

                        // Right Detail Pane (flex: 6)
                        Expanded(
                          flex: 6,
                          child: _selectedEmployee != null
                              ? Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                  child: AdminEmployeeDetailPane(
                                    employee: _selectedEmployee!,
                                    onClose: () {
                                      setState(() {
                                        _selectedEmployee = null;
                                      });
                                    },
                                  ),
                                )
                              : _buildNoEmployeeSelected(context, colorScheme),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Compact / Mobile Layout: Single Column ListView
        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<AdminDashboardBloc>()
                .add(const RefreshAdminDashboard());
          },
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 900 : double.infinity,
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                children: [
                  _buildSummaryGrid(context, state, isWide),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Attendance Feed',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (state.isFiltering)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AdminFilterBar(
                    selectedDate: state.selectedDate,
                    selectedEmployeeId: state.selectedEmployeeId,
                    employees: state.employees,
                    onDateChanged: (date) {
                      context
                          .read<AdminDashboardBloc>()
                          .add(AdminDateFilterChanged(date));
                    },
                    onEmployeeChanged: (empId) {
                      context
                          .read<AdminDashboardBloc>()
                          .add(AdminEmployeeFilterChanged(empId));
                    },
                    onClear: () {
                      context
                          .read<AdminDashboardBloc>()
                          .add(const ClearAdminFilters());
                    },
                  ),
                  const SizedBox(height: 16),

                  if (state.records.isEmpty)
                    _buildEmptyAttendance(context, colorScheme)
                  else
                    ...state.records.map((record) {
                      return AdminAttendanceTile(
                        record: record,
                        onTap: () {
                          final emp = state.employees
                                  .where((e) => e.employeeId == record.employeeId)
                                  .firstOrNull ??
                              (state.employees.isNotEmpty
                                  ? state.employees.first
                                  : Employee(
                                      id: record.employeeId,
                                      employeeId: record.employeeId,
                                      name: record.employeeName,
                                      email: '${record.employeeId.toLowerCase()}@smartattendance.com',
                                      role: 'employee',
                                      department: 'General',
                                    ));
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminEmployeeDetailPage(employee: emp),
                            ),
                          );
                        },
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    AdminDashboardLoaded state,
    bool isWide,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = state.summary;

    final cards = [
      SummaryCard(
        title: 'Total Employees',
        value: summary.totalEmployees.toString(),
        icon: Icons.people_alt_rounded,
        color: colorScheme.primary,
      ),
      SummaryCard(
        title: 'Present Today',
        value: summary.presentToday.toString(),
        icon: Icons.how_to_reg_rounded,
        color: colorScheme.secondary,
      ),
      SummaryCard(
        title: 'Checked Out',
        value: summary.checkedOutToday.toString(),
        icon: Icons.logout_rounded,
        color: colorScheme.tertiary,
      ),
      SummaryCard(
        title: 'Absent / Inactive',
        value: summary.absentToday.toString(),
        icon: Icons.person_off_rounded,
        color: colorScheme.outline,
      ),
    ];

    if (isWide) {
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: cards,
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: cards,
    );
  }

  Widget _buildNoEmployeeSelected(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.touch_app_outlined,
                size: 44,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select an Attendance Record',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click on any employee or attendance entry on the left to view their detailed profile, department, and full attendance logs.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAttendance(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No attendance records match the selected filters',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
