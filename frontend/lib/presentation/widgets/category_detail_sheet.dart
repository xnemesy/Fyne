import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/categorization_provider.dart';
import '../../models/categorization_rule.dart';

// ─── Palette dark Fyne (inline per indipendenza dal barrel file) ──────────────

const _kInk     = Color(0xFF1A1A1A);
const _kSurface = Color(0xFF2A2A2A);
const _kForest  = Color(0xFF4A6741);
const _kPaper   = Color(0xFFF5F5F0);
const _kGhost   = Color(0xFF6B6B6B);

// ─── CategoryDetailSheet ──────────────────────────────────────────────────────

/// Bottom sheet per creare o modificare una categoria.
/// Sezioni: Nome · Icona · Colore · Parole Chiave (chip input).
class CategoryDetailSheet extends ConsumerStatefulWidget {
  /// Se null → creazione nuova categoria.
  final CategoryModel? category;

  const CategoryDetailSheet({super.key, this.category});

  @override
  ConsumerState<CategoryDetailSheet> createState() =>
      _CategoryDetailSheetState();
}

class _CategoryDetailSheetState extends ConsumerState<CategoryDetailSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _keywordCtrl;
  late String _selectedColor;
  late String _selectedIcon;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameCtrl    = TextEditingController(text: cat?.name ?? '');
    _keywordCtrl = TextEditingController();
    _selectedColor = cat?.colorHex ?? '#4A6741';
    _selectedIcon  = cat?.iconCode ?? 'e56c';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _keywordCtrl.dispose();
    super.dispose();
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    final notifier = ref.read(categoriesProvider.notifier);

    if (widget.category == null) {
      await notifier.add(
          name: name, iconCode: _selectedIcon, colorHex: _selectedColor);
    } else {
      await notifier.update(widget.category!.uuid,
          name: name, iconCode: _selectedIcon, colorHex: _selectedColor);
    }

    if (mounted) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    }
  }

  // ── Aggiunta keyword chip ─────────────────────────────────────────────────

  Future<void> _addKeyword(String categoryId, String categoryName) async {
    final kw = _keywordCtrl.text.trim().toLowerCase();
    if (kw.isEmpty) return;

    await ref
        .read(categorizationRulesProvider.notifier)
        .addRule(kw, categoryName, categoryId);

    _keywordCtrl.clear();
    HapticFeedback.lightImpact();
  }

  Future<void> _deleteKeyword(String ruleUuid) async {
    await ref
        .read(categorizationRulesProvider.notifier)
        .deleteRule(ruleUuid);
    HapticFeedback.lightImpact();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit  = widget.category != null;
    final catId   = widget.category?.uuid;
    final catName = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text
        : (widget.category?.name ?? '');

    // Regole esistenti per questa categoria
    final rules = catId != null
        ? ref.watch(categorizationRulesProvider.notifier).rulesForCategory(catId)
        : <CategorizationRule>[];

    return Container(
      decoration: const BoxDecoration(
        color: _kInk,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ─────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _kGhost.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Titolo ─────────────────────────────────────────────────────
            Text(
              isEdit ? 'Modifica Categoria' : 'Nuova Categoria',
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _kPaper,
              ),
            ),
            const SizedBox(height: 24),

            // ── Nome ───────────────────────────────────────────────────────
            _SectionLabel('NOME'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.inter(color: _kPaper, fontSize: 16),
              textCapitalization: TextCapitalization.sentences,
              enabled: !(widget.category?.isSystem ?? false),
              decoration: InputDecoration(
                hintText: 'Es. Viaggi, Crypto…',
                hintStyle:
                    GoogleFonts.inter(color: _kGhost, fontSize: 15),
                filled: true,
                fillColor: _kSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kForest, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // ── Icona ──────────────────────────────────────────────────────
            _SectionLabel('ICONA'),
            const SizedBox(height: 12),
            _IconPicker(
              selected: _selectedIcon,
              onSelect: (code) => setState(() => _selectedIcon = code),
            ),
            const SizedBox(height: 24),

            // ── Colore ─────────────────────────────────────────────────────
            _SectionLabel('COLORE'),
            const SizedBox(height: 12),
            _ColorPicker(
              selected: _selectedColor,
              onSelect: (hex) => setState(() => _selectedColor = hex),
            ),
            const SizedBox(height: 24),

            // ── Parole Chiave (solo in edit) ───────────────────────────────
            if (isEdit) ...[
              _SectionLabel('PAROLE CHIAVE AUTOMATICHE'),
              const SizedBox(height: 6),
              Text(
                'Le transazioni che contengono queste parole vengono assegnate automaticamente a questa categoria.',
                style: GoogleFonts.inter(
                    color: _kGhost, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 12),

              // Input keyword
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keywordCtrl,
                      style:
                          GoogleFonts.inter(color: _kPaper, fontSize: 14),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          _addKeyword(catId!, catName),
                      decoration: InputDecoration(
                        hintText: 'Es. spotify, netflix…',
                        hintStyle:
                            GoogleFonts.inter(color: _kGhost, fontSize: 13),
                        filled: true,
                        fillColor: _kSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: _kForest, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => _addKeyword(catId!, catName),
                    icon: const Icon(LucideIcons.plus, color: _kForest),
                    style: IconButton.styleFrom(
                      backgroundColor: _kForest.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chips esistenti
              if (rules.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rules.map((rule) {
                    return _KeywordChip(
                      label: rule.pattern,
                      onDelete: () => _deleteKeyword(rule.uuid),
                    );
                  }).toList(),
                )
              else
                Text('Nessuna parola chiave impostata.',
                    style: GoogleFonts.inter(
                        color: _kGhost, fontSize: 12)),
              const SizedBox(height: 24),
            ],

            // ── Salva ──────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kForest,
                  disabledBackgroundColor: _kSurface,
                  foregroundColor: _kPaper,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kPaper),
                      )
                    : Text(
                        isEdit ? 'SALVA MODIFICHE' : 'CREA CATEGORIA',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _IconPicker ──────────────────────────────────────────────────────────────

class _IconPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _IconPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: fyneCategoriIcons.map((code) {
        final isSelected = code == selected;
        final icon = _parseIcon(code);
        return GestureDetector(
          onTap: () => onSelect(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? _kForest.withValues(alpha: 0.25)
                  : _kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? _kForest : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(icon,
                color: isSelected ? _kForest : _kGhost, size: 22),
          ),
        );
      }).toList(),
    );
  }

  IconData _parseIcon(String codeHex) {
    try {
      return IconData(int.parse(codeHex, radix: 16),
          fontFamily: 'MaterialIcons');
    } catch (_) {
      return Icons.label_outline;
    }
  }
}

// ─── _ColorPicker ─────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _ColorPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: fyneCategoriColors.map((hex) {
        final color = Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
        final isSelected = hex == selected;
        return GestureDetector(
          onTap: () => onSelect(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _kPaper : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: _kPaper, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─── _KeywordChip ─────────────────────────────────────────────────────────────

class _KeywordChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _KeywordChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kForest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kForest.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: _kForest,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Icon(LucideIcons.x,
                size: 14,
                color: _kForest.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

// ─── _SectionLabel ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: _kGhost,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}
