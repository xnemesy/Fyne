import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.settings, size: 28, color: Color(0xFF8E8E93)),
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
                    _buildTile(LucideIcons.user, "Profilo", authState.user?.email ?? "utente@fyne.it"),
                    _buildTile(LucideIcons.shield, "Sicurezza & Privacy", "Zero-Knowledge attivo"),
                  ]),
                  _buildSection("PREFERENZE", [
                    _buildTile(LucideIcons.palette, "Tema", "Segui sistema"),
                    _buildTile(LucideIcons.bell, "Notifiche", "Attive"),
                    _buildTile(LucideIcons.coins, "Valuta", "EUR (€)"),
                  ]),
                  _buildSection("SISTEMA", [
                    _buildTile(LucideIcons.database, "Esporta Dati", "CSV, PDF"),
                    _buildTile(LucideIcons.info, "Info su Fyne", "v1.0.0"),
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

  Widget _buildTile(IconData icon, String title, String value) {
    return ListTile(
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
}
