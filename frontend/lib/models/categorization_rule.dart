import 'package:isar/isar.dart';

part 'categorization_rule.g.dart';

@Collection()
class CategorizationRule {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String pattern;
  
  final String categoryId;
  final String categoryName;
  final bool isCustom;

  CategorizationRule({
    required this.pattern,
    required this.categoryId,
    required this.categoryName,
    this.isCustom = true,
  });
}
