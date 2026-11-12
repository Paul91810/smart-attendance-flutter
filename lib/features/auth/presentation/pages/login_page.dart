import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../admin/presentation/pages/admin_home_page.dart';
import '../../../attendance/presentation/pages/employee_home_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/demo_credentials_card.dart';

/// Authentication login page supporting email/employee ID sign-in, validation,
/// demo credentials auto-fill, and role-based redirection.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onDemoSelected(String identifier, String password) {
    _identifierController.text = identifier;
    _passwordController.text = password;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
            LoginSubmitted(
              identifier: _identifierController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
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
        } else if (state is AuthFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
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
            ],
          ),
          body: SafeArea(
            child: ResponsiveLayout(
              mobile: (context, constraints) => _buildLoginForm(
                context,
                theme,
                colorScheme,
                isLoading,
                maxWidth: double.infinity,
              ),
              tablet: (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildLoginForm(
                    context,
                    theme,
                    colorScheme,
                    isLoading,
                    maxWidth: 480,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLoading, {
    required double maxWidth,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 42,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to manage and mark attendance',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Identifier Field
              TextFormField(
                controller: _identifierController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Email or Employee ID',
                  hintText: 'e.g. EMP001 or admin@smartattendance.com',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email or employee ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              FilledButton(
                onPressed: isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Demo Credentials Card
              DemoCredentialsCard(
                onSelectCredentials: _onDemoSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
