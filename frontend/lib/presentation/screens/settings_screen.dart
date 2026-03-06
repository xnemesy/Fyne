import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/fyne_theme.dart';
import 'categorization_rules_screen.dart';
import 'category_list_screen.dart';
import 'backup_screen.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userEmail = authState.user?.email ?? (authState.user?.isAnonymous == true ? "Utente Verificato" : "utente@fyne.it");

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.settings, size: 28, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 20),
                    Text(
                      "Impostazioni",
                      style: GoogleFonts.lora(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "Gestisci il tuo account e le preferenze",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
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
                  _buildSection(context, "ACCOUNT", [
                    _buildProfileTile(context, userEmail, onTap: () => _showMsg(context, "Profilo utente")),
                    _buildTile(context, LucideIcons.shield, "Sicurezza & Privacy", "Gestisci", onTap: () => _showMsg(context, "Impostazioni sicurezza")),
                    _buildTile(context, LucideIcons.layoutList, "Gestione Categorie", "Personalizza", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryListScreen()));
                    }),
                    _buildTile(context, LucideIcons.tag, "Regole Categorizzazione", "Gestisci", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CategorizationRulesScreen()));
                    }),
                    _buildTile(context, LucideIcons.key, "Backup Chiave", "Richiesto", onTap: () => _showPrivateKey(context, ref)),
                  ]),
                  _buildSection(context, "STATO DELLA SICUREZZA", [
                    _buildSecurityTile(context, "Crittografia locale attiva (AES-256)"),
                    _buildSecurityTile(context, "Zero-Knowledge Vault attivo"),
                    _buildSecurityTile(context, "Keyword Intelligence (No Cloud)"),
                    _buildSecurityTile(context, "Nessuna telemetria esterna"),
                  ]),
                  _buildSection(context, "SISTEMA", [
                    _buildThemeTile(context, ref),
                    _buildTile(context, LucideIcons.database, "Backup & Recovery", "Gestisci", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupScreen()));
                    }),
                    _buildTile(context, LucideIcons.info, "Info", "v1.0.0", onTap: () => _showMsg(context, "Fyne v1.0.0 Stable")),
                  ]),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => ref.read(authProvider.notifier).signOut(),
                        style: TextButton.styleFrom(
                          backgroundColor: FyneColors.danger.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "ESCI DALL'ACCOUNT",
                          style: GoogleFonts.inter(color: FyneColors.danger, fontWeight: FontWeight.bold, letterSpacing: 1),
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
        // Fix Bug 2: sfondo dialog usa colorScheme — leggibile in dark mode
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          "Backup Chiave Privata",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Questa chiave serve per recuperare i tuoi dati crittografati. Salvala in un luogo sicuro!",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              // Fix Bug 2: sostituito Colors.grey[200] hardcoded (light) con colorScheme
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                key.substring(0, 50) + "...",
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 25, 24, 10),
          child: Text(
            title,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.5),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: FyneColors.ink.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: tiles,
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title, String value, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Icon(LucideIcons.chevronRight, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
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
            Icon(LucideIcons.user, color: Theme.of(context).colorScheme.onSurface, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profilo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(LucideIcons.chevronRight, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTile(BuildContext context, String label) {
    return ListTile(
      dense: true,
      leading: Icon(LucideIcons.check, color: Theme.of(context).colorScheme.primary, size: 16),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Toggle Light/Dark — senza crash GlobalKey.
  /// Legge il tema corrente via Theme.of(context).brightness (InheritedWidget cascade)
  /// invece di ref.watch(themeProvider), evitando il double-rebuild che causava
  /// "GlobalKey used multiple times — _InkFeatures" e "_dependents.isEmpty".
  Widget _buildThemeTile(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        isDark ? LucideIcons.moon : LucideIcons.sun,
        color: Theme.of(context).colorScheme.onSurface,
        size: 20,
      ),
      title: Text(
        "Tema App",
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: (v) => ref
            .read(themeProvider.notifier)
            .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
        activeColor: FyneColors.forest,
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
