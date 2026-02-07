import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/categorization_provider.dart';
import '../../services/categorization_service.dart';

class CategorizationRulesScreen extends ConsumerWidget {
  const CategorizationRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(categorizationRulesProvider);
    final service = ref.read(categorizationServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Regole Categorizzazione",
          style: GoogleFonts.lora(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
      ),
      body: rulesAsync.when(
        data: (rules) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              "KEYWORDS PERSONALIZZATE",
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            if (rules.isEmpty)
              _buildEmptyState()
            else
              ...rules.map((rule) => _buildRuleTile(context, ref, rule)),
            
            const SizedBox(height: 40),
            Text(
              "REGOLE DI SISTEMA (READ-ONLY)",
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            _buildSystemRulesInfo(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Errore: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRuleSheet(context, ref, service),
        backgroundColor: const Color(0xFF4A6741),
        icon: const Icon(LucideIcons.plus),
        label: Text("AGGIUNGI REGOLA", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRuleTile(BuildContext context, WidgetRef ref, dynamic rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1A1A).withOpacity(0.05)),
      ),
      child: ListTile(
        title: Text(rule.pattern, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        subtitle: Text("Categoria: ${rule.categoryName}", style: GoogleFonts.inter(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
          onPressed: () => ref.read(categorizationRulesProvider.notifier).deleteRule(rule.id),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.search, size: 48, color: const Color(0xFF1A1A1A).withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "Nessuna keyword personalizzata",
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            "Aggiungi parole chiave per categorizzare automaticamente le tue transazioni.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemRulesInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "Fyne include già regole per le principali catene (Esselunga, Amazon, Netflix, ecc.). Le tue regole personalizzate hanno sempre la precedenza.",
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1A1A).withOpacity(0.5), height: 1.5),
      ),
    );
  }

  void _showAddRuleSheet(BuildContext context, WidgetRef ref, CategorizationService service) {
    final patternController = TextEditingController();
    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 24, right: 24, top: 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFBFBF9),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nuova Keyword", style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: patternController,
              decoration: InputDecoration(
                hintText: "es. Coop, Benzinaio, Amazon...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Text("ASSEGNA A CATEGORIA", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: service.supportedCategories.map((cat) {
                final isSelected = selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    selectedCategory = cat;
                    (context as Element).markNeedsBuild();
                  },
                  selectedColor: const Color(0xFF4A6741),
                  labelStyle: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (patternController.text.isNotEmpty && selectedCategory != null) {
                    final catId = service.getCategoryId(selectedCategory!);
                    ref.read(categorizationRulesProvider.notifier).addRule(
                      patternController.text,
                      selectedCategory!,
                      catId,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6741),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text("SALVA REGOLA", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
