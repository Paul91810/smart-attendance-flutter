import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';

/// Employee home landing page with personal status, scanning preview, and logout.
class EmployeeHomePage extends StatelessWidget {
  final User user;

  const EmployeeHomePage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Attendance'),
          actions: [
            IconButton(
              icon: Icon(
                theme.brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              tooltip: 'Toggle Theme',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
              },
            ),
          ],
        ),
        body: ResponsiveLayout(
          mobile: (context, constraints) => _buildBody(context, theme, colorScheme),
          tablet: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildBody(context, theme, colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Employee Profile Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 36,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'EMPLOYEE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Employee ID: ${user.employeeId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Quick Actions Preview',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        // Phase 2 Card: Scan QR
        _EmployeeActionCard(
          icon: Icons.qr_code_scanner,
          title: 'Scan QR Code',
          subtitle: 'Check in or check out with live camera scan and GPS capture',
          badgeText: 'PHASE 2',
          badgeColor: colorScheme.primary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera QR scanner will be enabled in Phase 2'),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Phase 3 Card: My History
        _EmployeeActionCard(
          icon: Icons.history,
          title: 'My Attendance History',
          subtitle: 'View your check-in/out logs, timestamps, and sync status',
          badgeText: 'PHASE 3',
          badgeColor: colorScheme.secondary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attendance history will be enabled in Phase 3'),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Offline storage badge
        Card(
          color: colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.cloud_done_outlined, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline SQLite Ready',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        'Attendance records will be stored locally and synced when online',
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
        ),

        const SizedBox(height: 32),

        // Logout Button
        OutlinedButton.icon(
          onPressed: () {
            context.read<AuthBloc>().add(const LogoutRequested());
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}

class _EmployeeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  const _EmployeeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
