import 'package:flutter/material.dart';

class DemoCredentialsCard extends StatelessWidget {
  final void Function(String identifier, String password) onSelectCredentials;

  const DemoCredentialsCard({
    super.key,
    required this.onSelectCredentials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demo Credentials (Tap to Auto-fill)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                  label: const Text('Admin (EMP000)'),
                  onPressed: () {
                    onSelectCredentials('admin@smartattendance.com', 'admin123');
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text('Alice (EMP001)'),
                  onPressed: () {
                    onSelectCredentials('alice@smartattendance.com', 'password123');
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text('Bob (EMP002)'),
                  onPressed: () {
                    onSelectCredentials('EMP002', 'password123');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
