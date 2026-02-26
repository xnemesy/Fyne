import 'package:isar_community/isar.dart';

part 'category_model.g.dart';

// ─── CategoryModel ─────────────────────────────────────────────────────────────
//
// Metadati categoria: NON cifrati per garantire query ultra-veloci.
// Campi sensibili non presenti in questo modello.
//
// `iconCode`: stringa hex del codePoint di un'icona Material/LucideIcons.
//              Es. '0xe3af' per Icons.shopping_cart.
// `colorHex`: colore in formato '#RRGGBB' dalla palette Fyne.
// `isSystem`: se true, la categoria è di default e non può essere eliminata.

@Collection()
class CategoryModel {
  Id id = Isar.autoIncrement;

  /// UUID univoco univoco categoria (usato come chiave referenziale in CategorizationRule)
  @Index(unique: true, replace: true)
  late String uuid;

  /// Nome leggibile della categoria (es. "Alimentari")
  @Index()
  late String name;

  /// Codice esadecimale del codePoint icona (es. '0xe5ce' per LucideIcons)
  late String iconCode;

  /// Colore hex dalla palette Fyne (es. '#4A6741')
  late String colorHex;

  /// True per le 8 categorie di sistema seeded al primo avvio
  late bool isSystem;

  /// Soft-delete per compatibilità sync
  @Index()
  late bool isDeleted;

  late DateTime updatedAt;

  CategoryModel({
    required this.uuid,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    this.isSystem = false,
    this.isDeleted = false,
    required this.updatedAt,
  });

  CategoryModel copyWith({
    String? name,
    String? iconCode,
    String? colorHex,
    bool? isDeleted,
  }) => CategoryModel(
        uuid:      uuid,
        name:      name ?? this.name,
        iconCode:  iconCode ?? this.iconCode,
        colorHex:  colorHex ?? this.colorHex,
        isSystem:  isSystem,
        isDeleted: isDeleted ?? this.isDeleted,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'uuid':       uuid,
        'name':       name,
        'iconCode':   iconCode,
        'colorHex':   colorHex,
        'isSystem':   isSystem,
        'isDeleted':  isDeleted,
        'updatedAt':  updatedAt.toIso8601String(),
      };
}
