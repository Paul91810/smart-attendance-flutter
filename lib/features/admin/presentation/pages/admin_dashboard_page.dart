import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive_breakpoints.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../bloc/admin_dashboard_event.dart';
import '../bloc/admin_dashboard_state.dart';
import '../widgets/admin_attendance_tile.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/summary_card.dart';
import 'admin_employee_detail_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to Load Dashboard',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      onPressed: () {
                        context
                            .read<AdminDashboardBloc>()
                            .add(const LoadAdminDashboard());
                      },
                    ),
                  ],
                ),
              ),
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
        final isWide = constraints.maxWidth >= ResponsiveBreakpoints.mobileMax;

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
                  // KPI Summary Cards
                  _buildSummaryGrid(context, state, isWide),
                  const SizedBox(height: 20),

                  // Filter Row
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

                  // Attendance List
                  if (state.records.isEmpty)
                    _buildEmptyAttendance(context, colorScheme)
                  else
                    ...state.records.map((record) {
                      return AdminAttendanceTile(
                        record: record,
                        onTap: () {
                          // Find employee entity
                          final emp = state.employees.firstWhere(
                            (e) => e.employeeId == record.employeeId,
                            orElse: () => state.employees.first,
                          );
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

  Widget _buildEmptyAttendance(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
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
