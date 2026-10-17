import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:hive/hive.dart';
import '../models/active_workout.dart';
import '../models/exercise.dart';
import '../models/plan.dart';
import '../models/set_log.dart';
import '../models/workout_day.dart';
import '../models/workout_log.dart';
import '../models/workout_schedule.dart';
import 'backup_file_transaction.dart';

class InvalidBackup implements Exception {
  final String message;
  const InvalidBackup(this.message);
  @override
  String toString() => message;
}

class BackupValidator {
  static const maxArchiveBytes = 64 * 1024 * 1024;
  static const maxExpandedBytes = 128 * 1024 * 1024;
  static int _sequence = 0;

  Future<void> stage(File zip, Directory destination) async {
    if (await zip.length() > maxArchiveBytes) {
      throw const InvalidBackup('This backup is too large to restore.');
    }
    final bytes = await zip.readAsBytes();
    final directory = ZipDirectory()..read(InputMemoryStream(bytes));
    final allowed = {
      for (final name in workoutBoxNames) '$name.hive',
      'spottr.json',
    };
    final names = <String>{};
    var expanded = 0;
    for (final header in directory.fileHeaders) {
      final mode = (header.externalFileAttributes >> 16) & 0xf000;
      if (!allowed.contains(header.filename) ||
          !names.add(header.filename) ||
          (mode != 0 && mode != 0x8000)) {
        throw const InvalidBackup('This ZIP is not a supported Spottr backup.');
      }
      expanded += header.uncompressedSize;
      if (header.uncompressedSize < 0 || expanded > maxExpandedBytes) {
        throw const InvalidBackup('This backup is too large to restore.');
      }
    }
    final required = {
      'plans_box.hive',
      'exercises_box.hive',
      'workout_logs_box.hive',
      'settings_box.hive',
    };
    if (!names.containsAll(required)) {
      throw const InvalidBackup(
        'This backup is incomplete. Your data has not changed.',
      );
    }
    final archive = ZipDecoder().decodeBytes(bytes);
    final expectedCrc = {
      for (final header in directory.fileHeaders) header.filename: header.crc32,
    };
    final extracted = <String>{};
    for (final entry in archive) {
      if (!allowed.contains(entry.name) ||
          !extracted.add(entry.name) ||
          !entry.isFile ||
          entry.isSymbolicLink) {
        throw const InvalidBackup('Unsupported backup entry.');
      }
      final content = entry.content;
      if (content.length != entry.size ||
          getCrc32(content) != entry.crc32 ||
          entry.crc32 != expectedCrc[entry.name]) {
        throw const InvalidBackup(
          'This backup is damaged. Your data has not changed.',
        );
      }
      await File(
        '${destination.path}/${entry.name}',
      ).writeAsBytes(content, flush: true);
    }
    if (extracted.length != names.length || !extracted.containsAll(names)) {
      throw const InvalidBackup('This backup is damaged.');
    }
    final manifest = File('${destination.path}/spottr.json');
    if (await manifest.exists()) {
      final value = jsonDecode(await manifest.readAsString());
      if (value is! Map ||
          value['format'] != 'spottr' ||
          value['version'] != 1 ||
          !names.containsAll({
            for (final name in workoutBoxNames) '$name.hive',
          })) {
        throw const InvalidBackup('This backup version is not supported.');
      }
    }
    for (final name in workoutBoxNames) {
      final source = File('${destination.path}/$name.hive');
      if (!await source.exists()) continue;
      final check = 'spottr_check_${_sequence++}';
      try {
        final box = await _openForValidation(check, await source.readAsBytes());
        for (final value in box.values) {
          _validate(name, value);
        }
        if (name == 'settings_box') _settings(box);
      } finally {
        if (Hive.isBoxOpen(check)) await Hive.box<dynamic>(check).close();
      }
    }
  }

  Future<Box<dynamic>> _openForValidation(String name, List<int> bytes) {
    final result = Completer<Box<dynamic>>();
    runZonedGuarded(
      () async {
        try {
          result.complete(
            await Hive.openBox<dynamic>(
              name,
              bytes: Uint8List.fromList(bytes),
              crashRecovery: false,
            ),
          );
        } catch (_) {
          if (!result.isCompleted) {
            result.completeError(
              const InvalidBackup('This backup contains damaged Hive data.'),
            );
          }
        }
      },
      (error, stack) {
        // Hive 2.2 also reports failed opens through an internal completer.
        if (!result.isCompleted) {
          result.completeError(
            const InvalidBackup('This backup contains damaged Hive data.'),
          );
        }
      },
    );
    return result.future;
  }

