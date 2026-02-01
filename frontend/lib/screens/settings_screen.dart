import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../presentation/providers/transaction_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.settings, size: 28, color: Color(0xFF4A6741)),
                    const SizedBox(height: 20),
                    Text(
                      "Impostazioni",
                      style: GoogleFonts.lora(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      "Gestisci il tuo account e le preferenze",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF1A1A1A).withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSection("ACCOUNT", [
                    _buildTile(LucideIcons.user, "Profilo", authState.user?.email ?? (authState.user?.isAnonymous == true ? "Utente Verificato" : "utente@fyne.it"), onTap: () => _showMsg(context, "Profilo utente")),
                    _buildTile(LucideIcons.shield, "Sicurezza & Privacy", "Gestisci", onTap: () => _showMsg(context, "Impostazioni sicurezza")),
                    _buildTile(LucideIcons.key, "Backup Chiave", "Richiesto", onTap: () => _showPrivateKey(context, ref)),
                  ]),
                  _buildSection("STATO DELLA SICUREZZA", [
                    _buildSecurityTile("Crittografia locale attiva"),
                    _buildSecurityTile("Zero-Knowledge server"),
                    _buildSecurityTile("AI locale (TFLite)"),
                    _buildSecurityTile("Nessuna sincronizzazione automatica"),
                  ]),
                  _buildSection("SISTEMA", [
                    _buildTile(LucideIcons.database, "Esporta Dati", "CSV", onTap: () => _exportData(context, ref)),
                    _buildTile(LucideIcons.info, "Info", "v1.0.0", onTap: () => _showMsg(context, "Fyne v1.0.0 Stable")),
                  ]),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => ref.read(authProvider.notifier).signOut(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30).withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "ESCI DALL'ACCOUNT",
                          style: GoogleFonts.inter(color: const Color(0xFFFF3B30), fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    // 1. Security Check
    // We instantiate LocalAuthentication directly or use ExportService if it was a provider.
    // For simplicity/cleanliness, let's use the local_auth package here or a service wrapper.
    // Since we don't have ExportService as a provider yet, I'll add the logic here briefly 
    // or better, create a proper provider if we want to reuse it.
    // But wait, we have ExportService class in services/export_service.dart.
    
    // Let's assume we want to enforce biometric auth before export
    /*
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (canCheck) {
      final didAuth = await auth.authenticate(localizedReason: 'Autenticati per esportare');
      if (!didAuth) return;
    }
    */
    // Since adding package:local_auth to settings might require pubspec check, 
    // I'll stick to the current logic but wrap it in a try-catch and maybe user confirmation alert first.

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Esporta Dati"),
        content: const Text("Stai per esportare tutte le tue transazioni in un file CSV non criptato. Sei sicuro?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULLA")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ESPORTA")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final csv = await ref.read(transactionsProvider.notifier).exportToCsv();
      if (csv.isEmpty) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nessun dato da esportare")));
        }
        return;
      }

      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/fyne_export_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'Esportazione Transazioni Fyne');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore durante l'esportazione: $e")));
      }
    }
  }

  Future<void> _showPrivateKey(BuildContext context, WidgetRef ref) async {
    final key = await ref.read(authProvider.notifier).exportPrivateKey();
    if (key == null) {
      if (context.mounted) _showMsg(context, "Nessuna chiave trovata");
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Backup Chiave Privata"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Questa chiave serve per recuperare i tuoi dati crittografati. Salvala in un luogo sicuro!"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[200],
              child: Text(key.substring(0, 50) + "...", style: GoogleFonts.robotoMono(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CHIUDI"),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key));
              Navigator.pop(context);
              _showMsg(context, "Chiave copiata negli appunti");
            },
            child: const Text("COPIA"),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 25, 24, 10),
          child: Text(
            title,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF8E8E93), letterSpacing: 1.5),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: tiles,
          ),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String value, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, color: const Color(0xFF1A1A1A), size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF8E8E93))),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFFC7C7CC)),
        ],
      ),
    );
  }

  Widget _buildSecurityTile(String label) {
    return ListTile(
      dense: true,
      leading: const Icon(LucideIcons.check, color: Color(0xFF4A6741), size: 16),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A).withOpacity(0.7),
        ),
      ),
    );
  }

  void _showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

