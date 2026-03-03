import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/fyne_theme.dart';
import '../../services/backup_service.dart';
import '../../providers/isar_provider.dart';
import '../../providers/master_key_provider.dart';
import '../../providers/security_provider.dart';
import '../../services/analytics_service.dart';
import '../../providers/cloud_backups_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen>
    with WidgetsBindingObserver {
  BackupService get _backupService => ref.read(backupServiceProvider);
  bool _isExporting = false;
  bool _isImporting = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    if (mounted && (_isExporting || _isImporting)) {
      _showErrorDialog(
        'Memoria Insufficiente',
        'L\'operazione è stata rallentata o potrebbe fallire per proteggere i tuoi dati.',
      );
    }
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isExporting = true;
      _progress = 0;
    });

    try {
      final authenticated =
          await ref.read(securityProvider.notifier).authenticate(
                reason: 'Autentica per esportare il tuo Vault',
              );

      if (!authenticated) {
        AnalyticsService().logBiometricFail();
        if (mounted) {
          _showSnackBar('Autenticazione fallita o annullata.', isError: true);
        }
        return;
      }

      final isar = await ref.read(isarProvider.future);
      final masterKey = ref.read(masterKeyProvider);

      if (masterKey == null) {
        if (mounted) {
          _showSnackBar('Il vault non è ancora pronto. Riprova tra un momento.',
              isError: true);
        }
        return;
      }

      final filePath = await _backupService.exportEncryptedBackup(
        isar: isar,
        onProgress: (p) => setState(() => _progress = p),
      );

      await _backupService.shareBackup(filePath);

      if (mounted) {
        HapticFeedback.lightImpact();
        _showSnackBar('✅ Export completato con successo');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Errore Export', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importBackup() async {
    setState(() {
      _isImporting = true;
      _progress = 0;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['fyne'],
      );

      if (result == null || result.files.single.path == null) return;
      final filePath = result.files.single.path!;

      final authenticated =
          await ref.read(securityProvider.notifier).authenticate(
                reason: 'Autentica per ripristinare il backup',
              );

      if (!authenticated) {
        AnalyticsService().logBiometricFail();
        return;
      }

      final masterKey = ref.read(masterKeyProvider);
      if (masterKey == null) throw Exception('Chiave non trovata.');

      // Validazione rapida
      final info = await _backupService.validateBackup(
        filePath: filePath,
      );

      if (!mounted) return;
      final confirmed = await _showImportConfirmation(info);
      if (!confirmed) return;

      final isar = await ref.read(isarProvider.future);
      await _backupService.importEncryptedBackup(
        filePath: filePath,
        isar: isar,
        onProgress: (p) => setState(() => _progress = p),
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        _showSuccessDialog('Ripristino Completato',
            'I tuoi dati sono stati importati con successo.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Errore Ripristino', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: FyneColors.rust)),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: FyneColors.forest)),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CHIUDI')),
        ],
      ),
    );
  }

  Future<bool> _showImportConfirmation(Map<String, dynamic> info) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Conferma Ripristino'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Questo backup contiene:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Transazioni', info['transactions_count']),
                _buildInfoRow('Account', info['accounts_count']),
                _buildInfoRow('Budget', info['budgets_count']),
                _buildInfoRow('Regole', info['rules_count']),
                const SizedBox(height: 16),
                Text(
                  'Esportato il: ${_formatDate(info['exported_at'])}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6)),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ I dati attuali verranno sostituiti',
                  style: TextStyle(
                      color: FyneColors.rust, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ripristina'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildInfoRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Sconosciuto';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return 'Sconosciuto';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? FyneColors.rust : FyneColors.forest,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Recovery'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: FyneColors.forest.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FyneColors.forest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shield,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zero-Knowledge Vault',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'I tuoi dati restano cifrati anche durante il backup',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isExporting || _isImporting) ...[
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: FyneColors.paperDark,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            FyneColors.forest),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '${(_progress * 100).toInt()}% completato...',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Esporta Backup
                  Text(
                    'ESPORTA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.upload_file,
                    title: 'Crea Backup',
                    subtitle: 'Esporta tutti i tuoi dati in un file cifrato',
                    onTap: _isExporting ? null : _exportBackup,
                    isLoading: _isExporting,
                  ),

                  const SizedBox(height: 32),

                  // Importa Backup
                  Text(
                    'RIPRISTINA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.download,
                    title: 'Importa Backup',
                    subtitle: 'Ripristina i dati da un file .fyne',
                    onTap: _isImporting ? null : _importBackup,
                    isLoading: _isImporting,
                  ),

                  const SizedBox(height: 32),

                  // Cloud Backup Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CLOUD BACKUP',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            ref.read(cloudBackupsProvider.notifier).refresh(),
                        icon: const Icon(LucideIcons.refreshCw, size: 14),
                        label: const Text('Aggiorna',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCloudSection(),

                  const SizedBox(height: 24),

                  // Info Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FyneColors.paperDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'I file .fyne sono cifrati con AES-256 e possono essere aperti solo con la tua master key',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloudSection() {
    final cloudBackups = ref.watch(cloudBackupsProvider);

    return cloudBackups.when(
      data: (backups) => Column(
        children: [
          _buildActionCard(
            icon: Icons.cloud_upload_outlined,
            title: 'Salva sul Cloud',
            subtitle: 'Carica un backup cifrato su Firebase Storage',
            onTap: _isExporting ? null : _uploadToCloud,
            isLoading: _isExporting,
          ),
          if (backups.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'BACKUP DISPONIBILI',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: backups.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final b = backups[index];
                final date = _formatDate(b['exported_at'] ??
                    (b['createdAt'] as Timestamp).toDate().toIso8601String());
                final sizeInBytes = b['size'] as int? ?? 0;
                final sizeStr = sizeInBytes > 1024 * 1024
                    ? '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                    : '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.fileLock,
                      color: FyneColors.forest),
                  title: Text(date,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('$sizeStr • Online',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.downloadCloud, size: 20),
                        onPressed: () =>
                            _restoreFromCloud(b['storagePath'], b['fileName']),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2,
                            size: 20, color: FyneColors.rust),
                        onPressed: () => _deleteFromCloud(b['fileName']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Text('Errore caricamento backup cloud: $e',
            style: const TextStyle(color: FyneColors.rust, fontSize: 12)),
      ),
    );
  }

  Future<void> _uploadToCloud() async {
    setState(() {
      _isExporting = true;
      _progress = 0;
    });

    try {
      final authenticated =
          await ref.read(securityProvider.notifier).authenticate(
                reason: 'Autentica per caricare il backup sul cloud',
              );

      if (!authenticated) return;

      await ref.read(cloudBackupsProvider.notifier).uploadCurrentBackup();
      if (mounted) _showSnackBar('✅ Caricato con successo sul Cloud');
    } catch (e) {
      if (mounted) _showErrorDialog('Errore Cloud Backup', e.toString());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _restoreFromCloud(String storagePath, String fileName) async {
    setState(() => _isImporting = true);
    try {
      final authenticated =
          await ref.read(securityProvider.notifier).authenticate(
                reason: 'Autentica per ripristinare dal cloud',
              );

      if (!authenticated) return;

      await ref
          .read(cloudBackupsProvider.notifier)
          .restoreFromCloud(storagePath, fileName);
      if (mounted)
        _showSuccessDialog('Ripristino Cloud',
            'I tuoi dati sono stati ripristinati con successo dal cloud.');
    } catch (e) {
      if (mounted) _showErrorDialog('Errore Ripristino Cloud', e.toString());
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _deleteFromCloud(String fileName) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Elimina Backup'),
            content: const Text(
                'Sei sicuro di voler eliminare definitivamente questo backup dal cloud?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('ANNULLA')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('ELIMINA',
                      style: TextStyle(color: FyneColors.rust))),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await ref.read(cloudBackupsProvider.notifier).deleteFromCloud(fileName);
      if (mounted) _showSnackBar('Backup eliminato');
    }
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FyneColors.forest.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: FyneColors.forest,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
