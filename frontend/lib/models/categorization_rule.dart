import 'package:isar_community/isar.dart';

part 'categorization_rule.g.dart';

@Collection()
class CategorizationRule {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String uuid;

  @Index(unique: true)
  final String pattern;
  
  final String categoryId;
  final String categoryName;
  final bool isCustom;

  @Index()
  final DateTime updatedAt;

  @Index()
  final bool isDeleted;

  @Index()
  final int encryptionVersion;

  CategorizationRule({
    required this.uuid,
    required this.pattern,
    required this.categoryId,
    required this.categoryName,
    this.isCustom = true,
    required this.updatedAt,
    this.isDeleted = false,
    this.encryptionVersion = 1,
  });

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'pattern': pattern,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'isCustom': isCustom,
    'updated_at': updatedAt.toIso8601String(),
    'is_deleted': isDeleted,
    'encryption_version': encryptionVersion,
  };

  factory CategorizationRule.fromJson(Map<String, dynamic> json) => CategorizationRule(
    uuid: json['uuid'] ?? json['id'] ?? '',
    pattern: json['pattern'] ?? '',
    categoryId: json['categoryId'] ?? '',
    categoryName: json['categoryName'] ?? '',
    isCustom: json['isCustom'] ?? true,
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
    isDeleted: json['is_deleted'] ?? false,
    encryptionVersion: json['encryption_version'] ?? 1,
  );
}
