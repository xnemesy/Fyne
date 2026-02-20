import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/categorization_rule.dart';
import 'isar_provider.dart';

class CategorizationNotifier
    extends StateNotifier<AsyncValue<List<CategorizationRule>>> {
  final Ref _ref;
  final _uuid = const Uuid();

  CategorizationNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final isar = await _ref.watch(isarProvider.future);
      final rules = await isar.categorizationRules
          .where()
          .isDeletedEqualTo(false)
          .findAll();
      state = AsyncValue.data(rules);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRule(
      String pattern, String categoryName, String categoryUuid) async {
    try {
      final isar = await _ref.read(isarProvider.future);
      final rule = CategorizationRule(
        uuid: _uuid.v4(),
        pattern: pattern,
        categoryId: categoryUuid,
        categoryName: categoryName,
        isCustom: true,
        updatedAt: DateTime.now(),
        isDeleted: false,
      );

      await isar.writeTxn(() async {
        await isar.categorizationRules.put(rule);
      });

      await _loadRules();
    } catch (e) {
      print("Error adding rule: $e");
    }
  }

  Future<void> deleteRule(String uuid) async {
    try {
      final isar = await _ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        final existing = await isar.categorizationRules
            .where()
            .uuidEqualTo(uuid)
            .findFirst();
        if (existing != null) {
          final deletedRule = CategorizationRule(
            uuid: existing.uuid,
            pattern: existing.pattern,
            categoryId: existing.categoryId,
            categoryName: existing.categoryName,
            isCustom: existing.isCustom,
            updatedAt: DateTime.now(),
            isDeleted: true,
          );
          await isar.categorizationRules.put(deletedRule);
        }
      });
      await _loadRules();
    } catch (e) {
      print("Error deleting rule: $e");
    }
  }
}

final categorizationRulesProvider = StateNotifierProvider<
    CategorizationNotifier, AsyncValue<List<CategorizationRule>>>((ref) {
  return CategorizationNotifier(ref);
});
