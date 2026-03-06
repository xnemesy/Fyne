import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fyne_theme.dart';
import '../../services/categorization_service.dart';

class CategoryPickerSheet extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  const CategoryPickerSheet({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final service = CategorizationService();
    final categories = service.supportedCategories
        .map((name) => Category(id: service.getCategoryId(name), name: name))
        .toList();

    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedId == category.id;
          return ListTile(
            onTap: () {
              onSelect(category);
              Navigator.of(context).pop();
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isSelected ? FyneColors.forest.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
            title: Text(
              category.name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: FyneColors.forest)
                : const Icon(Icons.chevron_right, color: FyneColors.inkLighter),
          );
        },
      ),
    );
  }
}
