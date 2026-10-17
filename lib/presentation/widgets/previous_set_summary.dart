import 'package:flutter/material.dart';
import '../../data/models/set_log.dart';
import 'workout_value_control.dart';

class PreviousSetSummary extends StatelessWidget {
  final List<SetLog> sets;
  final int setIndex;

  const PreviousSetSummary({
    super.key,
    required this.sets,
    required this.setIndex,
  });

  @override
  Widget build(BuildContext context) {
    final completed = sets.where((set) => set.isCompleted).toList();
    if (completed.isEmpty) return const SizedBox.shrink();
    final index = setIndex.clamp(0, completed.length - 1);
    final previous = completed[index];
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        icon: const Icon(Icons.history_rounded, size: 20),
        label: Text(
          'Last time: ${formatWeight(previous.weight)} kg × ${previous.reps} reps',
        ),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .7,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Previous session',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close previous session',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                for (final (index, set) in completed.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Set ${index + 1}'),
                    subtitle: Text(
                      '${formatWeight(set.weight)} kg × ${set.reps} reps',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
