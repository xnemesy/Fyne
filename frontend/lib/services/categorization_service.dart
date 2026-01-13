import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

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

  // Expanded Rule-based dictionary
  final Map<String, String> _staticRules = {
    'AMAZON': 'Shopping',
    'ESSELUNGA': 'Spesa',
    'CARREFOUR': 'Spesa',
    'LIDL': 'Spesa',
    'COOP': 'Spesa',
    'NETFLIX': 'Intrattenimento',
    'SPOTIFY': 'Intrattenimento',
    'DISNEY': 'Intrattenimento',
    'SHELL': 'Trasporti',
    'ENI': 'Trasporti',
    'UBER': 'Trasporti',
    'ZARA': 'Abbigliamento',
    'H&M': 'Abbigliamento',
    'REVOLUT': 'Trasferimenti',
    'PAYPAL': 'Shopping',
    'APPLE.COM': 'Servizi Digitali',
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

    // 2. Comprehensive Rule-based Engine
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