  void _require(bool condition) {
    if (!condition) {
      throw const InvalidBackup('This backup contains invalid workout data.');
    }
  }

  void _text(String value, {bool empty = true}) =>
      _require((empty || value.trim().isNotEmpty) && value.length <= 10000);
  void _exercise(Exercise value) {
    _text(value.id, empty: false);
    _text(value.name, empty: false);
    _text(value.note);
    _require(
      value.targetSets > 0 &&
          value.targetSets <= 10000 &&
          value.targetReps >= 0 &&
          value.restDurationSeconds >= 0 &&
          (value.targetWeight == null ||
              value.targetWeight!.isFinite && value.targetWeight! >= 0),
    );
  }

  void _day(WorkoutDay value) {
    _text(value.id, empty: false);
    _text(value.name, empty: false);
    for (final exercise in value.exercises) {
      _exercise(exercise);
    }
  }

  void _sets(Map<String, List<SetLog>> logs) {
    for (final entry in logs.entries) {
      _text(entry.key, empty: false);
      for (final set in entry.value) {
        _text(set.id, empty: false);
        _require(set.reps >= 0 && set.weight.isFinite && set.weight >= 0);
      }
    }
  }

  void _validate(String name, dynamic value) {
    switch (name) {
      case 'plans_box':
        _require(value is Plan);
        final plan = value as Plan;
        _text(plan.id, empty: false);
        _text(plan.name, empty: false);
        for (final day in plan.days) {
          _day(day);
        }
      case 'exercises_box':
        _require(value is Exercise);
        _exercise(value as Exercise);
      case 'workout_logs_box':
        _require(value is WorkoutLog);
        final log = value as WorkoutLog;
        _text(log.id, empty: false);
        _text(log.planId, empty: false);
        _text(log.dayId, empty: false);
        _text(log.dayName);
        _sets(log.exerciseLogs);
        for (final name in log.exerciseNames.values) {
          _text(name);
        }
      case 'active_workout_box':
        _require(value is ActiveWorkout);
        final active = value as ActiveWorkout;
        _text(active.workoutLogId, empty: false);
        _text(active.planId, empty: false);
        _day(active.day);
        _sets(active.exerciseLogs);
        _sets(active.previousExerciseLogs);
      case 'workout_schedule_box':
        _require(value is WorkoutSchedule);
        final schedule = value as WorkoutSchedule;
        _require(
          schedule.workoutHour >= 0 &&
              schedule.workoutHour < 24 &&
              schedule.workoutMinute >= 0 &&
              schedule.workoutMinute < 60 &&
              schedule.workoutDays.every((day) => day >= 1 && day <= 7) &&
              schedule.workoutDays.toSet().length ==
                  schedule.workoutDays.length &&
              {
                'granted',
                'denied',
                'undetermined',
              }.contains(schedule.notificationPermissionStatus),
        );
      case 'settings_box':
        _require(
          value == null ||
              value is String ||
              value is bool ||
              value is num && value.isFinite,
        );
    }
  }

  void _settings(Box<dynamic> box) {
    for (final key in ['user_name', 'user_gender', 'theme_mode']) {
      _require(box.get(key) == null || box.get(key) is String);
    }
    for (final key in [
      'keep_screen_awake',
      'play_timer_sound',
      'onboarding_completed',
    ]) {
      _require(box.get(key) == null || box.get(key) is bool);
    }
    for (final key in ['user_height', 'user_weight']) {
      _require(
        box.get(key) == null ||
            box.get(key) is double &&
                (box.get(key) as double).isFinite &&
                box.get(key) > 0,
      );
    }
    _require(
      box.get('user_age') == null ||
          box.get('user_age') is int && box.get('user_age') > 0,
    );
    _require(
      box.get('rest_time') == null ||
          box.get('rest_time') is int && box.get('rest_time') >= 0,
    );
    _require(
      box.get('theme_mode') == null ||
          {'system', 'light', 'dark'}.contains(box.get('theme_mode')),
    );
  }
}
