import 'package:tflite_flutter/tflite_flutter.dart';
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
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

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
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/category_model.tflite');
      _isModelLoaded = true;
      print("✅ TFLite Model loaded successfully");
    } catch (e) {
      print("⚠️ TFLite Model load failed, using keyword fallback: $e");
    }
  }

  String getCategoryId(String name) {
    return _uuid.v5(Uuid.NAMESPACE_URL, name);
  }

  Future<Category> categorize(String description) async {
    final desc = description.toLowerCase();

    // 1. Try TFLite Inference if loaded
    if (_isModelLoaded && _interpreter != null) {
      try {
        final result = _runInference(desc);
        final prediction = result['label'] as String;
        final confidence = result['confidence'] as double;

        if (confidence >= 0.75) {
          print("🤖 TFLite Match: $prediction ($confidence)");
          return _getByName(prediction);
        }
      } catch (e) {
        print("🤖 TFLite Inference Error: $e");
      }
    }

    // 2. Keyword Fallback (Confidence < 75% or Model fail)
    return _keywordCategorize(desc);
  }

  Map<String, dynamic> _runInference(String text) {
    // Simple preprocessing: char-level or dummy tokenization for the placeholder
    // In a real scenario, this would match the training preprocessing
    var input = _preprocess(text);
    var output = List<double>.filled(supportedCategories.length, 0).reshape([1, supportedCategories.length]);

    _interpreter!.run(input, output);

    List<double> probabilities = List<double>.from(output[0]);
    int maxIndex = 0;
    double maxProb = 0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    return {
      'label': supportedCategories[maxIndex],
      'confidence': maxProb
    };
  }

  List<dynamic> _preprocess(String text) {
    // Basic text to tensor conversion
    // Clamping to 255 to prevent 'gather index out of bounds' if model vocab is small
    List<double> tensor = List.filled(50, 0.0);
    for (int i = 0; i < text.length && i < 50; i++) {
      tensor[i] = (text.codeUnitAt(i) % 255).toDouble();
    }
    return [tensor];
  }

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
