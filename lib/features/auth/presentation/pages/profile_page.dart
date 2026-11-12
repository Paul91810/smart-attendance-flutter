import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_state.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_role.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = user.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= ResponsiveBreakpoints.mobileMax;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity,
              ),
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Profile Header Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: isAdmin
                                ? colorScheme.primaryContainer
                                : colorScheme.secondaryContainer,
                            child: Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.person_rounded,
                              size: 44,
                              color: isAdmin
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAdmin ? 'ADMINISTRATOR' : 'EMPLOYEE',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isAdmin
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Info Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.badge_outlined,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Employee ID'),
                          subtitle: Text(user.employeeId),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.email_outlined,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Email Address'),
                          subtitle: Text(user.email),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.admin_panel_settings_outlined,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Access Level'),
                          subtitle: Text(
                            isAdmin ? 'System Administrator' : 'Standard Employee',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preferences Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, themeState) {
                        final mode = themeState.themeMode;
                        final isDark = mode == ThemeMode.dark ||
                            (mode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark);

                        return SwitchListTile(
                          title: const Text('Dark Mode'),
                          subtitle: Text(
                            isDark ? 'Dark theme active' : 'Light theme active',
                          ),
                          secondary: Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: colorScheme.primary,
                          ),
                          value: isDark,
                          onChanged: (_) {
                            context.read<ThemeCubit>().toggleTheme();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign Out Button
                  FilledButton.tonalIcon(
                    icon: Icon(
                      Icons.logout_rounded,
                      color: colorScheme.error,
                    ),
                    label: Text(
                      'Sign Out',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.4),
                    ),
                    onPressed: () {
                      context.read<AuthBloc>().add(const LogoutRequested());
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
