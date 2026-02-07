import '../models/categorization_rule.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Category {
// ... (imports and class start)
  final String id;
  final String name;
  final bool isHealthFocus;

  Category({required this.id, required this.name, this.isHealthFocus = false});
}

class CategorizationService {
  final _uuid = const Uuid();
  // Interpreter? _interpreter;
  // bool _isModelLoaded = false;

  // Categories Mapping (Order must match Model output indices)
  List<String> get supportedCategories => [
    'Abbonamenti',
    'Alimentari',
    'Altro',
    'Fast Food',
    'Shopping',
    'Trasporti',
    'Vizi',
    'Wellness'
  ];

  late final Map<String, Category> _categoryMap;

  CategorizationService() {
    _categoryMap = {
      for (var name in supportedCategories)
        _uuid.v5(Uuid.NAMESPACE_URL, name): Category(
          id: _uuid.v5(Uuid.NAMESPACE_URL, name),
          name: name,
          isHealthFocus: name == 'Wellness',
        )
    };
  }

  Future<void> loadModel() async {
    print("ℹ️ Categorization: Dynamic Rules Mode (No AI)");
  }

  String getCategoryId(String name) {
    return _uuid.v5(Uuid.NAMESPACE_URL, name);
  }

  Future<Category> categorize(String description, {List<CategorizationRule>? customRules}) async {
    final desc = description.toLowerCase();

    // 1. Check Custom User Rules (Priority)
    if (customRules != null) {
      for (var rule in customRules) {
        if (desc.contains(rule.pattern.toLowerCase())) {
          return _getByName(rule.categoryName);
        }
      }
    }

    // 2. Fallback to Hardcoded Rules
    return _keywordCategorize(desc);
  }

/*
  Map<String, dynamic> _runInference(String text) {
    // ...
  }

  List<dynamic> _preprocess(String text) {
    // ...
  }
*/

  Category _keywordCategorize(String desc) {
    // 1. Alimentari
    if (_matches(desc, ['esselunga', 'lidl', 'carrefour', 'coop', 'conad', 'pam', 'eurospin', 'supermercato', 'spesa'])) {
      return _getByName('Alimentari');
    }

    // 2. Wellness (Health-Focus)
    if (_matches(desc, ['virgin active', 'mcfit', 'palestra', 'gym', 'farmacia', 'parafarmacia', 'myprotein', 'decathlon', 'centro medico', 'nutrizionista', 'salute', 'sport'])) {
      return _getByName('Wellness');
    }

    // 3. Fast Food
    if (_matches(desc, ['mcdonald', 'burger king', 'kfc', 'poke', 'sushi', 'pizza', 'takeaway'])) {
      return _getByName('Fast Food');
    }

    // 4. Shopping
    if (_matches(desc, ['amazon', 'zalando', 'ebay', 'temu', 'shein', 'ikea'])) {
      return _getByName('Shopping');
    }

    // 5. Trasporti
    if (_matches(desc, ['eni', 'shell', 'q8', 'benzina', 'carburante', 'trenitalia', 'italo', 'uber', 'taxi', 'atm', 'mobility'])) {
      return _getByName('Trasporti');
    }

    // 6. Abbonamenti
    if (_matches(desc, ['netflix', 'spotify', 'disney', 'dazn', 'prime video', 'apple.com/bill'])) {
      return _getByName('Abbonamenti');
    }

    // 7. Vizi
    if (_matches(desc, ['tabacchi', 'sigarette', 'scommesse', 'casino'])) {
      return _getByName('Vizi');
    }

    return _getByName('Altro');
  }

  bool _matches(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k.toLowerCase()));
  }

  Category _getByName(String name) {
    final id = getCategoryId(name);
    return _categoryMap[id] ?? _categoryMap[getCategoryId('Altro')]!;
  }
}

final categorizationServiceProvider = Provider<CategorizationService>((ref) => CategorizationService());
