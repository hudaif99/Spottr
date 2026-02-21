import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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
                  const Divider(),
                  _buildSettingRow(
                    context,
                    Icons.fitness_center,
                    'Workout Preferences',
                    onTap: () => _showComingSoon(context),
                  ),
                  const Divider(),
                  _buildSettingRow(
                    context,
                    Icons.monitor_weight_outlined,
                    'Units (kg/lb)',
                    value: 'kg',
                    onTap: () => _showComingSoon(context),
                  ),
                  const Divider(),
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
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Developed by Hudaif',
                    style: AppTypography.textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryAccent,
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
      const SnackBar(
        content: Text('This feature will be available in a future update.'),
        backgroundColor: AppColors.surface,
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
                Icon(icon, color: AppColors.primaryText),
                const SizedBox(width: 16),
                Text(title, style: AppTypography.textTheme.bodyLarge),
              ],
            ),
            if (value != null)
              Text(
                value,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryAccent,
                ),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
