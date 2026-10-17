import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'backup_archive_store.dart';
import 'backup_validator.dart';
import 'local_database_service.dart';

class BackupRestoreService {
  final BackupArchiveStore _store;
  final Future<String?> Function() _pick;
  final Future<Directory> Function() _temporaryDirectory;
  final Future<ShareResult> Function(File, Rect?) _share;

  BackupRestoreService(
    LocalDatabaseService database, {
    BackupArchiveStore? store,
    Future<String?> Function()? pick,
    Future<Directory> Function()? temporaryDirectory,
    Future<ShareResult> Function(File, Rect?)? share,
  }) : _store = store ?? BackupArchiveStore(database),
       _pick = pick ?? _pickZip,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _share = share ?? _shareZip;

  static Future<String?> _pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    return result?.files.single.path;
  }

  static Future<ShareResult> _shareZip(File file, Rect? origin) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/zip')],
          subject: 'Spottr Workout Backup',
          sharePositionOrigin: origin,
        ),
      );

  Future<String?> exportData({Rect? sharePositionOrigin}) async {
    Directory? temporary;
    try {
      temporary = await (await _temporaryDirectory()).createTemp(
        'spottr_export_',
      );
      final file = await _store.exportTo(temporary);
      final result = await _share(file, sharePositionOrigin);
      return switch (result.status) {
        ShareResultStatus.success => null,
        ShareResultStatus.dismissed => 'Export cancelled.',
        _ => 'Backup prepared. The share sheet could not confirm it was saved.',
      };
    } on InvalidBackup catch (error) {
      return error.message;
    } catch (error, stack) {
      log('Backup export failed', error: error, stackTrace: stack);
      return 'Could not export backup. Try again.';
    } finally {
      if (temporary != null) {
        try {
          await temporary.delete(recursive: true);
        } catch (_) {
          /* The OS can clean up temporary exports. */
        }
      }
    }
  }

  Future<String?> importData() async {
    try {
      final path = await _pick();
      if (path == null) return 'Import cancelled.';
      await _store.restoreFrom(File(path));
      return null;
    } on InvalidBackup catch (error) {
      return error.message;
    } catch (error, stack) {
      log('Backup restore failed', error: error, stackTrace: stack);
      return 'Could not read this backup. Your data has not changed.';
    }
  }
}
