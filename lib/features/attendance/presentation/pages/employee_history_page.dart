import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/attendance_record.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../bloc/history/history_state.dart';
import '../bloc/sync/sync_cubit.dart';

class EmployeeHistoryPage extends StatelessWidget {
  const EmployeeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance History'),
        actions: [
          BlocBuilder<SyncCubit, SyncState>(
            builder: (context, syncState) {
              if (syncState.pendingCount == 0) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Badge.count(
                  count: syncState.pendingCount,
                  child: syncState is SyncInProgress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                ),
                tooltip: 'Sync ${syncState.pendingCount} offline records',
                onPressed: syncState is SyncInProgress
                    ? null
                    : () {
                        context.read<SyncCubit>().syncRecords();
                      },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<HistoryBloc>().add(const RefreshHistory());
            },
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryInitial || state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryFailure) {
            return _buildErrorState(context, state);
          }

          if (state is HistoryEmpty) {
            return _buildEmptyState(context, state.dateFilter);
          }

          if (state is HistoryLoaded) {
            return _buildLoadedContent(context, state.records, state.dateFilter);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    List<AttendanceRecord> records,
    DateTime? dateFilter,
  ) {
    final dailyGroups = _groupRecordsByDate(records);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= ResponsiveBreakpoints.mobileMax;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<HistoryBloc>().add(const RefreshHistory());
          },
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 720 : double.infinity,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                itemCount: dailyGroups.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildFilterBar(context, dateFilter);
                  }
                  final group = dailyGroups[index - 1];
                  return _DailyAttendanceCard(group: group);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, DateTime? dateFilter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          FilterChip(
            selected: dateFilter != null,
            label: Text(
              dateFilter == null
                  ? 'Filter by Date'
                  : DateFormat('dd MMM yyyy').format(dateFilter),
            ),
            avatar: Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: dateFilter != null
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            onSelected: (_) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dateFilter ?? DateTime.now(),
                firstDate: DateTime(2025),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (context.mounted && picked != null) {
                context
                    .read<HistoryBloc>()
                    .add(HistoryFilterChanged(date: picked));
              }
            },
          ),
          if (dateFilter != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 20),
              tooltip: 'Clear filter',
              onPressed: () {
                context
                    .read<HistoryBloc>()
                    .add(const HistoryFilterChanged(date: null));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DateTime? dateFilter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              dateFilter != null
                  ? 'No records for ${DateFormat('dd MMM yyyy').format(dateFilter)}'
                  : 'No attendance records yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your checked-in and checked-out sessions will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (dateFilter != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear Date Filter'),
                onPressed: () {
                  context
                      .read<HistoryBloc>()
                      .add(const HistoryFilterChanged(date: null));
                },
              )
            else
              FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
                onPressed: () {
                  context.read<HistoryBloc>().add(const LoadHistory());
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, HistoryFailure state) {
    return ErrorView(
      title: 'Unable to Load History',
      message: state.message,
      onRetry: () {
        context.read<HistoryBloc>().add(const LoadHistory());
      },
    );
  }

  List<_DailyAttendanceGroup> _groupRecordsByDate(List<AttendanceRecord> records) {
    final Map<String, List<AttendanceRecord>> grouped = {};
    final DateFormat keyFormat = DateFormat('yyyy-MM-dd');

    for (final r in records) {
      final key = keyFormat.format(r.timestamp);
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((k) {
      final recs = grouped[k]!;
      recs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      AttendanceRecord? inRec;
      AttendanceRecord? outRec;

      for (final r in recs) {
        if (r.type == AttendanceType.checkIn) {
          inRec ??= r;
        } else if (r.type == AttendanceType.checkOut) {
          outRec = r;
        }
      }

      return _DailyAttendanceGroup(
        date: recs.first.timestamp,
        checkIn: inRec,
        checkOut: outRec,
        allRecords: recs,
      );
    }).toList();
  }
}

class _DailyAttendanceGroup {
  final DateTime date;
  final AttendanceRecord? checkIn;
  final AttendanceRecord? checkOut;
  final List<AttendanceRecord> allRecords;

  const _DailyAttendanceGroup({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.allRecords,
  });

  bool get isPendingSync => allRecords.any((r) => !r.synced);

  String get statusText {
    if (isPendingSync) return 'Pending sync';
    if (checkOut != null) return 'Checked out';
    if (checkIn != null) return 'Present';
    return 'Recorded';
  }
}

class _DailyAttendanceCard extends StatelessWidget {
  final _DailyAttendanceGroup group;

  const _DailyAttendanceCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeFormat = DateFormat('hh:mm a');

    final now = DateTime.now();
    final isToday = group.date.year == now.year &&
        group.date.month == now.month &&
        group.date.day == now.day;
    final isYesterday = group.date.year == now.year &&
        group.date.month == now.month &&
        group.date.day == now.subtract(const Duration(days: 1)).day;

    final String dateLabel;
    if (isToday) {
      dateLabel = 'Today, ${DateFormat('dd MMM').format(group.date)}';
    } else if (isYesterday) {
      dateLabel = 'Yesterday, ${DateFormat('dd MMM').format(group.date)}';
    } else {
      dateLabel = DateFormat('EEEE, dd MMM yyyy').format(group.date);
    }

    final double? lat = group.checkIn?.latitude ?? group.checkOut?.latitude;
    final double? lng = group.checkIn?.longitude ?? group.checkOut?.longitude;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeTile(
                    context,
                    label: 'Check In',
                    icon: Icons.login_rounded,
                    iconColor: colorScheme.primary,
                    time: group.checkIn != null
                        ? timeFormat.format(group.checkIn!.timestamp)
                        : '--:--',
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _buildTimeTile(
                    context,
                    label: 'Check Out',
                    icon: Icons.logout_rounded,
                    iconColor: colorScheme.tertiary,
                    time: group.checkOut != null
                        ? timeFormat.format(group.checkOut!.timestamp)
                        : '--:--',
                  ),
                ),
              ],
            ),
            if (lat != null && lng != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (group.isPendingSync)
                    Row(
                      children: [
                        Icon(
                          Icons.sync_problem_rounded,
                          size: 14,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unsynced',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required String time,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                time,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bg;
    Color fg;

    switch (group.statusText) {
      case 'Present':
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        break;
      case 'Checked out':
        bg = colorScheme.secondaryContainer;
        fg = colorScheme.onSecondaryContainer;
        break;
      case 'Pending sync':
        bg = colorScheme.errorContainer;
        fg = colorScheme.onErrorContainer;
        break;
      default:
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        group.statusText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
