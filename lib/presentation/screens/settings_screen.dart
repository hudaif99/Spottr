import 'package:volt/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import '../widgets/volt_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VoltCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSettingRow(
                    context,
                    Icons.person_outline,
                    'Profile & Appearance',
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(),
                  _buildSettingRow(
                    context,
                    Icons.fitness_center,
                    'Workout Preferences',
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(),
                  _buildSettingRow(
                    context,
                    Icons.monitor_weight_outlined,
                    'Units (kg/lb)',
                    value: 'kg',
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(),
                  _buildSettingRow(
                    context,
                    Icons.storage_outlined,
                    'Backup & Restore Data',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    'Volt v1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crafted by Hudaif',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.colors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This feature will be available in a future update.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: context.colors.surface,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    IconData icon,
    String title, {
    String? value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: context.colors.primaryText),
                const SizedBox(width: 16),
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            if (value != null)
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.primaryAccent,
                ),
              )
            else
              Icon(Icons.chevron_right, color: context.colors.secondaryText),
          ],
        ),
      ),
    );
  }
}
