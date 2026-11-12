import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/connectivity_cubit.dart';

/// App shell banner that displays when device is offline or simulating offline mode.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (!state.isOffline) {
          return const SizedBox.shrink();
        }

        return Material(
          color: colorScheme.errorContainer,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 18,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.isSimulated
                        ? 'Simulated Offline Mode — Attendance stored locally & synced online'
                        : 'Offline Mode — Attendance will be saved locally & synced when online',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (state.isSimulated)
                  TextButton(
                    onPressed: () {
                      context.read<ConnectivityCubit>().setSimulateOffline(false);
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: colorScheme.onErrorContainer,
                    ),
                    child: const Text('Go Online'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
