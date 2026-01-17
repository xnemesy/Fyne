import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrencyService {
  // Tassi di cambio hardcoded per il prototipo (Base: EUR)
  final Map<String, double> _rates = {
    'EUR': 1.0,
    'USD': 0.92, // 1 USD = 0.92 EUR
    'GBP': 1.17, // 1 GBP = 1.17 EUR
    'JPY': 0.006,
    'CHF': 1.07,
    'BTC': 60000.0, // Example
    'ETH': 3000.0,
  };

  double convertToEur(double amount, String currency) {
    if (currency == 'EUR') return amount;
    
    final rate = _rates[currency] ?? 1.0;
    // Se è una crypto, il rate è il prezzo in EUR. Se è fiat, è il tasso di conversione.
    // Semplificazione per il prototipo: assumiamo che _rates contenga il valore in EUR di 1 unità della valuta
    
    // Per valute fiat comuni dove il tasso è spesso espresso come "Quanti EUR per 1 unità" (o viceversa),
    // qui usiamo: Valore in EUR = Quantità * Tasso (Prezzo di 1 unità in EUR)
    return amount * rate;
  }

  String formatCurrency(double amount, String currency) {
    return "${amount.toStringAsFixed(2)} $currency";
  }
}

final currencyServiceProvider = Provider((ref) => CurrencyService());
