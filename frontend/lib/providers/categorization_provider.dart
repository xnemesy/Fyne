import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/categorization_rule.dart';
import 'isar_provider.dart';

class CategorizationNotifier extends StateNotifier<AsyncValue<List<CategorizationRule>>> {
  final Ref ref;

  CategorizationNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final isar = await ref.watch(isarProvider.future);
      final rules = await isar.categorizationRules.where().findAll();
      state = AsyncValue.data(rules);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRule(String pattern, String categoryName, String categoryUuid) async {
    try {
      final isar = await ref.read(isarProvider.future);
      final rule = CategorizationRule(
        pattern: pattern,
        categoryId: categoryUuid,
        categoryName: categoryName,
        isCustom: true,
      );

      await isar.writeTxn(() async {
        await isar.categorizationRules.put(rule);
      });

      await _loadRules();
    } catch (e) {
      print("Error adding rule: $e");
    }
  }

  Future<void> deleteRule(int id) async {
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.categorizationRules.delete(id);
      });
      await _loadRules();
    } catch (e) {
      print("Error deleting rule: $e");
    }
  }
}

final categorizationRulesProvider = StateNotifierProvider<CategorizationNotifier, AsyncValue<List<CategorizationRule>>>((ref) {
  return CategorizationNotifier(ref);
});
