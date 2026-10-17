import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/exercise.dart';
import '../../domain/repositories/workout_repository.dart';
import '../blocs/exercise_library/exercise_library_bloc.dart';
import 'exercise_editor.dart';
import 'spottr_button.dart';

Future<Exercise?> showExercisePicker(
  BuildContext context, {
  Iterable<Exercise> localExercises = const [],
  bool replacing = false,
}) => showDialog<Exercise>(
  context: context,
  builder: (_) => BlocProvider(
    create: (_) => ExerciseLibraryBloc(
      context.read<WorkoutRepository>(),
      localExercises: localExercises,
    )..add(LoadExerciseLibrary()),
    child: _ExercisePicker(replacing: replacing),
  ),
);

class _ExercisePicker extends StatefulWidget {
  final bool replacing;
  const _ExercisePicker({required this.replacing});
  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final exercise = await showExerciseEditor(
      context,
      replacing: widget.replacing,
      initialName: _search.text.trim(),
    );
    if (mounted && exercise != null) Navigator.pop(context, exercise);
  }

  Widget get _header => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            widget.replacing ? 'Replace exercise' : 'Choose an exercise',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          tooltip: 'Cancel',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  Widget get _createAction => Padding(
    padding: const EdgeInsets.all(16),
    child: SpottrButton(text: 'Create exercise', onPressed: _create),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    insetAnimationDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 560,
      height: 660,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            BlocBuilder<ExerciseLibraryBloc, ExerciseLibraryState>(
              builder: (context, state) {
                final matches = state.matches;
                final compact = constraints.maxHeight < 360;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!compact) _header,
                    Expanded(
                      child: CustomScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          if (compact) SliverToBoxAdapter(child: _header),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (widget.replacing) ...[
                                    Text(
                                      'Only this workout changes. Unlogged sets will be replaced.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  TextField(
                                    controller: _search,
                                    decoration: const InputDecoration(
                                      labelText: 'Search',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    onChanged: (query) => context
                                        .read<ExerciseLibraryBloc>()
                                        .add(SearchExerciseLibrary(query)),
                                  ),
                                  if (state.isLoading) ...[
                                    const SizedBox(height: 12),
                                    const LinearProgressIndicator(),
                                  ],
                                  if (state.hasError) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Some saved exercises could not load. You can still search common exercises or create one.',
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: () => context
                                            .read<ExerciseLibraryBloc>()
                                            .add(LoadExerciseLibrary()),
                                        child: const Text('Retry'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (compact) SliverToBoxAdapter(child: _createAction),
                          if (matches.isEmpty && !state.isLoading)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No matching exercises. Use Create exercise to add your own.',
                                ),
                              ),
                            ),
                          SliverList.builder(
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final entry = matches[index];
                              final exercise = entry.exercise;
                              final section =
                                  index == 0 ||
                                  matches[index - 1].isSaved != entry.isSaved;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (section)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        12,
                                        20,
                                        8,
                                      ),
                                      child: Text(
                                        entry.isSaved
                                            ? 'Your exercises'
                                            : 'Common exercises',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                    ),
                                  ListTile(
                                    key: ValueKey(
                                      'pick-${exercise.identityId}',
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 4,
                                    ),
                                    title: Text(exercise.name),
                                    subtitle: entry.isSaved
                                        ? Text(
                                            exercise.note.isEmpty
                                                ? entry.source
                                                : '${entry.source}\n${exercise.note}',
                                          )
                                        : null,
                                    trailing: const Icon(Icons.add_rounded),
                                    onTap: () => Navigator.pop(
                                      context,
                                      exercise.copyWith(id: const Uuid().v4()),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        ],
                      ),
                    ),
                    if (!compact) _createAction,
                  ],
                );
              },
            ),
      ),
    ),
  );
}
