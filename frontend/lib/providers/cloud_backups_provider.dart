import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cloud_backup_service.dart';
import 'isar_provider.dart';
import 'master_key_provider.dart';
import '../services/backup_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CloudBackups extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final service = ref.watch(cloudBackupServiceProvider);
    return service.listBackups();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(cloudBackupServiceProvider).listBackups());
  }

  Future<void> uploadCurrentBackup() async {
    final masterKey = ref.read(masterKeyProvider);
    if (masterKey == null) throw Exception("Master Key non trovata");
    final backupService = ref.read(backupServiceProvider);
    final cloudService = ref.read(cloudBackupServiceProvider);
    final isar = await ref.read(isarProvider.future);

    // 1. Esporta localmente
    final localPath = await backupService.exportEncryptedBackup(
      isar: isar,
    );

    // 2. Carica sul cloud
    await cloudService.uploadBackup(localPath);

    // 3. Pulisci file temporaneo e refresh
    await File(localPath).delete();
    await refresh();
  }

  Future<void> restoreFromCloud(String storagePath, String fileName) async {
    final masterKey = ref.read(masterKeyProvider);
    if (masterKey == null) throw Exception("Master Key non trovata");

    final cloudService = ref.read(cloudBackupServiceProvider);
    final backupService = ref.read(backupServiceProvider);
    final isar = await ref.read(isarProvider.future);

    final tempDir = await getTemporaryDirectory();
    final localPath = '${tempDir.path}/$fileName';

    // 1. Scarica
    await cloudService.downloadBackup(storagePath, localPath);

    // 2. Ripristina
    await backupService.importEncryptedBackup(
      filePath: localPath,
      isar: isar,
    );

    // 3. Pulisci
    await File(localPath).delete();
  }

  Future<void> deleteFromCloud(String fileName) async {
    await ref.read(cloudBackupServiceProvider).deleteBackup(fileName);
    await refresh();
  }
}

final cloudBackupsProvider = AsyncNotifierProvider<CloudBackups, List<Map<String, dynamic>>>(() {
  return CloudBackups();
});
