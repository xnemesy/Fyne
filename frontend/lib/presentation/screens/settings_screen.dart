import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/auth_provider.dart';
import 'categorization_rules_screen.dart';
import 'backup_screen.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userEmail = authState.user?.email ?? (authState.user?.isAnonymous == true ? "Utente Verificato" : "utente@fyne.it");

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
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.4),
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
                    _buildProfileTile(context, userEmail, onTap: () => _showMsg(context, "Profilo utente")),
                    _buildTile(LucideIcons.shield, "Sicurezza & Privacy", "Gestisci", onTap: () => _showMsg(context, "Impostazioni sicurezza")),
                    _buildTile(LucideIcons.tag, "Regole Categorizzazione", "Gestisci", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CategorizationRulesScreen()));
                    }),
                    _buildTile(LucideIcons.key, "Backup Chiave", "Richiesto", onTap: () => _showPrivateKey(context, ref)),
                  ]),
                  _buildSection("STATO DELLA SICUREZZA", [
                    _buildSecurityTile("Crittografia locale attiva (AES-256)"),
                    _buildSecurityTile("Zero-Knowledge Vault attivo"),
                    _buildSecurityTile("Keyword Intelligence (No Cloud)"),
                    _buildSecurityTile("Nessuna telemetria esterna"),
                  ]),
                  _buildSection("SISTEMA", [
                    _buildTile(LucideIcons.database, "Backup & Recovery", "Gestisci", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupScreen()));
                    }),
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
                          backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.1),
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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

  Widget _buildProfileTile(BuildContext context, String userEmail, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(LucideIcons.user, color: Color(0xFF1A1A1A), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profilo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FyneColors.inkLight,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFFC7C7CC)),
          ],
        ),
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
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.7),
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
