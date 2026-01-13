import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

/**
 * Local database model for user category overrides.
 * This is how the system "learns" from manual user input.
 */
@collection
class CategoryOverride {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String keyword; // e.g. "ESSELUNGA"
  
  late String categoryUuid;
  late String encryptedCategoryName;
}

/**
 * Categorization Engine: Rules + ML + Local Learning
 * Operates strictly on-device with decrypted data.
 */
class CategorizationService {
  final Isar isar;
  final _uuid = Uuid();

  // Rule-based dictionary (Default fallback)
  final Map<String, String> _staticRules = {
    'AMAZON': 'Shopping',
    'ESSELUNGA': 'Spesa',
    'CARREFOUR': 'Spesa',
    'NETFLIX': 'Intrattenimento',
    'SPOTIFY': 'Intrattenimento',
    'SHELL': 'Trasporti',
    'ENI': 'Trasporti',
    'ZARA': 'Abbigliamento',
  };

  CategorizationService(this.isar);

  /**
   * Scans decrypted transaction description to find the best category.
   */
  Future<String> categorize(String description) async {
    final cleanDesc = description.toUpperCase();

    // 1. Check Local Learning (User Overrides)
    final userOverride = await isar.categoryOverrides
        .filter()
        .keywordEqualTo(cleanDesc)
        .findFirst();
    if (userOverride != null) {
      return userOverride.categoryUuid;
    }

    // 2. Rule-based Engine
    for (var entry in _staticRules.entries) {
      if (cleanDesc.contains(entry.key)) {
        // In a real flow, we'd map 'Shopping' to its anonymous UUID
        return _getUuidForCategory(entry.value);
      }
    }

    // 3. Local ML Classifier (NLP)
    // Placeholder: tflite_flutter implementation
    // var prediction = await _runTFLiteInference(cleanDesc);
    // if (prediction.confidence > 0.8) return prediction.categoryUuid;

    // 4. Fallback (General)
    return _getUuidForCategory('Altro');
  }

  /**
   * "Learn" from user manual categorization.
   */
  Future<void> learn(String keyword, String categoryUuid, String encryptedName) async {
    final override = CategoryOverride()
      ..keyword = keyword.toUpperCase()
      ..categoryUuid = categoryUuid
      ..encryptedCategoryName = encryptedName;
    
    await isar.writeTxn(() async {
      await isar.categoryOverrides.put(override);
    });
  }

  // Helper to ensure consistency between anonymous UUIDs and Category names
  String _getUuidForCategory(String name) {
    // In a real app, this would lookup a local vault of [UUID -> Encrypted Name]
    // For this demonstration, we use deterministic UUIDs based on the name strings
    return name.toLowerCase().hashCode.toString(); 
  }
}
