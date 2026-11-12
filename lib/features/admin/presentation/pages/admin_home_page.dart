import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../qr_session/presentation/pages/admin_qr_page.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../bloc/admin_dashboard_event.dart';
import 'admin_dashboard_page.dart';
import 'admin_employees_page.dart';

class AdminHomePage extends StatefulWidget {
  final User user;

  const AdminHomePage({
    super.key,
    required this.user,
  });

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = ResponsiveBreakpoints.isExpanded(context);

    final pages = IndexedStack(
      index: _currentIndex,
      children: [
        const AdminDashboardPage(),
        const AdminQrPage(),
        const AdminEmployeesPage(),
        ProfilePage(user: widget.user),
      ],
    );

    return BlocProvider<AdminDashboardBloc>(
      create: (_) =>
          sl<AdminDashboardBloc>()..add(const LoadAdminDashboard()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        },
        child: Scaffold(
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
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Admin',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard_rounded),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.qr_code_2_outlined),
                          selectedIcon: Icon(Icons.qr_code_2_rounded),
                          label: Text('QR Code'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.people_outline_rounded),
                          selectedIcon: Icon(Icons.people_rounded),
                          label: Text('Employees'),
                        ),
                        NavigationRailDestination(
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
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.qr_code_2_outlined),
                      selectedIcon: Icon(Icons.qr_code_2_rounded),
                      label: 'QR Code',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline_rounded),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: 'Employees',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
