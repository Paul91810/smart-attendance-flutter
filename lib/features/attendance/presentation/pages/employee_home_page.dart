import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../bloc/sync/sync_cubit.dart';
import 'employee_history_page.dart';
import 'employee_scan_page.dart';

class EmployeeHomePage extends StatefulWidget {
  final User user;

  const EmployeeHomePage({super.key, required this.user});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = ResponsiveBreakpoints.isExpanded(context);

    final pages = IndexedStack(
      index: _currentIndex,
      children: [
        EmployeeScanPage(user: widget.user),
        const EmployeeHistoryPage(),
        ProfilePage(user: widget.user),
      ],
    );

    return BlocProvider<HistoryBloc>(
      create: (_) => sl<HistoryBloc>()..add(const LoadHistory()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Unauthenticated) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          BlocListener<SyncCubit, SyncState>(
            listener: (context, state) {
              if (state is SyncSuccess && state.syncedCount > 0) {
                context.read<HistoryBloc>().add(const RefreshHistory());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Successfully synced ${state.syncedCount} offline record(s)!',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<SyncCubit, SyncState>(
          builder: (context, syncState) {
            final pending = syncState.pendingCount;

            final historyIcon = pending > 0
                ? Badge.count(
                    count: pending,
                    child: const Icon(Icons.history_outlined),
                  )
                : const Icon(Icons.history_outlined);

            final historySelectedIcon = pending > 0
                ? Badge.count(
                    count: pending,
                    child: const Icon(Icons.history_rounded),
                  )
                : const Icon(Icons.history_rounded);

            return Scaffold(
              body: isExpanded
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _currentIndex,
                          onDestinationSelected: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          labelType: NavigationRailLabelType.all,
                          leading: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  child: Icon(
                                    Icons.badge_rounded,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Employee',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          destinations: [
                            const NavigationRailDestination(
                              icon: Icon(Icons.qr_code_scanner_outlined),
                              selectedIcon: Icon(Icons.qr_code_scanner_rounded),
                              label: Text('Scan'),
                            ),
                            NavigationRailDestination(
                              icon: historyIcon,
                              selectedIcon: historySelectedIcon,
                              label: const Text('History'),
                            ),
                            const NavigationRailDestination(
                              icon: Icon(Icons.person_outline_rounded),
                              selectedIcon: Icon(Icons.person_rounded),
                              label: Text('Profile'),
                            ),
                          ],
                        ),
                        const VerticalDivider(thickness: 1, width: 1),
                        Expanded(
                          child: Column(
                            children: [
                              const OfflineBanner(),
                              Expanded(child: pages),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const OfflineBanner(),
                        Expanded(child: pages),
                      ],
                    ),
              bottomNavigationBar: isExpanded
                  ? null
                  : NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      destinations: [
                        const NavigationDestination(
                          icon: Icon(Icons.qr_code_scanner_outlined),
                          selectedIcon: Icon(Icons.qr_code_scanner_rounded),
                          label: 'Scan',
                        ),
                        NavigationDestination(
                          icon: historyIcon,
                          selectedIcon: historySelectedIcon,
                          label: 'History',
                        ),
                        const NavigationDestination(
                          icon: Icon(Icons.person_outline_rounded),
                          selectedIcon: Icon(Icons.person_rounded),
                          label: 'Profile',
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
