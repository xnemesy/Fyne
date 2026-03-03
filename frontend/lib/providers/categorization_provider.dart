import 'package:flutter/foundation.dart';
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
        pattern: pattern.trim().toLowerCase(),
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
      debugPrint('[Categorization] Error adding rule: $e');
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
      debugPrint('[Categorization] Error deleting rule: $e');
    }
  }

  // ── Matching deterministico (No-AI Policy) ────────────────────────────────

  /// Verifica in modo *strict* e case-insensitive se la descrizione matcha
  /// una delle regole utente.
  ///
  /// Priorità: regole custom (isCustom=true) prima delle regole di sistema.
  /// Algoritmo: `.toLowerCase().contains()` — niente fuzzy search.
  /// Restituisce il [categoryId] della prima regola che fa match, o null.
  String? matchKeyword(String description) {
    final lower = description.toLowerCase().trim();
    if (lower.isEmpty) return null;

    final rules = state.value ?? [];

    // 1. Priorità alle regole custom dell'utente
    for (final rule in rules.where((r) => r.isCustom)) {
      if (lower.contains(rule.pattern.toLowerCase())) return rule.categoryId;
    }

    // 2. Fallback: regole di sistema
    for (final rule in rules.where((r) => !r.isCustom)) {
      if (lower.contains(rule.pattern.toLowerCase())) return rule.categoryId;
    }

    return null;
  }

  /// Restituisce tutte le regole per un dato [categoryId].
  List<CategorizationRule> rulesForCategory(String categoryId) {
    return (state.value ?? [])
        .where((r) => r.categoryId == categoryId)
        .toList();
  }
}

final categorizationRulesProvider = StateNotifierProvider<
    CategorizationNotifier, AsyncValue<List<CategorizationRule>>>((ref) {
  return CategorizationNotifier(ref);
});
