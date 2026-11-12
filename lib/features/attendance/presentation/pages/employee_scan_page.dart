import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/connectivity_cubit.dart';
import '../../../../core/network/mock_attendance_store.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../qr_session/domain/entities/qr_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../bloc/sync/sync_cubit.dart';

class EmployeeScanPage extends StatelessWidget {
  final User user;

  const EmployeeScanPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>(),
      child: _EmployeeScanView(user: user),
    );
  }
}

class _EmployeeScanView extends StatefulWidget {
  final User user;

  const _EmployeeScanView({required this.user});

  @override
  State<_EmployeeScanView> createState() => _EmployeeScanViewState();
}

class _EmployeeScanViewState extends State<_EmployeeScanView> {
  late final MobileScannerController _controller;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        context.read<AttendanceBloc>().add(ScanReceived(rawValue));
        break;
      }
    }
  }

  void _showSuccessDialog(BuildContext context, AttendanceRecord record) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeStr = DateFormat('hh:mm:ss a, dd MMM yyyy').format(record.timestamp);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: record.synced
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.warning.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            record.synced
                ? Icons.check_circle_outline
                : Icons.cloud_done_outlined,
            color: record.synced ? AppColors.success : AppColors.warning,
            size: 48,
          ),
        ),
        title: Text(
          record.synced
              ? '${record.type.displayName} Successful!'
              : '${record.type.displayName} Saved Offline!',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Employee', '${widget.user.name} (${record.employeeId})'),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Type', record.type.displayName),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Timestamp', timeStr),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'GPS Coordinates',
              '${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Status',
              record.synced ? 'Validated & Synced Online' : 'Saved Locally (Pending Sync)',
            ),
            if (!record.synced) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sync_rounded, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stored securely offline. Will sync to the server when online.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AttendanceBloc>().add(const ResetAttendanceState());
              context.read<SyncCubit>().checkPendingCount();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(
    BuildContext context,
    String code,
    String message,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String title;
    switch (code) {
      case 'INVALID_SIGNATURE':
        title = 'Invalid Signature';
        break;
      case 'QR_EXPIRED':
        title = 'QR Code Expired';
        break;
      case 'QR_ALREADY_USED':
        title = 'QR Code Reused';
        break;
      case 'FORBIDDEN':
        title = 'Action Forbidden';
        break;
      case 'DUPLICATE_ATTENDANCE':
        title = 'Duplicate Attendance';
        break;
      case 'NO_CHECK_IN':
        title = 'Check-In Required';
        break;
      case 'LOCATION_DISABLED':
        title = 'Location Services Off';
        break;
      case 'LOCATION_PERMISSION_DENIED':
      case 'LOCATION_PERMISSION_PERMANENTLY_DENIED':
        title = 'Location Permission Required';
        break;
      default:
        title = 'Attendance Verification Failed';
    }

    final isPermDenied = code == 'LOCATION_PERMISSION_PERMANENTLY_DENIED';
    final isGpsDisabled = code == 'LOCATION_DISABLED';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, color: colorScheme.error, size: 48),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.error,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Code: $code',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (isPermDenied)
            TextButton(
              onPressed: () {
                sl<LocationService>().openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          if (isGpsDisabled)
            TextButton(
              onPressed: () {
                sl<LocationService>().openLocationSettings();
              },
              child: const Text('Enable GPS'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AttendanceBloc>().add(const ResetAttendanceState());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSuccess) {
          _showSuccessDialog(context, state.record);
        } else if (state is AttendanceFailureState) {
          _showFailureDialog(context, state.code, state.message);
        }
      },
      builder: (context, state) {
        final currentType = state is AttendanceScanning
            ? state.type
            : (state is AttendanceProcessing
                ? state.type
                : AttendanceType.checkIn);
        final isProcessing = state is AttendanceProcessing;

        final isExpanded = ResponsiveBreakpoints.isExpanded(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Scan QR Attendance'),
            actions: [
              if (!isExpanded) ...[
                IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: _isTorchOn ? Colors.amber : null,
                  ),
                  tooltip: 'Toggle Flashlight',
                  onPressed: () async {
                    await _controller.toggleTorch();
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_android),
                  tooltip: 'Switch Camera',
                  onPressed: () => _controller.switchCamera(),
                ),
              ],
            ],
          ),
          body: isExpanded
              ? _buildExpandedScannerLayout(
                  context,
                  theme,
                  colorScheme,
                  currentType,
                  isProcessing,
                )
              : _buildScannerBody(
                  context,
                  theme,
                  colorScheme,
                  currentType,
                  isProcessing,
                ),
          bottomNavigationBar: isExpanded
              ? null
              : _buildBottomActions(
                  context,
                  theme,
                  colorScheme,
                  currentType,
                  isProcessing,
                ),
        );
      },
    );
  }

  /// Tablet landscape expanded layout (side-by-side scanner and controls)
  Widget _buildExpandedScannerLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AttendanceType currentType,
    bool isProcessing,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left (flex: 5): Camera Preview with overlay & controls
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off_outlined,
                                  size: 56, color: colorScheme.error),
                              const SizedBox(height: 12),
                              Text('Camera Preview Unavailable',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(
                                'Use the simulation controls on the right to test check-in and check-out.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  _ScannerOverlay(
                    borderColor: colorScheme.primary,
                    isProcessing: isProcessing,
                  ),
                  // Camera controls overlay
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isTorchOn ? Icons.flash_on : Icons.flash_off,
                              color: _isTorchOn ? Colors.amber : Colors.white,
                            ),
                            onPressed: () async {
                              await _controller.toggleTorch();
                              setState(() => _isTorchOn = !_isTorchOn);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.flip_camera_android,
                                color: Colors.white),
                            onPressed: () => _controller.switchCamera(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isProcessing)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Card(
                        color: colorScheme.surface.withValues(alpha: 0.95),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Validating QR & GPS...',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Right (flex: 6): Attendance Controls, Status, Simulation
          Expanded(
            flex: 6,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Check',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select mode and scan the admin live QR code to mark attendance.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<AttendanceType>(
                      segments: const [
                        ButtonSegment<AttendanceType>(
                          value: AttendanceType.checkIn,
                          label: Text('Check In'),
                          icon: Icon(Icons.login),
                        ),
                        ButtonSegment<AttendanceType>(
                          value: AttendanceType.checkOut,
                          label: Text('Check Out'),
                          icon: Icon(Icons.logout),
                        ),
                      ],
                      selected: {currentType},
                      onSelectionChanged: isProcessing
                          ? null
                          : (Set<AttendanceType> selection) {
                              context
                                  .read<AttendanceBloc>()
                                  .add(ModeChanged(selection.first));
                            },
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      // Offline simulation switch in right pane
                      BlocBuilder<ConnectivityCubit, ConnectivityState>(
                        builder: (context, connState) {
                          return Card(
                            elevation: 0,
                            color: connState.isOffline
                                ? colorScheme.errorContainer.withValues(alpha: 0.3)
                                : colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: connState.isOffline
                                    ? colorScheme.error.withValues(alpha: 0.5)
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            child: SwitchListTile(
                              secondary: Icon(
                                connState.isOffline
                                    ? Icons.wifi_off_rounded
                                    : Icons.wifi_rounded,
                                color: connState.isOffline
                                    ? colorScheme.error
                                    : colorScheme.primary,
                              ),
                              title: Text(
                                'Simulate Offline Mode',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                connState.isOffline
                                    ? 'Offline active: Saves to SQLite locally'
                                    : 'Online active: Verifies with server API',
                                style: theme.textTheme.bodySmall,
                              ),
                              value: connState.isOffline,
                              onChanged: (val) {
                                context
                                    .read<ConnectivityCubit>()
                                    .setSimulateOffline(val);
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Server Error (500) simulation switch
                      StatefulBuilder(
                        builder: (context, setTileState) {
                          return Card(
                            elevation: 0,
                            color: MockAttendanceStore.simulateServerError
                                ? colorScheme.errorContainer.withValues(alpha: 0.3)
                                : colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: MockAttendanceStore.simulateServerError
                                    ? colorScheme.error.withValues(alpha: 0.5)
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            child: SwitchListTile(
                              secondary: Icon(
                                Icons.cloud_off_rounded,
                                color: MockAttendanceStore.simulateServerError
                                    ? colorScheme.error
                                    : colorScheme.primary,
                              ),
                              title: Text(
                                'Simulate Server Error (500)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                MockAttendanceStore.simulateServerError
                                    ? 'API returns 500 SIMULATED_500 failure'
                                    : 'API returns normal responses',
                                style: theme.textTheme.bodySmall,
                              ),
                              value: MockAttendanceStore.simulateServerError,
                              onChanged: (val) {
                                setTileState(() {
                                  MockAttendanceStore.simulateServerError = val;
                                });
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Debug simulation shortcuts
                      Text(
                        'Simulation Scenarios',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.check,
                                size: 16, color: AppColors.success),
                            label: const Text('Valid QR'),
                            onPressed: isProcessing
                                ? null
                                : () {
                                    final p = _generateTestPayload(
                                        isExpired: false, isTampered: false);
                                    context
                                        .read<AttendanceBloc>()
                                        .add(ScanReceived(p));
                                  },
                          ),
                          ActionChip(
                            avatar: Icon(Icons.timer_off,
                                size: 16, color: colorScheme.error),
                            label: const Text('Expired QR'),
                            onPressed: isProcessing
                                ? null
                                : () {
                                    final p = _generateTestPayload(
                                        isExpired: true, isTampered: false);
                                    context
                                        .read<AttendanceBloc>()
                                        .add(ScanReceived(p));
                                  },
                          ),
                          ActionChip(
                            avatar: Icon(Icons.gavel,
                                size: 16, color: colorScheme.error),
                            label: const Text('Tampered QR'),
                            onPressed: isProcessing
                                ? null
                                : () {
                                    final p = _generateTestPayload(
                                        isExpired: false, isTampered: true);
                                    context
                                        .read<AttendanceBloc>()
                                        .add(ScanReceived(p));
                                  },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.replay,
                                size: 16, color: AppColors.warning),
                            label: const Text('Reused Nonce'),
                            onPressed: isProcessing
                                ? null
                                : () {
                                    final p = _generateTestPayload(
                                      isExpired: false,
                                      isTampered: false,
                                      fixedNonce: 'reused-nonce-static-12345',
                                    );
                                    context
                                        .read<AttendanceBloc>()
                                        .add(ScanReceived(p));
                                  },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AttendanceType currentType,
    bool isProcessing,
  ) {
    return Column(
      children: [
        // Mode Selector (Check-In vs Check-Out)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SegmentedButton<AttendanceType>(
            segments: const [
              ButtonSegment<AttendanceType>(
                value: AttendanceType.checkIn,
                label: Text('Check In'),
                icon: Icon(Icons.login),
              ),
              ButtonSegment<AttendanceType>(
                value: AttendanceType.checkOut,
                label: Text('Check Out'),
                icon: Icon(Icons.logout),
              ),
            ],
            selected: {currentType},
            onSelectionChanged: isProcessing
                ? null
                : (Set<AttendanceType> selection) {
                    context
                        .read<AttendanceBloc>()
                        .add(ModeChanged(selection.first));
                  },
          ),
        ),

        // Camera Preview with Viewfinder reticle
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off_outlined,
                              size: 64, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            'Camera Unavailable',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please grant camera permissions or use the test scanner simulation below.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Reticle Overlay
              _ScannerOverlay(
                borderColor: colorScheme.primary,
                isProcessing: isProcessing,
              ),

              // Processing indicator banner
              if (isProcessing)
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Card(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Acquiring GPS & Validating QR...',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AttendanceType currentType,
    bool isProcessing,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Align QR code inside the box to verify attendance.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => _openDebugSimulationSheet(context, currentType),
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('Simulate Scan (Debug Tool)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Interactive debug simulation sheet allowing complete test coverage on emulator
  void _openDebugSimulationSheet(
    BuildContext parentContext,
    AttendanceType currentType,
  ) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        final colorScheme = theme.colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science_outlined, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Scan Simulation Scenarios',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                Text(
                  'Test all QR verification rules and edge cases directly on emulator:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Offline simulation toggle
                BlocBuilder<ConnectivityCubit, ConnectivityState>(
                  builder: (context, connState) {
                    return SwitchListTile(
                      secondary: Icon(
                        connState.isOffline
                            ? Icons.wifi_off_rounded
                            : Icons.wifi_rounded,
                        color: connState.isOffline
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                      title: const Text('Simulate Offline Mode'),
                      subtitle: Text(connState.isOffline
                          ? 'Offline: Saves to local SQLite database'
                          : 'Online: Verifies and syncs with server API'),
                      value: connState.isOffline,
                      onChanged: (val) {
                        parentContext
                            .read<ConnectivityCubit>()
                            .setSimulateOffline(val);
                      },
                    );
                  },
                ),
                StatefulBuilder(
                  builder: (context, setSheetState) {
                    return SwitchListTile(
                      secondary: Icon(
                        Icons.cloud_off_rounded,
                        color: MockAttendanceStore.simulateServerError
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                      title: const Text('Simulate Server Error (500)'),
                      subtitle: Text(MockAttendanceStore.simulateServerError
                          ? 'Server returns 500 SIMULATED_500 failure'
                          : 'Server returns normal HTTP 200 responses'),
                      value: MockAttendanceStore.simulateServerError,
                      onChanged: (val) {
                        setSheetState(() {
                          MockAttendanceStore.simulateServerError = val;
                        });
                      },
                    );
                  },
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Scenario 1: Valid QR
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.success,
                    child: Icon(Icons.check, color: AppColors.onSuccess),
                  ),
                  title: const Text('Simulate Valid QR'),
                  subtitle: const Text('Fresh session with valid HMAC signature'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    final payload = _generateTestPayload(isExpired: false, isTampered: false);
                    parentContext.read<AttendanceBloc>().add(ScanReceived(payload));
                  },
                ),

                // Scenario 2: Expired QR
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.errorContainer,
                    child: Icon(Icons.timer_off, color: colorScheme.onErrorContainer),
                  ),
                  title: const Text('Simulate Expired QR (60s+ old)'),
                  subtitle: const Text('Triggers QR_EXPIRED failure'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    final payload = _generateTestPayload(isExpired: true, isTampered: false);
                    parentContext.read<AttendanceBloc>().add(ScanReceived(payload));
                  },
                ),

                // Scenario 3: Tampered Signature
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.errorContainer,
                    child: Icon(Icons.gavel, color: colorScheme.onErrorContainer),
                  ),
                  title: const Text('Simulate Tampered Signature'),
                  subtitle: const Text('Triggers INVALID_SIGNATURE failure'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    final payload = _generateTestPayload(isExpired: false, isTampered: true);
                    parentContext.read<AttendanceBloc>().add(ScanReceived(payload));
                  },
                ),

                // Scenario 4: Reused Nonce
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.warning,
                    child: Icon(Icons.replay, color: AppColors.onWarning),
                  ),
                  title: const Text('Simulate Reused Nonce'),
                  subtitle: const Text('Submits fixed nonce: triggers QR_ALREADY_USED on 2nd attempt'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    final payload = _generateTestPayload(
                      isExpired: false,
                      isTampered: false,
                      fixedNonce: 'reused-nonce-static-12345',
                    );
                    parentContext.read<AttendanceBloc>().add(ScanReceived(payload));
                  },
                ),

                // Scenario 5: Malformed JSON
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.outlineVariant,
                    child: const Icon(Icons.code_off),
                  ),
                  title: const Text('Simulate Malformed Payload'),
                  subtitle: const Text('Triggers INVALID_QR format failure'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    parentContext.read<AttendanceBloc>().add(
                          const ScanReceived('{"garbage": 12345, "invalid": true}'),
                        );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _generateTestPayload({
    required bool isExpired,
    required bool isTampered,
    String? fixedNonce,
  }) {
    final now = DateTime.now();
    final issuedAt = isExpired ? now.subtract(const Duration(minutes: 5)) : now;
    final expiresAt = isExpired
        ? now.subtract(const Duration(minutes: 4))
        : now.add(const Duration(seconds: 60));
    final nonce = fixedNonce ??
        'sim_${Random().nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
    final sessionId = 'SES-${Random().nextInt(90000) + 10000}';

    String signature = QrSession.computeHmacSignature(
      sessionId: sessionId,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      nonce: nonce,
      secret: AppConstants.hmacSecret,
    );

    if (isTampered) {
      signature = 'tampered_invalid_hmac_hash_000000000000000000000';
    }

    final session = QrSession(
      sessionId: sessionId,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      nonce: nonce,
      signature: signature,
    );

    return session.toRawPayload();
  }
}

class _ScannerOverlay extends StatelessWidget {
  final Color borderColor;
  final bool isProcessing;

  const _ScannerOverlay({
    required this.borderColor,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = min(constraints.maxWidth * 0.75, 280.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Darkened scrim
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Reticle frame
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isProcessing ? Colors.amber : borderColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        );
      },
    );
  }
}
