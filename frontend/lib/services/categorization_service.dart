import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'categorization_service.g.dart';

@collection
class CategoryOverride {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String keyword; 
  
  late String categoryUuid;
  late String decryptedCategoryName;
}

class CategorizationService {
  final Isar isar;
  final _uuid = Uuid();

  // Editorial Rule-based dictionary
  final Map<String, String> _staticRules = {
    'AMAZON': 'Shopping',
    'ESSELUNGA': 'Alimentari',
    'CARREFOUR': 'Alimentari',
    'LIDL': 'Alimentari',
    'COOP': 'Alimentari',
    'NETFLIX': 'Sottoscrizioni',
    'SPOTIFY': 'Sottoscrizioni',
    'DISNEY': 'Sottoscrizioni',
    'SHELL': 'Mobilità',
    'ENI': 'Mobilità',
    'UBER': 'Mobilità',
    'ZARA': 'Stile',
    'H&M': 'Stile',
    'REVOLUT': 'Trasferimenti',
    'PAYPAL': 'Shopping',
    'APPLE.COM': 'Digital',
    'SUSHI': 'Alimentari',
  };

  CategorizationService(this.isar);

  /**
   * Scans decrypted transaction description to find the best category UUID.
   */
  Future<String> categorize(String description) async {
    final cleanDesc = description.toUpperCase();

    // 1. Check Local Learning (User Overrides)
    final userOverride = await isar.categoryOverrides
        .filter()
        .keywordContains(cleanDesc)
        .findFirst();
    if (userOverride != null) {
      return userOverride.categoryUuid;
    }

    // 2. Editorial Rule-based Engine
    for (var entry in _staticRules.entries) {
      if (cleanDesc.contains(entry.key)) {
        return _getDeterministicUuid(entry.value);
      }
    }

    // 3. Fallback
    return _getDeterministicUuid('Altro');
  }

  /**
   * Deterministic UUID for static categories to maintain cross-device consistency
   * without a centralized clear-text registry.
   */
  String _getDeterministicUuid(String name) {
    return _uuid.v5(Uuid.NAMESPACE_URL, "fyne.app/category/${name.toLowerCase()}");
  }

  /**
   * Persist a manual change to learn for the future.
   */
  Future<void> learn(String keyword, String categoryUuid, String decryptedName) async {
    final override = CategoryOverride()
      ..keyword = keyword.toUpperCase()
      ..categoryUuid = categoryUuid
      ..decryptedCategoryName = decryptedName;
    
    await isar.writeTxn(() async {
      await isar.categoryOverrides.put(override);
    });
  }
}
