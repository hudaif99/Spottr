import 'dart:io';

const workoutBoxNames = [
  'plans_box',
  'exercises_box',
  'workout_logs_box',
  'active_workout_box',
  'workout_schedule_box',
  'settings_box',
];

class BackupFileTransaction {
  final Directory root;
  BackupFileTransaction(this.root);
  Directory get journal => Directory('${root.path}/.spottr_restore');
  Directory get _finished => Directory('${root.path}/.spottr_restore_done');
  File _original(String name) => File('${journal.path}/previous/$name.hive');
  File _live(String name) => File('${root.path}/$name.hive');
  File get _pending => File('${journal.path}/pending');
  File get _committed => File('${journal.path}/committed');

  Future<void> prepare() async {
    await recover();
    if (await journal.exists()) {
      throw StateError('The previous restore journal could not be cleaned up.');
    }
    await Directory('${journal.path}/previous').create(recursive: true);
    for (final name in workoutBoxNames) {
      await _copy(_live(name), _original(name));
    }
    // Write the marker before the first live file can change.
    await _pending.writeAsString('pending', flush: true);
  }

  Future<void> install(
    Directory incoming, {
    Future<void> Function(File, File)? replaceFile,
  }) async {
    for (final name in workoutBoxNames) {
      final source = File('${incoming.path}/$name.hive');
      if (await source.exists()) {
        await (replaceFile ?? _copy)(source, _live(name));
      } else {
        await _live(name).writeAsBytes([], flush: true);
      }
    }
  }

  Future<void> commit() async {
    await _committed.writeAsString('committed', flush: true);
    await _cleanup();
  }

  Future<void> recover() async {
    if (!await journal.exists()) {
      await _cleanup();
      return;
    }
    final committed =
        await _committed.exists() &&
        await _committed.readAsString() == 'committed';
    if (await _pending.exists() && !committed) {
      for (final name in workoutBoxNames) {
        if (!await _original(name).exists()) {
          throw StateError('Restore recovery copy is incomplete.');
        }
      }
      for (final name in workoutBoxNames) {
        await _copy(_original(name), _live(name));
      }
      await _committed.writeAsString('committed', flush: true);
    }
    await _cleanup();
  }

  Future<void> _cleanup() async {
    try {
      if (await _finished.exists()) await _finished.delete(recursive: true);
      // Rename first so interrupted cleanup can never look like a pending restore.
      if (await journal.exists()) await journal.rename(_finished.path);
      if (await _finished.exists()) await _finished.delete(recursive: true);
    } catch (_) {
      // Keep the committed journal for the next cleanup attempt.
    }
  }

  static Future<void> _copy(File source, File target) async {
    final bytes = await source.readAsBytes();
    await target.writeAsBytes(bytes, flush: true);
  }
}
