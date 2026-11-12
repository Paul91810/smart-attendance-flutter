import 'package:flutter/material.dart';
import '../error/failures.dart';
import '../responsive/responsive_breakpoints.dart';

/// Reusable error widget providing clear feedback and a retry mechanism.
class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final String? code;
  final Failure? failure;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData? icon;

  const ErrorView({
    super.key,
    this.title = 'Something Went Wrong',
    required this.message,
    this.code,
    this.failure,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon,
  });

  factory ErrorView.fromFailure({
    Key? key,
    required Failure failure,
    VoidCallback? onRetry,
    String retryLabel = 'Try Again',
  }) {
    String title = 'Something Went Wrong';
    IconData icon = Icons.error_outline_rounded;

    if (failure is NetworkFailure || failure is TimeoutFailure) {
      title = 'Network Connection Issue';
      icon = Icons.wifi_off_rounded;
    } else if (failure is AuthFailure) {
      title = 'Authentication Error';
      icon = Icons.lock_outline_rounded;
    } else if (failure is ServerFailure) {
      title = 'Server Error';
      icon = Icons.dns_outlined;
    } else if (failure is QrValidationFailure) {
      title = 'QR Validation Failed';
      icon = Icons.qr_code_2_rounded;
    }

    return ErrorView(
      key: key,
      title: title,
      message: failure.message,
      code: failure.code,
      failure: failure,
      onRetry: onRetry,
      retryLabel: retryLabel,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final resolvedIcon = icon ??
        (code == 'NO_CONNECTION' || code == 'TIMEOUT'
            ? Icons.wifi_off_rounded
            : Icons.error_outline_rounded);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.maxFormWidth),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.5),
                child: Icon(
                  resolvedIcon,
                  size: 40,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (code != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Code: $code',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(retryLabel),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

