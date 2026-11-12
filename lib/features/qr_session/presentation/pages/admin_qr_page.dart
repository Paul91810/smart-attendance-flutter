import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../bloc/qr_session_bloc.dart';
import '../bloc/qr_session_event.dart';
import '../bloc/qr_session_state.dart';

class AdminQrPage extends StatelessWidget {
  const AdminQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QrSessionBloc>()..add(const StartQrSession()),
      child: const _AdminQrView(),
    );
  }
}

class _AdminQrView extends StatelessWidget {
  const _AdminQrView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Attendance QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh QR',
            onPressed: () {
              context.read<QrSessionBloc>().add(const RefreshQrSession());
            },
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: (context, constraints) => _buildContent(context, theme, colorScheme),
        tablet: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildContent(context, theme, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return BlocConsumer<QrSessionBloc, QrSessionState>(
      listener: (context, state) {
        if (state is QrSessionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is QrSessionLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating secure QR session...'),
              ],
            ),
          );
        }

        if (state is QrSessionError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Generate QR Code',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.error,
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
                    onPressed: () {
                      context.read<QrSessionBloc>().add(const StartQrSession());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is QrSessionActive) {
          final session = state.session;
          final remaining = state.secondsRemaining;
          final progress = (remaining / 60.0).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Scan to Mark Attendance',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Have employees scan this code using the employee portal. QR code auto-refreshes every 60 seconds.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // QR Container Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // White background box for QR scanner clarity
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: session.toRawPayload(),
                            version: QrVersions.auto,
                            size: 240.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Countdown Progress Circle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 5,
                                    backgroundColor: colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      remaining <= 10
                                          ? colorScheme.error
                                          : colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '$remaining',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: remaining <= 10
                                          ? colorScheme.error
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  remaining <= 0
                                      ? 'Refreshing...'
                                      : 'Expires in $remaining seconds',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Auto-regenerates on timeout',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Security info chip card
                Card(
                  color: colorScheme.surfaceContainerLowest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'HMAC-SHA256 Signed & Replay-Protected',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Session: ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                session.sessionId,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Manual refresh button
                OutlinedButton.icon(
                  onPressed: state.isRefreshing
                      ? null
                      : () {
                          context.read<QrSessionBloc>().add(const RefreshQrSession());
                        },
                  icon: state.isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(state.isRefreshing ? 'Refreshing...' : 'Force Refresh Now'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

