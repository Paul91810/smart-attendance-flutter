import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/widgets/error_view.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../bloc/admin_dashboard_event.dart';
import '../bloc/admin_dashboard_state.dart';
import 'admin_employee_detail_page.dart';

class AdminEmployeesPage extends StatelessWidget {
  const AdminEmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees Directory'),
      ),
      body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
        builder: (context, state) {
          if (state is AdminDashboardInitial ||
              state is AdminDashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminDashboardFailure) {
            return ErrorView(
              title: 'Failed to Load Employees',
              message: state.message,
              onRetry: () {
                context
                    .read<AdminDashboardBloc>()
                    .add(const LoadAdminDashboard());
              },
            );
          }

          if (state is AdminDashboardLoaded) {
            final employees = state.employees;

            if (employees.isEmpty) {
              return const Center(
                child: Text('No employees registered.'),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isExpanded =
                    constraints.maxWidth >= ResponsiveBreakpoints.mediumMax;
                final isWide =
                    constraints.maxWidth >= ResponsiveBreakpoints.mobileMax;

                if (isExpanded) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ResponsiveBreakpoints.maxExpandedContentWidth,
                      ),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final emp = employees[index];
                          final initial = emp.name.isNotEmpty
                              ? emp.name[0].toUpperCase()
                              : 'E';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminEmployeeDetailPage(
                                      employee: emp,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      child: Text(
                                        initial,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            emp.name,
                                            style: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${emp.employeeId} • ${emp.department}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            emp.email,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 720 : double.infinity,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final emp = employees[index];
                        final initial =
                            emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                initial,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              emp.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${emp.employeeId} • ${emp.department}\n${emp.email}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminEmployeeDetailPage(employee: emp),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
