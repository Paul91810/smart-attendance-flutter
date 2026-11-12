import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/widgets/error_view.dart';
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
      body: const _AdminQrBody(),
    );
  }
}

class _AdminQrBody extends StatelessWidget {
  const _AdminQrBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          return ErrorView(
            title: 'Failed to Generate QR Code',
            message: state.message,
            onRetry: () {
              context.read<QrSessionBloc>().add(const StartQrSession());
            },
          );
        }

        if (state is QrSessionActive) {
          return ResponsiveLayout(
            compact: (context, constraints) =>
                _buildCompactLayout(context, theme, colorScheme, state),
            expanded: (context, constraints) =>
                _buildExpandedLayout(context, theme, colorScheme, state),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    QrSessionActive state,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
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
              _buildQrCard(context, theme, colorScheme, state),
              const SizedBox(height: 20),
              _buildSecurityCard(context, theme, colorScheme, state),
              const SizedBox(height: 24),
              _buildRefreshButton(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    QrSessionActive state,
  ) {
    final session = state.session;
    final timeFormat = DateFormat('hh:mm:ss a');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: QR Code + Progress
              Expanded(
                flex: 5,
                child: _buildQrCard(context, theme, colorScheme, state),
              ),
              const SizedBox(width: 32),
              // Right Column: Session Details, Security, and Actions
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Live Attendance Session',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Employees must be within office GPS boundaries to check in or out with this QR code.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSecurityCard(context, theme, colorScheme, state),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              context,
                              'Generated At',
                              timeFormat.format(session.issuedAt),
                            ),
                            const Divider(height: 16),
                            _buildInfoRow(
                              context,
                              'Valid Until',
                              timeFormat.format(session.expiresAt),
                            ),
                            const Divider(height: 16),
                            _buildInfoRow(
                              context,
                              'Geofence Policy',
                              'Office Radius (500m)',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRefreshButton(context, state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    QrSessionActive state,
  ) {
    final session = state.session;
    final remaining = state.secondsRemaining;
    final progress = (remaining / 60.0).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          remaining <= 10 ? colorScheme.error : colorScheme.primary,
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
                      'Auto-regenerates every 60s',
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
    );
  }

  Widget _buildSecurityCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    QrSessionActive state,
  ) {
    final session = state.session;

    return Card(
      color: colorScheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
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
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context, QrSessionActive state) {
    return FilledButton.tonalIcon(
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
      label: Text(state.isRefreshing ? 'Refreshing...' : 'Force Refresh QR'),
    );
  }
}
