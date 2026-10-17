import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spottr/data/datasources/backup_archive_store.dart';
import 'package:spottr/data/datasources/backup_file_transaction.dart';
import 'package:spottr/data/datasources/backup_restore_service.dart';
import 'package:spottr/data/datasources/backup_validator.dart';
import 'package:spottr/data/datasources/local_database_service.dart';
import 'package:spottr/data/repositories/workout_repository_impl.dart';
import 'package:spottr/data/mappers/workout_storage_mapper.dart';
import 'package:spottr/domain/models/workout_models.dart';

extension on Archive {
  void removeWhere(bool Function(ArchiveFile) predicate) {
    for (final file in files.where(predicate).toList()) {
      removeFile(file);
    }
  }
}

class _ReopenFailure extends LocalDatabaseService {
  @override
  Future<void> reopenAll() async =>
      throw const FileSystemException('Injected reopen failure');
}

void main() {
  late Directory root;
  late Directory output;
  late LocalDatabaseService database;
  late BackupArchiveStore store;
  late WorkoutRepositoryImpl repository;
  final date = DateTime(2026, 10, 17, 18);
  final exercise = Exercise(
    id: 'exercise',
    name: 'Cable kickback',
    targetWeight: 12.5,
    note: 'Pulley at knee level',
  );
  final day = WorkoutDay(id: 'day', name: 'Lower', exercises: [exercise]);
  final plan = Plan(
    id: 'plan',
    name: 'Original routine',
    isActive: true,
    days: [day],
    createdAt: date,
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('spottr_backup_test_');
    output = await root.createTemp('export_');
    database = LocalDatabaseService();
    await database.init(path: root.path);
    store = BackupArchiveStore(database);
    repository = WorkoutRepositoryImpl(database);
    await repository.savePlan(plan);
    await repository.saveWorkoutLog(
      WorkoutLog(
        id: 'log',
        planId: 'plan',
        dayId: 'day',
        dayName: 'Lower',
        startTime: date,
        endTime: date.add(const Duration(minutes: 30)),
        exerciseLogs: {
          'exercise': [
            SetLog(id: 'set', reps: 8, weight: 12.5, isCompleted: true),
          ],
        },
        exerciseNames: {'exercise': 'Cable kickback'},
      ),
    );
    await database.saveProfile(name: 'Original name', height: 180, weight: 80);
    await database.saveRestTime(120);
    await database.saveThemeMode('dark');
  });
  tearDown(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });

  Future<File> editedBackup(File original, void Function(Archive) edit) async {
    final archive = ZipDecoder().decodeBytes(await original.readAsBytes());
    edit(archive);
    return File(
      '${output.path}/edited.zip',
    ).writeAsBytes(ZipEncoder().encode(archive), flush: true);
  }

  Future<void> unchanged() async {
    expect((await repository.getPlans()).single.name, 'Original routine');
    expect(database.getUserName(), 'Original name');
    expect(database.getRestTime(), 120);
    await database.saveRestTime(121);
    await database.saveRestTime(120);
  }

  test(
    'export is a complete named snapshot and restore replaces all data',
    () async {
      await repository.saveActiveWorkout(
        ActiveWorkout(
          workoutLogId: 'active',
          planId: 'plan',
          day: day,
          startTime: date,
          exerciseLogs: {
            'exercise': [SetLog(id: 'pending', reps: 10, weight: 12.5)],
          },
          restUntil: date.add(const Duration(seconds: 90)),
        ),
      );
      final zip = await store.exportTo(output);
      final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
      expect(archive.files.map((file) => file.name).toSet(), {
        for (final name in workoutBoxNames) '$name.hive',
        'spottr.json',
      });
      await repository.clearActiveWorkout();
      await repository.savePlan(
        plan.copyWith(id: 'later', name: 'Later routine'),
      );
      await database.saveProfile(name: 'Later name');
      await database.saveRestTime(30);
      await database.saveThemeMode('light');
      await store.restoreFrom(zip);
      expect((await repository.getPlans()).single.name, 'Original routine');
      expect(database.getUserName(), 'Original name');
      expect(database.getThemeMode(), 'dark');
      expect(database.getRestTime(), 120);
      expect((await repository.getWorkoutLogs()).single.totalVolume, 100);
      expect(
        repository.getActiveWorkout()!.day.exercises.single.note,
        exercise.note,
      );
      expect(
        repository.getActiveWorkout()!.restUntil,
        date.add(const Duration(seconds: 90)),
      );
      expect(await Directory('${root.path}/.spottr_restore').exists(), isFalse);
    },
  );

  test(
    'legacy ZIP accepts optional missing boxes and clears stale schedule',
    () async {
      final zip = await editedBackup(await store.exportTo(output), (archive) {
        archive.removeWhere(
          (entry) => {
            'spottr.json',
            'active_workout_box.hive',
            'workout_schedule_box.hive',
          }.contains(entry.name),
        );
      });
      await database.saveWorkoutSchedule(
        WorkoutSchedule(
          workoutHour: 6,
          workoutMinute: 0,
          workoutDays: [1],
        ).toStorage(),
      );
      await store.restoreFrom(zip);
      expect(await repository.getScheduleForToday(), isNull);
      await unchanged();
    },
  );

  for (final name in [
    '../escape.hive',
    '/escape.hive',
    'C:\\escape.hive',
    'unknown_box.hive',
  ]) {
    test(
      'rejects unsafe or unknown archive entry $name before changing data',
      () async {
        final zip = await editedBackup(
          await store.exportTo(output),
          (archive) => archive.addFile(ArchiveFile(name, 3, [1, 2, 3])),
        );
        await expectLater(
          store.restoreFrom(zip),
          throwsA(isA<InvalidBackup>()),
        );
        await unchanged();
        expect(await File('${root.parent.path}/escape.hive').exists(), isFalse);
      },
    );
  }
  test(
    'rejects incomplete backup, unsupported manifest and invalid Hive payload',
    () async {
      final good = await store.exportTo(output);
      for (final edit in <void Function(Archive)>[
        (archive) =>
            archive.removeWhere((entry) => entry.name == 'settings_box.hive'),
        (archive) {
          archive.removeWhere((entry) => entry.name == 'spottr.json');
          archive.addFile(
            ArchiveFile.string(
              'spottr.json',
              jsonEncode({'format': 'spottr', 'version': 99}),
            ),
          );
        },
        (archive) {
          archive.removeWhere((entry) => entry.name == 'plans_box.hive');
          archive.addFile(ArchiveFile('plans_box.hive', 3, [1, 2, 3]));
        },
        (archive) {
          final settings = archive.findFile('settings_box.hive')!.content;
          archive.removeWhere((entry) => entry.name == 'plans_box.hive');
          archive.addFile(
            ArchiveFile('plans_box.hive', settings.length, settings),
          );
        },
      ]) {
        final zip = await editedBackup(good, edit);
        await expectLater(store.restoreFrom(zip), throwsA(anything));
        await unchanged();
      }
    },
  );

  test('checks ZIP CRC and rejects duplicate file names', () async {
    final good = await store.exportTo(output);
    final bytes = Uint8List.fromList(await good.readAsBytes());
    final data = ByteData.sublistView(bytes);
    for (var index = 0; index < bytes.length - 20; index++) {
      if (data.getUint32(index, Endian.little) == 0x02014b50) {
        data.setUint32(index + 16, 123, Endian.little);
      }
      if (data.getUint32(index, Endian.little) == 0x04034b50) {
        data.setUint32(index + 14, 123, Endian.little);
      }
    }
    final damaged = await File(
      '${output.path}/damaged.zip',
    ).writeAsBytes(bytes);
    await expectLater(
      store.restoreFrom(damaged),
      throwsA(isA<InvalidBackup>()),
    );
    final duplicate = await editedBackup(
      good,
      (archive) => archive.addFile(ArchiveFile('planx_box.hive', 0, [])),
    );
    final dupBytes = await duplicate.readAsBytes();
    final from = utf8.encode('planx_box.hive');
    final to = utf8.encode('plans_box.hive');
    for (var index = 0; index <= dupBytes.length - from.length; index++) {
      if (List.generate(
            from.length,
            (offset) => dupBytes[index + offset],
          ).join(',') ==
          from.join(',')) {
        dupBytes.setRange(index, index + to.length, to);
      }
    }
    await duplicate.writeAsBytes(dupBytes);
    await expectLater(
      store.restoreFrom(duplicate),
      throwsA(isA<InvalidBackup>()),
    );
    await unchanged();
  });

  test(
    'rejects oversized compressed and expanded backups before replacement',
    () async {
      final oversized = File('${output.path}/oversized.zip');
      final handle = await oversized.open(mode: FileMode.write);
      await handle.truncate(BackupValidator.maxArchiveBytes + 1);
      await handle.close();
      await expectLater(
        store.restoreFrom(oversized),
        throwsA(isA<InvalidBackup>()),
      );
      final zip = await store.exportTo(output);
      final bytes = await zip.readAsBytes();
      final data = ByteData.sublistView(bytes);
      for (var index = 0; index < bytes.length - 28; index++) {
        if (data.getUint32(index, Endian.little) == 0x02014b50) {
          data.setUint32(
            index + 24,
            BackupValidator.maxExpandedBytes + 1,
            Endian.little,
          );
          break;
        }
      }
      await zip.writeAsBytes(bytes);
      await expectLater(store.restoreFrom(zip), throwsA(isA<InvalidBackup>()));
      await unchanged();
    },
  );

  test('failed reopen blocks writes and preserves files for restart', () async {
    final failed = _ReopenFailure();
    await failed.init(path: root.path);
    final service = BackupRestoreService(
      failed,
      temporaryDirectory: () async => output,
    );
    expect(
      await service.exportData(),
      'Could not reopen your data. Restart Spottr before continuing.',
    );
    await expectLater(failed.saveRestTime(30), throwsStateError);
    await database.init(path: root.path);
    await unchanged();
  });

  test('restore refuses to overwrite a current workout', () async {
    final zip = await store.exportTo(output);
    await repository.saveActiveWorkout(
      ActiveWorkout(
        workoutLogId: 'active',
        planId: 'plan',
        day: day,
        startTime: date,
        exerciseLogs: {},
      ),
    );
    await expectLater(store.restoreFrom(zip), throwsA(isA<InvalidBackup>()));
    expect(repository.getActiveWorkout()!.workoutLogId, 'active');
    await unchanged();
  });

  test(
    'failed replacement rolls all files back and leaves database usable',
    () async {
      final zip = await store.exportTo(output);
      await database.saveUserName('Latest name');
      await repository.savePlan(plan.copyWith(name: 'Latest routine'));
      var replacements = 0;
      final failing = BackupArchiveStore(
        database,
        replaceFile: (source, target) async {
          if (++replacements == 3) {
            throw const FileSystemException('Injected disk failure');
          }
          await target.writeAsBytes(await source.readAsBytes(), flush: true);
        },
      );
      await expectLater(
        failing.restoreFrom(zip),
        throwsA(isA<InvalidBackup>()),
      );
      expect((await repository.getPlans()).single.name, 'Latest routine');
      expect(database.getUserName(), 'Latest name');
      await database.saveRestTime(180);
      await Hive.close();
      await database.init(path: root.path);
      expect(database.getRestTime(), 180);
    },
  );

  test(
    'startup rolls interrupted installation back before opening boxes',
    () async {
      await database.closeAll();
      final transaction = BackupFileTransaction(root);
      await transaction.prepare();
      await File(
        '${root.path}/plans_box.hive',
      ).writeAsBytes([1, 2, 3], flush: true);
      await database.init(path: root.path);
      await unchanged();
      expect(await transaction.journal.exists(), isFalse);
      final cleanup = await Directory(
        '${root.path}/.spottr_restore_done',
      ).create();
      await File('${cleanup.path}/pending').writeAsString('pending');
      await File('${cleanup.path}/plans_box.hive').writeAsBytes([1, 2, 3]);
      await database.closeAll();
      await database.init(path: root.path);
      await unchanged();
      expect(await cleanup.exists(), isFalse);
    },
  );

  test('committed journal cleanup never rolls newer writes back', () async {
    await database.closeAll();
    final transaction = BackupFileTransaction(root);
    await transaction.prepare();
    await database.reopenAll();
    await database.saveUserName('Restored then edited');
    await database.closeAll();
    await File(
      '${transaction.journal.path}/committed',
    ).writeAsString('committed', flush: true);
    await database.init(path: root.path);
    expect(database.getUserName(), 'Restored then edited');
    expect(await transaction.journal.exists(), isFalse);
  });

  test(
    'maintenance drains pending writes and rejects writes during replacement',
    () async {
      final pending = database.saveRestTime(150);
      final zip = await store.exportTo(output);
      await pending;
      await database.saveRestTime(30);
      final entered = Completer<void>();
      final release = Completer<void>();
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      final delayed = BackupArchiveStore(
        database,
        replaceFile: (source, target) async {
          if (!entered.isCompleted) {
            entered.complete();
            await release.future;
          }
          await target.writeAsBytes(await source.readAsBytes(), flush: true);
        },
      );
      final restoring = delayed.restoreFrom(zip);
      await entered.future;
      await expectLater(database.saveRestTime(90), throwsStateError);
      await expectLater(database.maintenance(() async {}), throwsStateError);
      release.complete();
      await restoring;
      expect(database.getRestTime(), 150);
      await database.saveRestTime(120);
    },
  );

  test('platform cancellation and share errors leave boxes usable', () async {
    final cancelled = BackupRestoreService(database, pick: () async => null);
    expect(await cancelled.importData(), 'Import cancelled.');
    final origin = Rect.fromLTWH(10, 10, 1, 1);
    final sharing = BackupRestoreService(
      database,
      temporaryDirectory: () async => output,
      share: (file, rect) async {
        expect(rect, origin);
        expect(await file.exists(), isTrue);
        expect(database.getRestTime(), 120);
        await database.saveRestTime(125);
        return const ShareResult('', ShareResultStatus.dismissed);
      },
    );
    expect(
      await sharing.exportData(sharePositionOrigin: origin),
      'Export cancelled.',
    );
    expect(database.getRestTime(), 125);
    final failed = BackupRestoreService(
      database,
      temporaryDirectory: () async => output,
      share: (_, _) async => throw StateError('Share unavailable'),
    );
    expect(
      await failed.exportData(sharePositionOrigin: origin),
      'Could not export backup. Try again.',
    );
    expect(database.getRestTime(), 125);
  });
}
