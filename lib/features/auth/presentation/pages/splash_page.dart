import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../admin/presentation/pages/admin_home_page.dart';
import '../../../attendance/presentation/pages/employee_home_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';

/// Splash page verifying stored session token and automatically routing the user.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state is AuthInitial) {
      authBloc.add(const AppStarted());
    }
  }

  void _handleRouting(BuildContext context, AuthState state) {
    if (state is Authenticated) {
      if (state.user.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminHomePage(user: state.user)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => EmployeeHomePage(user: state.user)),
        );
      }
    } else if (state is Unauthenticated || state is AuthFailureState) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: _handleRouting,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 56,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Smart Attendance',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'QR-Based Attendance Management',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
