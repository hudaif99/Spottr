import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import 'local_database_service.dart';

class BackupRestoreService {
  final LocalDatabaseService _localDb;

  BackupRestoreService(this._localDb);

  Future<String?> exportData() async {
    try {
      await _localDb.closeAll();

      try {
        final appDir = await getApplicationDocumentsDirectory();
        final files = appDir.listSync();
        final hiveFiles = files.where((f) => f.path.endsWith('.hive')).toList();

        if (hiveFiles.isEmpty) {
          return 'No workout data found to export.';
        }

        final archive = Archive();
        for (var file in hiveFiles) {
          final fileInfo = File(file.path);
          final bytes = await fileInfo.readAsBytes();
          final filename = file.path.split('/').last;
          archive.addFile(ArchiveFile(filename, bytes.length, bytes));
          log('Added $filename to archive, size: ${bytes.length} bytes');
        }

        final zipData = ZipEncoder().encode(archive);

        final tempDir = await getTemporaryDirectory();
        final zipFilePath = '${tempDir.path}/spottr_backup.zip';
        final zipFile = File(zipFilePath);
        await zipFile.writeAsBytes(zipData, flush: true);

        log(
          'Zip generated at: $zipFilePath, size: ${zipFile.lengthSync()} bytes',
        );

        final xFile = XFile(zipFilePath, mimeType: 'application/zip');
        await Share.shareXFiles([xFile], subject: 'Spottr Workout Backup');

        return null;
      } finally {
        await _localDb.reopenAll();
      }
    } catch (e) {
      log(e.toString());
      return 'Failed to export backup: $e';
    }
  }

  Future<String?> importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return 'Import cancelled.';
      }

      final zipFile = File(result.files.single.path!);
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final hasHiveFiles = archive.any((f) => f.name.endsWith('.hive'));
      if (!hasHiveFiles) {
        return 'Invalid backup file. No data found.';
      }

      final appDir = await getApplicationDocumentsDirectory();

      await _localDb.closeAll();

      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.hive')) {
          final data = file.content as List<int>;
          File('${appDir.path}/${file.name}')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      await _localDb.reopenAll();

      return null;
    } catch (e) {
      await _localDb.reopenAll();
      log(e.toString());
      return 'Failed to import backup: $e';
    }
  }
}
