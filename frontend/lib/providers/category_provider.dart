// category_provider.dart — CategoryNotifier per il modulo Gestione Categorie
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import 'isar_provider.dart';

// ─── Costanti palette Fyne per i colori categoria ─────────────────────────────

/// Palette limitata alle varianti coerenti con il design system Fyne.
const fyneCategoriColors = <String>[
  '#4A6741', // Forest (verde primario)
  '#7A9E74', // Moss chiaro
  '#355030', // Forest scuro
  '#8FA68B', // Sage
  '#B85450', // Rust
  '#9C4A40', // Rust scuro
  '#C8A84B', // Gold
  '#6B6B6B', // Stone neutro
];

/// Icone disponibili per le categorie (codice hex del codePoint Material).
/// Mostrate come griglia nella CategoryDetailSheet.
const fyneCategoriIcons = <String>[
  'e5da', // shopping_cart
  'e549', // restaurant
  'e57d', // directions_car
  'e8f8', // subscriptions
  'e56c', // local_grocery_store
  'e8b8', // favorite (wellness)
  'e87d', // home
  'e84d', // account_balance
  'e263', // flight
  'e533', // local_bar (vizi)
  'e559', // local_pharmacy
  'e153', // fitness_center
  'e0b7', // smartphone
  'e14e', // receipt
  'e2bd', // savings
  'e57e', // attach_money
];

// ─── Categorie di default (seed al primo avvio) ───────────────────────────────

class _DefaultCategory {
  final String name;
  final String iconCode;
  final String colorHex;
  const _DefaultCategory(this.name, this.iconCode, this.colorHex);
}

const _kDefaultCategories = <_DefaultCategory>[
  _DefaultCategory('Alimentari',  'e56c', '#4A6741'),
  _DefaultCategory('Abbonamenti', 'e8f8', '#355030'),
  _DefaultCategory('Fast Food',   'e549', '#B85450'),
  _DefaultCategory('Shopping',    'e5da', '#8FA68B'),
  _DefaultCategory('Trasporti',   'e57d', '#6B6B6B'),
  _DefaultCategory('Wellness',    'e8b8', '#7A9E74'),
  _DefaultCategory('Vizi',        'e533', '#9C4A40'),
  _DefaultCategory('Altro',       'e14e', '#6B6B6B'),
];

// ─── CategoryNotifier ─────────────────────────────────────────────────────────

class CategoryNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final Ref _ref;
  final _uuid = const Uuid();

  CategoryNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  // ── Caricamento e seed ───────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final isar = await _ref.read(isarProvider.future);
      final cats = await isar.categoryModels
          .where()
          .isDeletedEqualTo(false)
          .sortByName()
          .findAll();

      if (cats.isEmpty) {
        // Primo avvio: seed delle categorie di sistema
        await _seedDefaults(isar);
        return _load();
      }

      state = AsyncValue.data(cats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> _seedDefaults(Isar isar) async {
    final defaults = _kDefaultCategories.map((d) => CategoryModel(
      uuid:      _uuid.v5('6ba7b811-9dad-11d1-80b4-00c04fd430c8', 'fyne:category:${d.name}'),
          name:      d.name,
          iconCode:  d.iconCode,
          colorHex:  d.colorHex,
          isSystem:  true,
          isDeleted: false,
          updatedAt: DateTime.now(),
        ));

    await isar.writeTxn(() async {
      for (final cat in defaults) {
        await isar.categoryModels.put(cat);
      }
    });
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  /// Aggiunge una nuova categoria custom.
  Future<void> add({
    required String name,
    required String iconCode,
    required String colorHex,
  }) async {
    final isar = await _ref.read(isarProvider.future);
    final cat = CategoryModel(
      uuid:      _uuid.v4(),
      name:      name.trim(),
      iconCode:  iconCode,
      colorHex:  colorHex,
      isSystem:  false,
      isDeleted: false,
      updatedAt: DateTime.now(),
    );
    await isar.writeTxn(() async => isar.categoryModels.put(cat));
    await _load();
  }

  /// Aggiorna nome, icona o colore di una categoria esistente.
  Future<void> update(
    String uuid, {
    String? name,
    String? iconCode,
    String? colorHex,
  }) async {
    final isar = await _ref.read(isarProvider.future);
    final existing = await isar.categoryModels
        .where()
        .uuidEqualTo(uuid)
        .findFirst();
    if (existing == null) return;

    final updated = existing.copyWith(
      name:     name,
      iconCode: iconCode,
      colorHex: colorHex,
    );
    await isar.writeTxn(() async => isar.categoryModels.put(updated));
    await _load();
  }

  /// Soft-delete — solo categorie custom (isSystem=false).
  Future<bool> delete(String uuid) async {
    final isar = await _ref.read(isarProvider.future);
    final existing = await isar.categoryModels
        .where()
        .uuidEqualTo(uuid)
        .findFirst();
    if (existing == null || existing.isSystem) return false;

    final deleted = existing.copyWith(isDeleted: true);
    await isar.writeTxn(() async => isar.categoryModels.put(deleted));
    await _load();
    return true;
  }

  // ── Helper lookup ─────────────────────────────────────────────────────────

  /// Restituisce la categoria per UUID.
  CategoryModel? findById(String uuid) {
    return state.value?.firstWhere(
      (c) => c.uuid == uuid,
      orElse: () => state.value!.firstWhere((c) => c.name == 'Altro'),
    );
  }

  /// Restituisce la categoria per nome (es. 'Alimentari').
  CategoryModel? findByName(String name) {
    return state.value
        ?.where((c) => c.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
  }

  /// UUID deterministico per la categoria di sistema con il nome dato.
  /// Utile per risolvere il categoryId in CategorizationRule senza query.
  String systemUuidForName(String name) =>
      _uuid.v5('6ba7b811-9dad-11d1-80b4-00c04fd430c8', 'fyne:category:$name');
}

// ─── Provider ────────────────────────────────────────────────────────────────

final categoriesProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<CategoryModel>>>(
        (ref) => CategoryNotifier(ref));
