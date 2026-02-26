import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../widgets/category_detail_sheet.dart';

// ─── Palette e costanti dark Fyne ─────────────────────────────────────────────

const _kInk     = Color(0xFF1A1A1A);
const _kSurface = Color(0xFF2A2A2A);
const _kForest  = Color(0xFF4A6741);
const _kForestL = Color(0xFF8FA68B);
const _kPaper   = Color(0xFFF5F5F0);
const _kGhost   = Color(0xFF6B6B6B);
const _kRust    = Color(0xFFB85450);

// ─── CategoryListScreen ───────────────────────────────────────────────────────

/// Schermata principale delle categorie.
/// Mostra la lista di tutte le categorie attive con navigazione verso il detail.
class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: _kInk,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _kInk,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: _kPaper),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Categorie',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kPaper,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // ── Corpo ─────────────────────────────────────────────────────────
          categoriesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: _kForest),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('Errore: $e',
                    style: GoogleFonts.inter(color: _kGhost)),
              ),
            ),
            data: (categories) {
              if (categories.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyState(),
                );
              }

              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _CategoryTile(
                    category: categories[i],
                    onTap: () => _openDetail(context, ref, categories[i]),
                    onDelete: categories[i].isSystem
                        ? null
                        : () => _confirmDelete(context, ref, categories[i]),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ── FAB Aggiungi categoria ─────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kForest,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _openDetail(context, ref, null),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  // ── Navigazione ────────────────────────────────────────────────────────────

  void _openDetail(
      BuildContext context, WidgetRef ref, CategoryModel? category) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryDetailSheet(category: category),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Elimina categoria',
            style: GoogleFonts.lora(color: _kPaper, fontWeight: FontWeight.bold)),
        content: Text(
          'Vuoi eliminare "${category.name}"? Le transazioni associate manterranno la categoria.',
          style: GoogleFonts.inter(color: _kGhost, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ANNULLA',
                style: GoogleFonts.inter(color: _kGhost, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ELIMINA',
                style: GoogleFonts.inter(color: _kRust, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await ref.read(categoriesProvider.notifier).delete(category.uuid);
    }
  }
}

// ─── _CategoryTile ────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CategoryTile({
    required this.category,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.colorHex);
    final icon  = _parseIcon(category.iconCode);

    return Dismissible(
      key: Key('cat-${category.uuid}'),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _kRust.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(LucideIcons.trash2, color: _kRust),
      ),
      confirmDismiss: (_) async {
        onDelete?.call();
        return false; // La delete è gestita dal dialog
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Icona categoria
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              // Nome + badge sistema
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.inter(
                        color: _kPaper,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (category.isSystem)
                      Text(
                        'Sistema',
                        style: GoogleFonts.inter(
                            color: _kGhost, fontSize: 11),
                      ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: _kGhost),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return _kForestL;
    }
  }

  IconData _parseIcon(String codeHex) {
    try {
      final code = int.parse(codeHex, radix: 16);
      return IconData(code, fontFamily: 'MaterialIcons');
    } catch (_) {
      return Icons.label_outline;
    }
  }
}

// ─── _EmptyState ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.tag,
              size: 48, color: _kGhost.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Nessuna categoria',
            style: GoogleFonts.inter(color: _kGhost, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
