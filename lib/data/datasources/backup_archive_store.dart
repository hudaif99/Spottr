import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'backup_file_transaction.dart';
import 'backup_validator.dart';
import 'local_database_service.dart';

class BackupArchiveStore {
  final LocalDatabaseService database;
  final Future<void> Function(File, File)? replaceFile;
  BackupArchiveStore(this.database, {this.replaceFile});

  Future<File> exportTo(Directory destination) =>
      database.maintenance(() async {
        final archive = Archive();
        var expandedBytes = 0;
        try {
          await database.closeAll();
          for (final name in workoutBoxNames) {
            final file = File('${database.directory.path}/$name.hive');
            expandedBytes += await file.length();
            if (expandedBytes > BackupValidator.maxExpandedBytes) {
              throw const InvalidBackup('This backup is too large to export.');
            }
            final bytes = await file.readAsBytes();
            archive.addFile(ArchiveFile('$name.hive', bytes.length, bytes));
          }
        } finally {
          try {
            await database.reopenAll();
          } catch (_) {
            database.markUnavailable();
            throw const InvalidBackup(
              'Could not reopen your data. Restart Spottr before continuing.',
            );
          }
        }
        archive.addFile(
          ArchiveFile.string(
            'spottr.json',
            jsonEncode({'format': 'spottr', 'version': 1}),
          ),
        );
        final zip = File('${destination.path}/spottr_backup.zip');
        final bytes = ZipEncoder().encode(archive);
        if (bytes.length > BackupValidator.maxArchiveBytes) {
          throw const InvalidBackup('This backup is too large to export.');
        }
        await zip.writeAsBytes(bytes, flush: true);
        return zip;
      });

  Future<void> restoreFrom(File zip) async {
    final stage = await database.directory.createTemp('.spottr_stage_');
    try {
      await BackupValidator().stage(zip, stage);
      await database.maintenance(() async {
        if (database.getActiveWorkout() != null) {
          throw const InvalidBackup(
            'Finish or discard your current workout before restoring a backup.',
          );
        }
        final transaction = BackupFileTransaction(database.directory);
        try {
          await database.closeAll();
          await transaction.prepare();
          await transaction.install(stage, replaceFile: replaceFile);
          await database.reopenAll();
          await transaction.commit();
        } catch (_) {
          try {
            await database.closeAll();
            await transaction.recover();
            await database.reopenAll();
          } catch (_) {
            database.markUnavailable();
            throw const InvalidBackup(
              'Restore stopped. Restart Spottr before continuing.',
            );
          }
          throw const InvalidBackup(
            'Could not restore this backup. Your previous data is still available.',
          );
        }
      });
    } finally {
      try {
        if (await stage.exists()) await stage.delete(recursive: true);
      } catch (_) {
        // A stale staging folder does not change the restore result.
      }
    }
  }
}
